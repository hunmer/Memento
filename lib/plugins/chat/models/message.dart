import 'package:Memento/models/file_path_converter.dart';
import 'package:flutter/material.dart';
import 'user.dart';
import '../../../utils/color_extension.dart';

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

  /// 初始化消息，处理文件路径转换
  static Future<Message> create({
    required String id,
    required String content,
    required User user,
    required MessageType type,
    DateTime? date,
    DateTime? editedAt,
    String? fixedSymbol,
    Color? bubbleColor,
    Map<String, dynamic>? metadata,
  }) async {
    // 创建基本消息实例
    final message = Message(
      id: id,
      content: content,
      user: user,
      type: type,
      date: date,
      editedAt: editedAt,
      fixedSymbol: fixedSymbol,
      bubbleColor: bubbleColor,
      metadata: metadata,
    );

    // 处理 metadata 中的文件路径，转换为绝对路径
    if (metadata != null && metadata.containsKey(Message.metadataKeyFileInfo)) {
      final fileInfo = Map<String, dynamic>.from(
        metadata[Message.metadataKeyFileInfo] as Map<String, dynamic>,
      );
      if (fileInfo.containsKey('filePath')) {
        final filePath = fileInfo['filePath'] as String;
        // 只有当路径是相对路径时才进行转换
        if (filePath.startsWith('./')) {
          // 使用FilePathConverter将相对路径转换为绝对路径
          fileInfo['filePath'] = await FilePathConverter.toAbsolutePath(
            filePath,
          );
        }
      }
      // 更新转换后的fileInfo
      message.metadata![Message.metadataKeyFileInfo] = fileInfo;
    }

    return message;
  }

  /// 创建消息的副本，可选择性地更新某些字段
  Future<Message> copyWith({
    String? id,
    String? content,
    User? user,
    DateTime? date,
    MessageType? type,
    DateTime? editedAt,
    String? fixedSymbol,
    Color? bubbleColor,
    Map<String, dynamic>? metadata,
  }) async {
    return create(
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

  /// 将消息转换为JSON格式
  Future<Map<String, dynamic>> toJson() async {
    // 获取原始的 metadata
    final messageMetadata =
        metadata != null
            ? Map<String, dynamic>.from(metadata!)
            : <String, dynamic>{};

    // 确保文件路径是相对路径格式
    if (messageMetadata.containsKey(Message.metadataKeyFileInfo)) {
      final fileInfo = Map<String, dynamic>.from(
        messageMetadata[Message.metadataKeyFileInfo] as Map<String, dynamic>,
      );
      if (fileInfo.containsKey('filePath')) {
        final filePath = fileInfo['filePath'] as String;
        fileInfo['filePath'] = (await FilePathConverter.toRelativePath(
          filePath,
        )).replaceAll('./app_data/', './');
      }
      // 更新转换后的fileInfo
      messageMetadata[Message.metadataKeyFileInfo] = fileInfo;
    }

    return {
      'id': id,
      'content': content,
      'user': user.toJson(),
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'fixedSymbol': fixedSymbol,
      'bubbleColor': bubbleColor?.toHex(),
      'metadata': messageMetadata,
    };
  }

  /// 从JSON格式创建Message实例
  static Future<Message> fromJson(
    Map<String, dynamic> json,
    List<User> users,
  ) async {
    // 从消息中直接获取完整的用户信息
    final user = User.fromJson(json['user'] as Map<String, dynamic>);

    // 获取元数据，但路径转换将在create方法中处理
    final messageMetadata =
        json['metadata'] != null
            ? Map<String, dynamic>.from(
              json['metadata'] as Map<String, dynamic>,
            )
            : null;

    return create(
      id: json['id'] as String,
      content: json['content'] as String,
      user: user,
      type: MessageType.values.firstWhere(
        (t) => t.toString().split('.').last == json['type'],
        orElse: () => MessageType.received,
      ),
      date: DateTime.parse(json['date'] as String),
      editedAt:
          json['editedAt'] != null
              ? DateTime.parse(json['editedAt'] as String)
              : null,
      fixedSymbol: json['fixedSymbol'] as String?,
      bubbleColor:
          json['bubbleColor'] != null
              ? HexColor.fromHex(json['bubbleColor'] as String)
              : null,
      metadata: messageMetadata,
    );
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
}
