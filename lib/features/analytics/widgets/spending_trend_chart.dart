import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/transaction_model.dart';
import '../../../../providers/finance_provider.dart';

class SpendingTrendChart extends ConsumerWidget {
  final int selectedPeriod; // 0=Daily, 1=Monthly, 2=Yearly

  const SpendingTrendChart({super.key, required this.selectedPeriod});

  List<FlSpot> _getSpots(List<TransactionModel> transactions) {
    // Only count expenses
    final expenses = transactions.where((tx) => tx.type == TransactionType.expense).toList();
    final now = DateTime.now();

    List<double> values;
    if (selectedPeriod == 0) {
      // Daily: 7 slots representing hours (e.g. 6am, 9am, 12pm, 3pm, 6pm, 9pm, 12am)
      values = List.filled(7, 0.0);
      final todayExpenses = expenses.where((tx) => 
        tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day);
      
      for (var tx in todayExpenses) {
        final hour = tx.date.hour;
        if (hour >= 6 && hour < 9) values[0] += tx.amount;
        else if (hour >= 9 && hour < 12) values[1] += tx.amount;
        else if (hour >= 12 && hour < 15) values[2] += tx.amount;
        else if (hour >= 15 && hour < 18) values[3] += tx.amount;
        else if (hour >= 18 && hour < 21) values[4] += tx.amount;
        else if (hour >= 21 || hour < 0) values[5] += tx.amount; 
        else values[6] += tx.amount; // Midnight to 6am
      }
    } else if (selectedPeriod == 2) {
      // Yearly: 7 slots representing bi-monthly (Jan, Mar, May, Jul, Sep, Nov, Dec)
      values = List.filled(7, 0.0);
      final yearExpenses = expenses.where((tx) => tx.date.year == now.year);
      
      for (var tx in yearExpenses) {
        final month = tx.date.month;
        if (month <= 2) values[0] += tx.amount;
        else if (month <= 4) values[1] += tx.amount;
        else if (month <= 6) values[2] += tx.amount;
        else if (month <= 8) values[3] += tx.amount;
        else if (month <= 10) values[4] += tx.amount;
        else if (month == 11) values[5] += tx.amount;
        else values[6] += tx.amount; // Dec
      }
    } else {
      // Monthly: 4 slots representing weeks (W1, W2, W3, W4)
      values = List.filled(7, 0.0); // Keep size 7 to match UI width
      final monthExpenses = expenses.where((tx) => 
        tx.date.year == now.year && tx.date.month == now.month);
      
      for (var tx in monthExpenses) {
        final day = tx.date.day;
        if (day <= 7) values[0] += tx.amount;
        else if (day <= 14) values[1] += tx.amount;
        else if (day <= 21) values[2] += tx.amount;
        else values[3] += tx.amount;
      }
    }

    // Convert to spots. Divide by 1000 for 'k' scale if large numbers, else raw.
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i] / 1000.0));
    }
    return spots;
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10.0;
    double maxVal = 0;
    for (var spot in spots) {
      if (spot.y > maxVal) maxVal = spot.y;
    }
    // Return maxVal plus 20% padding, minimum 1
    return (maxVal * 1.2).clamp(1.0, double.infinity);
  }

  List<String> get _bottomLabels {
    switch (selectedPeriod) {
      case 0: // Daily
        return ['6am', '9am', '12pm', '3pm', '6pm', '9pm', '12am'];
      case 2: // Yearly
        return ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov', 'Dec'];
      default: // Monthly
        return ['W1', 'W2', 'W3', 'W4', '', '', ''];
    }
  }

  String get _chartTitle {
    switch (selectedPeriod) {
      case 0:
        return 'Today\'s Spending';
      case 2:
        return 'Yearly Overview';
      default:
        return 'This Month\'s Trend';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final spots = _getSpots(transactions);
    final maxY = _getMaxY(spots);
    final labels = _bottomLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_chartTitle, style: AppTypography.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.listSpacing),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey(selectedPeriod),
            height: 220,
            padding: const EdgeInsets.only(right: 20, left: 8, top: 20, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1, // 4 horizontal steps
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox();
                        final label = labels[idx];
                        if (label.isEmpty) return const SizedBox();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(label, style: AppTypography.textTheme.labelSmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4 > 0 ? maxY / 4 : 1,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}k',
                          style: AppTypography.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryAccent.withValues(alpha: 0.15),
                          AppColors.primaryAccent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
