import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple theme mode notifier
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(false); // false = light, true = dark

  void toggle() => state = !state;
  void setDark(bool isDark) => state = isDark;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>(
  (ref) => ThemeModeNotifier(),
);
