import 'package:flutter/material.dart';
import '../../../../models/file_message.dart';
import '../../../../models/message.dart';

/// 消息输入动作的基础类
class MessageInputAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  MessageInputAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// 文件选择回调
typedef OnFileSelected = void Function(FileMessage fileMessage);

/// 发送消息回调
typedef OnSendMessage = void Function(
  String content, {
  Map<String, dynamic>? metadata,
  String type,
  Message? replyTo,
});