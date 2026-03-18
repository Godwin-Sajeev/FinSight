import '../models/transaction_model.dart';

class AppAIService {
  static String processQuery(String query, List<TransactionModel> transactions) {
    final lowerQuery = query.toLowerCase();

    // 1. Total Spending / Balance questions
    if (lowerQuery.contains('total') || lowerQuery.contains('how much')) {
      if (lowerQuery.contains('food')) {
        return _calculateCategoryTotal(transactions, 'Food');
      } else if (lowerQuery.contains('travel')) {
        return _calculateCategoryTotal(transactions, 'Travel');
      } else if (lowerQuery.contains('shopping')) {
        return _calculateCategoryTotal(transactions, 'Shopping');
      } else if (lowerQuery.contains('bills')) {
        return _calculateCategoryTotal(transactions, 'Bills');
      } else if (lowerQuery.contains('income')) {
        final total = transactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
        return "Your total income is ₹${total.toStringAsFixed(2)}.";
      } else {
        final total = transactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
        return "Your total spending is ₹${total.toStringAsFixed(2)}.";
      }
    }

    // 2. Count questions
    if (lowerQuery.contains('many') || lowerQuery.contains('number of')) {
      final count = transactions.length;
      return "You have recorded $count transactions in total.";
    }

    // 3. Highest Spending
    if (lowerQuery.contains('highest') || lowerQuery.contains('expensive')) {
      final expenses = transactions.where((t) => t.isExpense).toList();
      if (expenses.isEmpty) return "I don't see any expenses yet.";
      expenses.sort((a, b) => b.amount.compareTo(a.amount));
      final top = expenses.first;
      return "Your most expensive transaction was '${top.title}' for ₹${top.amount.toStringAsFixed(2)}.";
    }

    // 4. Greetings / Generic
    if (lowerQuery.contains('hi') || lowerQuery.contains('hello')) {
      return "Hello! I'm your FinSight assistant. Ask me about your spending, like 'How much did I spend on Food?'";
    }

    return "I'm still learning, but I can help you with totals, category spending, or finding your most expensive purchase. Try asking 'Total food spend'.";
  }

  static String _calculateCategoryTotal(List<TransactionModel> transactions, String category) {
    final total = transactions
        .where((t) => t.isExpense && t.category.toLowerCase() == category.toLowerCase())
        .fold(0.0, (sum, t) => sum + t.amount);
    
    if (total == 0) {
      return "You haven't spent anything in the $category category yet.";
    }
    return "You've spent a total of ₹${total.toStringAsFixed(2)} on $category.";
  }
}
