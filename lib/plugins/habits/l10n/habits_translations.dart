import 'package:get/get.dart';
import 'habits_translations_zh.dart';
import 'habits_translations_en.dart';
import 'habits_translations_jp.dart';

/// Habits 插件的 GetX 国际化翻译类
class HabitsTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': HabitsTranslationsZh.translations,
        'en_US': HabitsTranslationsEn.translations,
        'ja_JP': HabitsTranslationsJp.translations,
      };
}
