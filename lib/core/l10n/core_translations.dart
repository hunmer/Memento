import 'package:get/get.dart';
import 'core_translations_zh.dart';
import 'core_translations_en.dart';

/// 核心模块 GetX 国际化 Translations 类
class CoreTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': coreTranslationsZh,
        'en_US': coreTranslationsEn,
      };
}
