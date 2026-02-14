import 'package:get/get.dart';
import 'chat_translations_zh.dart';
import 'chat_translations_en.dart';
import 'chat_translations_jp.dart';

/// 聊天插件的 GetX Translations 类
class ChatTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': ChatTranslationsZh.keys,
        'en_US': ChatTranslationsEn.keys,
        'ja_JP': ChatTranslationsJp.keys,
      };
}
