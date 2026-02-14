import 'package:get/get.dart';
import 'notes_translations_zh.dart';
import 'notes_translations_en.dart';
import 'notes_translations_jp.dart';

/// Notes 插件的国际化翻译类
///
/// 使用 GetX 的 Translations 系统
/// 所有翻译键都带有 'notes_' 前缀
class NotesTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': notesTranslationsZh,
    'en_US': notesTranslationsEn,
    'ja_JP': notesTranslationsJp,
  };
}
