import 'package:Memento/core/app_initializer.dart' show globalConfigManager;
import 'package:Memento/core/utils/app.dart';
import 'package:Memento/screens/l10n/screens_localizations.dart';
import 'package:flutter/material.dart';

class BaseSettingsController extends ChangeNotifier {
  Locale _currentLocale = globalConfigManager.getLocale();
  BaseSettingsController();

  // 切换语言
  Future<Locale?> showLanguageSelectionDialog(BuildContext context) async {
    final localizations = ScreensLocalizations.of(context);

    final result = await showDialog<Locale>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(localizations.selectLanguage),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, const Locale('zh')),
                child: Row(
                  children: [
                    if (_currentLocale.languageCode == 'zh')
                      Icon(Icons.check, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(localizations.chinese),
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
                    Text(localizations.english),
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

    return result;
  }
}
