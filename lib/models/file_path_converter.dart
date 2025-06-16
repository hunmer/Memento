import 'package:Memento/core/storage/storage_manager.dart';

/// 文件路径转换工具类
/// 用于处理文件路径在相对路径和绝对路径之间的转换
class FilePathConverter {
  /// 将绝对路径转换为相对路径
  ///
  /// [absolutePath] 绝对路径或已经是相对路径的字符串
  /// 返回相对于应用数据目录的路径
  static Future<String> toRelativePath(String absolutePath) async {
    // 如果路径已经是相对路径（以 './' 开头），则规范化路径格式
    if (absolutePath.startsWith('./')) {
      // 修复多余斜杠问题，如 ".///" 变为 "./"
      return _normalizeRelativePath(absolutePath);
    }

    final appDataPath = await StorageManager.getApplicationDocumentsDirectory();
    final appDataPathStr = appDataPath.path;
    if (absolutePath.startsWith(appDataPathStr)) {
      // 生成相对路径并规范化
      String relativePath =
          './${absolutePath.substring(appDataPathStr.length)}';
      return _normalizeRelativePath(relativePath);
    }
    return absolutePath;
  }

  /// 规范化相对路径，处理多余的斜杠
  ///
  /// [path] 需要规范化的路径
  /// 返回规范化后的路径
  static String _normalizeRelativePath(String path) {
    // 确保以 './' 开头
    if (!path.startsWith('./')) {
      return path;
    }

    // 处理 './//' 这种情况，将多个斜杠替换为单个斜杠
    String normalized = './';
    String remainder = path.substring(2);

    // 去除开头的多余斜杠
    while (remainder.startsWith('/')) {
      remainder = remainder.substring(1);
    }

    // 组合最终路径
    return normalized + remainder;
  }

  /// 将相对路径转换为绝对路径
  ///
  /// [relativePath] 相对路径（以 './' 开头）
  /// 返回绝对路径
  static Future<String> toAbsolutePath(String relativePath) async {
    if (relativePath.startsWith('./')) {
      final appDataPath =
          await StorageManager.getApplicationDocumentsDirectory();
      return '$appDataPath/app_data/${relativePath.substring(2)}';
    }
    return relativePath;
  }
}
