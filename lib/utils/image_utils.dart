import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
    if (relativePath == null || !relativePath.startsWith('./')) {
      return relativePath ?? '';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'app_data', relativePath.substring(2));
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
