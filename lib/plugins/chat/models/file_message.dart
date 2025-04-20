import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/file_service.dart';
import '../../../utils/image_utils.dart';

enum FileMessageType { document, image, video, audio, other }

class FileMessage {
  final String id;
  final String fileName; // 存储系统中的文件名（UUID）
  final String originalFileName; // 原始上传时的文件名
  final String filePath;
  final int fileSize;
  final DateTime timestamp;
  final String? mimeType;
  final FileMessageType type;

  FileMessage({
    required this.id,
    required this.fileName,
    required this.originalFileName,
    required this.filePath,
    required this.fileSize,
    required this.timestamp,
    this.mimeType,
    FileMessageType? type,
  }) : type = type ?? _determineFileType(filePath);

  // 根据文件路径确定文件类型
  static FileMessageType _determineFileType(String filePath) {
    final fileService = FileService();
    if (fileService.isImage(filePath)) {
      return FileMessageType.image;
    } else if (fileService.isVideo(filePath)) {
      return FileMessageType.video;
    } else if (fileService.isAudio(filePath)) {
      return FileMessageType.audio;
    } else {
      final ext = path.extension(filePath).toLowerCase();
      if ([
        '.pdf',
        '.doc',
        '.docx',
        '.xls',
        '.xlsx',
        '.ppt',
        '.pptx',
        '.txt',
      ].contains(ext)) {
        return FileMessageType.document;
      }
      return FileMessageType.other;
    }
  }

  // 检查是否为图片
  bool get isImage => type == FileMessageType.image;

  // 检查是否为视频
  bool get isVideo => type == FileMessageType.video;

  // 检查是否为音频
  bool get isAudio => type == FileMessageType.audio;

  // 检查是否为文档
  bool get isDocument => type == FileMessageType.document;

  // 获取文件扩展名
  String get extension => path.extension(fileName).toLowerCase();

  // 获取格式化的文件大小
  String get formattedSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  // 从文件创建FileMessage
  static Future<FileMessage> fromFile(
    File file, {
    String? relativePath,
    String? systemFileName,
    String? originalFileName,
  }) async {
    final stats = await file.stat();
    final fileService = FileService();
    final mimeType = fileService.getMimeType(file.path);
    final fileType = _determineFileType(file.path);
    // 如果没有提供原始文件名，则使用文件路径的基本名称
    final fileName = originalFileName ?? path.basename(file.path);

    return FileMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: systemFileName ?? path.basename(file.path), // 系统文件名（UUID）
      originalFileName: fileName, // 保存原始文件名
      filePath: relativePath ?? file.path, // 使用相对路径
      fileSize: stats.size,
      timestamp: DateTime.now(),
      mimeType: mimeType,
      type: fileType,
    );
  }

  // 获取文件的绝对路径
  Future<String> getAbsolutePath() async {
    return await PathUtils.toAbsolutePath(filePath);
  }

  // 转换为Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'originalFileName': originalFileName, // 添加原始文件名
      'filePath': filePath, // 存储相对路径
      'fileSize': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'mimeType': mimeType,
      'type': type.toString().split('.').last,
    };
  }

  // 从Map创建FileMessage
  factory FileMessage.fromJson(Map<String, dynamic> json) {
    // 确保必要的字段存在
    if (!json.containsKey('fileName') || !json.containsKey('filePath')) {
      throw FormatException(
        'Invalid file message format: missing required fields',
      );
    }

    // 解析文件类型
    FileMessageType fileType;
    if (json.containsKey('type') && json['type'] != null) {
      switch (json['type']) {
        case 'image':
          fileType = FileMessageType.image;
          break;
        case 'video':
          fileType = FileMessageType.video;
          break;
        case 'audio':
          fileType = FileMessageType.audio;
          break;
        case 'document':
          fileType = FileMessageType.document;
          break;
        default:
          fileType = FileMessageType.other;
      }
    } else {
      // 如果没有类型信息，尝试从文件路径推断
      fileType = _determineFileType(json['filePath'] ?? '');
    }

    // 处理文件名和路径
    String fileName = json['fileName'];
    String filePath = json['filePath'];

    // 如果是URI编码的路径，进行解码
    if (filePath.contains('%')) {
      filePath = Uri.decodeFull(filePath);
    }

    return FileMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      originalFileName: json['originalFileName'] ?? fileName,
      filePath: filePath,
      fileSize: json['fileSize'] ?? 0,
      timestamp:
          json.containsKey('timestamp') && json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
      mimeType: json['mimeType'],
      type: fileType,
    );
  }

  // 获取文件图标
  IconData getIcon() {
    switch (type) {
      case FileMessageType.image:
        return Icons.image;
      case FileMessageType.video:
        return Icons.videocam;
      case FileMessageType.audio:
        return Icons.audiotrack;
      case FileMessageType.document:
        final ext = extension.toLowerCase();
        if (ext == '.pdf') return Icons.picture_as_pdf;
        if (['.doc', '.docx'].contains(ext)) return Icons.description;
        if (['.xls', '.xlsx'].contains(ext)) return Icons.table_chart;
        if (['.ppt', '.pptx'].contains(ext)) return Icons.slideshow;
        return Icons.insert_drive_file;
      case FileMessageType.other:
        return Icons.insert_drive_file;
    }
  }
}
