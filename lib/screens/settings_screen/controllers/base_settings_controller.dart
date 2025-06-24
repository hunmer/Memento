import 'package:flutter/material.dart';
import '../../../main.dart';

class BaseSettingsController extends ChangeNotifier {
  final bool _mounted = true;
  bool isDarkMode = false;
  Locale? _currentLocale;

  BaseSettingsController();

  // 获取当前语言设置
  Locale get currentLocale => _currentLocale ?? const Locale('en');

  // 判断是否为中文
  bool get isChineseLocale => currentLocale.languageCode == 'zh';

  Future<void> initTheme(BuildContext context) async {
    if (!_mounted) return;
    _currentLocale = Localizations.localeOf(context);
    // 从配置管理器获取保存的主题设置
    final savedThemeMode = globalConfigManager.getThemeMode();
    isDarkMode = savedThemeMode == ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    final newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // 保存主题设置到配置管理器
    await globalConfigManager.setThemeMode(newThemeMode);
    notifyListeners();
  }

  // 切换语言
  Future<void> toggleLanguage() async {
    if (!_mounted) return;
    final newLocale = isChineseLocale ? const Locale('en') : const Locale('zh');

    // 保存语言设置到配置管理器
    await globalConfigManager.setLocale(newLocale);
    _currentLocale = newLocale;
    notifyListeners();
  }
}
