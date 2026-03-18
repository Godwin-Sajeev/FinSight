import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/ml_service.dart';
import '../../../../providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notifications_sheet.dart';

class DashboardHeader extends ConsumerStatefulWidget {
  const DashboardHeader({super.key});

  @override
  ConsumerState<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends ConsumerState<DashboardHeader> {
  String _greeting = 'Welcome back,';
  bool _showingWelcome = true;
  Timer? _welcomeTimer;

  @override
  void initState() {
    super.initState();
    _startWelcomeTimer();
  }

  void _startWelcomeTimer() {
    _welcomeTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showingWelcome = false;
          _updateGreeting();
        });
      }
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      _greeting = hour < 12
          ? 'Good Morning,'
          : hour < 17
              ? 'Good Afternoon,'
              : 'Good Evening,';
    });
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfile = ref.watch(userProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting, 
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const Gap(4),
            Text(
              userProfile.userName, 
              style: AppTypography.textTheme.titleLarge?.copyWith(
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
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
                      color: theme.cardTheme.color,
                      shape: BoxShape.circle,
                      boxShadow: theme.brightness == Brightness.light ? AppTheme.cardShadow : null,
                    ),
                    child: Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: theme.iconTheme.color,
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
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
              backgroundImage: userProfile.profilePicPath != null ? FileImage(File(userProfile.profilePicPath!)) : null,
              child: userProfile.profilePicPath == null 
                ? Text(
                    userProfile.userName.isNotEmpty ? userProfile.userName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            ),
          ],
        )
      ],
    );
  }
}
