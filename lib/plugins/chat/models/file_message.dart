import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../services/file_service.dart';

enum FileMessageType { document, image, video, audio, other }

class FileMessage {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final DateTime timestamp;
  final String? mimeType;
  final FileMessageType type;

  FileMessage({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.timestamp,
    this.mimeType,
    FileMessageType? type,
  }) : type = type ?? _determineFileType(filePath);
  
  // 根据文件路径确定文件类型
  static FileMessageType _determineFileType(String filePath) {
    if (FileService.isImage(filePath)) {
      return FileMessageType.image;
    } else if (FileService.isVideo(filePath)) {
      return FileMessageType.video;
    } else if (FileService.isAudio(filePath)) {
      return FileMessageType.audio;
    } else {
      final ext = path.extension(filePath).toLowerCase();
      if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].contains(ext)) {
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
  static Future<FileMessage> fromFile(File file) async {
    final stats = await file.stat();
    final mimeType = FileService.getMimeType(file.path);
    final fileType = _determineFileType(file.path);
    
    return FileMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: path.basename(file.path),
      filePath: file.path,
      fileSize: stats.size,
      timestamp: DateTime.now(),
      mimeType: mimeType,
      type: fileType,
    );
  }

  // 转换为Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'mimeType': mimeType,
      'type': type.toString().split('.').last,
    };
  }

  // 从Map创建FileMessage
  factory FileMessage.fromJson(Map<String, dynamic> json) {
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
      fileType = _determineFileType(json['filePath']);
    }
    
    return FileMessage(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      timestamp: DateTime.parse(json['timestamp']),
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