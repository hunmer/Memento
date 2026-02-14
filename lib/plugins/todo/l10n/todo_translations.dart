import 'package:get/get.dart';
import 'todo_translations_zh.dart';
import 'todo_translations_en.dart';
import 'todo_translations_jp.dart';

class TodoTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': todoTranslationsZh,
        'en_US': todoTranslationsEn,
        'ja_JP': todoTranslationsJp,
      };
}
