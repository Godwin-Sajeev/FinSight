import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../navigation/main_nav_screen.dart';

enum OtpMethod { sms, email }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _otpSent = false;
  OtpMethod _selectedMethod = OtpMethod.sms;

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_contactController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _isLoading = false; _otpSent = true; });
  }

  Future<void> _verifyAndLogin() async {
    if (_otpController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(40),
              // ─── Logo & Tagline ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryAccent, Color(0xFF8C7BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          )
                        ],
                      ),
                      child: const Icon(LucideIcons.fingerprint, size: 56, color: Colors.white),
                    ),
                    const Gap(24),
                    Text('FinSight', style: AppTypography.textTheme.displayMedium),
                    const Gap(8),
                    Text(
                      'Your Money, Intelligently Managed',
                      style: AppTypography.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Gap(48),

              // ─── OTP Method Toggle ─────────────────────────────────
              if (!_otpSent) ...[
                Text('Sign in with', style: AppTypography.textTheme.bodyMedium),
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMethodCard(
                        icon: LucideIcons.smartphone,
                        label: 'SMS',
                        method: OtpMethod.sms,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _buildMethodCard(
                        icon: LucideIcons.mail,
                        label: 'Email',
                        method: OtpMethod.email,
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                _buildInput(
                  controller: _contactController,
                  hint: _selectedMethod == OtpMethod.sms
                      ? 'Enter phone number'
                      : 'Enter email address',
                  icon: _selectedMethod == OtpMethod.sms
                      ? LucideIcons.phone
                      : LucideIcons.atSign,
                  keyboardType: _selectedMethod == OtpMethod.sms
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                ),
              ] else ...[
                // OTP Sent confirmation banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
                    border: Border.all(
                      color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: AppColors.secondaryAccent, size: 20),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          'OTP sent to ${_contactController.text}.\nPlease check your ${_selectedMethod == OtpMethod.sms ? "SMS" : "email"}.',
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                _buildInput(
                  controller: _otpController,
                  hint: 'Enter 6-digit OTP',
                  icon: LucideIcons.lock,
                  keyboardType: TextInputType.number,
                ),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() { _otpSent = false; _otpController.clear(); }),
                      child: Text(
                        'Change number / email',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const Gap(24),

              // ─── Primary Button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyAndLogin : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    disabledBackgroundColor: AppColors.primaryAccent.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _otpSent ? 'Verify & Enter FinSight' : 'Send OTP',
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const Gap(40),

              // ─── Trust badges ──────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.secondaryAccent),
                        const Gap(6),
                        Text(
                          '256-bit bank-grade encryption',
                          style: AppTypography.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const Gap(12),
                    Text(
                      'By continuing you agree to our Privacy Policy\nand Terms of Service.',
                      style: AppTypography.textTheme.labelSmall?.copyWith(height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String label,
    required OtpMethod method,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.smallRadius),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.divider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTypography.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
