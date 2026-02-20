/// 积分商店插件主页小组件工具函数
library;

import 'package:Memento/utils/image_utils.dart';

/// 获取商品的图片绝对路径
Future<String?> getProductImagePath(String? imagePath) async {
  if (imagePath == null || imagePath.isEmpty) return null;

  // 如果是绝对路径，直接返回
  if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
    return imagePath;
  }

  // 如果是相对路径，使用 ImageUtils 转换
  return ImageUtils.getAbsolutePath(imagePath);
}
