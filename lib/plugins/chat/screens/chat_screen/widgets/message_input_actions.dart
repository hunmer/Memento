import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../../widgets/markdown_editor/index.dart';
import '../../../services/file_service.dart';
import '../../../models/file_message.dart';
import '../../../models/message.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

class MessageInputAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  MessageInputAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

typedef OnFileSelected = void Function(FileMessage fileMessage);
typedef OnSendMessage =
    void Function(
      String content, {
      Map<String, dynamic>? metadata,
      MessageType? type,
    });

class MessageInputActionsDrawer extends StatelessWidget {
  final List<MessageInputAction> actions;
  final OnFileSelected? onFileSelected;
  final OnSendMessage? onSendMessage;

  const MessageInputActionsDrawer({
    super.key,
    required this.actions,
    this.onFileSelected,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        top: 16.0 + MediaQuery.of(context).padding.top,
        bottom: 16.0 + MediaQuery.of(context).padding.bottom,
        left: 16.0,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择操作',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 24.0,
              ),
              itemCount: actions.length,
              itemBuilder:
                  (context, index) => _buildActionItem(context, actions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, MessageInputAction action) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // 关闭抽屉
        action.onTap();
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Icon(
              action.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            action.title,
            style: TextStyle(
              fontSize: 14.0,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 预定义的操作列表
List<MessageInputAction> getDefaultMessageInputActions(
  BuildContext context, {
  OnFileSelected? onFileSelected,
  OnSendMessage? onSendMessage,
}) {
  // 创建FileService实例
  final fileService = FileService();
  final logger = Logger('MessageInputActions');
  return [
    MessageInputAction(
      title: '高级编辑',
      icon: Icons.text_fields,
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: MarkdownEditor(
                    showTitle: false,
                    contentHint: '在此输入消息内容...',
                    showPreviewButton: true,
                    onSave: (_, content) {
                      if (content.isNotEmpty) {
                        // 发送消息
                        onSendMessage?.call(content, type: MessageType.sent);
                      }
                      Navigator.of(context).pop();
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
        );
      },
    ),
    MessageInputAction(
      title: '文件',
      icon: Icons.attach_file,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        final fileMessage = await fileService.pickFile();
        if (fileMessage != null) {
          // 调用回调函数发送文件消息
          onFileSelected?.call(fileMessage);

          // 如果提供了onSendMessage回调，创建文件类型的消息
          if (onSendMessage != null) {
            // 创建文件消息内容
            final fileContent =
                '📎 ${fileMessage.fileName} (${fileMessage.formattedSize})';

            // 创建文件元数据
            final fileMetadata = {
              Message.metadataKeyFileInfo: {
                'id': fileMessage.id,
                'fileName': fileMessage.fileName,
                'filePath': fileMessage.filePath,
                'fileSize': fileMessage.fileSize,
                'extension': fileMessage.extension,
                'mimeType': fileMessage.mimeType,
              },
            };

            // 发送文件消息
            onSendMessage(
              fileContent,
              metadata: fileMetadata,
              type: MessageType.file,
            );
          }

          // 显示文件选择成功的提示
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('已发送文件: ${fileMessage.fileName}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
    MessageInputAction(
      title: '图片',
      icon: Icons.image,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          // 使用ImagePicker选择图片
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80, // 图片质量
          );

          if (image != null) {
            // 将图片转换为文件
            final File imageFile = File(image.path);

            // 保存图片到应用目录
            final savedFile = await fileService.saveImage(imageFile);
            final fileMessage = await FileMessage.fromFile(savedFile);
            // 调用回调函数发送图片消息
            onFileSelected?.call(fileMessage);

            // 如果提供了onSendMessage回调，创建图片类型的消息
            if (onSendMessage != null) {
              // 创建图片占位内容，不包含实际路径
              final fileContent = '[图片] ${fileMessage.fileName}';

              // 创建图片元数据
              final fileMetadata = {
                Message.metadataKeyFileInfo: {
                  'id': fileMessage.id,
                  'fileName': fileMessage.fileName,
                  'filePath': fileMessage.filePath, // 存储相对路径
                  'fileSize': fileMessage.fileSize,
                  'extension': fileMessage.extension,
                  'mimeType':
                      'image/${fileMessage.extension.replaceAll('.', '')}',
                  'isImage': true,
                },
              };

              // 发送图片消息，类型为image
              onSendMessage(
                fileContent,
                metadata: fileMetadata,
                type: MessageType.image,
              );
            }

            // 显示图片选择成功的提示
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('已发送图片: ${path.basename(image.path)}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('选择图片失败: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
    MessageInputAction(
      title: '视频',
      icon: Icons.videocam,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          // 使用ImagePicker选择视频
          final ImagePicker picker = ImagePicker();
          final XFile? video = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10), // 限制视频长度
          );

          if (video != null) {
            // 将视频转换为文件
            final File videoFile = File(video.path);

            // 保存视频到应用目录
            final savedFile = await fileService.saveVideo(videoFile);
            final fileMessage = await FileMessage.fromFile(savedFile);
            logger.info('保存视频文件: ${savedFile.path}');
            // 调用回调函数发送视频消息
            onFileSelected?.call(fileMessage);

            // 如果提供了onSendMessage回调，创建视频类型的消息
            if (onSendMessage != null) {
              // 尝试获取视频封面
              String? thumbnailPath;
              // try {
              //   thumbnailPath = await fileService.getVideoThumbnail(
              //     savedFile.path,
              //   );
              // } catch (e) {
              //   logger.warning('获取视频封面失败: $e');
              //   // 如果获取封面失败，使用默认视频图标
              //   thumbnailPath = null;
              // }

              // 创建Markdown格式的视频消息内容
              String fileContent;
              if (thumbnailPath != null) {
                // 如果有封面，使用封面图片
                fileContent =
                    '[![${fileMessage.fileName}](${thumbnailPath} "${fileMessage.fileName} - 点击播放")](${fileMessage.filePath})';
              } else {
                // 如果没有封面，使用纯文本格式
                fileContent =
                    '🎥 ${fileMessage.fileName} (${fileMessage.formattedSize})';
              }

              // 创建视频元数据，包含封面路径（如果有的话）
              final Map<String, dynamic> fileInfo = {
                'id': fileMessage.id,
                'fileName': fileMessage.fileName,
                'filePath': fileMessage.filePath,
                'fileSize': fileMessage.fileSize,
                'extension': fileMessage.extension,
                'mimeType':
                    'video/${fileMessage.extension.replaceAll('.', '')}',
                'isVideo': true,
              };

              // 只有在成功生成缩略图的情况下才添加缩略图路径
              if (thumbnailPath != null) {
                fileInfo['thumbnailPath'] = thumbnailPath;
              }

              final fileMetadata = {Message.metadataKeyFileInfo: fileInfo};

              // 发送视频消息
              onSendMessage(
                fileContent,
                metadata: fileMetadata,
                type: MessageType.video,
              );
            }

            // 显示视频选择成功的提示
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('已发送视频: ${path.basename(video.path)}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('选择视频失败: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
  ];
}
