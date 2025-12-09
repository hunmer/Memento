import 'package:get/get.dart';
import 'group_selector_translations_zh.dart';
import 'group_selector_translations_en.dart';

/// GroupSelector组件GetX翻译类
class GroupSelectorTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': groupSelectorTranslationsZh,
        'en_US': groupSelectorTranslationsEn,
      };
}
