import 'package:get/get.dart';
import 'openai_translations_zh.dart';
import 'openai_translations_en.dart';
import 'openai_translations_jp.dart';

/// OpenAI 插件 GetX 国际化翻译类
class OpenAITranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': openaiTranslationsZh,
        'en_US': openaiTranslationsEn,
        'ja_JP': openaiTranslationsJp,
      };
}
