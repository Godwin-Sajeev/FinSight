import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../transactions/transactions_screen.dart';
import '../ai_center/ai_hub_sheet.dart';
import '../../screens/sms_import_screen.dart';
import '../../screens/add_transaction_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _fabOpen = false;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    TransactionsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) {
      _fabAnimController.forward();
    } else {
      _fabAnimController.reverse();
    }
  }

  void _closeFab() {
    if (_fabOpen) {
      setState(() => _fabOpen = false);
      _fabAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: _closeFab,
        child: Stack(
          children: [
            // Ambient Glow Background
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryAccent.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondaryAccent.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),

            // Speed Dial options (appear above FAB when open)
            if (_fabOpen)
              Positioned(
                bottom: 90,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _fabScaleAnimation,
                      child: _SpeedDialItem(
                        icon: LucideIcons.messageSquarePlus,
                        label: 'Import from SMS',
                        color: const Color(0xFF00CFE8),
                        onTap: () {
                          _closeFab();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SmsImportScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ScaleTransition(
                      scale: _fabScaleAnimation,
                      child: _SpeedDialItem(
                        icon: LucideIcons.plus,
                        label: 'Add Manually',
                        color: AppColors.primaryAccent,
                        onTap: () {
                          _closeFab();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddTransactionScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ScaleTransition(
                      scale: _fabScaleAnimation,
                      child: _SpeedDialItem(
                        icon: LucideIcons.sparkles,
                        label: 'AI Hub',
                        color: const Color(0xFF7367F0),
                        onTap: () {
                          _closeFab();
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const AIHubSheet(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFab,
        backgroundColor: _fabOpen ? AppColors.danger : AppColors.primaryAccent,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedRotation(
          turns: _fabOpen ? 0.125 : 0, // 45deg rotation on open
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _fabOpen ? LucideIcons.x : LucideIcons.plus,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, -10),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            elevation: 0,
            onTap: (index) {
              _closeFab();
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.layoutDashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.barChart2),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.list),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(LucideIcons.user),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Speed Dial Item ─────────────────────────────────────────────────────────
class _SpeedDialItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SpeedDialItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
