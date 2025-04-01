import 'package:flutter/material.dart';
import 'message.dart';
import 'user.dart';

class Channel {
  final String id;
  String title;
  IconData icon;
  Color backgroundColor; // 图标背景颜色
  final List<User> members;
  final List<Message> messages;
  int priority;
  final DateTime lastMessageTime;
  List<String> groups; // 频道所属的组，可以属于多个组
  String? fixedSymbol; // 频道的固定符号

  Channel({
    required this.id,
    required this.title,
    required this.icon,
    this.backgroundColor = Colors.blue, // 默认蓝色背景
    required this.members,
    required this.messages,
    this.priority = 0,
    this.groups = const [], // 默认为空列表，表示不属于任何组
    this.fixedSymbol,
  }) : lastMessageTime =
           messages.isNotEmpty ? messages.last.date : DateTime.now();

  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

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
    List<User>? members,
    List<Message>? messages,
    int? priority,
    List<String>? groups,
    String? fixedSymbol,
  }) {
    return Channel(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      members: members ?? this.members,
      messages: messages ?? this.messages,
      priority: priority ?? this.priority,
      groups: groups ?? this.groups,
      fixedSymbol: fixedSymbol ?? this.fixedSymbol,
    );
  }
}
