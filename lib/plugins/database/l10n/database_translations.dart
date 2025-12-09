import 'package:get/get.dart';
import 'database_translations_zh.dart';
import 'database_translations_en.dart';

/// Database插件GetX翻译类
class DatabaseTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': databaseTranslationsZh,
        'en_US': databaseTranslationsEn,
      };
}
