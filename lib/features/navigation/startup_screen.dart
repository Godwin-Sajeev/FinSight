import 'package:flutter/material.dart';
import '../../core/services/ml_service.dart';
import '../../core/services/biometric_service.dart';
import '../navigation/main_nav_screen.dart';
import '../auth/email_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    final loggedIn = await MLService.isLoggedIn();
    if (!loggedIn) {
      _navigateTo(const EmailScreen());
      return;
    }

    final bioEnabled = await BiometricService.isBiometricEnabled();
    if (bioEnabled) {
      final authenticated = await BiometricService.authenticate();
      if (authenticated) {
        _navigateTo(const MainNavScreen());
      } else {
        // Stay on this screen or show retry button
        setState(() {});
      }
    } else {
      _navigateTo(const MainNavScreen());
    }
  }

  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldCheck, 
                size: 64, 
                color: AppColors.primaryAccent
              ),
            ),
            const Gap(24),
            Text(
              'FinSight Security',
              style: AppTypography.textTheme.displaySmall,
            ),
            const Gap(48),
            ElevatedButton.icon(
              onPressed: _handleStartup,
              icon: const Icon(LucideIcons.unlock),
              label: const Text('Authenticate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
