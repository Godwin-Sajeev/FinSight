import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import 'notifications_sheet.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
            ? 'Good Afternoon,'
            : 'Good Evening,';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: AppTypography.textTheme.bodyMedium),
            const Gap(4),
            Text('Alex', style: AppTypography.textTheme.titleLarge),
          ],
        ),
        Row(
          children: [
            // 🔔 Working notification bell 
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const NotificationsSheet(),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: const Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Red dot badge
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
              child: const Text(
                'A',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
