import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gap/gap.dart';
import '../../core/services/biometric_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Text(
                'Access Control',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
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
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (textColor ?? AppColors.textPrimary).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.fingerprint, color: textColor, size: 20),
                      ),
                      title: Text(
                        'Biometric Lock',
                        style: AppTypography.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text('Require authentication to open the app'),
                      trailing: Switch(
                        value: _biometricEnabled,
                        onChanged: (val) async {
                          if (val) {
                            final authenticated = await BiometricService.authenticate();
                            if (authenticated) {
                              await BiometricService.setBiometricEnabled(true);
                              setState(() => _biometricEnabled = true);
                            }
                          } else {
                            await BiometricService.setBiometricEnabled(false);
                            setState(() => _biometricEnabled = false);
                          }
                        },
                        activeColor: AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(32),
              Text(
                'Encryption',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 24),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local Data Encryption',
                            style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Gap(4),
                          Text(
                            'All your financial data is encrypted and stored locally on your device.',
                            style: AppTypography.textTheme.bodySmall,
                          ),
                        ],
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
