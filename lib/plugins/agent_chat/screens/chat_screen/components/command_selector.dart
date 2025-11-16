import 'package:flutter/material.dart';
import '../../../models/chat_command.dart';

/// 命令选择器组件
///
/// 显示在输入框上方，用于选择命令
class CommandSelector extends StatelessWidget {
  final List<ChatCommand> commands;
  final Function(ChatCommand) onCommandSelected;

  const CommandSelector({
    super.key,
    required this.commands,
    required this.onCommandSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '可用命令',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 命令列表
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: commands.length,
            itemBuilder: (context, index) {
              final command = commands[index];
              return _buildCommandItem(command);
            },
          ),
        ],
      ),
    );
  }

  /// 构建命令项
  Widget _buildCommandItem(ChatCommand command) {
    return InkWell(
      onTap: () => onCommandSelected(command),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 命令图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: command.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                command.icon,
                size: 20,
                color: command.color,
              ),
            ),

            const SizedBox(width: 12),

            // 命令信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '/${command.command}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: command.color,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (command.requiresArgument) ...[
                        const SizedBox(width: 4),
                        Text(
                          '[参数]',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    command.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // 箭头图标
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
