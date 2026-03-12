// Import flutter
import 'package:flutter/material.dart';

// Import model
import '../core/models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {

  // 🔥 This receives the full transaction object
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction, // 👈 IMPORTANT
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Transaction Details"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              // Transaction Title
              Text(
                transaction.title,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Amount
              Text(
                "${transaction.isExpense ? "-" : "+"} ₹ ${transaction.amount.abs()}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: transaction.isExpense
                      ? Colors.redAccent
                      : Colors.greenAccent,
                ),
              ),

              const SizedBox(height: 20),

              // Category
              Text(
                "Category: ${transaction.category}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 10),

              // Date
              Text(
                "Date: ${transaction.date.toLocal()}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
