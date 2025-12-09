import 'package:get/get.dart';
import 'bill_translations_zh.dart';
import 'bill_translations_en.dart';

/// 账单插件的 GetX 国际化支持类
class BillTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': BillTranslationsZh.translations,
        'en_US': BillTranslationsEn.translations,
      };
}
