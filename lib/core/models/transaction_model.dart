import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String merchantName;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final bool isExpense;

  @HiveField(7)
  final String? bankSource;

  @HiveField(8)
  final String? aiComment;

  TransactionModel({
    String? id,
    required this.title,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    required this.isExpense,
    this.bankSource,
    this.aiComment,
  }) : id = id ?? Uuid().v4();
}
