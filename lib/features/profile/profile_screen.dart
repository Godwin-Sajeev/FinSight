import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.1),
                    child: const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 36,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text('Alex', style: AppTypography.textTheme.displayMedium),
                  const Gap(4),
                  Text(
                    '+91 •••• ••• 420 | alex@example.com',
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sectionSpacing * 2),

            // ── Settings ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildItem(context, LucideIcons.landmark, 'Linked Bank Accounts', isFirst: true),
                  _buildItem(context, LucideIcons.bellRing, 'Notification Settings'),
                  // ── Dark Mode (wired) ──────────────────────
                  _buildDarkModeItem(context, ref, isDark),
                  _buildItem(context, LucideIcons.shieldCheck, 'Security'),
                  _buildItem(context, LucideIcons.lock, 'Privacy'),
                ],
              ),
            ),

            const Gap(AppSpacing.sectionSpacing),

            // ── Logout ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.logOut, color: AppColors.danger, size: 20),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const Gap(80),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeItem(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.moon, color: AppColors.textPrimary, size: 20),
          ),
          title: Text(
            'Dark Mode',
            style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: Switch(
            value: isDark,
            onChanged: (val) => ref.read(themeModeProvider.notifier).setDark(val),
            activeColor: AppColors.primaryAccent,
          ),
        ),
        const Divider(color: AppColors.divider, height: 1, indent: 64, endIndent: 20),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary),
        ),
        if (!isLast) const Divider(color: AppColors.divider, height: 1, indent: 64, endIndent: 20),
      ],
    );
  }
}
