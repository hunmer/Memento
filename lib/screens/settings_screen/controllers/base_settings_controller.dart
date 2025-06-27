import 'package:Memento/core/utils/app.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';

class BaseSettingsController extends ChangeNotifier {
  final bool _mounted = true;
  Locale? _currentLocale;

  BaseSettingsController();

  // 获取当前语言设置
  Locale get currentLocale => _currentLocale ?? const Locale('en');

  // 判断是否为中文
  bool get isChineseLocale => currentLocale.languageCode == 'zh';

  // 切换语言
  Future<void> toggleLanguage(BuildContext context) async {
    if (!_mounted) return;

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
                    if (isChineseLocale) Icon(Icons.check, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('中文'),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('en')),
                child: Row(
                  children: [
                    if (!isChineseLocale) Icon(Icons.check, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
            ],
          ),
    );

    if (result != null && result != currentLocale) {
      await globalConfigManager.setLocale(result);
      _currentLocale = result;
      notifyListeners();
      // 重启应用以应用语言设置
      restartApplication();
    }
  }
}
