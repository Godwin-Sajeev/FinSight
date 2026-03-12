// finance_service.dart
// This is the financial brain of the application
// All calculations happen here

import '../core/models/transaction_model.dart';

class FinanceService {

  // calculate total income
  double totalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((t) => !t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // calculate total expense
  double totalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // calculate balance
  double balance(List<TransactionModel> transactions) {
    return totalIncome(transactions) - totalExpense(transactions);
  }

  // category breakdown for analytics
  Map<String, double> categoryBreakdown(
      List<TransactionModel> transactions) {

    final Map<String, double> data = {};

    for (var t in transactions) {
      if (t.isExpense) {
        data[t.category] =
            (data[t.category] ?? 0) + t.amount;
      }
    }

    return data;
  }

  // basic AI insight generator
  String generateInsight(List<TransactionModel> transactions) {
    final total = totalExpense(transactions);

    if (total == 0) {
      return "No expenses recorded yet.";
    }

    final breakdown = categoryBreakdown(transactions);

    final highest = breakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return "Your highest spending is on ${highest.key}. "
           "Try reducing it by 10% to improve savings.";
  }
}
