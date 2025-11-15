import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 文件选择器助手类
///
/// 提供统一的文件选择功能，支持图片和文档
class FilePickerHelper {
  /// 选择图片（支持多选）
  ///
  /// [multiple] 是否允许多选，默认为true
  /// 返回选中的文件列表，如果用户取消则返回空列表
  static Future<List<File>> pickImages({bool multiple = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: multiple,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();
    }

    return [];
  }

  /// 选择文档（支持多选）
  ///
  /// [multiple] 是否允许多选，默认为true
  /// 支持的文档类型：PDF, DOC, DOCX, TXT, XLS, XLSX等
  /// 返回选中的文件列表，如果用户取消则返回空列表
  static Future<List<File>> pickDocuments({bool multiple = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: multiple,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();
    }

    return [];
  }

  /// 选择任意类型的文件
  ///
  /// [multiple] 是否允许多选，默认为true
  /// [allowedExtensions] 允许的文件扩展名列表（可选）
  static Future<List<File>> pickFiles({
    bool multiple = true,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      allowMultiple: multiple,
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();
    }

    return [];
  }

  /// 判断文件是否为图片
  ///
  /// 支持的图片格式：jpg, jpeg, png, gif, bmp, webp
  static bool isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  /// 判断文件是否为文档
  ///
  /// 支持的文档格式：pdf, doc, docx, xls, xlsx, txt, ppt, pptx
  static bool isDocumentFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'txt',
      'ppt',
      'pptx'
    ].contains(extension);
  }

  /// 获取文件对应的图标
  static IconData getFileIcon(File file) {
    final extension = file.path.split('.').last.toLowerCase();

    switch (extension) {
      // 文档
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;

      // 表格
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;

      // 演示文稿
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;

      // 文本
      case 'txt':
      case 'md':
      case 'log':
        return Icons.text_snippet;

      // 代码
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'cpp':
      case 'c':
      case 'h':
        return Icons.code;

      // 压缩文件
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;

      // 图片
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return Icons.image;

      // 视频
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
        return Icons.video_file;

      // 音频
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'm4a':
        return Icons.audio_file;

      // 默认
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 获取文件名（不含路径）
  static String getFileName(File file) {
    return file.path.split('/').last.split('\\').last;
  }

  /// 获取文件扩展名
  static String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// 格式化文件大小
  ///
  /// 将字节数转换为人类可读的格式（B, KB, MB, GB）
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 获取文件大小（字节）
  static Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// 验证文件是否存在
  static Future<bool> fileExists(File file) async {
    try {
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
