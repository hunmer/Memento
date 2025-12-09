import 'package:get/get.dart';
import 'checkin_translations_zh.dart';
import 'checkin_translations_en.dart';

/// 打卡插件的 GetX Translations 类
class CheckinTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': CheckinTranslationsZh.translations,
        'en_US': CheckinTranslationsEn.translations,
      };
}
