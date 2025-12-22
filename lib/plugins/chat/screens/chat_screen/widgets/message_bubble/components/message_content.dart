import 'dart:convert';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/quill_viewer/index.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/widgets/image_message_widget.dart';
import 'package:Memento/widgets/file_preview/index.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/audio_message_bubble.dart';
import 'package:Memento/widgets/file_preview/file_preview_screen.dart';
import 'thinking_indicator.dart';

class MessageContent extends StatelessWidget {
  final Message message;
  final Color textColor;

  const MessageContent({
    super.key,
    required this.message,
    required this.textColor,
  });

  /// 判断内容是否为纯文本（没有任何 Quill 格式）
  bool _isPlainText(String content) {
    if (content.isEmpty) return true;

    try {
      // 尝试解析为 JSON
      final json = jsonDecode(content);

      // 检查是否为 Quill Delta 格式
      if (json is! List) return true;

      // 遍历所有操作
      for (var op in json) {
        if (op is! Map<String, dynamic>) continue;

        // 检查是否有格式属性
        if (op.containsKey('attributes')) {
          final attributes = op['attributes'];
          if (attributes != null && attributes is Map && attributes.isNotEmpty) {
            return false; // 包含格式属性，不是纯文本
          }
        }

        // 检查 insert 的内容类型
        if (op.containsKey('insert')) {
          final insert = op['insert'];
          // 如果 insert 是 Map（如嵌入的图片、视频等），不是纯文本
          if (insert is Map) {
            return false;
          }
        }
      }

      return true; // 没有任何格式属性，是纯文本
    } catch (e) {
      // JSON 解析失败，说明是纯文本
      return true;
    }
  }

