import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

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
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double totalExpense() {
    return state
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }
}
