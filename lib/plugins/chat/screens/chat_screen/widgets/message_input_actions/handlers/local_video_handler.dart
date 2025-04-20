import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../../../../utils/image_utils.dart';
import '../../../../../models/file_message.dart';
import '../../../../../models/message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleLocalVideoSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
  required OnSendMessage? onSendMessage,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  try {
    debugPrint('开始选择本地视频...');
    // 使用ImagePicker从相册选择视频
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video != null) {
      debugPrint('本地视频选择完成: ${video.path}');
      
      try {
        // 将视频转换为文件
        final File videoFile = File(video.path);
        if (!await videoFile.exists()) {
          debugPrint('警告：视频文件不存在: ${video.path}');
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('视频文件不存在'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final originalFileName = path.basename(video.path);
        debugPrint('原始文件名: $originalFileName');

        // 保存视频到应用目录
        debugPrint('开始保存视频...');
        final savedFile = await fileService.saveVideo(videoFile);
        debugPrint('视频已保存: ${savedFile.path}');

        // 获取相对路径
        final relativePath = await PathUtils.toRelativePath(
          savedFile.path,
        );
        debugPrint('相对路径: $relativePath');

        debugPrint('创建文件消息...');
        final fileMessage = await FileMessage.fromFile(
          savedFile,
          relativePath: relativePath,
          originalFileName: originalFileName,
        );
        debugPrint('文件消息已创建: ${fileMessage.id}');

        // 调用回调函数发送视频消息
        debugPrint('调用onFileSelected回调...');
        onFileSelected?.call(fileMessage);
        debugPrint('onFileSelected回调已调用');

        // 如果提供了onSendMessage回调，创建视频类型的消息
        if (onSendMessage != null) {
          debugPrint('准备发送消息...');
          // 创建纯文本格式的视频消息内容
          final fileContent =
              '🎥 ${fileMessage.fileName} (${fileMessage.formattedSize})';
          debugPrint('消息内容: $fileContent');

          // 创建视频元数据
          final Map<String, dynamic> fileInfo = {
            'id': fileMessage.id,
            'fileName': fileMessage.fileName,
            'originalFileName': fileMessage.originalFileName,
            'filePath': fileMessage.filePath,
            'fileSize': fileMessage.fileSize,
            'extension': fileMessage.extension,
            'mimeType':
                'video/${fileMessage.extension.replaceAll('.', '')}',
            'isVideo': true,
          };

          final fileMetadata = {Message.metadataKeyFileInfo: fileInfo};
          debugPrint('元数据已创建');

          // 发送视频消息
          debugPrint('调用onSendMessage回调...');
          try {
            onSendMessage.call(
              fileContent,
              metadata: fileMetadata,
              type: MessageType.video,
            );
            debugPrint('消息已发送');
          } catch (sendError) {
            debugPrint('错误：发送消息时出错: $sendError');
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('发送消息失败: $sendError'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          debugPrint('警告：onSendMessage回调为null');
        }

        // 显示视频选择成功的提示
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已发送视频: ${path.basename(video.path)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (processingError) {
        debugPrint('错误：处理视频时出错: $processingError');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('处理视频失败: $processingError'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      debugPrint('未获取到视频文件，可能是用户取消了选择');
    }
  } catch (e) {
    debugPrint('错误：选择视频过程中出错: $e');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('选择视频失败: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}