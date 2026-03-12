import '../core/models/transaction_model.dart';

class AIEngine {

  // ==============================
  // TOTAL INCOME
  // ==============================
  static double totalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((tx) => !tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // ==============================
  // TOTAL EXPENSE
  // ==============================
  static double totalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // ==============================
  // HIGHEST SPENDING CATEGORY
  // ==============================
  static String highestSpendingCategory(List<TransactionModel> transactions) {
    final breakdown = categoryBreakdown(transactions);
    if (breakdown.isEmpty) return 'No data yet';
    final highest = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${highest.key} (₹${highest.value.toStringAsFixed(0)})';
  }

  // ==============================
  // CATEGORY BREAKDOWN (For Donut)
  // ==============================
  static Map<String, double> categoryBreakdown(
      List<TransactionModel> transactions) {

    final Map<String, double> data = {};

    for (var tx in transactions) {
      if (tx.isExpense) {
        data[tx.category] =
            (data[tx.category] ?? 0) + tx.amount;
      }
    }

    return data;
  }

  // ==============================
  // MONTHLY COMPARISON
  // ==============================
  static Map<String, double> monthlyComparison(
      List<TransactionModel> transactions) {

    final now = DateTime.now();
    final currentMonth = now.month;
    final previousMonth = now.month - 1;

    double current = 0;
    double previous = 0;

    for (var tx in transactions) {
      if (tx.isExpense) {
        if (tx.date.month == currentMonth) {
          current += tx.amount;
        } else if (tx.date.month == previousMonth) {
          previous += tx.amount;
        }
      }
    }

    return {
      "current": current,
      "previous": previous,
    };
  }

  // ==============================
  // SAVING PREDICTION
  // ==============================
  static String savingPrediction(
      List<TransactionModel> transactions) {

    final breakdown = categoryBreakdown(transactions);

    if (breakdown.isEmpty) {
      return "Start tracking expenses to get AI insights.";
    }

    final highest = breakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    final saveAmount = highest.value * 0.15;

    return "You spend most on ${highest.key}. "
        "Reduce 15% and save ₹${saveAmount.toStringAsFixed(0)}.";
  }

  // ==============================
  // QUICK AI SUGGESTION
  // ==============================
  static String suggestion(
      List<TransactionModel> transactions) {

    final comparison = monthlyComparison(transactions);

    if (comparison["current"]! > comparison["previous"]!) {
      return "Your spending increased this month. Try cutting unnecessary expenses.";
    } else {
      return "Great! Your spending is under control this month.";
    }
  }
}
