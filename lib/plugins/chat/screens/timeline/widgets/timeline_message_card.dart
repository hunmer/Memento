import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/message.dart';
import '../../../models/channel.dart';
import '../../../utils/date_formatter.dart';
import '../utils/text_highlight.dart';
import '../controllers/timeline_controller.dart';
import '../../../utils/message_options_handler.dart';
import '../../../models/file_message.dart';

/// Timeline 中显示的消息卡片组件
class TimelineMessageCard extends StatelessWidget {
  final Message message;
  final Channel channel;
  final TimelineController controller;
  final bool isGridView;

  const TimelineMessageCard({
    super.key,
    required this.message,
    required this.channel,
    required this.controller,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormatter = DateFormatter();
    final cardColor = message.bubbleColor;
    
    // 根据视图模式调整卡片样式
    return Card(
      elevation: isGridView ? 2 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isGridView ? 12 : 8),
      ),
      margin: EdgeInsets.zero, // 移除卡片默认边距，使用外部padding控制间距
      child: InkWell(
        onLongPress: () {
          MessageOptionsHandler.showOptionsDialog(
            context: context,
            message: message,
            onMessageEdit: (_) => controller.handleMessageEdit(message),
            onMessageDelete: (_) => controller.handleMessageDelete(message),
            onMessageCopy: (_) => controller.handleMessageCopy(message),
            onSetFixedSymbol: (msg, symbol) => controller.handleSetFixedSymbol(message, symbol),
            onSetBubbleColor: (msg, color) => controller.handleSetBubbleColor(message, color),
          );
        },
        onTap: () async {
          // 导航到频道页面并定位到消息
          await Navigator.pushNamed(
            context,
            '/channel/${channel.id}',
            arguments: {
              'channel': channel,
              'initialMessage': message, // 用于初始滚动定位
              'highlightMessage': message, // 用于高亮显示
              'autoScroll': true, // 明确指示需要自动滚动
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isGridView ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 头像和用户名
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  radius: isGridView ? 14 : 20,
                  child: Text(
                    message.user.username[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: isGridView ? 12 : 16,
                    ),
                  ),
                ),
                SizedBox(width: isGridView ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.user.username,
                        style: isGridView 
                            ? theme.textTheme.titleSmall 
                            : theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormatter.formatDateTime(message.date, context),
                        style: isGridView 
                            ? theme.textTheme.bodySmall?.copyWith(fontSize: 10) 
                            : theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isGridView ? 8 : 12),
            
            // 消息内容（带高亮）和固定字符
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 显示固定字符（如果有）
                if (message.fixedSymbol != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isGridView ? 4 : 6, 
                      vertical: isGridView ? 1 : 2
                    ),
                    margin: EdgeInsets.only(right: isGridView ? 4 : 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      message.fixedSymbol!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: isGridView ? 10 : 12,
                      ),
                    ),
                  ),
                ],
                
                // 消息内容
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RichText(
                        maxLines: isGridView ? 12 : null, // 增加最大行数，但仍保持一定限制以避免过长
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: TextHighlight.highlightText(
                            text: message.content,
                            query: controller.searchQuery,
                            style: isGridView
                                ? theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    height: 1.3, // 调整行高使文本更紧凑
                                  ) ?? const TextStyle(fontSize: 13, height: 1.3)
                                : theme.textTheme.bodyLarge ?? const TextStyle(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isGridView ? 8 : 12),
            
            // 频道信息
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: isGridView ? 12 : 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: isGridView ? 2 : 4),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: TextHighlight.highlightText(
                      text: channel.title,
                      query: controller.searchQuery,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: isGridView ? 10 : null,
                      ) ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}