  /// 从 Quill Delta 格式中提取纯文本内容
  String _extractPlainText(String content) {
    try {
      final json = jsonDecode(content);
      if (json is! List) return content;

      final buffer = StringBuffer();
      for (var op in json) {
        if (op is Map<String, dynamic> && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }

      return buffer.toString();
    } catch (e) {
      return content;
    }
  }

  /// 打开链接
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 检测文本是否包含 Markdown 语法
  bool _containsMarkdown(String text) {
    // 常见 Markdown 语法的正则表达式
    final patterns = [
      RegExp(r'^#{1,6}\s', multiLine: true),          // 标题: # ## ###
      RegExp(r'\*\*[^*]+\*\*'),                        // 粗体: **text**
      RegExp(r'__[^_]+__'),                            // 粗体: __text__
      RegExp(r'(?<!\*)\*(?!\*)[^*]+\*(?!\*)'),        // 斜体: *text*
      RegExp(r'(?<!_)_(?!_)[^_]+_(?!_)'),             // 斜体: _text_
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),             // 链接: [text](url)
      RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'),            // 图片: ![alt](url)
      RegExp(r'`[^`]+`'),                              // 行内代码: `code`
      RegExp(r'```[\s\S]*?```', multiLine: true),     // 代码块: ```code```
      RegExp(r'^>\s', multiLine: true),               // 引用: > text
      RegExp(r'^[-*+]\s', multiLine: true),           // 无序列表: - * +
      RegExp(r'^\d+\.\s', multiLine: true),           // 有序列表: 1. 2.
      RegExp(r'^---+$', multiLine: true),             // 水平线: ---
      RegExp(r'^\*\*\*+$', multiLine: true),          // 水平线: ***
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 检查消息是否处于"正在思考"状态
    final bool isThinking = message.metadata?.containsKey('isThinking') == true && 
                          message.metadata!['isThinking'] == true;
    
    if (isThinking) {
      return ThinkingIndicator(textColor: textColor);
    }
    
    // 检查消息是否包含文件信息
    if (message.metadata?.containsKey(Message.metadataKeyFileInfo) == true) {
      final fileInfo = message.metadata![Message.metadataKeyFileInfo] as Map<String, dynamic>;
      final filePath = fileInfo['path'] as String?;
      if (filePath == null) {
        return Text(
          '文件路径无效',
          style: TextStyle(color: Colors.red, fontSize: 13),
        );
      }
      final fileName = fileInfo['fileName'] as String? ?? fileInfo['name'] as String? ?? '未命名文件';
      final mimeType = fileInfo['mimeType'] as String? ?? 'application/octet-stream';
      final fileSize = fileInfo['fileSize'] as int? ?? fileInfo['size'] as int? ?? 0;
      final type = fileInfo['type'] as String? ?? '';

      if (type == 'image') {
        return ImageMessageWidget(
          message: message,
          isOutgoing: message.type == MessageType.sent,
        );
      } else if (type == 'audio') {
        return AudioMessageBubble(
          message: message,
          isCurrentUser: message.type == MessageType.sent,
        );
      } else if (type == 'video') {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              NavigationHelper.push(context, FilePreviewScreen(
                    filePath: filePath,
                    fileName: fileName,
                    mimeType: mimeType,
                    fileSize: fileSize,),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.videocam,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              fileName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(fileSize / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (type == 'document' || type == 'file') {
        // 确定文件图标和颜色
        IconData fileIcon;
        Color iconColor;
        
        if (mimeType.contains('pdf')) {
          fileIcon = Icons.picture_as_pdf;
          iconColor = Colors.red.shade700;
        } else if (mimeType.contains('word') || mimeType.contains('document')) {
          fileIcon = Icons.description;
          iconColor = Colors.blue.shade700;
        } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
          fileIcon = Icons.table_chart;
          iconColor = Colors.green.shade700;
        } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
          fileIcon = Icons.slideshow;
          iconColor = Colors.orange.shade700;
        } else if (mimeType.contains('zip') || mimeType.contains('compressed')) {
          fileIcon = Icons.folder_zip;
          iconColor = Colors.amber.shade700;
        } else {
          fileIcon = Icons.insert_drive_file;
          iconColor = Theme.of(context).colorScheme.primary;
        }
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              NavigationHelper.push(context, FilePreviewScreen(
                    filePath: filePath,
                    fileName: fileName,
                    mimeType: mimeType,
                    fileSize: fileSize,),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        fileIcon,
                        size: 24,
                        color: iconColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${(fileSize / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ]
              ),
            ),
          ),
        );
      } else {
        return FutureBuilder<String>(
          future: ImageUtils.getAbsolutePath(filePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilePreviewScreen(
                    filePath: snapshot.data!,
                    fileName: fileName,
                    mimeType: mimeType,
                    fileSize: fileSize,
                  ),
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(message.content),
                    ),
                ],
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      }
    } else {
      // 普通文本消息
      // 判断是否为纯文本（无 Quill 格式）
      if (_isPlainText(message.content)) {
        final plainText = _extractPlainText(message.content);

        // 检测是否包含 Markdown 语法
        if (_containsMarkdown(plainText)) {
          // 包含 Markdown，使用 MarkdownBody 渲染
          return MarkdownBody(
            data: plainText,
            selectable: false,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: textColor, fontSize: 15, height: 1.5),
              code: TextStyle(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: textColor,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              codeblockPadding: const EdgeInsets.all(12),
              blockquote: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 4,
                  ),
                ),
              ),
              blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              h1: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
              h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              h3: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              listBullet: TextStyle(color: textColor, fontSize: 15),
              a: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
              strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                _launchURL(href);
              }
            },
          );
        } else {
          // 纯文本，使用 Text 显示（保留换行符）
          return Text(
            plainText,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
          );
        }
      } else {
        // 包含 Quill 格式，使用 QuillViewer 显示（禁用选择功能以避免与长按菜单冲突）
        return QuillViewer(
          data: message.content,
          selectable: false,
          customStyles: quill.DefaultStyles(
            paragraph: quill.DefaultTextBlockStyle(
              TextStyle(color: textColor),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h1: quill.DefaultTextBlockStyle(
              TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(8, 4),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h2: quill.DefaultTextBlockStyle(
              TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(6, 4),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            h3: quill.DefaultTextBlockStyle(
              TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(4, 4),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            code: quill.DefaultTextBlockStyle(
              TextStyle(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'monospace',
              ),
              const quill.HorizontalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              const quill.VerticalSpacing(0, 0),
              null,
            ),
            inlineCode: quill.InlineCodeStyle(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      }
    }
  }
}