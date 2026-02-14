import 'package:get/get.dart';
import 'database_translations_zh.dart';
import 'database_translations_en.dart';
import 'database_translations_jp.dart';

/// 数据库插件的 GetX Translations 类
class DatabaseTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': DatabaseTranslationsZh.translations,
        'en_US': DatabaseTranslationsEn.translations,
        'ja_JP': DatabaseTranslationsJp.translations,
      };
}
