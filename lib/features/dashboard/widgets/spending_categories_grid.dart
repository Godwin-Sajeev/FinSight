import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/luxury_glass_card.dart';

class SpendingCategoriesGrid extends StatelessWidget {
  const SpendingCategoriesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryData('Food', 35, LucideIcons.pizza, const Color(0xFFFF9F43)),
      _CategoryData('Shopping', 22, LucideIcons.shoppingBag, const Color(0xFF00CFE8)),
      _CategoryData('Bills', 18, LucideIcons.fileText, const Color(0xFFEA5455)),
      _CategoryData('Travel', 10, LucideIcons.plane, const Color(0xFF7367F0)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Categories',
          style: AppTypography.textTheme.titleLarge,
        ),
        const Gap(AppSpacing.listSpacing),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.listSpacing,
            mainAxisSpacing: AppSpacing.listSpacing,
            childAspectRatio: 1.4,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return LuxuryGlassCard(
              borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 18),
                      ),
                      Text(
                        '${cat.percentage}%',
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  const Gap(8),
                  Text(
                    cat.name,
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                  const Gap(4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: cat.percentage / 100,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                      minHeight: 4,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryData {
  final String name;
  final int percentage;
  final IconData icon;
  final Color color;

  _CategoryData(this.name, this.percentage, this.icon, this.color);
}
