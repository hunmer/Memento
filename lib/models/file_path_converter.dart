import '../core/storage/storage_manager.dart';

/// 文件路径转换工具类
/// 用于处理文件路径在相对路径和绝对路径之间的转换
class FilePathConverter {
  /// 将绝对路径转换为相对路径
  ///
  /// [absolutePath] 绝对路径
  /// [storage] StorageManager实例，用于获取应用数据目录
  /// 返回相对于应用数据目录的路径
  static String toRelativePath(String absolutePath, StorageManager storage) {
    final appDataPath = storage.basePath;
    if (absolutePath.startsWith(appDataPath)) {
      return './${absolutePath.substring(appDataPath.length)}';
    }
    return absolutePath;
  }

  /// 将相对路径转换为绝对路径
  ///
  /// [relativePath] 相对路径（以 './' 开头）
  /// [storage] StorageManager实例，用于获取应用数据目录
  /// 返回绝对路径
  static String toAbsolutePath(String relativePath, StorageManager storage) {
    if (relativePath.startsWith('./')) {
      final appDataPath = storage.basePath;
      return '$appDataPath${relativePath.substring(2)}';
    }
    return relativePath;
  }
}
