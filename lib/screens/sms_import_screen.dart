import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/ml_service.dart';
import '../../providers/finance_provider.dart';
import '../../core/models/transaction_model.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

/// A screen that lets users paste one or more bank SMS messages
/// OR sync directly from their device's real SMS inbox.
class SmsImportScreen extends ConsumerStatefulWidget {
  const SmsImportScreen({super.key});

  @override
  ConsumerState<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends ConsumerState<SmsImportScreen> {
  final _smsController = TextEditingController();
  final _senderController = TextEditingController();

  bool _analyzing = false;
  bool _syncing = false;
  final List<_ImportResult> _results = [];

  // ── Sync from real inbox ──────────────────────────────────────────────────
  Future<void> _syncRealInbox() async {
    setState(() => _syncing = true);

    try {
      // 1. Request Permission
      final permission = await Permission.sms.request();
      if (!permission.isGranted) {
        setState(() => _syncing = false);
        _showError('SMS Permission denied. Please enable it in Settings.');
        return;
      }

      // 2. Fetch SMS
      final SmsQuery query = SmsQuery();
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50, // Scan last 50 messages for demo efficiency
      );

      if (messages.isEmpty) {
        _showError('No messages found in your inbox.');
        setState(() => _syncing = false);
        return;
      }

      // 3. Filter for likely transaction messages
      final List<SmsMessage> potentialTxns = messages.where((m) {
        final body = m.body?.toLowerCase() ?? '';
        return body.contains('rs.') ||
               body.contains('inr') ||
               body.contains('₹') ||
               body.contains('amt') ||
               body.contains('debited') ||
               body.contains('credited') ||
               body.contains('upi') ||
               body.contains('paid') ||
               body.contains('received');
      }).toList();

      if (potentialTxns.isEmpty) {
        _showError('No transaction-related messages found in your last 50 SMS.');
        setState(() => _syncing = false);
        return;
      }

      // 4. Process each message
      int savedCount = 0;
      for (final msg in potentialTxns) {
        final body = msg.body ?? '';
        final sender = msg.address;

        setState(() => _analyzing = true); // Update UI state for each
        final result = await MLService.analyzeSms(
          smsBody: body,
          senderId: sender,
        );

        if (result != null && !result.rejected && result.nlp?.amount != null) {
          final nlp = result.nlp!;
          final category = _guessCategory(nlp.merchant ?? '');

          final tx = TransactionModel(
            title: nlp.merchant?.isNotEmpty == true ? nlp.merchant! : 'SMS Sync',
            merchantName: nlp.merchant?.isNotEmpty == true ? nlp.merchant! : 'Unknown',
            amount: nlp.amount!,
            date: msg.date ?? DateTime.now(),
            category: category,
            isExpense: nlp.type != 'credit',
          );

          ref.read(transactionProvider.notifier).addTransaction(tx);
          savedCount++;

          _addResult(_ImportResult(
            smsSnippet: _snippet(body),
            status: _ImportStatus.saved,
            message: '✅ Auto-Synced: ₹${tx.amount.toStringAsFixed(0)} · ${tx.title}',
            transaction: tx,
          ));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync complete! Imported $savedCount transactions.')),
      );

    } catch (e) {
      _showError('Error during sync: $e');
    } finally {
      setState(() {
        _syncing = false;
        _analyzing = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Analyze + save (Manual Paste) ──────────────────────────────────────────
  Future<void> _analyzeSms() async {
    final sms = _smsController.text.trim();
    if (sms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste an SMS first.')),
      );
      return;
    }

    setState(() => _analyzing = true);

    final senderId = _senderController.text.trim();
    final result = await MLService.analyzeSms(
      smsBody: sms,
      senderId: senderId.isEmpty ? null : senderId,
    );

    setState(() => _analyzing = false);

    if (result == null) {
      _addResult(_ImportResult(
        smsSnippet: _snippet(sms),
        status: _ImportStatus.serverError,
        message: 'ML server not reachable. Make sure the Python backend is running.',
      ));
      return;
    }

    if (result.rejected) {
      _addResult(_ImportResult(
        smsSnippet: _snippet(sms),
        status: _ImportStatus.rejected,
        message: result.reason ?? 'Not a UPI transaction SMS.',
      ));
      return;
    }

    // --- NLP successfully extracted data ---
    final nlp = result.nlp;
    final ml = result.ml;

    if (nlp == null || nlp.amount == null) {
      _addResult(_ImportResult(
        smsSnippet: _snippet(sms),
        status: _ImportStatus.rejected,
        message: 'Could not extract amount from SMS.',
      ));
      return;
    }

    // Determine category based on merchant name
    String category = _guessCategory(nlp.merchant ?? '');

    // Auto-save transaction
    final tx = TransactionModel(
      title: nlp.merchant?.isNotEmpty == true ? nlp.merchant! : 'UPI Transaction',
      merchantName: nlp.merchant?.isNotEmpty == true ? nlp.merchant! : 'Unknown',
      amount: nlp.amount!,
      date: DateTime.now(),
      category: category,
      isExpense: nlp.type != 'credit',
    );

    ref.read(transactionProvider.notifier).addTransaction(tx);

    // Build success message
    final mlMsg = ml != null
        ? ' | Risk: ${ml.riskLabel} (${ml.riskPercent}%)'
        : '';

    _addResult(_ImportResult(
      smsSnippet: _snippet(sms),
      status: _ImportStatus.saved,
      message:
          '✅ Saved: ${tx.isExpense ? "−" : "+"}₹${tx.amount.toStringAsFixed(0)} · ${tx.title} · ${tx.category}$mlMsg',
      transaction: tx,
    ));

    // Clear fields for next SMS
    _smsController.clear();
    _senderController.clear();
  }

  void _addResult(_ImportResult r) => setState(() => _results.insert(0, r));

  String _snippet(String sms) =>
      sms.length > 60 ? '${sms.substring(0, 60)}…' : sms;

  String _guessCategory(String merchant) {
    final m = merchant.toLowerCase();
    if (m.contains('swiggy') || m.contains('zomato') || m.contains('food') || m.contains('restaurant')) return 'Food';
    if (m.contains('amazon') || m.contains('flipkart') || m.contains('myntra') || m.contains('shop')) return 'Shopping';
    if (m.contains('electricity') || m.contains('airtel') || m.contains('jio') || m.contains('bill')) return 'Bills';
    if (m.contains('uber') || m.contains('ola') || m.contains('rapido') || m.contains('railway') || m.contains('travel')) return 'Travel';
    if (m.contains('netflix') || m.contains('spotify') || m.contains('hotstar') || m.contains('prime')) return 'Entertainment';
    return 'General';
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from SMS'),
        actions: [
          if (_results.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _results.clear()),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Input area ────────────────────────────────────────────────
          Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                    border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sparkles, color: AppColors.primaryAccent, size: 16),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'Paste a bank SMS and tap Analyze. NLP will extract the amount, merchant, and type — then auto-save it as a transaction.',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                // NEW: Sync Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                    ),
                    onPressed: _syncing ? null : _syncRealInbox,
                    icon: _syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.refreshCw, size: 18),
                    label: Text(
                      _syncing ? 'Syncing Inbox...' : 'Sync Device Inbox (Real SMS)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Gap(24),

                const Text(
                  'OR MANUALLY PASTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(12),

                // Sender ID
                TextField(
                  controller: _senderController,
                  decoration: InputDecoration(
                    labelText: 'Sender ID (optional)',
                    hintText: 'e.g. VM-SBIUPI, JD-HDFC',
                    prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                ),
                const Gap(12),

                // SMS text
                TextField(
                  controller: _smsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Paste Bank SMS Here',
                    hintText: 'Rs.1250 debited from your SBI account...',
                    prefixIcon: const Icon(LucideIcons.messageSquare, size: 18),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const Gap(12),

                // Analyze button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                    ),
                    onPressed: _analyzing ? null : _analyzeSms,
                    icon: _analyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.zap, size: 18),
                    label: Text(
                      _analyzing ? 'Analyzing with NLP...' : 'Analyze & Save Transaction',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Results list ─────────────────────────────────────────────
          if (_results.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'IMPORT LOG',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_results.length}',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (context, i) => _ResultCard(result: _results[i]),
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.messageSquarePlus,
                      size: 48,
                      color: AppColors.divider,
                    ),
                    const Gap(16),
                    Text(
                      'Paste a bank SMS above\nto auto-import a transaction',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Result card widget ────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final _ImportResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (result.status) {
      case _ImportStatus.saved:
        iconColor = const Color(0xFF28C76F);
        bgColor = const Color(0xFF28C76F).withOpacity(0.08);
        icon = LucideIcons.checkCircle;
        break;
      case _ImportStatus.rejected:
        iconColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.08);
        icon = LucideIcons.alertTriangle;
        break;
      case _ImportStatus.serverError:
        iconColor = AppColors.danger;
        bgColor = AppColors.danger.withOpacity(0.08);
        icon = LucideIcons.wifiOff;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.message,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  '"${result.smsSnippet}"',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
enum _ImportStatus { saved, rejected, serverError }

class _ImportResult {
  final String smsSnippet;
  final _ImportStatus status;
  final String message;
  final TransactionModel? transaction;

  const _ImportResult({
    required this.smsSnippet,
    required this.status,
    required this.message,
    this.transaction,
  });
}
