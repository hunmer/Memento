import 'package:get/get.dart';
import 'timer_translations_zh.dart';
import 'timer_translations_en.dart';

class TimerTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': TimerTranslationsZh.keys,
        'en_US': TimerTranslationsEn.keys,
      };
}
