import 'package:get/get.dart';
import 'group_selector_translations_jp.dart';
import 'group_selector_translations_zh.dart';
import 'group_selector_translations_en.dart';

/// GroupSelector component GetX translation class
class GroupSelectorTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ja_JP': groupSelectorTranslationsJp,
        'zh_CN': groupSelectorTranslationsZh,
        'en_US': groupSelectorTranslationsEn,
      };
}
