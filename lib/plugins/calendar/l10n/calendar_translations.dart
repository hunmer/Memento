import 'package:get/get.dart';
import 'calendar_translations_zh.dart';
import 'calendar_translations_en.dart';
import 'calendar_translations_jp.dart';

/// 日历插件的 GetX Translations 类
class CalendarTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': calendarTranslationsZh,
        'en_US': calendarTranslationsEn,
        'ja_JP': calendarTranslationsJp,
      };
}
