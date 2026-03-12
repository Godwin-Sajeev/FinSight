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
    final isExpense = transaction.isExpense;
    
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
                color: isExpense 
                    ? AppColors.textPrimary.withOpacity(0.05)
                    : AppColors.secondaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense ? LucideIcons.shoppingBag : LucideIcons.arrowDownLeft,
                size: 48,
                color: isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
              ),
            ),
            const Gap(24),
            Text(
              transaction.title,
              style: AppTypography.textTheme.displayMedium,
            ),
            const Gap(8),
            Text(
              '${isExpense ? "-" : "+"}₹${transaction.amount.toStringAsFixed(2)}',
              style: AppTypography.textTheme.displayLarge?.copyWith(
                color: isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
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
                  // The real model does not have bankSource or aiComment natively mapped 
                  // to the main UI yet, so removing them for now or using defaults.
                ],
              ),
            ),
            
            const Gap(24),
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
