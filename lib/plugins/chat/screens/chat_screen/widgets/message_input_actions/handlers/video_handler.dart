import 'dart:io';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/chat/models/file_message.dart';
import 'package:Memento/plugins/chat/services/file_service.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/types.dart';

Future<void> handleVideoSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {
  // 检查是否在Web平台上
  if (kIsWeb) {
    toastService.showToast('chat_videoNotSupportedOnWeb'.tr);
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
            toastService.showToast('chat_videoNotExist'.tr);
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
          toastService.showToast(
            'chat_videoProcessingFailed'.trParams({'processingError': processingError.toString()}),
          );
        }
      }
    } catch (e) {
      toastService.showToast(
        'chat_videoSelectionFailed'.trParams({'e': e.toString()}),
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
          toastService.showToast('chat_videoNotExist'.tr);
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
        toastService.showToast(
          '${'chat_videoSent'.tr}: ${path.basename(video.path)}',
        );
      } catch (processingError) {
        toastService.showToast(
          'chat_videoProcessingFailed'.trParams({'processingError': processingError.toString()}),
        );
      }
    }
  } catch (e) {
    toastService.showToast(
      'chat_videoSelectionFailed'.trParams({'e': e.toString()}),
    );
  }
}
