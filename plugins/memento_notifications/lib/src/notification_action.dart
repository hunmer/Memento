import 'package:flutter/material.dart';

/// 按钮动作类型
enum MementoButtonActionType {
  /// 默认动作
  defaultAction,

  /// 静默动作（不打开应用）
  silentAction,

  /// 静默后台动作
  silentBackgroundAction,

  /// 保持通知可见
  keepOnTop,

  /// 禁用动作
  disabledAction,

  /// 关闭通知
  dismissAction,

  /// 输入字段动作
  inputField,
}

/// 通知按钮
class MementoNotificationButton {
  /// 按钮唯一标识
  final String key;

  /// 按钮标签
  final String label;

  /// 按钮动作类型
  final MementoButtonActionType actionType;

  /// 按钮颜色
  final Color? color;

  /// 是否启用
  final bool enabled;

  /// 自动关闭通知
  final bool autoDismissible;

  /// 是否需要输入字段
  final bool requireInputText;

  const MementoNotificationButton({
    required this.key,
    required this.label,
    this.actionType = MementoButtonActionType.defaultAction,
    this.color,
    this.enabled = true,
    this.autoDismissible = true,
    this.requireInputText = false,
  });
}

/// 接收到的通知动作
class MementoReceivedAction {
  /// 通知 ID
  final int? id;

  /// 按钮标识
  final String? buttonKeyPressed;

  /// 输入的文本（如果有）
  final String? buttonKeyInput;

  /// 自定义数据
  final Map<String, String?>? payload;

  /// 通道标识
  final String? channelKey;

  /// 通知标题
  final String? title;

  /// 通知正文
  final String? body;

  const MementoReceivedAction({
    this.id,
    this.buttonKeyPressed,
    this.buttonKeyInput,
    this.payload,
    this.channelKey,
    this.title,
    this.body,
  });
}
