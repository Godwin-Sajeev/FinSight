import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/spending_trend_chart.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/insight_cards.dart';
import '../ai_center/widgets/ai_chat_interface.dart';
import '../../core/services/report_service.dart';
import '../../providers/finance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedFilterIndex = 1; // 0=Daily, 1=Monthly, 2=Yearly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.download),
            onSelected: (value) async {
              final transactions = ref.read(transactionProvider);
              if (value == 'pdf') {
                await ReportService.generatePdfReport(transactions);
              } else if (value == 'csv') {
                await ReportService.generateCsvReport(transactions);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
              const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
            ],
          ),
          const Gap(16),
        ],
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
