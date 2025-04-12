import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/file_message.dart';

class FileService {
  // 应用文件存储目录
  static Future<Directory> get _appFilesDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory('${appDir.path}/chat_files');
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }

  // 选择文件
  static Future<FileMessage?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final savedFile = await _saveFile(file);
      return FileMessage.fromFile(savedFile);
    }
    return null;
  }

  // 保存文件到应用目录
  static Future<File> _saveFile(File sourceFile, {String? subdirectory}) async {
    final filesDir = await _appFilesDir;
    String targetDir = filesDir.path;
    
    // 如果指定了子目录，创建它
    if (subdirectory != null) {
      targetDir = '${filesDir.path}/$subdirectory';
      final subDir = Directory(targetDir);
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }
    }

    // 生成唯一的文件名
    final extension = path.extension(sourceFile.path);
    final uuid = const Uuid().v4();
    final uniqueFileName = '$uuid$extension';
    final targetFile = File('$targetDir/$uniqueFileName');
    
    // 复制文件到目标目录
    return await sourceFile.copy(targetFile.path);
  }

  // 保存图片到应用目录
  static Future<File> saveImage(File imageFile) async {
    return await _saveFile(imageFile, subdirectory: 'images');
  }

  // 保存视频到应用目录
  static Future<File> saveVideo(File videoFile) async {
    return await _saveFile(videoFile, subdirectory: 'videos');
  }

  // 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除文件错误: $e');
      return false;
    }
  }

  // 获取文件MIME类型
  static String? getMimeType(String filePath) {
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
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.mp3':
        return 'audio/mpeg';
      case '.mp4':
        return 'video/mp4';
      case '.zip':
        return 'application/zip';
      // 新增视频格式支持
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
      // 新增图片格式支持
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
      default:
        return 'application/octet-stream';
    }
  }

  // 获取文件类型
  static FileType getFileType(String filePath) {
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
  static bool isImage(String filePath) {
    return getFileType(filePath) == FileType.image;
  }

  // 检查文件是否为视频
  static bool isVideo(String filePath) {
    return getFileType(filePath) == FileType.video;
  }

  // 检查文件是否为音频
  static bool isAudio(String filePath) {
    return getFileType(filePath) == FileType.audio;
  }
}