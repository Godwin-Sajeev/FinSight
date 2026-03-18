import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/theme_provider.dart';
import '../auth/email_screen.dart';
import '../../core/services/ml_service.dart';
import '../../core/services/biometric_service.dart';
import '../../providers/user_provider.dart';
import 'linked_bank_accounts_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _userEmail = 'alex@example.com';
  bool _biometricEnabled = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final email = await MLService.getUserEmail();
    final bioEnabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        if (email != null) _userEmail = email;
        _biometricEnabled = bioEnabled;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await ref.read(userProvider.notifier).updateProfilePic(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final userProfile = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                          backgroundImage: userProfile.profilePicPath != null
                              ? FileImage(File(userProfile.profilePicPath!))
                              : null,
                          child: userProfile.profilePicPath == null
                              ? Text(
                                  userProfile.userName.isNotEmpty ? userProfile.userName[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Text(
                    userProfile.userName,
                    style: AppTypography.textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).textTheme.displayMedium?.color,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _userEmail,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
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
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildItem(context, LucideIcons.landmark, 'Linked Bank Accounts', isFirst: true, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkedBankAccountsScreen()));
                  }),
                  _buildItem(context, LucideIcons.bellRing, 'Notification Settings'),
                  // ── Dark Mode (wired) ──────────────────────
                  _buildDarkModeItem(context, ref, isDark),
                  _buildItem(context, LucideIcons.shieldCheck, 'Security', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
                  }),
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
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                onTap: () async {
                  await MLService.logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const EmailScreen()),
                      (route) => false,
                    );
                  }
                },
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (textColor ?? AppColors.textPrimary).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.moon, color: textColor, size: 20),
          ),
          title: Text(
            'Dark Mode',
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
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
    VoidCallback? onTap,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (textColor ?? AppColors.textPrimary).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          trailing: Icon(LucideIcons.chevronRight, size: 20, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary),
        ),
        if (!isLast) const Divider(color: AppColors.divider, height: 1, indent: 64, endIndent: 20),
      ],
    );
  }
}
