import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'user.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/storage_manager.dart';

enum MessageType { received, sent, file, image, video, audio }

/// 文件路径转换工具类
class FilePathConverter {
  /// 将相对路径转换为绝对路径
  static String toAbsolutePath(String relativePath, StorageManager storage) {
    if (relativePath.startsWith('./')) {
      relativePath = relativePath.substring(2);
    }
    return path.join(storage.basePath, relativePath);
  }

  /// 将绝对路径转换为相对路径
  static String toRelativePath(String absolutePath, StorageManager storage) {
    final basePath = storage.basePath;
    if (absolutePath.startsWith(basePath)) {
      String relativePath = absolutePath.substring(basePath.length + 1);
      return './$relativePath';
    }
    return absolutePath;
  }
}

class Message {
  static const String metadataKeyFileInfo = 'fileInfo';

  final String id;
  String content; // 改为非final以支持编辑
  final User user;
  final DateTime date;
  final MessageType type;
  DateTime? editedAt; // 添加编辑时间字段
  String? fixedSymbol; // 添加固定符号字段
  Color? bubbleColor; // 添加气泡颜色字段
  Map<String, dynamic>? metadata; // 添加元数据字段，用于存储额外信息

  Message({
    required this.id,
    required this.content,
    required this.user,
    required this.type,
    DateTime? date,
    this.editedAt,
    this.fixedSymbol,
    this.bubbleColor,
    this.metadata,
  }) : date = date ?? DateTime.now();

  /// 创建消息的副本，可以选择性地替换某些属性
  Message copyWith({
    String? id,
    String? content,
    User? user,
    DateTime? date,
    MessageType? type,
    DateTime? editedAt,
    String? fixedSymbol,
    Color? bubbleColor,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      user: user ?? this.user,
      date: date ?? this.date,
      type: type ?? this.type,
      editedAt: editedAt ?? this.editedAt,
      fixedSymbol: fixedSymbol ?? this.fixedSymbol,
      bubbleColor: bubbleColor ?? this.bubbleColor,
      metadata: metadata ?? this.metadata,
    );
  }

  // 编辑消息内容
  void edit(String newContent) {
    content = newContent;
    editedAt = DateTime.now();
  }

  // 判断消息是否被编辑过
  bool get isEdited => editedAt != null;

  // 设置固定符号
  void setFixedSymbol(String? symbol) {
    fixedSymbol = symbol;
  }

  // 判断是否为音频消息
  bool get isAudioMessage => type == MessageType.audio;

  // 获取音频消息的元数据
  Map<String, dynamic>? get audioMetadata {
    if (isAudioMessage &&
        metadata != null &&
        metadata!.containsKey(metadataKeyFileInfo)) {
      return metadata![metadataKeyFileInfo] as Map<String, dynamic>;
    }
    return null;
  }

  // 获取音频消息的时长（秒）
  int get audioDuration {
    final data = audioMetadata;
    if (data != null && data.containsKey('duration')) {
      return data['duration'] as int;
    }
    return 0;
  }

  // 获取音频消息的文件路径（返回绝对路径）
  String? audioFilePathWithStorage(StorageManager storage) {
    final data = audioMetadata;
    if (data != null && data.containsKey('filePath')) {
      String filePath = data['filePath'] as String;
      // 如果是相对路径，转换为绝对路径
      if (filePath.startsWith('./')) {
        return FilePathConverter.toAbsolutePath(filePath, storage);
      }
      return filePath;
    }
    return null;
  }

  // 获取原始文件路径（用于存储，保持相对路径）
  String? get originalFilePath {
    final data = metadata?[metadataKeyFileInfo];
    if (data != null &&
        data is Map<String, dynamic> &&
        data.containsKey('filePath')) {
      return data['filePath'] as String;
    }
    return null;
  }

  // 设置文件路径（自动转换为相对路径进行存储）
  void setFilePath(String absolutePath, StorageManager storage) {
    if (metadata == null) {
      metadata = {};
    }
    if (!metadata!.containsKey(metadataKeyFileInfo)) {
      metadata![metadataKeyFileInfo] = {};
    }

    final relativePath = FilePathConverter.toRelativePath(
      absolutePath,
      storage,
    );
    (metadata![metadataKeyFileInfo] as Map<String, dynamic>)['filePath'] =
        relativePath;
  }
}
