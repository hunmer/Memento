import 'package:path_provider/path_provider.dart';

/// 文件路径转换工具类
/// 用于处理文件路径在相对路径和绝对路径之间的转换
class FilePathConverter {
  /// 将绝对路径转换为相对路径
  ///
  /// [absolutePath] 绝对路径
  /// 返回相对于应用数据目录的路径
  static Future<String> toRelativePath(String absolutePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final appDataPath = appDir.path;
    if (absolutePath.startsWith(appDataPath)) {
      return './app_data/${absolutePath.substring(appDataPath.length)}';
    }
    return absolutePath;
  }

  /// 将相对路径转换为绝对路径
  ///
  /// [relativePath] 相对路径（以 './' 开头）
  /// 返回绝对路径
  static Future<String> toAbsolutePath(String relativePath) async {
    if (relativePath.startsWith('./')) {
      final appDir = await getApplicationDocumentsDirectory();
      final appDataPath = appDir.path;
      return '$appDataPath/app_data/${relativePath.substring(2)}';
    }
    return relativePath;
  }
}
