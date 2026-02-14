import 'package:get/get.dart';
import 'core_translations_jp.dart';
import 'core_translations_zh.dart';
import 'core_translations_en.dart';

/// Core module GetX internationalization Translations class
class CoreTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ja_JP': coreTranslationsJp,
        'zh_CN': coreTranslationsZh,
        'en_US': coreTranslationsEn,
      };
}
