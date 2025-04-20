import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/file_message.dart';
import '../../../utils/image_utils.dart';

class FileService {
  Future<Directory> get _appFilesDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory('${appDir.path}/app_data/chat_files');
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }

  // 选择文件
  Future<FileMessage?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final savedFile = await _saveFile(file);
      // 将绝对路径转换为相对路径
      final relativePath = await PathUtils.toRelativePath(savedFile.path);
      return FileMessage.fromFile(savedFile, relativePath: relativePath);
    }
    return null;
  }

  // 保存文件到应用目录
  Future<File> _saveFile(File sourceFile, {String? subdirectory}) async {
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
  Future<File> saveImage(File imageFile) async {
    return await _saveFile(imageFile, subdirectory: 'images');
  }

  // 保存视频到应用目录
  Future<File> saveVideo(File videoFile) async {
    return await _saveFile(videoFile, subdirectory: 'videos');
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
      final absoluteVideoPath = videoFile.absolute.path;

      final filesDir = await _appFilesDir;
      final thumbnailsDir = Directory('${filesDir.path}/thumbnails');

      // 确保缩略图目录存在
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      // 生成唯一的缩略图文件名并确保是绝对路径
      final uuid = const Uuid().v4();
      final thumbnailFile = File('${thumbnailsDir.path}/$uuid.jpg');
      final absoluteThumbnailPath = thumbnailFile.absolute.path;

      try {
        // 使用 fc_native_video_thumbnail 生成缩略图，使用绝对路径
        // final plugin = FcNativeVideoThumbnail();
        // final thumbnailGenerated = await plugin.getVideoThumbnail(
        //   srcFile: absoluteVideoPath,
        //   destFile: absoluteThumbnailPath,
        //   width: 200,
        //   height: 200,
        //   format: 'jpeg',
        //   quality: 75,
        // );

        // // 检查缩略图是否成功生成
        // if (thumbnailGenerated && await thumbnailFile.exists()) {
        //   return absoluteThumbnailPath;
        // } else {
        //   _logError('缩略图生成失败，返回值为空或文件不存在');
        //   return null;
        // }
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
    // TODO: 替换为proper logging
    print(message);
  }
}
