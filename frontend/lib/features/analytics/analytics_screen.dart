import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/spending_trend_chart.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/insight_cards.dart';
import '../ai_center/widgets/ai_chat_interface.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedFilterIndex = 1; // 0=Daily, 1=Monthly, 2=Yearly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          children: [
            const Gap(16),
            // Segmented Control (Mocked for visual match)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                children: [
                  _buildSegment(0, 'Daily'),
                  _buildSegment(1, 'Monthly'),
                  _buildSegment(2, 'Yearly'),
                ],
              ),
            ),
            
            const Gap(AppSpacing.sectionSpacing * 1.5),
            SpendingTrendChart(selectedPeriod: _selectedFilterIndex),
            
            const Gap(AppSpacing.sectionSpacing * 1.5),
            CategoryDonutChart(selectedPeriod: _selectedFilterIndex),
            
            const Gap(AppSpacing.sectionSpacing * 1.5),
            const InsightCards(),

            const Gap(AppSpacing.sectionSpacing * 2),
            Text(
              'Ask FinSight AI',
              style: AppTypography.textTheme.titleLarge,
            ),
            const Gap(AppSpacing.listSpacing),
            const AIChatInterface(),
            
            const Gap(120), // For nav bar and FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(int index, String text) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
