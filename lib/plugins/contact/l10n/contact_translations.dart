import 'package:get/get.dart';
import 'contact_translations_en.dart';
import 'contact_translations_zh.dart';

/// 联系人插件的 GetX Translations 类
class ContactTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': contactTranslationsZh,
        'en_US': contactTranslationsEn,
      };
}
