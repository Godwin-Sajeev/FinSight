import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/finance_provider.dart';
import '../core/ai_engine.dart';

class AIDetailScreen extends ConsumerWidget {
  const AIDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    final income = AIEngine.totalIncome(transactions);
    final expense = AIEngine.totalExpense(transactions);
    final balance = income - expense;
    final highestCategory = AIEngine.highestSpendingCategory(transactions);
    final suggestion = AIEngine.savingPrediction(transactions);

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        title: const Text("AI Financial Report"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            // 💰 Balance Overview
            _infoCard(
              title: "Current Balance",
              value: "₹ ${balance.toStringAsFixed(0)}",
              color: Colors.greenAccent,
            ),

            const SizedBox(height: 16),

            _infoCard(
              title: "Total Income",
              value: "₹ ${income.toStringAsFixed(0)}",
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            _infoCard(
              title: "Total Expenses",
              value: "₹ ${expense.toStringAsFixed(0)}",
              color: Colors.redAccent,
            ),

            const SizedBox(height: 24),

            // 🏷 Highest Spending Category
            const Text(
              "Highest Spending Category",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                highestCategory,
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 24),

            // 🤖 AI Suggestion
            const Text(
              "AI Suggestion",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                suggestion,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
