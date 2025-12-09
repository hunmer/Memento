import 'package:get/get.dart';
import 'image_picker_translations_zh.dart';
import 'image_picker_translations_en.dart';

/// 图片选择器GetX翻译类
class ImagePickerTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': imagePickerTranslationsZh,
        'en_US': imagePickerTranslationsEn,
      };
}
