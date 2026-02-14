import 'package:get/get.dart';
import 'tracker_translations_zh.dart';
import 'tracker_translations_en.dart';
import 'tracker_translations_jp.dart';

class TrackerTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': TrackerTranslationsZh.keys,
        'en_US': TrackerTranslationsEn.keys,
        'ja_JP': TrackerTranslationsJp.keys,
      };
}
