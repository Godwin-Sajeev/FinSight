import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/models/transaction_model.dart';

final transactionProvider =
    StateNotifierProvider<FinanceNotifier, List<TransactionModel>>((ref) {
  return FinanceNotifier();
});

class FinanceNotifier extends StateNotifier<List<TransactionModel>> {
  FinanceNotifier() : super([]) {
    loadTransactions();
  }

  late Box<TransactionModel> _box;

  void loadTransactions() async {
    _box = await Hive.openBox<TransactionModel>('transactions');
    state = _box.values.toList();
  }

  void addTransaction(TransactionModel transaction) async {
    await _box.put(transaction.id, transaction);
    state = _box.values.toList();
  }

  void deleteTransaction(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }

  double totalIncome() {
    return state
        .where((t) => !t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double totalExpense() {
    return state
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  /// Detects potential recurring transactions based on frequency and title.
  List<Map<String, dynamic>> getRecurringTransactions() {
    // Group transactions by title
    final Map<String, List<TransactionModel>> grouped = {};
    for (var t in state) {
      if (!t.isExpense) continue;
      grouped.update(t.title, (list) => list..add(t), ifAbsent: () => [t]);
    }

    final List<Map<String, dynamic>> recurring = [];

    grouped.forEach((title, list) {
      if (list.length >= 2) {
        // Simple logic: if seen more than twice with similar amounts
        final avgAmount = list.fold(0.0, (sum, t) => sum + t.amount) / list.length;
        recurring.add({
          'title': title,
          'avgAmount': avgAmount,
          'count': list.length,
          'category': list.first.category,
          'lastDate': list.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b),
        });
      }
    });

    return recurring;
  }
}
