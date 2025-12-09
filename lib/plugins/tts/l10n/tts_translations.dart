import 'package:get/get.dart';
import 'tts_translations_zh.dart';
import 'tts_translations_en.dart';

/// TTS插件GetX翻译类
class TTSTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': ttsTranslationsZh,
        'en_US': ttsTranslationsEn,
      };
}
