import 'package:get/get.dart';
import 'diary_translations_zh.dart';
import 'diary_translations_en.dart';

/// 日记插件国际化 Translations 类
class DiaryTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': DiaryTranslationsZh.translations,
        'en_US': DiaryTranslationsEn.translations,
      };
}
