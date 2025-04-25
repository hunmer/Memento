import 'package:flutter/material.dart';
import '../../../main.dart';
import 'rebuild_controller.dart';

class BaseSettingsController extends ChangeNotifier {
  final BuildContext context;
  final bool _mounted = true;
  bool isDarkMode = false;

  BaseSettingsController(this.context);

  // 获取当前语言设置
  Locale get currentLocale => Localizations.localeOf(context);

  // 判断是否为中文
  bool get isChineseLocale => currentLocale.languageCode == 'zh';

  Future<void> initTheme() async {
    if (!_mounted) return;
    // 从配置管理器获取保存的主题设置
    final savedThemeMode = globalConfigManager.getThemeMode();
    isDarkMode = savedThemeMode == ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    // 保存当前BuildContext，因为后面要在异步操作后使用
    final currentContext = context;

    isDarkMode = !isDarkMode;
    final newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // 保存主题设置到配置管理器
    await globalConfigManager.setThemeMode(newThemeMode);

    // 重建应用以应用新主题
    if (!_mounted) return;
    await RebuildController.rebuildApplication(
      currentContext: currentContext,
      newThemeMode: newThemeMode,
    );

    // 显示切换提示
    if (!_mounted) return;
    ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text(isDarkMode ? '已切换到深色主题' : '已切换到浅色主题'),
        duration: const Duration(seconds: 1),
      ),
    );

    notifyListeners();
  }

  // 切换语言
  Future<void> toggleLanguage() async {
    if (!_mounted) return;
    final newLocale = isChineseLocale ? const Locale('en') : const Locale('zh');

    // 保存语言设置到配置管理器
    await globalConfigManager.setLocale(newLocale);

    // 重建应用以应用新语言
    await RebuildController.rebuildApplication(
      currentContext: context,
      newLocale: newLocale,
    );

    if (!_mounted) return;
    // 显示切换提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isChineseLocale ? 'Switched to English' : '已切换到中文'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
