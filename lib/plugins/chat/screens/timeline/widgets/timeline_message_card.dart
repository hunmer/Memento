import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/file_message.dart';
import 'package:Memento/plugins/chat/utils/date_formatter.dart';
import 'package:Memento/widgets/file_preview/file_preview_screen.dart';
import 'package:Memento/plugins/chat/widgets/image_message_widget.dart';
import 'package:Memento/plugins/chat/widgets/audio_player_widget.dart';
import 'package:Memento/plugins/chat/services/settings_service.dart';
import 'package:Memento/plugins/chat/screens/timeline/utils/text_highlight.dart';
import 'package:Memento/plugins/chat/screens/timeline/controllers/timeline_controller.dart';
import 'package:Memento/plugins/chat/utils/message_options_handler.dart';

/// Timeline 中显示的消息卡片组件
class TimelineMessageCard extends StatelessWidget {
  final Message message;
  final Channel channel;
  final TimelineController controller;
  final bool isGridView;
  final SettingsService? settingsService;

  const TimelineMessageCard({
    super.key,
    required this.message,
    required this.channel,
    required this.controller,
    this.isGridView = false,
    this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            onSetFixedSymbol:
                (msg, symbol) =>
                    controller.handleSetFixedSymbol(message, symbol),
            onSetBubbleColor:
                (msg, color) => controller.handleSetBubbleColor(message, color),
            onToggleFavorite: (_) => controller.handleToggleFavorite(message),
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
                  // 根据设置决定是否显示头像
                  if (settingsService?.showAvatarInTimeline ?? true) ...[
                    Container(
                      width: isGridView ? 28 : 40,
                      height: isGridView ? 28 : 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child:
                          message.user.iconPath != null
                              ? FutureBuilder<String>(
                                future: _getAbsolutePath(
                                  message.user.iconPath!,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return ClipOval(
                                      child: Image.file(
                                        File(snapshot.data!),
                                        width: isGridView ? 28 : 40,
                                        height: isGridView ? 28 : 40,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }
                                  return _buildDefaultAvatar(theme, isGridView);
                                },
                              )
                              : _buildDefaultAvatar(theme, isGridView),
                    ),
                    SizedBox(width: isGridView ? 8 : 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.user.username,
                          style:
                              isGridView
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormatter.formatDateTime(message.date, context),
                          style:
                              isGridView
                                  ? theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                  )
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
                        vertical: isGridView ? 1 : 2,
                      ),
                      margin: EdgeInsets.only(right: isGridView ? 4 : 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                        // 检查消息类型
                        if (message.metadata?[Message.metadataKeyFileInfo] !=
                            null) {
                          final fileInfo = FileMessage.fromJson(
                            Map<String, dynamic>.from(
                              message.metadata![Message.metadataKeyFileInfo],
                            ),
                          );

                          // 根据文件类型显示不同的预览
                          switch (fileInfo.type) {
                            case FileMessageType.image:
                              return GestureDetector(
                                onTap: () {
                                  NavigationHelper.push(context, FilePreviewScreen(
                                                filePath: fileInfo.filePath,
                                                fileName: fileInfo.fileName,
                                                mimeType:
                                                    fileInfo.mimeType ??
                                                    'image/jpeg',
                                                fileSize: fileInfo.fileSize,),
                                  );
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: isGridView ? 120 : 200,
                                    maxHeight: isGridView ? 120 : 200,
                                  ),
                                  child: ImageMessageWidget(
                                    message: message,
                                    isOutgoing: false,
                                  ),
                                ),
                              );

                            case FileMessageType.document:
                            case FileMessageType.audio:
                              return Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      isGridView
                                          ? constraints.maxWidth * 0.8
                                          : constraints.maxWidth,
                                ),
                                child: AudioPlayerWidget(
                                  audioPath: fileInfo.filePath,
                                  durationInSeconds: message.audioDuration,
                                  isLocalFile: true,
                                  primaryColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surface,
                                  progressColor: theme.colorScheme.primary,
                                ),
                              );

                            case FileMessageType.video:
                              return GestureDetector(
                                onTap: () {
                                  NavigationHelper.push(context, FilePreviewScreen(
                                                filePath: fileInfo.filePath,
                                                fileName: fileInfo.fileName,
                                                mimeType:
                                                    fileInfo.mimeType ??
                                                    'video/mp4',
                                                fileSize: fileInfo.fileSize,),
                                  );
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: isGridView ? 120 : 200,
                                    maxHeight: isGridView ? 120 : 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.video_library,
                                        size: isGridView ? 32 : 48,
                                        color: theme.colorScheme.primary,
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Text(
                                          fileInfo.originalFileName,
                                          style: TextStyle(
                                            fontSize: isGridView ? 10 : 12,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                            default: // 文档和其他类型文件
                              return GestureDetector(
                                onTap: () {
                                  NavigationHelper.push(context, FilePreviewScreen(
                                                filePath: fileInfo.filePath,
                                                fileName: fileInfo.fileName,
                                                mimeType:
                                                    fileInfo.mimeType ??
                                                    'application/octet-stream',
                                                fileSize: fileInfo.fileSize,),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      fileInfo.getIcon(),
                                      size: isGridView ? 16 : 24,
                                      color: theme.colorScheme.primary,
                                    ),
                                    SizedBox(width: isGridView ? 4 : 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            fileInfo.originalFileName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: isGridView ? 12 : 14,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            fileInfo.formattedSize,
                                            style: TextStyle(
                                              fontSize: isGridView ? 10 : 12,
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                          }
                        }
                        return RichText(
                          maxLines:
                              isGridView ? 12 : null, // 增加最大行数，但仍保持一定限制以避免过长
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: TextHighlight.highlightText(
                              text: message.content,
                              query: controller.searchQuery,
                              style:
                                  isGridView
                                      ? theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: 13,
                                            height: 1.3, // 调整行高使文本更紧凑
                                          ) ??
                                          const TextStyle(
                                            fontSize: 13,
                                            height: 1.3,
                                          )
                                      : theme.textTheme.bodyLarge ??
                                          const TextStyle(),
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
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: isGridView ? 10 : null,
                            ) ??
                            const TextStyle(),
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

  Widget _buildDefaultAvatar(ThemeData theme, bool isGridView) {
    return Center(
      child: Text(
        message.user.username.isNotEmpty
            ? message.user.username[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: isGridView ? 12 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<String> _getAbsolutePath(String relativePath) async {
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    return path.join(
      appDir.path,
      'app_data',
      relativePath.replaceFirst('./', ''),
    );
  }
}
