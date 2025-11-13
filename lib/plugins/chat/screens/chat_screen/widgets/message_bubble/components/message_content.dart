import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/widgets/quill_viewer/index.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../../../../../../plugins/chat/models/message.dart';
import '../../../../../../../plugins/chat/widgets/image_message_widget.dart';
import '../../../../../../../widgets/file_preview/index.dart';
import '../../audio_message_bubble.dart';
import '../../../../../../../widgets/file_preview/file_preview_screen.dart';
import 'thinking_indicator.dart';

class MessageContent extends StatelessWidget {
  final Message message;
  final Color textColor;

  const MessageContent({
    super.key,
    required this.message,
    required this.textColor,
  });

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
      final fileName = fileInfo['name'] as String? ?? '未命名文件';
      final mimeType = fileInfo['mimeType'] as String? ?? 'application/octet-stream';
      final fileSize = fileInfo['size'] as int? ?? 0;
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) => FilePreviewScreen(
                    filePath: filePath,
                    fileName: fileName,
                    mimeType: mimeType,
                    fileSize: fileSize,
                  ),
                ),
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
                            color:  Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext ctx) => FilePreviewScreen(
                    filePath: filePath,
                    fileName: fileName,
                    mimeType: mimeType,
                    fileSize: fileSize,
                  ),
                ),
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
                      color: iconColor.withOpacity(0.1),
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
      return QuillViewer(
        data: message.content,
        selectable: true,
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
          code: TextStyle(
            backgroundColor: Colors.grey[200],
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
          inlineCode: quill.InlineCodeStyle(
            backgroundColor: Colors.grey[200],
            style: const TextStyle(
              color: Colors.black87,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }
  }
}