import 'package:flutter/material.dart';

/// 聊天命令类型
enum ChatCommandType {
  files,  // /files - 添加附件
  tools,  // /tools [名称] - 执行已保存的工具
}

/// 聊天命令
class ChatCommand {
  /// 命令类型
  final ChatCommandType type;

  /// 命令文本（不含斜杠）
  final String command;

  /// 命令显示名称
  final String displayName;

  /// 命令描述
  final String description;

  /// 命令图标
  final IconData icon;

  /// 命令颜色
  final Color color;

  /// 是否需要参数
  final bool requiresArgument;

  const ChatCommand({
    required this.type,
    required this.command,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
    this.requiresArgument = false,
  });

  /// 获取所有可用命令
  static List<ChatCommand> get allCommands => [
        const ChatCommand(
          type: ChatCommandType.files,
          command: 'files',
          displayName: '添加附件',
          description: '选择图片或文档添加到消息中',
          icon: Icons.attach_file,
          color: Colors.blue,
        ),
        const ChatCommand(
          type: ChatCommandType.tools,
          command: 'tools',
          displayName: '执行工具',
          description: '执行已保存的工具模板',
          icon: Icons.build,
          color: Colors.orange,
          requiresArgument: true,
        ),
      ];

  /// 根据输入文本过滤命令
  static List<ChatCommand> filterCommands(String input) {
    // 移除开头的 /
    final cleanInput = input.startsWith('/') ? input.substring(1) : input;

    if (cleanInput.isEmpty) {
      return allCommands;
    }

    return allCommands.where((cmd) {
      return cmd.command.toLowerCase().startsWith(cleanInput.toLowerCase()) ||
          cmd.displayName.toLowerCase().contains(cleanInput.toLowerCase());
    }).toList();
  }

  /// 解析命令输入
  /// 返回：(命令类型, 参数)
  static (ChatCommandType?, String?) parseInput(String input) {
    if (!input.startsWith('/')) {
      return (null, null);
    }

    final cleanInput = input.substring(1);
    final parts = cleanInput.split(' ');

    if (parts.isEmpty) {
      return (null, null);
    }

    final commandText = parts[0].toLowerCase();
    final argument = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    for (var cmd in allCommands) {
      if (cmd.command == commandText) {
        return (cmd.type, argument);
      }
    }

    return (null, null);
  }
}
