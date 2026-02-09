/// 公共图片辅助方法
///
/// 为 widgets_gallery 中的卡片组件提供统一的图片加载支持
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Memento/widgets/adaptive_image.dart';

/// 公共图片构建器
///
/// 支持网络 URL 和本地文件路径，自动判断并使用合适的加载方式
/// 适用于 widgets_gallery 中的各种卡片组件
class CommonImageBuilder {
  /// 构建图片 Widget（带圆角裁剪）
  ///
  /// 参数:
  /// - [imageUrl]: 图片 URL 或本地文件路径
  /// - [width]: 图片宽度
  /// - [height]: 图片高度
  /// - [fit]: 填充模式，默认 BoxFit.cover
  /// - [borderRadius]: 圆角半径，默认 12
  /// - [defaultIcon]: 无图片时显示的默认图标（可选）
  /// - [isDark]: 是否为深色模式（用于错误占位符）
  static Widget buildImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 12,
    IconData? defaultIcon,
    bool isDark = false,
  }) {
    // 空图片路径时显示默认图片或占位
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildDefaultPlaceholder(width, height, defaultIcon, isDark);
    }

    // 网络图片直接使用
    if (isNetworkImage(imageUrl)) {
      return AdaptiveImage(
        imagePath: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        defaultImage: _buildDefaultPlaceholder(width, height, defaultIcon, isDark),
      );
    }

    // 本地文件路径 - 直接使用 FileImage
    return _buildLocalImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      defaultIcon: defaultIcon,
      isDark: isDark,
    );
  }

  /// 构建本地图片 Widget（直接使用 File，避免路径转换问题）
  static Widget _buildLocalImageWidget({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 12,
    IconData? defaultIcon,
    bool isDark = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(imageUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPlaceholder(width, height, defaultIcon, isDark);
        },
      ),
    );
  }

  /// 构建圆形图片（用于头像等场景）
  ///
  /// 参数:
  /// - [imageUrl]: 图片 URL 或本地文件路径
  /// - [size]: 圆形直径
  /// - [defaultIcon]: 无图片时显示的默认图标（可选）
  /// - [isDark]: 是否为深色模式
  static Widget buildCircleImage({
    required String? imageUrl,
    double size = 40,
    IconData? defaultIcon,
    bool isDark = false,
  }) {
    // 空图片路径时显示默认图片或占位
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildCirclePlaceholder(size, defaultIcon, isDark);
    }

    // 网络图片直接使用
    if (isNetworkImage(imageUrl)) {
      return AdaptiveImage(
        imagePath: imageUrl,
        width: size,
        height: size,
        shape: BoxShape.circle,
        defaultImage: _buildDefaultPlaceholder(size, size, defaultIcon, isDark),
      );
    }

    // 本地文件路径 - 直接使用 FileImage
    return ClipOval(
      child: Image.file(
        File(imageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildCirclePlaceholder(size, defaultIcon, isDark);
        },
      ),
    );
  }

  /// 构建圆形占位符
  static Widget _buildCirclePlaceholder(double size, IconData? defaultIcon, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: Center(
        child: Icon(
          defaultIcon ?? Icons.person,
          size: size * 0.5,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
    );
  }

  /// 构建头像或图标（带边框圆形）
  ///
  /// 用于 InboxMessageCard 等组件
  /// 优先使用图标（如果提供 iconCodePoint），否则使用图片
  ///
  /// 参数:
  /// - [imageUrl]: 图片 URL 或本地文件路径
  /// - [iconCodePoint]: 图标 codePoint（可选，优先于 imageUrl）
  /// - [iconBackgroundColor]: 图标背景颜色（可选）
  /// - [size]: 圆形直径，默认 40
  /// - [isDark]: 是否为深色模式
  static Widget buildAvatarOrIcon({
    required String? imageUrl,
    int? iconCodePoint,
    int? iconBackgroundColor,
    double size = 40,
    bool isDark = false,
  }) {
    // 优先使用图标
    if (iconCodePoint != null) {
      final backgroundColor = iconBackgroundColor != null
          ? Color(iconBackgroundColor)
          : Colors.grey.shade300;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Icon(
          IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: size * 0.6,
        ),
      );
    }

    // 如果有图片 URL，使用圆形图片
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // 网络图片使用 AdaptiveImage
      if (isNetworkImage(imageUrl)) {
        return AdaptiveImage(
          imagePath: imageUrl,
          width: size,
          height: size,
          shape: BoxShape.circle,
          defaultImage: _buildCirclePlaceholder(size, Icons.person, isDark),
        );
      }

      // 本地文件直接使用 File
      return ClipOval(
        child: Image.file(
          File(imageUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildCirclePlaceholder(size, Icons.person, isDark);
          },
        ),
      );
    }

    // 默认图标
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.grey.shade600,
      ),
    );
  }

  /// 构建默认占位符
  static Widget _buildDefaultPlaceholder(
    double? width,
    double? height,
    IconData? defaultIcon,
    bool isDark,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          defaultIcon ?? Icons.image,
          size: _calculateIconSize(width, height),
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
    );
  }

  /// 计算图标大小（基于容器尺寸）
  static double _calculateIconSize(double? width, double? height) {
    final size = (width ?? height ?? 50).clamp(20.0, 100.0);
    return size * 0.5;
  }

  /// 判断是否为网络图片
  static bool isNetworkImage(String path) {
    return AdaptiveImage.isNetworkImage(path);
  }

  /// 判断是否为本地文件路径
  static bool isLocalFile(String path) {
    return path.startsWith('/') ||
        path.startsWith('file://') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(path);
  }
}
