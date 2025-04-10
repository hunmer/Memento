import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../../models/channel.dart';
import '../../../utils/date_formatter.dart';
import '../utils/text_highlight.dart';
import '../controllers/timeline_controller.dart';

/// Timeline 中显示的消息卡片组件
class TimelineMessageCard extends StatelessWidget {
  final Message message;
  final Channel channel;
  final TimelineController controller;

  const TimelineMessageCard({
    super.key,
    required this.message,
    required this.channel,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormatter = DateFormatter();
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像和用户名
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    message.user.username[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.user.username,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        DateFormatter.formatDateTime(message.date, context),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 消息内容（带高亮）
            RichText(
              text: TextSpan(
                children: TextHighlight.highlightText(
                  text: message.content,
                  query: controller.searchQuery,
                  style: theme.textTheme.bodyLarge ?? const TextStyle(),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 频道信息
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    children: TextHighlight.highlightText(
                      text: channel.title,
                      query: controller.searchQuery,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ) ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}