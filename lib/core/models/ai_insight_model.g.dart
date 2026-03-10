// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_insight_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIInsightModelAdapter extends TypeAdapter<AIInsightModel> {
  @override
  final int typeId = 1;

  @override
  AIInsightModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIInsightModel(
      id: fields[0] as String?,
      monthlyGrowthPercent: fields[1] as double,
      topCategory: fields[2] as String,
      predictedEMI: fields[3] as double,
      savingsSuggestion: fields[4] as String,
      riskAlerts: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AIInsightModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.monthlyGrowthPercent)
      ..writeByte(2)
      ..write(obj.topCategory)
      ..writeByte(3)
      ..write(obj.predictedEMI)
      ..writeByte(4)
      ..write(obj.savingsSuggestion)
      ..writeByte(5)
      ..write(obj.riskAlerts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIInsightModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
