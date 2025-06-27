import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class ThemeController {
  static Future<void> initializeTheme(BuildContext context) async {
    final savedThemeMode = await AdaptiveTheme.getThemeMode();
    AdaptiveTheme.of(
      context,
    ).setThemeMode(savedThemeMode ?? AdaptiveThemeMode.light);
  }

  static void setLightTheme(BuildContext context) {
    AdaptiveTheme.of(context).setLight();
  }

  static bool isDarkTheme(BuildContext context) {
    return AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;
  }

  static void setDarkTheme(BuildContext context) {
    AdaptiveTheme.of(context).setDark();
  }

  static void setSystemTheme(BuildContext context) {
    AdaptiveTheme.of(context).setSystem();
  }

  static void toggleTheme(BuildContext context) {
    AdaptiveTheme.of(context).toggleThemeMode();
  }
}
