import 'package:get/get.dart';
import 'settings_screen_translations_zh.dart';
import 'settings_screen_translations_en.dart';

/// 设置屏幕GetX翻译类
class SettingsScreenTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': settingsScreenTranslationsZh,
        'en_US': settingsScreenTranslationsEn,
      };
}
