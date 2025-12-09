import 'dart:io';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/chat/models/file_message.dart';
import 'package:Memento/plugins/chat/services/file_service.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/types.dart';

Future<void> handleLocalVideoSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {

  try {
    // 使用ImagePicker从相册选择视频
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      try {
        // 将视频转换为文件
        final File videoFile = File(video.path);
        if (!await videoFile.exists()) {
          toastService.showToast(
            'chat_videoFileNotExist'.tr,
          );
          return;
        }

        final originalFileName = path.basename(video.path);

        final savedFile = await fileService.saveVideo(videoFile);

        final fileMessage = await FileMessage.fromFile(
          savedFile,
          originalFileName: originalFileName,
        );

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
        toastService.showToast(
          'chat_videoSent'.tr,
        );
      } catch (processingError) {
        toastService.showToast(
          '${'chat_videoProcessingFailed'.tr}: ${processingError.toString()}',
        );
      }
    }
  } catch (e) {
    toastService.showToast(
      '${'chat_videoSelectionFailed'.tr}: ${e.toString()}',
    );
  }
}
