import 'package:get/get.dart';
import 'store_translations_zh.dart';
import 'store_translations_en.dart';
import 'store_translations_jp.dart';

class StoreTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': storeTranslationsZh,
        'en_US': storeTranslationsEn,
        'ja_JP': storeTranslationsJp,
      };
}
