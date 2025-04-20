class GoodsPathConstants {
  // 图片相关路径常量
  static const String goodsImagesDir = 'goods_images';
  static const String warehouseImagesDir = 'warehouse_images';
  static const String relativePrefix = './';
  static const String appDataDir = 'app_data';

  // 清理路径中的多余斜杠
  static String cleanPath(String path) {
    // 移除连续的斜杠
    return path.replaceAll(RegExp(r'\/+'), '/');
  }

  // 获取相对路径
  static String toRelativePath(String? absolutePath) {
    if (absolutePath == null) return '';
    if (absolutePath.contains(goodsImagesDir)) {
      final parts = absolutePath.split(goodsImagesDir);
      final fileName =
          parts.last.startsWith('/') ? parts.last.substring(1) : parts.last;
      return '$relativePrefix$goodsImagesDir/$fileName';
    } else if (absolutePath.contains(warehouseImagesDir)) {
      final parts = absolutePath.split(warehouseImagesDir);
      final fileName =
          parts.last.startsWith('/') ? parts.last.substring(1) : parts.last;
      return '$relativePrefix$warehouseImagesDir/$fileName';
    }
    return absolutePath;
  }

  // 获取绝对路径
  static String toAbsolutePath(String appDocPath, String? relativePath) {
    if (relativePath == null) return '';
    if (relativePath.startsWith(relativePrefix)) {
      final cleanRelativePath = relativePath.substring(relativePrefix.length);
      // 确保路径之间只有一个斜杠
      final path = [
        appDocPath,
        appDataDir,
        cleanRelativePath,
      ].where((part) => part.isNotEmpty).join('/');
      // 移除任何连续的斜杠
      return path.replaceAll(RegExp(r'\/+'), '/');
    }
    return relativePath;
  }
}
