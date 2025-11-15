import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/chat_message.dart';
import '../../../services/token_counter_service.dart';
import 'markdown_content.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 消息气泡组件
///
/// 极简设计，显示单条消息
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Future<void> Function(String messageId, String newContent)? onEdit;
  final Future<void> Function(String messageId)? onDelete;
  final Future<void> Function(String messageId)? onRegenerate;

  const MessageBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onDelete,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI头像
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 消息内容
                      if (message.isGenerating)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '正在生成...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      else if (message.content.isEmpty)
                        const Text(
                          '(空消息)',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        )
                      else
                        MarkdownContent(content: message.content),

                      // 附件显示
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildAttachments(),
                      ],
                    ],
                  ),
                ),

                // 底部信息栏
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Token统计
                    Text(
                      TokenCounterService.formatTokenCountShort(
                        message.tokenCount,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 时间
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),

                    // 已编辑标记
                    if (message.editedAt != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(已编辑)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // 操作按钮
                    if (!message.isGenerating) ...[
                      const SizedBox(width: 8),
                      _buildActionMenu(context),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            // 用户头像
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.green[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建附件显示
  Widget _buildAttachments() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: message.attachments.map((attachment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                attachment.isImage ? Icons.image : Icons.description,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                attachment.fileName,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                attachment.formattedSize,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建操作菜单
  Widget _buildActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: Colors.grey[600],
      ),
      onSelected: (value) {
        switch (value) {
          case 'copy':
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制到剪贴板')),
            );
            break;
          case 'edit':
            _showEditDialog(context);
            break;
          case 'delete':
            onDelete?.call(message.id);
            break;
          case 'regenerate':
            onRegenerate?.call(message.id);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('复制'),
            ],
          ),
        ),
        if (message.isUser && onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('编辑'),
              ],
            ),
          ),
        if (!message.isUser && onRegenerate != null)
          const PopupMenuItem(
            value: 'regenerate',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('重新生成'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('删除', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  /// 显示编辑对话框
  void _showEditDialog(BuildContext context) {
    final textController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: textController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '输入消息内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newContent = textController.text.trim();
              if (newContent.isNotEmpty && newContent != message.content) {
                onEdit?.call(message.id, newContent);
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 24) {
      return timeago.format(dateTime, locale: 'zh');
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
