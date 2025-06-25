import 'dart:io';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/l10n/local_video_handler_localizations.dart';
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
    // 使用ImagePicker从相册选择视频
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      try {
        // 将视频转换为文件
        final File videoFile = File(video.path);
        if (!await videoFile.exists()) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                LocalVideoHandlerLocalizations.getText(
                  context,
                  LocalVideoHandlerLocalizations.videoFileNotExist,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
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
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              LocalVideoHandlerLocalizations.getText(
                context,
                LocalVideoHandlerLocalizations.videoSent,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (processingError) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              LocalVideoHandlerLocalizations.getText(
                context,
                LocalVideoHandlerLocalizations.videoProcessingFailed,
                processingError.toString(),
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          LocalVideoHandlerLocalizations.getText(
            context,
            LocalVideoHandlerLocalizations.videoSelectionFailed,
            e.toString(),
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
