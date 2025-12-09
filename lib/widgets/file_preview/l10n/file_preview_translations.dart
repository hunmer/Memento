import 'package:get/get.dart';
import 'file_preview_translations_zh.dart';
import 'file_preview_translations_en.dart';

/// 文件预览组件的 GetX Translations
///
/// 使用方式:
/// ```dart
/// Text('file_preview_name'.tr)  // 输出: 文件预览 或 File Preview
/// ```
class FilePreviewTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': filePreviewTranslationsZh,
        'en_US': filePreviewTranslationsEn,
      };
}
