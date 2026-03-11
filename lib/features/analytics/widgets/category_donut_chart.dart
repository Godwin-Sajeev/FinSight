import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/transaction_model.dart';
import '../../../../providers/finance_provider.dart';

class CategoryDonutChart extends ConsumerWidget {
  final int selectedPeriod; // 0=Daily, 1=Monthly, 2=Yearly
  const CategoryDonutChart({super.key, required this.selectedPeriod});

  List<(String, double, Color)> _getCategoryData(List<TransactionModel> transactions) {
    // Return Top 4 + Other
    final expenses = transactions.where((tx) => tx.type == TransactionType.expense).toList();
    final now = DateTime.now();

    Iterable<TransactionModel> filteredTxs;
    if (selectedPeriod == 0) {
      filteredTxs = expenses.where((tx) => tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day);
    } else if (selectedPeriod == 2) {
      filteredTxs = expenses.where((tx) => tx.date.year == now.year);
    } else {
      filteredTxs = expenses.where((tx) => tx.date.year == now.year && tx.date.month == now.month);
    }

    final categoryMap = <String, double>{};
    double total = 0;
    for (var tx in filteredTxs) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
      total += tx.amount;
    }

    if (total == 0 || categoryMap.isEmpty) {
      return [('No Data', 100, AppColors.divider)];
    }

    // Sort by amount descending
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors roughly matching theme or generic palette
    final colorPalette = [
      const Color(0xFFFF9F43), // Orange
      const Color(0xFF00CFE8), // Cyan
      const Color(0xFFEA5455), // Red
      const Color(0xFF7367F0), // Purple
      AppColors.divider,       // Grey
    ];

    final result = <(String, double, Color)>[];
    double otherAmount = 0;

    for (int i = 0; i < sortedCategories.length; i++) {
      if (i < 4) {
        final percentage = (sortedCategories[i].value / total) * 100;
        result.add((sortedCategories[i].key, percentage, colorPalette[i]));
      } else {
        otherAmount += sortedCategories[i].value;
      }
    }

    if (otherAmount > 0) {
      final percentage = (otherAmount / total) * 100;
      result.add(('Other', percentage, colorPalette[4]));
    }

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final data = _getCategoryData(transactions);

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
                      sections: _sectionsFor(data),
                    ),
                  ),
                ),
              ),
              const Gap(24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _legendFor(selectedPeriod, data),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _sectionsFor(List<(String, double, Color)> data) {
    return data.map((e) => PieChartSectionData(
      color: e.$3, 
      value: e.$2, 
      title: '', 
      radius: 20
    )).toList();
  }

  Widget _legendFor(int period, List<(String, double, Color)> data) {
    return Column(
      key: ValueKey(period),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildLegend(e.$1, e.$2.toInt(), e.$3),
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
