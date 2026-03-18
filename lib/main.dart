import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/models/transaction_model.dart';
import 'core/models/ai_insight_model.dart';
import 'features/auth/email_screen.dart';
import 'features/navigation/startup_screen.dart';
import 'core/services/ml_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(AIInsightModelAdapter());
  
  runApp(const ProviderScope(child: FinSightApp(initialScreen: StartupScreen())));
}

class FinSightApp extends ConsumerWidget {
  final Widget initialScreen;
  const FinSightApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'FinSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: initialScreen,
    );
  }
}