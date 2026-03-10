import 'package:flutter/material.dart';
import 'premium_dashboard_screen.dart';
import '../widgets/premium_navbar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PremiumDashboardScreen(),
    Center(child: Text("Analytics")),
    Center(child: Text("Transfer")),
    Center(child: Text("Profile")),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: PremiumNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}