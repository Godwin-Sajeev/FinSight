import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'ai_insight_model.g.dart';

@HiveType(typeId: 1)
class AIInsightModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double monthlyGrowthPercent;

  @HiveField(2)
  final String topCategory;

  @HiveField(3)
  final double predictedEMI;

  @HiveField(4)
  final String savingsSuggestion;

  @HiveField(5)
  final List<String> riskAlerts;

  AIInsightModel({
    String? id,
    required this.monthlyGrowthPercent,
    required this.topCategory,
    required this.predictedEMI,
    required this.savingsSuggestion,
    required this.riskAlerts,
  }) : id = id ?? const Uuid().v4();
}
