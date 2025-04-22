import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// 全局工具类，用于路径转换
class PathUtils {
  /// 将绝对路径转换为相对路径
  /// [absolutePath] 绝对路径
  /// 返回相对于应用数据目录的路径，格式为 ./xxx/xxx
  static Future<String> toRelativePath(String absolutePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final appDataPath = path.join(appDir.path, 'app_data');

    if (absolutePath.startsWith(appDataPath)) {
      final relativePath = absolutePath.substring(appDir.path.length);
      if (relativePath.startsWith('/app_data/')) {
        return '.${relativePath.substring('/app_data'.length)}';
      } else if (relativePath.startsWith('/')) {
        // 处理其他可能的情况
        return '.${relativePath}';
      }
    }

    // 如果已经是相对路径格式，直接返回
    if (absolutePath.startsWith('./')) {
      return absolutePath;
    }

    // 如果不是应用数据目录下的文件，尝试构造相对路径
    final fileName = path.basename(absolutePath);
    if (fileName.contains('.')) {
      return './chat/chat_files/$fileName';
    }

    // 最后的回退方案，返回原路径
    return absolutePath;
  }

  /// 获取绝对路径
  /// [relativePath] 相对路径
  /// 返回绝对路径
  static Future<String> toAbsolutePath(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    final appDir = await getApplicationDocumentsDirectory();

    // 移除开头的 './'（如果存在）
    final normalizedPath =
        relativePath.startsWith('./')
            ? relativePath.substring(2)
            : relativePath;

    // 检查路径是否已经包含 app_data
    if (normalizedPath.startsWith('app_data/')) {
      return path.join(appDir.path, normalizedPath);
    } else {
      // 添加 app_data 前缀
      final result = path.join(appDir.path, 'app_data', normalizedPath);
      // 确认文件是否存在，如果不存在，尝试其他可能的路径
      if (!await File(result).exists()) {
        // 尝试直接在应用目录下查找
        final directPath = path.join(appDir.path, normalizedPath);
        if (await File(directPath).exists()) {
          return directPath;
        }
        // 尝试在 chat_files 目录下查找
        final chatFilesPath = path.join(
          appDir.path,
          'app_data/chat/chat_files',
          path.basename(normalizedPath),
        );
        if (await File(chatFilesPath).exists()) {
          return chatFilesPath;
        }
      }
      return result;
    }
  }
}

class ImageUtils {
  /// 将图片保存到应用数据目录，并返回相对路径
  /// [imageFile] 源图片文件
  /// [saveDirectory] 保存目录（相对于应用数据目录的路径）
  /// 返回相对于应用数据目录的路径
  static Future<String> saveImageToAppDirectory(
    File imageFile,
    String saveDirectory,
  ) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(
        path.join(appDir.path, 'app_data', saveDirectory),
      );

      // 确保目录存在
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 生成唯一文件名
      final fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
      final savedImage = File(path.join(imagesDir.path, fileName));

      // 复制图片到目标目录
      await imageFile.copy(savedImage.path);

      // 返回相对路径
      return './$saveDirectory/$fileName';
    } catch (e) {
      rethrow;
    }
  }

  /// 将字节数据保存为图片
  /// [imageBytes] 图片字节数据
  /// [saveDirectory] 保存目录（相对于应用数据目录的路径）
  /// [extension] 文件扩展名，默认为.jpg
  /// 返回相对于应用数据目录的路径
  static Future<String> saveBytesToAppDirectory(
    List<int> imageBytes,
    String saveDirectory, {
    String extension = '.jpg',
  }) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(
        path.join(appDir.path, 'app_data', saveDirectory),
      );

      // 确保目录存在
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 生成唯一文件名
      final fileName = '${const Uuid().v4()}$extension';
      final savedImage = File(path.join(imagesDir.path, fileName));

      // 写入图片数据
      await savedImage.writeAsBytes(imageBytes);

      // 返回相对路径
      return './$saveDirectory/$fileName';
    } catch (e) {
      rethrow;
    }
  }

  /// 获取图片的绝对路径
  /// [relativePath] 相对路径
  static Future<String> getAbsolutePath(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    if (!relativePath.startsWith('./')) {
      // 不是相对路径格式，可能是旧数据，尝试处理
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, relativePath);
    }

    final appDir = await getApplicationDocumentsDirectory();
    final pathWithoutPrefix = relativePath.substring(2); // 移除 './' 前缀

    // 检查路径是否已经包含 app_data
    if (pathWithoutPrefix.startsWith('app_data/')) {
      return path.join(appDir.path, pathWithoutPrefix);
    } else {
      // 添加 app_data 前缀
      return path.join(appDir.path, 'app_data', pathWithoutPrefix);
    }
  }

  /// 删除指定的图片文件
  /// [relativePath] 相对路径，必须以 './' 开头
  /// 返回是否删除成功
  static Future<bool> deleteImage(String? relativePath) async {
    try {
      if (relativePath == null || !relativePath.startsWith('./')) {
        return false;
      }

      final absolutePath = await getAbsolutePath(relativePath);
      final file = File(absolutePath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('删除图片失败: $e');
      return false;
    }
  }
}
