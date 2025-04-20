import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../models/file_message.dart';
import '../../../../../models/message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleFileSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
  required OnSendMessage? onSendMessage,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    // 使用FileService选择文件
    final FileMessage? fileMessage = await fileService.pickFile();

    if (fileMessage != null) {
      debugPrint('文件选择完成: ${fileMessage.filePath}');

      try {
        // 文件已经由 FileService.pickFile() 方法保存，无需再次检查和保存
        debugPrint('文件已选择: ${fileMessage.fileName}');

        // 调用回调函数发送文件消息
        onFileSelected?.call(fileMessage);

        // 如果提供了onSendMessage回调，创建文件类型的消息
        if (onSendMessage != null) {
          // 创建纯文本格式的文件消息内容
          final fileContent =
              '📎 ${fileMessage.fileName} (${fileMessage.formattedSize})';

          // 创建文件元数据
          final Map<String, dynamic> fileInfo = {
            'id': fileMessage.id,
            'fileName': fileMessage.fileName,
            'originalFileName': fileMessage.originalFileName,
            'filePath': fileMessage.filePath,
            'fileSize': fileMessage.fileSize,
            'extension': fileMessage.extension,
            'mimeType': 'application/octet-stream',
            'isFile': true,
          };

          final fileMetadata = {Message.metadataKeyFileInfo: fileInfo};

          // 发送文件消息
          onSendMessage.call(
            fileContent,
            metadata: fileMetadata,
            type: MessageType.file,
          );
        }

        // 显示文件选择成功的提示
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已发送文件: ${fileMessage.originalFileName}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (processingError) {
        debugPrint('错误：处理文件时出错: $processingError');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('处理文件失败: $processingError'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      debugPrint('未获取到文件，可能是用户取消了选择');
    }
  } catch (e) {
    debugPrint('错误：选择文件过程中出错: $e');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('选择文件失败: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
