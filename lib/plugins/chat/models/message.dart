import 'user.dart';

enum MessageType { received, sent, file, image, video }

class Message {
  static const String metadataKeyFileInfo = 'fileInfo';

  final String id;
  String content; // 改为非final以支持编辑
  final User user;
  final DateTime date;
  final MessageType type;
  DateTime? editedAt; // 添加编辑时间字段
  String? fixedSymbol; // 添加固定符号字段
  Map<String, dynamic>? metadata; // 添加元数据字段，用于存储额外信息

  Message({
    required this.id,
    required this.content,
    required this.user,
    required this.type,
    DateTime? date,
    this.editedAt,
    this.fixedSymbol,
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
}
