import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/transaction_model.dart';
import '../../../../providers/finance_provider.dart';

class InsightCards extends ConsumerWidget {
  const InsightCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final expenses = transactions.where((tx) => tx.type == TransactionType.expense).toList();
    
    // Insights Logic
    double currentMonthSpend = 0;
    double lastMonthSpend = 0;
    final now = DateTime.now();

    final categoryMap = <String, double>{};

    for (var tx in expenses) {
      // Calculate monthly diffs
      if (tx.date.year == now.year && tx.date.month == now.month) {
        currentMonthSpend += tx.amount;
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
      } else if (tx.date.year == now.year && tx.date.month == now.month - 1) {
        lastMonthSpend += tx.amount;
      } else if (now.month == 1 && tx.date.year == now.year - 1 && tx.date.month == 12) {
        lastMonthSpend += tx.amount;
      }
    }

    // 1. Month vs Month Change
    String monthInsight = 'No previous month data to compare.';
    IconData monthIcon = LucideIcons.minus;
    Color monthColor = AppColors.textSecondary;
    if (lastMonthSpend > 0) {
      final diff = currentMonthSpend - lastMonthSpend;
      final percent = (diff / lastMonthSpend * 100).abs().toStringAsFixed(1);
      if (diff > 0) {
        monthInsight = 'You spent $percent% more this month compared to last month.';
        monthIcon = LucideIcons.trendingUp;
        monthColor = AppColors.danger;
      } else {
        monthInsight = 'Great! You have spent $percent% less this month compared to last month.';
        monthIcon = LucideIcons.trendingDown;
        monthColor = const Color(0xFF28C76F); // Green
      }
    } else if (currentMonthSpend > 0) {
      monthInsight = 'You have spent ₹${currentMonthSpend.toStringAsFixed(0)} this month.';
      monthIcon = LucideIcons.trendingUp;
      monthColor = AppColors.danger;
    }

    // 2. Highest Category
    String topCatInsight = 'Spend more to see category insights.';
    if (categoryMap.isNotEmpty) {
      final sortedCats = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topCat = sortedCats.first;
      topCatInsight = 'Your highest spending category this month is ${topCat.key} at ₹${topCat.value.toInt()}.';
    }

    // 3. Average Daily Spend
    // If it's the current month, divide by current day. 
    // Wait, a better average is all-time daily average
    double allTimeExpenses = 0;
    DateTime? earliestDate;
    for (var tx in expenses) {
      allTimeExpenses += tx.amount;
      if (earliestDate == null || tx.date.isBefore(earliestDate)) {
        earliestDate = tx.date;
      }
    }

    String avgDailyInsight = 'Not enough data for daily average.';
    if (earliestDate != null && allTimeExpenses > 0) {
      final daysDiff = now.difference(earliestDate).inDays;
      final effectiveDays = daysDiff == 0 ? 1 : daysDiff; // Avoid div by 0
      final avgDaily = allTimeExpenses / effectiveDays;
      avgDailyInsight = 'Your average daily spend is ₹${avgDaily.toInt()}.';
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Insights',
          style: AppTypography.textTheme.titleLarge,
        ),
        const Gap(AppSpacing.listSpacing),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildInsightCard(
                icon: monthIcon,
                iconColor: monthColor,
                text: monthInsight,
              ),
              const Gap(16),
              _buildInsightCard(
                icon: LucideIcons.shoppingBag,
                iconColor: const Color(0xFF00CFE8),
                text: topCatInsight,
              ),
              const Gap(16),
              _buildInsightCard(
                icon: LucideIcons.calendar,
                iconColor: AppColors.primaryAccent,
                text: avgDailyInsight,
              ),
            ],
          ),
        ),

        const Gap(AppSpacing.sectionSpacing),
        
        Text(
          'Predictions & Reminders',
          style: AppTypography.textTheme.titleLarge,
        ),
        const Gap(AppSpacing.listSpacing),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, color: AppColors.primaryAccent),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analyzing...',
                      style: AppTypography.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'As you add more transactions, the backend AI will detect recurring payments here.',
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const Gap(12),
          Text(text, style: AppTypography.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
