import 'package:get/get.dart';
import 'data_management_translations_zh.dart';
import 'data_management_translations_en.dart';

/// Data Management Screen GetX翻译类
class DataManagementTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': dataManagementTranslationsZh,
        'en_US': dataManagementTranslationsEn,
      };
}
