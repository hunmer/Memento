import 'package:Memento/core/utils/app.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

class BaseSettingsController extends ChangeNotifier {
  Locale _currentLocale = globalConfigManager.getLocale();
  BaseSettingsController();

  // 切换语言
  Future<void> toggleLanguage(BuildContext context) async {
    final result = await showDialog<Locale>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Select Language'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('zh')),
                child: Row(
                  children: [
                    if (_currentLocale.languageCode == 'zh')
                      Icon(Icons.check, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('中文'),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('en')),
                child: Row(
                  children: [
                    if (_currentLocale.languageCode == 'en')
                      Icon(Icons.check, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
            ],
          ),
    );

    if (result != null) {
      await globalConfigManager.setLocale(result);
      _currentLocale = result;
      notifyListeners();
      // 重启应用以应用语言设置
      restartApplication();
    }
  }
}
