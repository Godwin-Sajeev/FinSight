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

class RecentTransactionsPreview extends ConsumerWidget {
  const RecentTransactionsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get real data from provider and sort by newest
    final allTransactions = ref.watch(transactionProvider);
    final sortedTxs = List<TransactionModel>.from(allTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Take up to 3 most recent
    final transactions = sortedTxs.take(3).toList();

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
          child: transactions.isEmpty 
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.cardPadding),
              child: Center(child: Text("No transactions yet")),
            )
          : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 24),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isExpense = tx.isExpense;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? LucideIcons.shoppingCart : LucideIcons.arrowDownLeft,
                      color: isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
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
                        '${isExpense ? "-" : "+"}₹${tx.amount.toInt()}',
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
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
