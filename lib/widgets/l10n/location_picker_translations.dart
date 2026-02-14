import 'package:get/get.dart';
import 'location_picker_translations_jp.dart';
import 'location_picker_translations_zh.dart';
import 'location_picker_translations_en.dart';

/// LocationPicker component GetX translation class
class LocationPickerTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ja_JP': locationPickerTranslationsJp,
        'zh_CN': locationPickerTranslationsZh,
        'en_US': locationPickerTranslationsEn,
      };
}
