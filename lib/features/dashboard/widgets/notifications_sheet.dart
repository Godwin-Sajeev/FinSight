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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mockNotifications = [
      {
        'icon': LucideIcons.alertTriangle,
        'color': AppColors.danger,
        'title': 'EMI Due Soon',
        'message': 'Your home loan EMI of ₹8,200 is due in 4 days.',
        'time': '10 mins ago',
      },
      {
        'icon': LucideIcons.arrowDownLeft,
        'color': AppColors.secondaryAccent,
        'title': 'Salary Credited',
        'message': '₹45,000 has been credited to your account from TechCorp Inc.',
        'time': '2 hours ago',
      },
      {
        'icon': LucideIcons.sparkles,
        'color': AppColors.primaryAccent,
        'title': 'AI Insight Ready',
        'message': 'FinSight has detected a new saving opportunity worth ₹1,500/month.',
        'time': '5 hours ago',
      },
      {
        'icon': LucideIcons.shoppingBag,
        'color': const Color(0xFF00CFE8),
        'title': 'Spending Alert',
        'message': 'You have exceeded your shopping budget for this week.',
        'time': 'Yesterday',
      },
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              const Gap(12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: AppTypography.textTheme.displaySmall?.copyWith(
                        color: theme.textTheme.displaySmall?.color,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  itemCount: mockNotifications.length,
                  separatorBuilder: (_, __) => const Gap(16),
                  itemBuilder: (_, index) {
                    final note = mockNotifications[index];
                    return _NotificationItem(note: note);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> note;

  const _NotificationItem({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (theme.textTheme.bodyLarge?.color ?? Colors.black).withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (note['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(note['icon'] as IconData, color: note['color'] as Color, size: 20),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note['title'] as String,
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    Text(
                      note['time'] as String,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: theme.textTheme.labelSmall?.color,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  note['message'] as String,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
