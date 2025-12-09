import 'package:get/get.dart';
import 'day_translations_zh.dart';
import 'day_translations_en.dart';

/// Day plugin translations
class DayTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': dayTranslationsZh,
        'en_US': dayTranslationsEn,
      };
}
