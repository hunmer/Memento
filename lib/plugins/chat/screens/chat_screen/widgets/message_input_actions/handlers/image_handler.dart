import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../models/message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleImageSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
  required OnSendMessage? onSendMessage,
  required bool fromCamera,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final ImagePicker picker = ImagePicker();

  try {
    final XFile? image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (image != null) {
      debugPrint('图片选择完成: ${image.path}');

      try {
        // 将图片转换为文件
        final File imageFile = File(image.path);
        if (!await imageFile.exists()) {
          debugPrint('警告：图片文件不存在: ${image.path}');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('图片文件不存在'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final originalFileName = path.basename(image.path);
        debugPrint('原始文件名: $originalFileName');

        // 保存图片到应用目录
        debugPrint('开始保存图片...');
        final savedFile = await fileService.saveImage(imageFile);
        debugPrint('图片已保存: ${savedFile.path}');

        debugPrint('创建文件消息...');
        final fileMessage = await FileMessage.fromFile(
          savedFile,
          originalFileName: originalFileName,
        );
        debugPrint('文件消息已创建: ${fileMessage.id}');

        // 创建图片元数据用于回调
        final Map<String, dynamic> fileInfoForCallback = {
          'id': fileMessage.id,
          'name': fileMessage.fileName,
          'originalName': fileMessage.originalFileName,
          'path': fileMessage.filePath,
          'size': fileMessage.fileSize,
          'extension': fileMessage.extension,
          'mimeType': 'image/${fileMessage.extension.replaceAll('.', '')}',
          'type': 'image', // 添加type字段
          'isImage': true,
        };

        // 调用回调函数发送图片消息
        debugPrint('调用onFileSelected回调...');
        onFileSelected?.call(fileInfoForCallback);
        debugPrint('onFileSelected回调已调用');

        // 如果提供了onSendMessage回调，创建图片类型的消息
        if (onSendMessage != null) {
          debugPrint('准备发送消息...');
          // 创建纯文本格式的图片消息内容
          final fileContent =
              '🖼️ ${fileMessage.fileName} (${fileMessage.formattedSize})';
          debugPrint('消息内容: $fileContent');

          // 创建图片元数据
          final Map<String, dynamic> fileInfo = {
            'id': fileMessage.id,
            'fileName': fileMessage.fileName,
            'originalFileName': fileMessage.originalFileName,
            'filePath': fileMessage.filePath,
            'fileSize': fileMessage.fileSize,
            'extension': fileMessage.extension,
            'mimeType': 'image/${fileMessage.extension.replaceAll('.', '')}',
            'isImage': true,
          };

          final fileMetadata = {Message.metadataKeyFileInfo: fileInfo};
          debugPrint('元数据已创建');

          // 发送图片消息
          debugPrint('调用onSendMessage回调...');
          onSendMessage.call(
            fileContent,
            metadata: fileMetadata,
            type: 'image',
          );
          debugPrint('消息已发送');
        }
      } catch (processingError) {
        debugPrint('错误：处理图片时出错: $processingError');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('处理图片失败: $processingError'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      debugPrint('未获取到图片文件，可能是用户取消了选择');
    }
  } catch (e) {
    debugPrint('错误：选择图片过程中出错: $e');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('选择图片失败: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
