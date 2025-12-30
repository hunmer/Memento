import 'package:flutter/material.dart';
import '../picker/image_picker_dialog.dart';
import '../adaptive_image.dart';

/// 图片选择器字段组件
///
/// 集成 ImagePickerDialog，提供图片选择和预览功能。
/// 支持图片预览、布局比例设置和默认图片显示。
class ImagePickerField extends StatefulWidget {
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

  /// 布局比例（类似 Flex 中的 flex，用于 Row/Column 布局）
  final int flex;

  /// 预览区域宽度
  final double? previewWidth;

  /// 预览区域高度
  final double? previewHeight;

  /// 默认图片（当未选择图片时显示）
  final Widget? defaultImage;

  /// 默认图片路径（字符串形式，会被转换为 defaultImage）
  final String? defaultImagePath;

  /// 是否显示标签文本
  final bool showLabel;

  /// 是否显示阴影
  final bool showShadow;

  /// 边框半径
  final double borderRadius;

  /// 是否显示选择按钮
  final bool showSelectButton;

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
    this.flex = 1,
    this.previewWidth,
    this.previewHeight,
    this.defaultImage,
    this.defaultImagePath,
    this.showLabel = true,
    this.showShadow = false,
    this.borderRadius = 12,
    this.showSelectButton = true,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  /// 内部状态，用于本地更新 UI
  dynamic _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentImage;
  }

  @override
  void didUpdateWidget(ImagePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImage != oldWidget.currentImage) {
      _selectedImage = widget.currentImage;
    }
  }

  /// 获取图片路径（从当前选择的图片中提取）
  String? get _imagePath {
    if (_selectedImage == null) return null;
    if (_selectedImage is Map) {
      return _selectedImage['url'] as String?;
    }
    return _selectedImage as String?;
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _imagePath;

    return Flex(
      direction: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.labelText != null)
          Padding(
            padding: const EdgeInsets.only(top: 12, right: 12),
            child: Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    widget.enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        Expanded(
          flex: widget.flex,
          child: Builder(
            builder: (ctx) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片预览区域
                  GestureDetector(
                    onTap: widget.enabled ? () => _showPicker(ctx) : null,
                    child: AdaptiveImage(
                      imagePath: imagePath,
                      width: widget.previewWidth,
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                  // 选择按钮
                  if (widget.showSelectButton) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: widget.enabled ? () => _showPicker(ctx) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: widget.enabled
                                ? Theme.of(ctx).colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.enabled
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Theme.of(ctx).colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image,
                                size: 18,
                                color: widget.enabled
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDisplayText(),
                                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                      color: widget.enabled
                                          ? Theme.of(ctx).colorScheme.primary
                                          : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 显示图片选择器对话框
  Future<void> _showPicker(BuildContext context) async {
    final initialUrl =
        _selectedImage is Map
            ? _selectedImage['url'] as String?
            : _selectedImage as String?;

    final result = await showDialog<dynamic>(
      context: context,
      builder:
          (ctx) => ImagePickerDialog(
            initialUrl: initialUrl,
            saveDirectory: widget.saveDirectory,
            enableCrop: widget.enableCrop,
            cropAspectRatio: widget.cropAspectRatio,
            multiple: widget.multiple,
            enableCompression: widget.enableCompression,
          ),
    );

    if (result != null) {
      setState(() {
        _selectedImage = result;
      });
      widget.onImageChanged(result);
    }
  }

  /// 获取显示文本
  String _getDisplayText() {
    if (_selectedImage != null) {
      if (widget.multiple && _selectedImage is List) {
        return '已选择 ${_selectedImage.length} 张图片';
      } else {
        return '更换图片';
      }
    }
    return widget.hintText ?? '选择图片';
  }
}

/// 图片选择器字段构建器（用于 FormBuilderWrapper）
///
/// 封装 ImagePickerField，提供与 FormBuilderWrapper 集成的能力。
class ImagePickerFormField extends StatelessWidget {
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

  /// 布局比例
  final int flex;

  /// 预览区域宽度
  final double? previewWidth;

  /// 预览区域高度
  final double? previewHeight;

  /// 默认图片
  final Widget? defaultImage;

  /// 默认图片路径
  final String? defaultImagePath;

  /// 是否显示标签
  final bool showLabel;

  /// 是否显示阴影
  final bool showShadow;

  /// 边框半径
  final double borderRadius;

  /// 是否显示选择按钮
  final bool showSelectButton;

  const ImagePickerFormField({
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
    this.flex = 1,
    this.previewWidth,
    this.previewHeight,
    this.defaultImage,
    this.defaultImagePath,
    this.showLabel = true,
    this.showShadow = false,
    this.borderRadius = 12,
    this.showSelectButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ImagePickerField(
      currentImage: currentImage,
      labelText: labelText,
      hintText: hintText,
      enabled: enabled,
      onImageChanged: onImageChanged,
      saveDirectory: saveDirectory,
      enableCrop: enableCrop,
      cropAspectRatio: cropAspectRatio,
      multiple: multiple,
      enableCompression: enableCompression,
      flex: flex,
      previewWidth: previewWidth,
      previewHeight: previewHeight,
      defaultImage: defaultImage,
      defaultImagePath: defaultImagePath,
      showLabel: showLabel,
      showShadow: showShadow,
      borderRadius: borderRadius,
      showSelectButton: showSelectButton,
    );
  }
}
