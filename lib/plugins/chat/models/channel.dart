import 'package:flutter/material.dart';
import '../../../utils/color_extension.dart';
import 'message.dart';

class Channel {
  final String id;
  String title;
  IconData icon;
  Color backgroundColor; // 图标背景颜色
  final List<Message> messages;
  int priority;
  final DateTime lastMessageTime;
  List<String> groups; // 频道所属的组，可以属于多个组
  String? fixedSymbol; // 频道的固定符号
  String? draft; // 频道的草稿内容
  String? backgroundPath; // 频道背景图片路径
  Message? _lastMessage; // 最后一条消息的缓存
  Map<String, dynamic>? metadata; // 存储频道的元数据，如上下文范围和最后选择的智能体

  Channel({
    required this.id,
    required this.title,
    required this.icon,
    this.backgroundColor = Colors.blue, // 默认蓝色背景
    required this.messages,
    this.priority = 0,
    this.groups = const [], // 默认为空列表，表示不属于任何组
    this.fixedSymbol,
    this.draft,
    this.backgroundPath,
    Message? lastMessage,
    this.metadata,
  }) : lastMessageTime =
           messages.isNotEmpty ? messages.last.date : DateTime.now() {
    _lastMessage = lastMessage ?? (messages.isNotEmpty ? messages.last : null);
  }

  Message? get lastMessage =>
      _lastMessage ?? (messages.isNotEmpty ? messages.last : null);

  set lastMessage(Message? message) {
    _lastMessage = message;
  }

  // 用于排序的比较器
  static int compare(Channel a, Channel b) {
    // 首先按优先级排序
    if (a.priority != b.priority) {
      return b.priority.compareTo(a.priority);
    }
    // 然后按最后消息时间排序
    return b.lastMessageTime.compareTo(a.lastMessageTime);
  }

  // 创建一个新的Channel实例，但可以更改某些属性
  Channel copyWith({
    String? title,
    IconData? icon,
    Color? backgroundColor,
    List<Message>? messages,
    int? priority,
    List<String>? groups,
    String? fixedSymbol,
    String? draft,
    String? backgroundPath,
    Message? lastMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Channel(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      messages: messages ?? this.messages,
      priority: priority ?? this.priority,
      groups: groups ?? this.groups,
      fixedSymbol: fixedSymbol ?? this.fixedSymbol,
      draft: draft ?? this.draft,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      lastMessage: lastMessage ?? _lastMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 将频道转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'draft': draft,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'backgroundColor': backgroundColor.toHex(),
      'priority': priority,
      'groups': groups,
      'fixedSymbol': fixedSymbol,
      'backgroundPath': backgroundPath,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 从JSON格式创建Channel实例
  static Channel fromJson(
    Map<String, dynamic> json, {
    List<Message> messages = const [],
  }) {

    // 解析图标
    final IconData icon = IconData(
      json['icon'] as int,
      fontFamily: json['iconFontFamily'] as String?,
      fontPackage: json['iconFontPackage'] as String?,
    );

    // 解析背景颜色
    final Color backgroundColor =
        json['backgroundColor'] != null
            ? HexColor.fromHex(json['backgroundColor'] as String)
            : Colors.blue;

    return Channel(
      id: json['id'] as String,
      title: json['title'] as String,
      draft: json['draft'] as String?,
      icon: icon,
      backgroundColor: backgroundColor,
      messages: messages,
      priority: json['priority'] as int? ?? 0,
      groups:
          json['groups'] != null
              ? List<String>.from(json['groups'] as List<dynamic>)
              : const [],
      fixedSymbol: json['fixedSymbol'] as String?,
      backgroundPath: json['backgroundPath'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
