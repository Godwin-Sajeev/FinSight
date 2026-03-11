import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/finance_provider.dart';

class BalanceHeroCard extends ConsumerWidget {
  const BalanceHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(transactionProvider.notifier);
    
    // We also need to watch the provider state to rebuild when transactions change
    ref.watch(transactionProvider);

    final double totalIncome = notifier.totalIncome();
    final double totalExpense = notifier.totalExpense();
    final double totalBalance = totalIncome - totalExpense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryAccent,
            Color(0xFF8C7BFF), // Slightly lighter premium purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wallet, color: Colors.white.withOpacity(0.8), size: 16),
              const Gap(8),
              Text(
                'Total Balance',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            '₹ ${totalBalance.toInt()}',
            style: AppTypography.textTheme.displayLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlowItem('Income', '₹ ${totalIncome.toInt()}', LucideIcons.arrowDownLeft, AppColors.secondaryAccent),
              _buildFlowItem('Expense', '₹ ${totalExpense.toInt()}', LucideIcons.arrowUpRight, AppColors.danger),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFlowItem(String label, String amount, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const Gap(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              amount,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
      ],
    );
  }
}
