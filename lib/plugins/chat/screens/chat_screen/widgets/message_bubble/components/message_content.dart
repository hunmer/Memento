import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../../../plugins/chat/models/message.dart';
import '../../../../../../../plugins/chat/models/file_message.dart';
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
      final filePath = fileInfo['filePath'] as String;
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
      return MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: textColor),
          h1: TextStyle(color: textColor),
          h2: TextStyle(color: textColor),
          h3: TextStyle(color: textColor),
          h4: TextStyle(color: textColor),
          h5: TextStyle(color: textColor),
          h6: TextStyle(color: textColor),
          em: TextStyle(color: textColor),
          strong: TextStyle(color: textColor),
          code: TextStyle(
            backgroundColor: Colors.grey[200],
            color: Colors.black87,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }
  }
}