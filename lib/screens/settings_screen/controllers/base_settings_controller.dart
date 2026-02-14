import 'package:Memento/core/app_initializer.dart' show globalConfigManager;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BaseSettingsController extends ChangeNotifier {
  Locale _currentLocale = globalConfigManager.getLocale();
  BaseSettingsController();

  // 切换语言
  Future<Locale?> showLanguageSelectionDialog(BuildContext context) async {
    final result = await showDialog<Locale>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('settingsScreen_selectLanguage'.tr),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('zh')),
                child: Row(
                  children: [
                    if (_currentLocale.languageCode == 'zh')
                      Icon(Icons.check, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('settingsScreen_chinese'.tr),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('en')),
                child: Row(
                  children: [
                    if (_currentLocale.languageCode == 'en')
                      Icon(Icons.check, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('settingsScreen_english'.tr),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('ja')),
                child: Row(
                  children: [
                    if (_currentLocale.languageCode == 'ja')
                      Icon(Icons.check, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('settingsScreen_japanese'.tr),
                  ],
                ),
              ),
            ],
          ),
    );

    if (result != null) {
      await globalConfigManager.setLocale(result);
      _currentLocale = result;
      // 使用 GetX 更新当前显示语言
      Get.updateLocale(result);
      notifyListeners();
    }

    return result;
  }
}
