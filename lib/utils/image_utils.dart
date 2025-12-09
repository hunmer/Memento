import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// 图片类型枚举
enum ImageType {
  network, // 网络图片
  asset, // Asset图片
  file, // 本地文件图片
  unknown, // 未知类型
}
  
class ImageUtils {
  /// 缓存的应用文档目录路径，用于同步方法
  static String? _appDocumentDirectoryPath;

  /// 将图片保存到应用数据目录，并返回相对路径
  /// [imageFile] 源图片文件
  /// [saveDirectory] 保存目录（相对于应用数据目录的路径）
  /// 返回相对于应用数据目录的路径
  static Future<String> saveImage(File imageFile, String saveDirectory) async {
    try {
      // 获取应用文档目录
      final appDir = await StorageManager.getApplicationDocumentsDirectory();
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

      // 返回相对路径（统一使用正斜杠，因为这是API的约定格式）
      return './${saveDirectory.replaceAll(r'\', '/')}/${fileName.replaceAll(r'\', '/')}';
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
      final appDir = await StorageManager.getApplicationDocumentsDirectory();
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

      // 返回相对路径（统一使用正斜杠，因为这是API的约定格式）
      return './${saveDirectory.replaceAll(r'\', '/')}/${fileName.replaceAll(r'\', '/')}';
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
      final appDir = await StorageManager.getApplicationDocumentsDirectory();
      // 缓存应用目录路径
      _appDocumentDirectoryPath = appDir.path;
      // 确保使用正确的路径分隔符
      final normalizedPath = relativePath.replaceAll('/', path.separator);
      return path.join(appDir.path, normalizedPath);
    }

    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    // 缓存应用目录路径
    _appDocumentDirectoryPath = appDir.path;
    // 移除 './' 前缀并规范化路径分隔符
    final pathWithoutPrefix = relativePath
        .substring(2)
        .replaceAll('/', path.separator);

    // 检查路径是否已经包含 app_data（处理不同的路径分隔符）
    // 如果路径中已经包含 app_data，则从该位置截取后面的部分
    if (pathWithoutPrefix.contains('app_data')) {
      final index = pathWithoutPrefix.indexOf('app_data') + 'app_data'.length;
      final remainingPath = pathWithoutPrefix.substring(index);
      // 确保路径开头没有多余的分隔符
      final cleanPath =
          remainingPath.startsWith(path.separator) ||
                  remainingPath.startsWith('/')
              ? remainingPath.substring(1)
              : remainingPath;
      return path.join(appDir.path, 'app_data', cleanPath);
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

  /// 获取本地路径（同步版本，用于UI渲染）
  /// 注意：这个方法不会进行复杂的路径解析，仅适用于简单的本地路径场景
  /// 对于需要精确路径的场景，请使用异步的getAbsolutePath方法
  static String getLocalPath(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    // 如果是网络路径，直接返回
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }

    // 简单处理相对路径，不进行复杂的应用目录解析
    // 注意：这可能不是最终的绝对路径，但对于FileImage构造函数来说已足够
    if (relativePath.startsWith('./')) {
      return relativePath.substring(2);
    }

    return relativePath;
  }

  /// 获取图片的绝对路径（同步版本）
  ///
  /// 注意：此方法依赖于缓存的应用目录路径。
  /// 请确保在应用启动后已至少调用过一次异步的 getAbsolutePath 方法，
  /// 或者在应用初始化时调用 initializeSync 方法。
  /// 如果缓存未初始化，此方法会尝试使用相对路径，但可能无法正确工作。
  ///
  /// [relativePath] 相对路径
  static String getAbsolutePathSync(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    // 如果是网络路径，直接返回
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }

    // 如果缓存的应用目录路径不存在，返回相对路径（可能无法工作）
    if (_appDocumentDirectoryPath == null) {
      debugPrint('警告: 应用目录路径未缓存，getAbsolutePathSync 可能无法正确工作');
      return relativePath;
    }

    // 处理相对路径
    if (!relativePath.startsWith('./')) {
      // 不是相对路径格式，可能是旧数据
      final normalizedPath = relativePath.replaceAll('/', path.separator);
      return path.join(_appDocumentDirectoryPath!, normalizedPath);
    }

    // 移除 './' 前缀并规范化路径分隔符
    final pathWithoutPrefix = relativePath
        .substring(2)
        .replaceAll('/', path.separator);

    // 检查路径是否已经包含 app_data
    if (pathWithoutPrefix.contains('app_data')) {
      final index = pathWithoutPrefix.indexOf('app_data') + 'app_data'.length;
      final remainingPath = pathWithoutPrefix.substring(index);
      final cleanPath =
          remainingPath.startsWith(path.separator) ||
                  remainingPath.startsWith('/')
              ? remainingPath.substring(1)
              : remainingPath;
      return path.join(_appDocumentDirectoryPath!, 'app_data', cleanPath);
    } else {
      // 添加 app_data 前缀
      return path.join(_appDocumentDirectoryPath!, 'app_data', pathWithoutPrefix);
    }
  }

