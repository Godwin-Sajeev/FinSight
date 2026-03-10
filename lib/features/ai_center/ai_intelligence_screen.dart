import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/ai_chat_interface.dart';

class AIIntelligenceScreen extends StatelessWidget {
  const AIIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligence Center'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightCard(
              icon: LucideIcons.barChart,
              iconColor: AppColors.primaryAccent,
              title: 'Spending Summary',
              description: 'You spent ₹12,400 this week, which is exactly on track with your budget.',
              isHighlight: true,
            ),
            const Gap(16),
            _buildInsightCard(
              icon: LucideIcons.alertTriangle,
              iconColor: AppColors.danger,
              title: 'Risk Alerts',
              description: 'EMI ₹8,200 due in 4 days. Please maintain sufficient balance.',
            ),
            const Gap(16),
            _buildInsightCard(
              icon: LucideIcons.piggyBank,
              iconColor: AppColors.secondaryAccent,
              title: 'Saving Suggestions',
              description: 'If you reduce food delivery by 20%, you save ₹1,500/month. Shall we set a goal?',
            ),
            const Gap(AppSpacing.sectionSpacing * 1.5),
            Text(
              'Ask FinSight AI',
              style: AppTypography.textTheme.titleLarge,
            ),
            const Gap(AppSpacing.listSpacing),
            const AIChatInterface(),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primaryAccent.withOpacity(0.05) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppTheme.cardShadow,
        border: isHighlight ? Border.all(color: AppColors.primaryAccent.withOpacity(0.2)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  description,
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
