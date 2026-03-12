import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/widgets/luxury_glass_card.dart';
import '../../../providers/finance_provider.dart';

class SpendingCategoriesGrid extends ConsumerWidget {
  const SpendingCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get real data from provider
    final allTransactions = ref.watch(transactionProvider);
    
    // Process expenses by category
    final expenseMap = <String, double>{};
    double totalExpense = 0;
    
    for (var tx in allTransactions) {
      if (tx.isExpense) {
        expenseMap[tx.category] = (expenseMap[tx.category] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }

    // Default categories with base styling properties mapping
    final categoryStyles = {
      'Food': _CategoryStyle(LucideIcons.pizza, const Color(0xFFFF9F43)),
      'Shopping': _CategoryStyle(LucideIcons.shoppingBag, const Color(0xFF00CFE8)),
      'Bills': _CategoryStyle(LucideIcons.fileText, const Color(0xFFEA5455)),
      'Travel': _CategoryStyle(LucideIcons.plane, const Color(0xFF7367F0)),
      'Entertainment': _CategoryStyle(LucideIcons.popcorn, const Color(0xFFAA55AA)),
      'General': _CategoryStyle(LucideIcons.grid, const Color(0xFF67B0F0)),
      'Others': _CategoryStyle(LucideIcons.layoutGrid, const Color(0xFF888888)),
    };

    // Calculate percentages
    final calculatedCategories = expenseMap.entries.map((e) {
      final percentage = totalExpense > 0 ? (e.value / totalExpense * 100).toInt() : 0;
      final style = categoryStyles[e.key] ?? _CategoryStyle(LucideIcons.circle, const Color(0xFF888888));
      return _CategoryData(e.key, percentage, style.icon, style.color);
    }).toList();

    // Sort by highest percentage
    calculatedCategories.sort((a, b) => b.percentage.compareTo(a.percentage));
    
    // Take top 4
    final displayCategories = calculatedCategories.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Categories',
          style: AppTypography.textTheme.titleLarge,
        ),
        const Gap(AppSpacing.listSpacing),
        displayCategories.isEmpty 
          ? LuxuryGlassCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No expenses to categorize yet"),
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.listSpacing,
                mainAxisSpacing: AppSpacing.listSpacing,
                childAspectRatio: 1.4,
              ),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final cat = displayCategories[index];
                return LuxuryGlassCard(
                  borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cat.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 18),
                          ),
                          Text(
                            '${cat.percentage}%',
                            style: AppTypography.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                      const Gap(8),
                      Text(
                        cat.name,
                        style: AppTypography.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: totalExpense > 0 ? cat.percentage / 100 : 0,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                          minHeight: 4,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }
}

class _CategoryData {
  final String name;
  final int percentage;
  final IconData icon;
  final Color color;

  _CategoryData(this.name, this.percentage, this.icon, this.color);
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  _CategoryStyle(this.icon, this.color);
}