  /// 初始化同步方法所需的缓存
  ///
  /// 建议在应用启动时调用此方法，以确保同步方法能够正常工作
  static Future<void> initializeSync() async {
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    _appDocumentDirectoryPath = appDir.path;
    debugPrint('ImageUtils: 应用目录路径已缓存: $_appDocumentDirectoryPath');
  }

  static Future<String> toRelativePath(String absolutePath) async {
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    final appDataPath = path.join(appDir.path, 'app_data');

    if (absolutePath.startsWith(appDataPath)) {
      String relativePath = absolutePath.substring(appDir.path.length);
      // 统一使用正斜杠
      relativePath = relativePath.replaceAll(r'\', '/');

      if (relativePath.startsWith('/app_data/') ||
          relativePath.startsWith('\\app_data\\')) {
        return '.${relativePath.substring('/app_data'.length).replaceAll(r'\', '/')}';
      } else if (relativePath.startsWith('/') ||
          relativePath.startsWith('\\')) {
        // 处理其他可能的情况，确保使用正斜杠
        return '.${relativePath.replaceAll(r'\', '/')}';
      }
    }

    // 如果已经是相对路径格式，直接返回（确保使用正斜杠）
    if (absolutePath.startsWith('./')) {
      return absolutePath.replaceAll(r'\', '/');
    }

    // 如果不是应用数据目录下的文件，尝试构造相对路径
    final fileName = path.basename(absolutePath);
    if (fileName.contains('.')) {
      return './chat/chat_files/${fileName.replaceAll(r'\', '/')}';
    }

    // 最后的回退方案，返回原路径
    return absolutePath;
  }

  /// 根据文件路径判断图片类型
  static ImageType getImageType(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return ImageType.unknown;
    }

    // 网络图片
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return ImageType.network;
    }

    // Asset图片 - 以 assets/ 开头或包含 lib/plugins/*/assets/
    if (imagePath.startsWith('assets/') ||
        imagePath.contains('lib/plugins/') && imagePath.contains('/assets/')) {
      return ImageType.asset;
    }

    // 绝对路径的本地文件
    if (path.isAbsolute(imagePath)) {
      return ImageType.file;
    }

    // 相对路径的本地文件（以 ./ 开头或没有协议前缀）
    if (imagePath.startsWith('./') ||
        (!imagePath.startsWith('http://') &&
            !imagePath.startsWith('https://'))) {
      return ImageType.file;
    }

    return ImageType.unknown;
  }

  /// 根据图片路径智能创建对应的 ImageProvider
  static ImageProvider createImageProvider(String? imagePath) {
    final imageType = getImageType(imagePath);

    switch (imageType) {
      case ImageType.network:
        return NetworkImage(imagePath!);
      case ImageType.asset:
        // 对于 asset 路径，需要转换为正确的格式
        String assetPath = imagePath!;
        if (assetPath.contains('lib/plugins/') &&
            assetPath.contains('/assets/')) {
          // 从 lib/plugins/calendar_album/assets/images/bg.png 转换为 assets/plugins/calendar_album/bg.png
          final pluginMatch = RegExp(
            r'lib/plugins/([^/]+)/assets/(.+)',
          ).firstMatch(assetPath);
          if (pluginMatch != null) {
            final pluginName = pluginMatch.group(1)!;
            final relativePath = pluginMatch.group(2)!;
            assetPath = 'assets/plugins/$pluginName/$relativePath';
          }
        } else if (assetPath.startsWith('assets/')) {
          // 已经是正确的 asset 格式
          assetPath = assetPath.substring(7); // 移除 'assets/' 前缀
        }
        return AssetImage(assetPath);
      case ImageType.file:
        // 对于文件路径，需要转换为绝对路径
        String filePath = imagePath!;
        if (!path.isAbsolute(filePath)) {
          // 尝试获取绝对路径
          try {
            filePath = getAbsolutePathSync(filePath);
          } catch (e) {
            // 如果获取绝对路径失败，使用相对路径
            if (filePath.startsWith('./')) {
              filePath = filePath.substring(2);
            }
          }
        }
        return FileImage(File(filePath));
      case ImageType.unknown:
        // 返回一个空的占位图片
        return const AssetImage('assets/images/placeholder.png');
    }
  }

  /// 获取显示用的图片路径（用于调试和日志）
  static String getDisplayPath(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '空路径';
    }

    final imageType = getImageType(imagePath);
    final typeLabel = switch (imageType) {
      ImageType.network => '网络',
      ImageType.asset => 'Asset',
      ImageType.file => '文件',
      ImageType.unknown => '未知',
    };

    return '[$typeLabel] $imagePath';
  }
}
