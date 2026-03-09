import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/widgets/luxury_glass_card.dart';

class RecentTransactionsPreview extends StatelessWidget {
  const RecentTransactionsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final transactions = [
      TransactionModel(
        title: 'Swiggy Delivery',
        merchantName: 'Swiggy',
        amount: 850,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'Food',
        isExpense: true,
      ),
      TransactionModel(
        title: 'Netflix Subscription',
        merchantName: 'Netflix',
        amount: 649,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Entertainment',
        isExpense: true,
      ),
      TransactionModel(
        title: 'Salary Credit',
        merchantName: 'TechCorp Inc',
        amount: 145000,
        date: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Income',
        isExpense: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTypography.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // Navigate to transactions tab or full screen
              },
              child: Text(
                'View All',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.listSpacing),
        LuxuryGlassCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 24),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.isExpense ? LucideIcons.shoppingCart : LucideIcons.arrowDownLeft,
                      color: tx.isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
                      size: 20,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          tx.category,
                          style: AppTypography.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.isExpense ? "-" : "+"}₹${tx.amount.toInt()}',
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tx.isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
                        ),
                      ),
                      Text(
                        '${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}',
                        style: AppTypography.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
