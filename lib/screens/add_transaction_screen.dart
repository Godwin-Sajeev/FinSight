import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();
  final TextEditingController _amountController =
      TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _category = "General";

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final newTransaction = TransactionModel(
      id: Uuid().v4(),
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      category: _category,
      type: _selectedType,
    );

    ref
        .read(transactionProvider.notifier)
        .addTransaction(newTransaction);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Transaction"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter title" : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter amount" : null,
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text("Income"),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text("Expense"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration:
                    const InputDecoration(labelText: "Type"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}