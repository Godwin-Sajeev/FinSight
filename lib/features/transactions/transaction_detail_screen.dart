import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/transaction_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // Center Hex/Circle Icon Concept
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: transaction.isExpense 
                    ? AppColors.textPrimary.withOpacity(0.05)
                    : AppColors.secondaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.isExpense ? LucideIcons.shoppingBag : LucideIcons.arrowDownLeft,
                size: 48,
                color: transaction.isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
              ),
            ),
            const Gap(24),
            Text(
              transaction.merchantName,
              style: AppTypography.textTheme.displayMedium,
            ),
            const Gap(8),
            Text(
              '${transaction.isExpense ? "-" : "+"}₹${transaction.amount.toStringAsFixed(2)}',
              style: AppTypography.textTheme.displayLarge?.copyWith(
                color: transaction.isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
              ),
            ),
            const Gap(32),

            // Detail Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _buildDetailRow('Date & Time', '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} • ${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}'),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildDetailRow('Category', transaction.category),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildDetailRow('Payment Method', 'UPI'), // Mock
                  const Divider(color: AppColors.divider, height: 1),
                  _buildDetailRow('Source', transaction.bankSource ?? 'Auto-detected via SMS'),
                ],
              ),
            ),
            
            const Gap(24),

            // AI Insight box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.primaryAccent),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Insight',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          transaction.aiComment ?? 'Recurring subscription detected. Expecting the next deduction on ${transaction.date.day} of next month.',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.textTheme.bodyMedium),
          Text(
            value,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
