import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Memento/utils/image_utils.dart';

/// 图片预览组件
///
/// 支持网络图片和本地图片的显示，提供占位图和错误状态展示。
/// 适用于表单字段预览、列表项缩略图等场景。
class ImagePreview extends StatelessWidget {
  /// 图片路径（网络 URL 或本地相对路径）
  final String? imagePath;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 容器宽度约束（用于固定显示区域大小）
  final double? containerWidth;

  /// 容器高度约束（用于固定显示区域大小）
  final double? containerHeight;

  /// 默认图片（当 imagePath 为空时显示）
  final Widget? defaultImage;

  /// 默认图片路径（字符串形式，会被转换为 defaultImage）
  final String? defaultImagePath;

  /// 边框半径
  final double borderRadius;

  /// 填充模式
  final BoxFit fit;

  /// 是否显示阴影
  final bool showShadow;

  /// 加载状态指示器颜色
  final Color? loadingColor;

  const ImagePreview({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.containerWidth,
    this.containerHeight,
    this.defaultImage,
    this.defaultImagePath,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.showShadow = false,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    // 确定容器尺寸
    final effectiveWidth = containerWidth ?? width ?? 200;
    final effectiveHeight = containerHeight ?? height ?? 200;

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imagePath != null && imagePath!.isNotEmpty
            ? _buildImage(imagePath!)
            : _buildDefaultPreview(context),
      ),
    );
  }

  Widget _buildImage(String path) {
    // 网络图片
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: loadingColor != null
                    ? AlwaysStoppedAnimation<Color>(loadingColor!)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPreview();
        },
      );
    }

    // 本地图片（相对路径）
    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPreview();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorPreview();
        }

        final file = File(snapshot.data!);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPreview();
            },
          );
        }

        return _buildErrorPreview();
      },
    );
  }

  Widget _buildLoadingPreview() {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: loadingColor != null
              ? AlwaysStoppedAnimation<Color>(loadingColor!)
              : null,
        ),
      ),
    );
  }

  Widget _buildErrorPreview() {
    return const Center(
      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }

  Widget _buildDefaultPreview(BuildContext context) {
    // 优先使用 defaultImage
    if (defaultImage != null) return defaultImage!;

    // 其次使用 defaultImagePath
    if (defaultImagePath != null && defaultImagePath!.isNotEmpty) {
      return _buildImage(defaultImagePath!);
    }

    // 默认占位符
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            '未选择图片',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
