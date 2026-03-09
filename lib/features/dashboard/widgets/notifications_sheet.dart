import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _NotifData(
        icon: LucideIcons.alertTriangle,
        iconColor: AppColors.danger,
        title: 'EMI Due Soon',
        body: 'Your home loan EMI of ₹8,200 is due in 4 days.',
        time: '10 mins ago',
      ),
      _NotifData(
        icon: LucideIcons.arrowDownLeft,
        iconColor: AppColors.secondaryAccent,
        title: 'Salary Credited',
        body: '₹45,000 has been credited to your account from TechCorp Inc.',
        time: '2 hours ago',
      ),
      _NotifData(
        icon: LucideIcons.sparkles,
        iconColor: AppColors.primaryAccent,
        title: 'AI Insight Ready',
        body: 'FinSight has detected a new saving opportunity worth ₹1,500/month.',
        time: '5 hours ago',
      ),
      _NotifData(
        icon: LucideIcons.shoppingBag,
        iconColor: const Color(0xFF00CFE8),
        title: 'Spending Alert',
        body: 'You have exceeded your shopping budget for this week.',
        time: 'Yesterday',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radius),
          topRight: Radius.circular(AppSpacing.radius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: AppTypography.textTheme.titleLarge),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Mark all read',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.divider, height: 1, indent: 70),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: n.iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(n.icon, color: n.iconColor, size: 20),
                ),
                title: Text(
                  n.title,
                  style: AppTypography.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(2),
                    Text(n.body, style: AppTypography.textTheme.bodyMedium),
                    const Gap(4),
                    Text(
                      n.time,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Gap(24),
        ],
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;

  _NotifData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
  });
}
