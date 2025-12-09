import 'dart:io';
import 'package:get/get.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/chat/models/file_message.dart';

// 用于返回保存文件的结果
class SaveFileResult {
  final File savedFile;
  final String systemFileName;

  SaveFileResult(this.savedFile, this.systemFileName);
}

class FileService {
  Future<Directory> get _appFilesDir async {
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    // 确保使用正确的路径分隔符
    final filesDir = Directory(path.join('app_data', 'chat', 'chat_files'));
    final absoluteFilesDir = Directory(path.join(appDir.path, filesDir.path));
    if (!await absoluteFilesDir.exists()) {
      await absoluteFilesDir.create(recursive: true);
    }
    return absoluteFilesDir;
  }

  // 选择文件
  Future<FileMessage?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.first;
      final file = File(platformFile.path!);
      // 获取原始文件名
      final originalFileName = platformFile.name;

      // 保存文件到应用目录
      final saveResult = await _saveFile(file);
      debugPrint('文件已保存到: ${saveResult.savedFile.path}');

      // 创建FileMessage对象
      final fileMessage = await FileMessage.fromFile(
        saveResult.savedFile,
        systemFileName: saveResult.systemFileName,
        originalFileName: originalFileName, // 传递原始文件名
      );

      // 验证文件路径
      final absolutePath = await fileMessage.getAbsolutePath();
      final fileExists = await File(absolutePath).exists();
      debugPrint('文件路径验证: $absolutePath, 文件存在: $fileExists');

      return fileMessage;
    }
    return null;
  }

  // 保存文件到应用目录
  Future<SaveFileResult> _saveFile(
    File sourceFile, {
    String? subdirectory,
  }) async {
    final filesDir = await _appFilesDir;
    String targetDir = filesDir.path;

    // 如果指定了子目录，创建它
    if (subdirectory != null) {
      targetDir = path.join(filesDir.path, subdirectory);
      final subDir = Directory(targetDir);
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }
    }

    // 生成唯一的文件名
    final extension = path.extension(sourceFile.path);
    final uuid = const Uuid().v4();
    final uniqueFileName = '$uuid$extension';
    final targetFile = File(path.join(targetDir, uniqueFileName));

    // 复制文件到目标目录
    final savedFile = await sourceFile.copy(targetFile.path);
    return SaveFileResult(savedFile, uniqueFileName);
  }

  // 保存图片到应用目录
  Future<File> saveImage(File imageFile) async {
    final saveResult = await _saveFile(imageFile, subdirectory: 'images');
    return saveResult.savedFile;
  }

  // 保存视频到应用目录
  Future<File> saveVideo(File videoFile) async {
    final saveResult = await _saveFile(videoFile, subdirectory: 'videos');
    return saveResult.savedFile;
  }

  // 保存音频到应用目录
  Future<File> saveAudio(File audioFile) async {
    final saveResult = await _saveFile(audioFile, subdirectory: 'audios');
    return saveResult.savedFile;
  }

  // 删除文件
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _logError('删除文件错误: $e');
      return false;
    }
  }

  // 获取文件MIME类型
  String? getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      // 图片格式
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      // 音频格式
      case '.mp3':
        return 'audio/mpeg';
      // 视频格式
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  // 获取文件类型
  FileType getFileType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
      case '.svg':
        return FileType.image;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.wmv':
      case '.flv':
      case '.webm':
        return FileType.video;
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.m4a':
        return FileType.audio;
      default:
        return FileType.any;
    }
  }

  // 检查文件是否为图片
  bool isImage(String filePath) {
    return getFileType(filePath) == FileType.image;
  }

  // 检查文件是否为视频
  bool isVideo(String filePath) {
    return getFileType(filePath) == FileType.video;
  }

  // 检查文件是否为音频
  bool isAudio(String filePath) {
    return getFileType(filePath) == FileType.audio;
  }

  // 获取视频缩略图
  Future<String?> getVideoThumbnail(String videoPath) async {
    try {
      // 首先检查视频文件是否存在，并获取绝对路径
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        _logError('视频文件不存在: $videoPath');
        return null;
      }

      final filesDir = await _appFilesDir;
      final thumbnailsDir = Directory(path.join(filesDir.path, 'thumbnails'));

      // 确保缩略图目录存在
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      // 生成唯一的缩略图文件名
      final uuid = const Uuid().v4();
      final thumbnailPath = path.join(thumbnailsDir.path, '$uuid.jpg');

      try {
        // TODO: 实现视频缩略图生成逻辑
        return thumbnailPath;
      } catch (thumbnailError) {
        _logError('视频缩略图生成失败: $thumbnailError');
        return null;
      }
    } catch (e) {
      _logError('处理视频缩略图时出错: $e');
      return null;
    }
  }

  // 记录错误信息
  void _logError(String message) {
    // TODO: 实现proper logging
    debugPrint(message);
  }
}
