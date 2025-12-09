import 'package:get/get.dart';
import 'scripts_center_translations_zh.dart';
import 'scripts_center_translations_en.dart';

/// 脚本中心插件GetX翻译类
class ScriptsCenterTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': scriptsCenterTranslationsZh,
        'en_US': scriptsCenterTranslationsEn,
      };
}
