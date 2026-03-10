import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class SpendingTrendChart extends StatelessWidget {
  final int selectedPeriod; // 0=Daily, 1=Monthly, 2=Yearly

  const SpendingTrendChart({super.key, required this.selectedPeriod});

  List<FlSpot> get _spots {
    switch (selectedPeriod) {
      case 0: // Daily — hourly pattern
        return const [
          FlSpot(0, 0.5),
          FlSpot(1, 1.2),
          FlSpot(2, 0.8),
          FlSpot(3, 2.4),
          FlSpot(4, 1.9),
          FlSpot(5, 3.1),
          FlSpot(6, 2.0),
        ];
      case 2: // Yearly — monthly totals
        return const [
          FlSpot(0, 2.8),
          FlSpot(1, 3.5),
          FlSpot(2, 2.1),
          FlSpot(3, 4.8),
          FlSpot(4, 3.9),
          FlSpot(5, 5.2),
          FlSpot(6, 4.5),
        ];
      default: // Monthly — weekly pattern
        return const [
          FlSpot(0, 3),
          FlSpot(1, 2),
          FlSpot(2, 5),
          FlSpot(3, 3.1),
          FlSpot(4, 4),
          FlSpot(5, 3),
          FlSpot(6, 4),
        ];
    }
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
  Widget build(BuildContext context) {
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
                  horizontalInterval: 1,
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
                      interval: 1,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0) return const SizedBox();
                        return Text(
                          '${value.toInt()}k',
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
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
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
