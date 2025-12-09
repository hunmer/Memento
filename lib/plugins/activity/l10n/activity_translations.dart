import 'package:get/get.dart';
import 'activity_translations_zh.dart';
import 'activity_translations_en.dart';

/// Activity plugin GetX translations
class ActivityTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': ActivityTranslationsZh.translations,
        'en_US': ActivityTranslationsEn.translations,
      };
}
