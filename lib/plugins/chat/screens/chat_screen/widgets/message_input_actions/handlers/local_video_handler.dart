import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleLocalVideoSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    debugPrint('开始选择本地视频...');
    // 使用ImagePicker从相册选择视频
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

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

        debugPrint('创建文件消息...');
        final fileMessage = await FileMessage.fromFile(
          savedFile,
          originalFileName: originalFileName,
        );
        debugPrint('文件消息已创建: ${fileMessage.id}');

        // 标准化文件信息结构
        final Map<String, dynamic> metadata = {
          'fileInfo': {
            'id': fileMessage.id,
            'name': fileMessage.fileName,
            'originalName': fileMessage.originalFileName,
            'path': fileMessage.filePath,
            'size': fileMessage.fileSize,
            'extension': fileMessage.extension,
            'mimeType': 'video/${fileMessage.extension.replaceAll('.', '')}',
            'type': 'video',
            'isImage': false,
            'createdAt': DateTime.now().toIso8601String(),
          },
          'senderInfo': {
            'userId': 'current_user',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        };

        // 调用回调函数
        onFileSelected?.call(metadata);

        // 显示视频选择成功的提示
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已发送视频'),
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
