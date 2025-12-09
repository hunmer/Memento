import 'package:get/get.dart';
import 'location_picker_translations_zh.dart';
import 'location_picker_translations_en.dart';

/// LocationPicker组件GetX翻译类
class LocationPickerTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': locationPickerTranslationsZh,
        'en_US': locationPickerTranslationsEn,
      };
}
