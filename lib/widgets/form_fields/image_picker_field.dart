import 'package:flutter/material.dart';
import '../picker/image_picker_dialog.dart';

/// 图片选择器字段组件
///
/// 集成 ImagePickerDialog，提供图片选择功能
class ImagePickerField extends StatelessWidget {
  /// 当前图片 URL 或结果 Map
  final dynamic currentImage;

  /// 字段标签
  final String? labelText;

  /// 占位提示
  final String? hintText;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<dynamic> onImageChanged;

  /// 图片保存目录
  final String saveDirectory;

  /// 是否启用裁剪
  final bool enableCrop;

  /// 裁剪比例
  final double? cropAspectRatio;

  /// 是否允许多选
  final bool multiple;

  /// 是否启用压缩
  final bool enableCompression;

  const ImagePickerField({
    super.key,
    required this.onImageChanged,
    this.currentImage,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.saveDirectory = 'app_images',
    this.enableCrop = false,
    this.cropAspectRatio,
    this.multiple = false,
    this.enableCompression = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          enabled
              ? () async {
                final initialUrl =
                    currentImage is Map
                        ? currentImage['url'] as String?
                        : currentImage as String?;

                final result = await showDialog<dynamic>(
                  context: context,
                  builder:
                      (context) => ImagePickerDialog(
                        initialUrl: initialUrl,
                        saveDirectory: saveDirectory,
                        enableCrop: enableCrop,
                        cropAspectRatio: cropAspectRatio,
                        multiple: multiple,
                        enableCompression: enableCompression,
                      ),
                );
                if (result != null) {
                  onImageChanged(result);
                }
              }
              : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getDisplayText(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (enabled) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (currentImage != null) {
      if (multiple && currentImage is List) {
        return '已选择 ${currentImage.length} 张图片';
      } else if (currentImage is Map) {
        return '已选择图片';
      } else {
        return '已选择图片';
      }
    }
    return labelText ?? hintText ?? '选择图片';
  }
}
