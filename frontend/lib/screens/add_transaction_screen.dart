import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _smsFormKey = GlobalKey<FormState>();

  // Manual form
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _category = "General";

  // SMS analysis
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();
  bool _isAnalyzing = false;
  SmsAnalysisResult? _analysisResult;
  String? _analysisError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _smsController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final newTransaction = TransactionModel(
      id: const Uuid().v4(),
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      category: _category,
      type: _selectedType,
    );

    ref.read(transactionProvider.notifier).addTransaction(newTransaction);
    Navigator.pop(context);
  }

  Future<void> _analyzeSms() async {
    if (!_smsFormKey.currentState!.validate()) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _analysisError = null;
    });

    try {
      final result = await ApiService.analyzeSms(
        message: _smsController.text,
        senderId: _senderController.text.isNotEmpty
            ? _senderController.text
            : null,
      );
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _analysisError = e.toString().replaceFirst('Exception: ', '');
        _isAnalyzing = false;
      });
    }
  }

  void _saveFromSms() {
    final r = _analysisResult;
    if (r == null) return;

    final newTransaction = TransactionModel(
      id: const Uuid().v4(),
      title: r.merchant ?? 'SMS Transaction',
      amount: r.amount ?? 0.0,
      date: DateTime.now(),
      category: 'General',
      type: r.type == 'credit'
          ? TransactionType.income
          : TransactionType.expense,
    );

    ref.read(transactionProvider.notifier).addTransaction(newTransaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Transaction"),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: "Manual"),
            Tab(icon: Icon(Icons.sms), text: "From SMS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── Tab 1: Manual Entry ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => v!.isEmpty ? "Enter title" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount"),
                    validator: (v) => v!.isEmpty ? "Enter amount" : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<TransactionType>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(
                          value: TransactionType.income,
                          child: Text("Income")),
                      DropdownMenuItem(
                          value: TransactionType.expense,
                          child: Text("Expense")),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v!),
                    decoration: const InputDecoration(labelText: "Type"),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
          ),

          // ─── Tab 2: SMS AI Analysis ─────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _smsFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Paste your bank SMS below and our AI will extract\ntransaction details automatically.",
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _smsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "SMS Message",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      hintText:
                          "e.g. Rs.500 debited from a/c **1234 to SWIGGY via UPI...",
                    ),
                    validator: (v) =>
                        v!.isEmpty ? "Paste an SMS message" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senderController,
                    decoration: const InputDecoration(
                      labelText: "Sender ID (optional)",
                      hintText: "e.g. VM-SBIUPI",
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeSms,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isAnalyzing ? "Analyzing..." : "Analyze SMS"),
                  ),

                  // Error
                  if (_analysisError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisError!,
                              style: TextStyle(
                                  color: colorScheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Result cards
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 24),
                    _SectionHeader("Extracted Details"),
                    const SizedBox(height: 8),
                    _ResultCard(children: [
                      _ResultRow("Amount",
                          "₹ ${_analysisResult!.amount?.toStringAsFixed(2) ?? 'N/A'}"),
                      _ResultRow("Type",
                          (_analysisResult!.type ?? 'N/A').toUpperCase()),
                      _ResultRow(
                          "Merchant", _analysisResult!.merchant ?? 'N/A'),
                      _ResultRow("Date", _analysisResult!.date ?? 'N/A'),
                      _ResultRow(
                          "Bank", _analysisResult!.bankName ?? 'N/A'),
                    ]),
                    const SizedBox(height: 16),
                    _SectionHeader("Risk Assessment"),
                    const SizedBox(height: 8),
                    _AlertCard(
                      level: _analysisResult!.alertLevel,
                      message: _analysisResult!.alertMessage,
                      probability: _analysisResult!.failureProbability,
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader("Budget Status"),
                    const SizedBox(height: 8),
                    _BudgetCard(
                      level: _analysisResult!.budgetAlertLevel,
                      message: _analysisResult!.budgetAlertMessage,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveFromSms,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      icon: const Icon(Icons.save),
                      label: const Text("Save Transaction"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
}

class _ResultCard extends StatelessWidget {
  final List<Widget> children;
  const _ResultCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String level;
  final String message;
  final double probability;
  const _AlertCard(
      {required this.level, required this.message, required this.probability});

  Color get _color {
    switch (level) {
      case 'HIGH':
        return Colors.red.shade700;
      case 'MEDIUM':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _color.withOpacity(0.1),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: _color),
                const SizedBox(width: 8),
                Text(level,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _color,
                        fontSize: 15)),
                const Spacer(),
                Text(
                    "Risk: ${(probability * 100).toStringAsFixed(0)}%",
                    style: TextStyle(color: _color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String level;
  final String message;
  const _BudgetCard({required this.level, required this.message});

  @override
  Widget build(BuildContext context) {
    final isWarning = level == 'WARNING';
    final color =
        isWarning ? Colors.orange.shade700 : Colors.green.shade700;
    return Card(
      color: color.withOpacity(0.1),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
                isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: color),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}