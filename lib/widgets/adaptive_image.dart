import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/utils/image_utils.dart';

/// 自适应图片组件
///
/// 支持网络图片和本地图片的显示，自动处理相对路径转绝对路径。
/// 特点：高度自适应，支持圆形裁剪，适用于列表项、图片卡片、头像等场景。
/// 加载状态和错误状态有对应的占位显示。
class AdaptiveImage extends StatelessWidget {
  /// 图片路径（网络 URL 或本地相对路径）
  final String? imagePath;

  /// 宽度约束（可选）
  final double? width;

  /// 高度约束（可选）
  final double? height;

  /// 填充模式
  final BoxFit fit;

  /// 边框半径
  final double borderRadius;

  /// 形状（用于圆形头像等场景）
  final BoxShape shape;

  /// 错误状态显示的图片（默认显示破损图标）
  final Widget? errorImage;

  /// 空图片时显示的默认图片
  final Widget? defaultImage;

  /// 加载状态指示器颜色
  final Color? loadingColor;

  const AdaptiveImage({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.errorImage,
    this.defaultImage,
    this.loadingColor,
  });

  /// 判断是否为网络图片
  static bool isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    // 空图片路径时显示默认图片或占位
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildDefaultOrError();
    }

    final path = imagePath!;

    // 网络图片直接加载
    if (isNetworkImage(path)) {
      return _buildNetworkImage(path);
    }

    // 本地图片需要转换路径
    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            final absolutePath = snapshot.data!;
            if (absolutePath.isEmpty) {
              return _buildDefaultOrError();
            }
            return _buildLocalImage(absolutePath);
          }
          return _buildDefaultOrError();
        }
        return _buildLoadingIndicator();
      },
    );
  }

  /// 构建网络图片
  Widget _buildNetworkImage(String path) {
    return _buildImageWidget(
      Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildLoadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      ),
    );
  }

  /// 构建本地图片
  Widget _buildLocalImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return _buildDefaultOrError();
    }

    return _buildImageWidget(
      Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      ),
    );
  }

  /// 构建图片 Widget（应用形状和裁剪）
  Widget _buildImageWidget(Widget imageWidget) {
    if (shape == BoxShape.circle) {
      return ClipOval(child: imageWidget);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageWidget,
    );
  }

  /// 加载指示器
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Center(
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
      ),
    );
  }

  /// 错误状态图片
  Widget _buildErrorImage() {
    return errorImage ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: (width ?? height ?? 50).clamp(20.0, 50.0),
              color: Colors.grey.shade400,
            ),
          ),
        );
  }

  /// 默认图片或占位
  Widget _buildDefaultOrError() {
    if (defaultImage != null) {
      return defaultImage!;
    }
    return _buildErrorImage();
  }
}
