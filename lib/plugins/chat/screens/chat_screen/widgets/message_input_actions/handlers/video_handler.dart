import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleVideoSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // 检查是否在Web平台上
  if (kIsWeb) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Web平台不支持视频拍摄功能'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // 检查是否在macOS平台上
  if (Platform.isMacOS) {
    try {
      // 在macOS上使用图片选择器从相册选择视频
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        try {
          // 将视频转换为文件
          final File videoFile = File(video.path);
          if (!await videoFile.exists()) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('视频文件不存在'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final originalFileName = path.basename(video.path);

          // 保存视频到应用目录
          final savedFile = await fileService.saveVideo(videoFile);

          final fileMessage = await FileMessage.fromFile(
            savedFile,
            originalFileName: originalFileName,
          );

          // 标准化文件信息结构，确保包含FileMessage.fromJson所需的所有字段
          final Map<String, dynamic> metadata = {
            'fileInfo': {
              'id': fileMessage.id,
              'fileName': fileMessage.fileName, // FileMessage.fromJson必需字段
              'filePath': fileMessage.filePath, // FileMessage.fromJson必需字段
              'originalFileName': fileMessage.originalFileName,
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
        } catch (processingError) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('处理视频失败: $processingError'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
    return; // 在 macOS 上处理完成后返回，不执行下面的相机拍摄代码
  }

  try {
    // 使用ImagePicker启动相机拍摄视频
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 10), // 限制视频长度为10分钟
    );

    if (video != null) {
      try {
        // 将视频转换为文件
        final File videoFile = File(video.path);
        if (!await videoFile.exists()) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('视频文件不存在'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final originalFileName = path.basename(video.path);

        // 保存视频到应用目录
        final savedFile = await fileService.saveVideo(videoFile);

        final fileMessage = await FileMessage.fromFile(
          savedFile,
          originalFileName: originalFileName,
        );

        // 标准化文件信息结构
        final Map<String, dynamic> metadata = {
          'fileInfo': {
            'id': fileMessage.id,
            'fileName': fileMessage.fileName, // 修正字段名
            'originalFileName': fileMessage.originalFileName,
            'filePath': fileMessage.filePath, // 修正字段名
            'fileSize': fileMessage.fileSize, // 修正字段名
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
            content: Text('已发送视频: ${path.basename(video.path)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (processingError) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('处理视频失败: $processingError'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('拍摄视频失败: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
