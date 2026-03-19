import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../core/models/transaction_model.dart';
import '../core/services/ml_service.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;
  
  const AddTransactionScreen({
    super.key, 
    this.initialTitle, 
    this.initialAmount,
    this.initialCategory,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController    = TextEditingController();
  final TextEditingController _amountController   = TextEditingController();
  final TextEditingController _smsController      = TextEditingController();
  final TextEditingController _senderIdController = TextEditingController();

  bool            _isExpense    = true;
  DateTime        _selectedDate = DateTime.now();
  String          _category     = 'General';
  bool            _isSaving     = false;
  String?         _mlComment;
  String?         _mlAlertLevel;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _category = widget.initialCategory!;
    }
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  final List<String> _categories = [
    'Food', 'Bills', 'Travel', 'Shopping', 'Others', 'General',
  ];

  // ── SMS Analysis (calls Python API) ───────────────────────────────────────
  Future<void> _analyzeSmS() async {
    final sms      = _smsController.text.trim();
    final senderId = _senderIdController.text.trim();
    if (sms.isEmpty) return;

    setState(() {
      _isSaving   = true;
      _mlComment  = null;
    });

    final result = await MLService.analyzeSms(
      smsBody:  sms,
      senderId: senderId.isEmpty ? null : senderId,
    );

    setState(() => _isSaving = false);

    if (result == null) {
      setState(() => _mlComment = 'ML server not reachable. Enter details manually.');
      return;
    }

    if (result.rejected) {
      setState(() {
        _mlComment  = 'Rejected: ${result.reason ?? "Invalid sender or not a transaction."}';
        _mlAlertLevel = 'HIGH';
      });
      return;
    }

    // Auto-fill form fields from NLP result
    final nlp = result.nlp;
    if (nlp != null) {
      if (nlp.amount != null) {
        _amountController.text = nlp.amount!.toStringAsFixed(2);
      }
      if (nlp.merchant != null && nlp.merchant!.isNotEmpty) {
        _titleController.text = nlp.merchant!;
      }
      if (nlp.type == 'credit') {
        setState(() => _isExpense = false);
      } else {
        setState(() => _isExpense = true);
      }
    }

    // Show ML alert
    final ml = result.ml;
    if (ml != null) {
      setState(() {
        _mlAlertLevel = ml.alertLevel;
        _mlComment    =
            '${ml.riskLabel} (${ml.riskPercent}% failure chance) — ${ml.alertMessage}';
      });
    }
  }

  // ── Save transaction ───────────────────────────────────────────────────────
  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final tx = TransactionModel(
      title:        _titleController.text.trim(),
      merchantName: _titleController.text.trim(),
      amount:       double.parse(_amountController.text),
      date:         _selectedDate,
      category:     _category,
      isExpense:    _isExpense,
      aiComment:    _mlComment,
    );

    ref.read(transactionProvider.notifier).addTransaction(tx);
    Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── SMS Auto-fill section ─────────────────────────────────────
              _sectionLabel('Smart SMS Detection (optional)'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _senderIdController,
                decoration: const InputDecoration(
                  labelText: 'Sender ID',
                  hintText:  'e.g. VM-SBIUPI, JD-IPBMSG-S',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _smsController,
                decoration: const InputDecoration(
                  labelText:  'Paste SMS Here',
                  hintText:   'Rs.1250 debited from...',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _analyzeSmS,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isSaving ? 'Analyzing...' : 'Analyze with AI'),
              ),

              // ── ML Alert Banner ───────────────────────────────────────────
              if (_mlComment != null) ...[
                const SizedBox(height: 12),
                _alertBanner(_mlComment!, _mlAlertLevel),
              ],

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              // ── Manual fields ─────────────────────────────────────────────
              _sectionLabel('Transaction Details'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText:  'Title / Merchant',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller:  _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText:   'Amount (INR)',
                  prefixIcon:  Icon(Icons.currency_rupee),
                ),
                validator: (v) => v!.isEmpty ? 'Enter an amount' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<bool>(
                value: _isExpense,
                decoration: const InputDecoration(
                  labelText:  'Type',
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: const [
                  DropdownMenuItem(
                      value: true, child: Text('Expense')),
                  DropdownMenuItem(
                      value: false, child: Text('Income')),
                ],
                onChanged: (v) => setState(() => _isExpense = v!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText:  'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.4,
        ),
      );

  Widget _alertBanner(String message, String? level) {
    final isHigh   = level == 'HIGH';
    final isMedium = level == 'MEDIUM';
    final color    = isHigh
        ? Colors.red.shade700
        : isMedium
            ? Colors.orange.shade700
            : Colors.green.shade700;
    final bgColor  = isHigh
        ? Colors.red.shade50
        : isMedium
            ? Colors.orange.shade50
            : Colors.green.shade50;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isHigh ? Icons.warning_amber_rounded : Icons.info_outline,
            color: color, size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}