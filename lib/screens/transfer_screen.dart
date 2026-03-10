import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../core/ai_engine.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() =>
      _TransferScreenState();
}

class _TransferScreenState
    extends ConsumerState<TransferScreen> {

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _titleController =
      TextEditingController();

  String selectedCategory = "Shopping";

  @override
  Widget build(BuildContext context) {

    final transactions = ref.watch(transactionProvider);
    final suggestion =
        AIEngine.suggestion(transactions);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2F),
      appBar: AppBar(
        title: const Text("Transfer Money"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Title",
                labelStyle:
                    TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount",
                labelStyle:
                    TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 16),

            // Category
            DropdownButton<String>(
              value: selectedCategory,
              dropdownColor: const Color(0xFF1E2A4A),
              items: [
                "Shopping",
                "Food",
                "Bills",
                "Others",
              ]
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat,
                            style: const TextStyle(
                                color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedCategory = val!;
                });
              },
            ),

            const SizedBox(height: 30),

            // SEND BUTTON
            ElevatedButton(
              onPressed: () {

                final amount =
                    double.tryParse(_amountController.text);

                if (amount == null ||
                    _titleController.text.isEmpty) {
                  return;
                }

                // =========================
                // FIXED: ADD ID
                // =========================
                ref
                    .read(transactionProvider.notifier)
                    .addTransaction(
                      TransactionModel(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        title: _titleController.text,
                        amount: amount,
                        date: DateTime.now(),
                        category: selectedCategory,
                        type: TransactionType.expense,
                      ),
                    );

                _amountController.clear();
                _titleController.clear();
              },
              child: const Text("Send Money"),
            ),

            const SizedBox(height: 30),

            // AI Suggestion
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A4A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                suggestion,
                style:
                    const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
