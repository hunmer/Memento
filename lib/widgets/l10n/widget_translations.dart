import 'package:get/get.dart';
import 'widget_translations_zh.dart';
import 'widget_translations_en.dart';

/// Widget 通用组件国际化翻译
class WidgetTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': zhCN,
        'en_US': enUS,
      };
}
