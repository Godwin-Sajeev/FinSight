import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/transaction_model.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final todayTransactions = [
      TransactionModel(
        title: 'Swiggy Delivery',
        merchantName: 'Swiggy',
        amount: 850,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'Food',
        isExpense: true,
      ),
      TransactionModel(
        title: 'Uber Ride',
        merchantName: 'Uber',
        amount: 320,
        date: DateTime.now().subtract(const Duration(hours: 5)),
        category: 'Travel',
        isExpense: true,
      ),
    ];

    final yesterdayTransactions = [
      TransactionModel(
        title: 'Netflix Subscription',
        merchantName: 'Netflix',
        amount: 649,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Entertainment',
        isExpense: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            _buildDateGroup(context, 'TODAY', todayTransactions),
            const Gap(24),
            _buildDateGroup(context, 'YESTERDAY', yesterdayTransactions),
            const Gap(80), // For bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, String title, List<TransactionModel> txs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Gap(12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txs.length,
            separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: const Icon(LucideIcons.trash2, color: Colors.white),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tx.isExpense ? LucideIcons.shoppingBag : LucideIcons.arrowDownLeft,
                      color: tx.isExpense ? AppColors.textPrimary : AppColors.secondaryAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.title,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    tx.category,
                    style: AppTypography.textTheme.labelSmall,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(transaction: tx),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
