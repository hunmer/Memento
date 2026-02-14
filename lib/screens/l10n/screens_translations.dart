import 'package:get/get.dart';
import 'screens_translations_zh.dart';
import 'screens_translations_en.dart';
import 'screens_translations_jp.dart';

/// Screens通用翻译GetX类
class ScreensTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': screensTranslationsZh,
        'en_US': screensTranslationsEn,
        'ja_JP': screensTranslationsJp,
      };
}
