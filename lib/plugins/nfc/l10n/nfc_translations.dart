import 'package:get/get.dart';
import 'nfc_translations_zh.dart';
import 'nfc_translations_en.dart';
import 'nfc_translations_jp.dart';

/// NFC插件GetX翻译类
class NfcTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': nfcTranslationsZh,
        'en_US': nfcTranslationsEn,
        'ja_JP': nfcTranslationsJp,
      };
}
