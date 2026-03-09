import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class CategoryDonutChart extends StatelessWidget {
  final int selectedPeriod; // 0=Daily, 1=Monthly, 2=Yearly
  const CategoryDonutChart({super.key, required this.selectedPeriod});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: AppTypography.textTheme.titleLarge,
        ),
        const Gap(AppSpacing.listSpacing),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: PieChart(
                    key: ValueKey(selectedPeriod),
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _sectionsFor(selectedPeriod),
                    ),
                  ),
                ),
              ),
              const Gap(24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _legendFor(selectedPeriod),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _sectionsFor(int period) {
    // Different data per period
    final data = period == 0
        ? [('Food', 45, const Color(0xFFFF9F43)), ('Bills', 30, const Color(0xFFEA5455)), ('Other', 25, AppColors.divider)]
        : period == 2
            ? [('Food', 28, const Color(0xFFFF9F43)), ('Shopping', 30, const Color(0xFF00CFE8)), ('Bills', 22, const Color(0xFFEA5455)), ('Travel', 20, const Color(0xFF7367F0))]
            : [('Food', 35, const Color(0xFFFF9F43)), ('Shopping', 22, const Color(0xFF00CFE8)), ('Bills', 18, const Color(0xFFEA5455)), ('Travel', 10, const Color(0xFF7367F0)), ('Other', 15, AppColors.divider)];

    return data.map((e) => PieChartSectionData(color: e.$3, value: e.$2.toDouble(), title: '', radius: 20)).toList();
  }

  Widget _legendFor(int period) {
    final data = period == 0
        ? [('Food', 45, const Color(0xFFFF9F43)), ('Bills', 30, const Color(0xFFEA5455)), ('Other', 25, AppColors.divider)]
        : period == 2
            ? [('Food', 28, const Color(0xFFFF9F43)), ('Shopping', 30, const Color(0xFF00CFE8)), ('Bills', 22, const Color(0xFFEA5455)), ('Travel', 20, const Color(0xFF7367F0))]
            : [('Food', 35, const Color(0xFFFF9F43)), ('Shopping', 22, const Color(0xFF00CFE8)), ('Bills', 18, const Color(0xFFEA5455)), ('Travel', 10, const Color(0xFF7367F0))];

    return Column(
      key: ValueKey(period),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildLegend(e.$1, e.$2, e.$3),
      )).toList(),
    );
  }

  Widget _buildLegend(String title, int percent, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$percent%',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
