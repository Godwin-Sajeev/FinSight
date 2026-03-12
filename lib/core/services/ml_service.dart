// lib/core/services/ml_service.dart
// ---------------------------------------------------------------------------
// HTTP service that connects the Flutter app to the Python FastAPI backend.
//
// The Android emulator reaches the host machine's localhost at 10.0.2.2.
// Change BASE_URL to your PC's LAN IP if testing on a real device.
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import '../models/transaction_model.dart';

class MLService {
  // Real device: Use your PC's LAN IP
  static const String _baseUrl = 'http://192.168.23.29:8001';

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Sends a real 6-digit OTP to the provided email.
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      print('[MLService] Calling /auth/send-otp for $email');
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      print('[MLService] Response status: ${res.statusCode}');
      print('[MLService] Response body: ${res.body}');

      return jsonDecode(res.body);
    } catch (e) {
      print('[MLService] sendOtp error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Verifies the OTP and saves the token to SharedPreferences on success.
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      print('[MLService] Calling /auth/verify-otp for $email');
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 10));

      print('[MLService] Response status: ${res.statusCode}');
      final data = jsonDecode(res.body);
      
      if (data['success'] == true && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setString('user_email', email);
      }
      
      return data;
    } catch (e) {
      print('[MLService] verifyOtp error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Checks if the user is currently logged in.
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('auth_token');
    } catch (e) {
      return false;
    }
  }

  /// Logs out the user by clearing the token.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
  }

  // ── Health check ───────────────────────────────────────────────────────────
  /// Returns true if the Python server is running and ML model is trained.
  static Future<bool> isServerAlive() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'ok' && data['ml_trained'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Analyze SMS ────────────────────────────────────────────────────────────
  /// Sends an SMS body (and optional sender ID) to the Python NLP+ML pipeline.
  ///
  /// Returns an [MLAnalysisResult] containing extracted transaction data
  /// and ML failure prediction, or null if server is unreachable.
  static Future<MLAnalysisResult?> analyzeSms({
    required String smsBody,
    String? senderId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/analyze-sms'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sms_body': smsBody,
              if (senderId != null) 'sender_id': senderId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return MLAnalysisResult.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Budget summary ─────────────────────────────────────────────────────────
  /// Sends transaction list to Python budget engine and returns budget insights.
  static Future<BudgetResult?> getBudgetSummary({
    required List<Map<String, dynamic>> transactions,
    double monthlyBudget = 15000.0,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/budget'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'transactions': transactions,
              'monthly_budget': monthlyBudget,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return BudgetResult.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class MLAnalysisResult {
  final bool rejected;
  final String? reason;
  final NLPData? nlp;
  final MLData? ml;

  MLAnalysisResult({
    required this.rejected,
    this.reason,
    this.nlp,
    this.ml,
  });

  factory MLAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MLAnalysisResult(
      rejected: json['rejected'] ?? true,
      reason:   json['reason'],
      nlp:      json['nlp'] != null ? NLPData.fromJson(json['nlp']) : null,
      ml:       json['ml']  != null ? MLData.fromJson(json['ml'])   : null,
    );
  }
}

class NLPData {
  final double? amount;
  final String? type;       // 'debit' | 'credit'
  final String? merchant;
  final String? date;
  final String? status;     // 'success' | 'failed'
  final String? bankName;
  final String? senderId;
  final double? confidence;

  NLPData({
    this.amount,
    this.type,
    this.merchant,
    this.date,
    this.status,
    this.bankName,
    this.senderId,
    this.confidence,
  });

  factory NLPData.fromJson(Map<String, dynamic> json) {
    return NLPData(
      amount:     (json['amount'] as num?)?.toDouble(),
      type:       json['type'],
      merchant:   json['merchant'],
      date:       json['date'],
      status:     json['status'],
      bankName:   json['bank_name'],
      senderId:   json['sender_id'],
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class MLData {
  final double failureProbability;
  final double combinedFailureProbability;
  final String alertLevel;    // 'LOW' | 'MEDIUM' | 'HIGH'
  final String alertMessage;

  MLData({
    required this.failureProbability,
    required this.combinedFailureProbability,
    required this.alertLevel,
    required this.alertMessage,
  });

  factory MLData.fromJson(Map<String, dynamic> json) {
    return MLData(
      failureProbability:         (json['failure_probability']          as num).toDouble(),
      combinedFailureProbability: (json['combined_failure_probability'] as num).toDouble(),
      alertLevel:                 json['alert_level']   ?? 'LOW',
      alertMessage:               json['alert_message'] ?? 'Transaction looks safe.',
    );
  }

  /// Human-readable risk label.
  String get riskLabel {
    if (alertLevel == 'HIGH')   return 'High Risk';
    if (alertLevel == 'MEDIUM') return 'Medium Risk';
    return 'Low Risk';
  }

  /// Risk percentage (0–100).
  int get riskPercent => (combinedFailureProbability * 100).round();
}

class BudgetResult {
  final double totalDailySpend;
  final double totalMonthlySpend;
  final double monthlyBudget;
  final double? monthlySpendPercentage;
  final Map<String, double> categoryBreakdown;
  final int transactionCount;
  final String budgetAlertLevel;    // 'OK' | 'WARNING'
  final String budgetAlertMessage;

  BudgetResult({
    required this.totalDailySpend,
    required this.totalMonthlySpend,
    required this.monthlyBudget,
    this.monthlySpendPercentage,
    required this.categoryBreakdown,
    required this.transactionCount,
    required this.budgetAlertLevel,
    required this.budgetAlertMessage,
  });

  factory BudgetResult.fromJson(Map<String, dynamic> json) {
    final summary = json['budget_summary'] as Map<String, dynamic>;
    final alert   = json['budget_alert']   as Map<String, dynamic>;

    final rawBreakdown = summary['category_breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = rawBreakdown.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    return BudgetResult(
      totalDailySpend:        (summary['total_daily_spend']   as num).toDouble(),
      totalMonthlySpend:      (summary['total_monthly_spend'] as num).toDouble(),
      monthlyBudget:          (summary['monthly_budget']      as num).toDouble(),
      monthlySpendPercentage: (summary['monthly_spend_percentage'] as num?)?.toDouble(),
      categoryBreakdown:      breakdown,
      transactionCount:       summary['transaction_count'] as int? ?? 0,
      budgetAlertLevel:       alert['level']   ?? 'OK',
      budgetAlertMessage:     alert['message'] ?? 'Budget OK.',
    );
  }

  bool get isOverBudget    => budgetAlertLevel == 'WARNING';
  double get remainingBudget => monthlyBudget - totalMonthlySpend;
}
