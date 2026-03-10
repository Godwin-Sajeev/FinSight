import 'dart:convert';
import 'package:http/http.dart' as http;

/// The base URL for the Python FastAPI backend.
/// Change this to your server's IP if running on a physical device.
/// For emulators use http://10.0.2.2:8000, for real device use your PC's LAN IP.
const String _baseUrl = 'http://127.0.0.1:8000';

class SmsAnalysisResult {
  final Map<String, dynamic> nlpExtraction;
  final Map<String, dynamic> mlAnalysis;

  SmsAnalysisResult({required this.nlpExtraction, required this.mlAnalysis});

  factory SmsAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SmsAnalysisResult(
      nlpExtraction: json['nlp_extraction'] ?? {},
      mlAnalysis: json['ml_analysis'] ?? {},
    );
  }

  /// Convenience getters for the most important fields
  double? get amount => (nlpExtraction['amount'] as num?)?.toDouble();
  String? get type => nlpExtraction['type'];
  String? get merchant => nlpExtraction['merchant'];
  String? get date => nlpExtraction['date'];
  String? get bankName => nlpExtraction['bank_name'];

  String get alertLevel =>
      (mlAnalysis['transaction_alert']?['level'] ?? 'LOW').toString();
  String get alertMessage =>
      (mlAnalysis['transaction_alert']?['message'] ?? '').toString();
  double get failureProbability =>
      (mlAnalysis['combined_failure_probability'] as num?)?.toDouble() ?? 0.0;

  String get budgetAlertLevel =>
      (mlAnalysis['budget_alert']?['level'] ?? 'OK').toString();
  String get budgetAlertMessage =>
      (mlAnalysis['budget_alert']?['message'] ?? '').toString();
}

class ApiService {
  static Future<SmsAnalysisResult> analyzeSms({
    required String message,
    String? senderId,
    String userId = 'USER_DEFAULT',
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/process_sms');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'sender_id': senderId,
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      return SmsAnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to analyze SMS');
    }
  }

  static Future<bool> isBackendOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
