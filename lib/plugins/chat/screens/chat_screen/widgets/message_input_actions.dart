import 'package:flutter/material.dart';
import 'dart:io';
import '../../../services/file_service.dart';
import '../../../models/file_message.dart';
import '../../../models/message.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

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
typedef OnSendMessage = void Function(String content, {Map<String, dynamic>? metadata, MessageType? type});

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
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
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
              itemBuilder: (context, index) => _buildActionItem(context, actions[index]),
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
              color: Theme.of(context).brightness == Brightness.dark
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
              color: Theme.of(context).brightness == Brightness.dark
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
  return [
    MessageInputAction(
      title: '文本样式',
      icon: Icons.text_fields,
      onTap: () {
        // 文本样式功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文本样式功能待实现')),
        );
      },
    ),
    MessageInputAction(
      title: '文件',
      icon: Icons.attach_file,
      onTap: () async {
        BuildContext? currentContext = context;
        
        final fileMessage = await FileService.pickFile();
        if (fileMessage != null && currentContext.mounted) {
          // 调用回调函数发送文件消息
          onFileSelected?.call(fileMessage);
          
          // 如果提供了onSendMessage回调，创建文件类型的消息
          if (onSendMessage != null) {
            // 创建文件消息内容
            final fileContent = '📎 ${fileMessage.fileName} (${fileMessage.formattedSize})';
            
            // 创建文件元数据
            final fileMetadata = {
              Message.metadataKeyFileInfo: {
                'id': fileMessage.id,
                'fileName': fileMessage.fileName,
                'filePath': fileMessage.filePath,
                'fileSize': fileMessage.fileSize,
                'extension': fileMessage.extension,
                'mimeType': fileMessage.mimeType,
              }
            };
            
            // 发送文件消息
            onSendMessage(fileContent, metadata: fileMetadata, type: MessageType.file);
          }
          
          // 显示文件选择成功的提示
          final messenger = ScaffoldMessenger.of(currentContext);
          if (messenger.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('已发送文件: ${fileMessage.fileName}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    ),
    MessageInputAction(
      title: '图片',
      icon: Icons.image,
      onTap: () async {
        BuildContext? currentContext = context;
        
        try {
          // 使用ImagePicker选择图片
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80, // 图片质量
          );
          
          if (image != null && currentContext.mounted) {
            // 将图片转换为文件
            final File imageFile = File(image.path);
            
            // 保存图片到应用目录
            final savedFile = await FileService.saveImage(imageFile);
            final fileMessage = await FileMessage.fromFile(savedFile);
            
            // 调用回调函数发送图片消息
            onFileSelected?.call(fileMessage);
            
            // 如果提供了onSendMessage回调，创建图片类型的消息
            if (onSendMessage != null) {
              // 创建图片消息内容
              final fileContent = '🖼️ 图片: ${fileMessage.fileName}';
              
              // 创建图片元数据
              final fileMetadata = {
                Message.metadataKeyFileInfo: {
                  'id': fileMessage.id,
                  'fileName': fileMessage.fileName,
                  'filePath': fileMessage.filePath,
                  'fileSize': fileMessage.fileSize,
                  'extension': fileMessage.extension,
                  'mimeType': 'image/${fileMessage.extension.replaceAll('.', '')}',
                  'isImage': true,
                }
              };
              
              // 发送图片消息
              onSendMessage(fileContent, metadata: fileMetadata, type: MessageType.image);
            }
            
            // 显示图片选择成功的提示
            if (currentContext.mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text('已发送图片: ${path.basename(image.path)}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text('选择图片失败: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    ),
    MessageInputAction(
      title: '视频',
      icon: Icons.videocam,
      onTap: () async {
        BuildContext? currentContext = context;
        
        try {
          // 使用ImagePicker选择视频
          final ImagePicker picker = ImagePicker();
          final XFile? video = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10), // 限制视频长度
          );
          
          if (video != null && currentContext.mounted) {
            // 将视频转换为文件
            final File videoFile = File(video.path);
            
            // 保存视频到应用目录
            final savedFile = await FileService.saveVideo(videoFile);
            final fileMessage = await FileMessage.fromFile(savedFile);
            
            // 调用回调函数发送视频消息
            onFileSelected?.call(fileMessage);
            
            // 如果提供了onSendMessage回调，创建视频类型的消息
            if (onSendMessage != null) {
              // 创建视频消息内容
              final fileContent = '🎬 视频: ${fileMessage.fileName} (${fileMessage.formattedSize})';
              
              // 创建视频元数据
              final fileMetadata = {
                Message.metadataKeyFileInfo: {
                  'id': fileMessage.id,
                  'fileName': fileMessage.fileName,
                  'filePath': fileMessage.filePath,
                  'fileSize': fileMessage.fileSize,
                  'extension': fileMessage.extension,
                  'mimeType': 'video/${fileMessage.extension.replaceAll('.', '')}',
                  'isVideo': true,
                }
              };
              
              // 发送视频消息
              onSendMessage(fileContent, metadata: fileMetadata, type: MessageType.video);
            }
            
            // 显示视频选择成功的提示
            if (currentContext.mounted) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text('已发送视频: ${path.basename(video.path)}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (currentContext.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text('选择视频失败: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    ),
    MessageInputAction(
      title: '位置',
      icon: Icons.location_on,
      onTap: () {
        // 位置功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('位置功能待实现')),
        );
      },
    ),
    MessageInputAction(
      title: '联系人',
      icon: Icons.person,
      onTap: () {
        // 联系人功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('联系人功能待实现')),
        );
      },
    ),
  ];
}