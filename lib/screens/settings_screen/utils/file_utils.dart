import 'dart:io';

class FileUtils {
  /// 复制目录及其所有内容到目标位置
  static Future<void> copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    // 确保目标目录存在
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    // 获取源目录中的所有实体（文件和子目录）
    await for (final entity in source.list(recursive: false)) {
      final String newPath =
          '${destination.path}/${entity.path.split('/').last}';

      if (entity is File) {
        // 如果是文件，直接复制
        await entity.copy(newPath);
      } else if (entity is Directory) {
        // 如果是目录，递归复制
        final newDirectory = Directory(newPath);
        await copyDirectory(entity, newDirectory);
      }
    }
  }
}
