import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/balance_hero_card.dart';
import 'widgets/spending_categories_grid.dart';
import 'widgets/recent_transactions_preview.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            DashboardHeader(),
            Gap(AppSpacing.sectionSpacing),
            BalanceHeroCard(),
            Gap(AppSpacing.sectionSpacing),
            SpendingCategoriesGrid(),
            Gap(AppSpacing.sectionSpacing),
            RecentTransactionsPreview(),
            Gap(80), // To prevent FAB overlap
          ],
        ),
      ),
    );
  }
}
