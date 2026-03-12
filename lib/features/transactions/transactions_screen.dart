import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    // Sort transactions by date (newest first)
    final sortedTxs = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final todayTransactions = sortedTxs.where((tx) {
      return tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day;
    }).toList();

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayTransactions = sortedTxs.where((tx) {
      return tx.date.year == yesterday.year &&
          tx.date.month == yesterday.month &&
          tx.date.day == yesterday.day;
    }).toList();

    final olderTransactions = sortedTxs.where((tx) {
      final isToday = tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day;
      final isYesterday = tx.date.year == yesterday.year &&
          tx.date.month == yesterday.month &&
          tx.date.day == yesterday.day;
      return !isToday && !isYesterday;
    }).toList();

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
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions yet. Add some!'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),
                  if (todayTransactions.isNotEmpty) ...[
                    _buildDateGroup(context, ref, 'TODAY', todayTransactions),
                    const Gap(24),
                  ],
                  if (yesterdayTransactions.isNotEmpty) ...[
                    _buildDateGroup(context, ref, 'YESTERDAY', yesterdayTransactions),
                    const Gap(24),
                  ],
                  if (olderTransactions.isNotEmpty) ...[
                    _buildDateGroup(context, ref, 'OLDER', olderTransactions),
                    const Gap(80),
                  ],
                  if (olderTransactions.isEmpty) const Gap(80), // For bottom nav
                ],
              ),
            ),
    );
  }

  Widget _buildDateGroup(BuildContext context, WidgetRef ref, String title,
      List<TransactionModel> txs) {
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
            separatorBuilder: (context, index) =>
                const Divider(color: AppColors.divider, height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final isExpense = tx.isExpense;
              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                },
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense
                          ? LucideIcons.shoppingBag
                          : LucideIcons.arrowDownLeft,
                      color: isExpense
                          ? AppColors.textPrimary
                          : AppColors.secondaryAccent,
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
                        '${isExpense ? "-" : "+"}₹${tx.amount.toInt()}',
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isExpense
                              ? AppColors.textPrimary
                              : AppColors.secondaryAccent,
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
                        builder: (context) =>
                            TransactionDetailScreen(transaction: tx),
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

