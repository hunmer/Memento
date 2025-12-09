import 'package:get/get.dart';
import 'file_preview_translations_zh.dart';
import 'file_preview_translations_en.dart';

/// FilePreview组件GetX翻译类
class FilePreviewTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': filePreviewTranslationsZh,
        'en_US': filePreviewTranslationsEn,
      };
}
