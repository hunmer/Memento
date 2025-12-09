import 'package:get/get.dart';
import 'nodes_translations_zh.dart';
import 'nodes_translations_en.dart';

/// Nodes插件的 GetX Translations 类
class NodesTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': nodesTranslationsZh,
        'en_US': nodesTranslationsEn,
      };
}
