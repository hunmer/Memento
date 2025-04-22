import 'package:flutter/material.dart';
import 'user.dart';

enum MessageType { received, sent, file, image, video, audio }

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

  // 获取音频消息的文件路径
  String? get audioFilePath {
    final data = audioMetadata;
    if (data != null && data.containsKey('filePath')) {
      return data['filePath'] as String;
    }
    return null;
  }
}
