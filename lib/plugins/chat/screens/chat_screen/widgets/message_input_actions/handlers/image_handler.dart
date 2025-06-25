import 'dart:io';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleImageSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
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
        final File imageFile = File(image.path);
        if (!await imageFile.exists()) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                ChatLocalizations.of(context)?.imageNotExist ?? '图片文件不存在',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final originalFileName = path.basename(image.path);
        final savedFile = await fileService.saveImage(imageFile);
        final fileMessage = await FileMessage.fromFile(
          savedFile,
          originalFileName: originalFileName,
        );

        // 详细的metadata结构
        final Map<String, dynamic> metadata = {
          'fileInfo': {
            'id': fileMessage.id,
            'name': fileMessage.fileName,
            'originalName': fileMessage.originalFileName,
            'path': fileMessage.filePath,
            'size': fileMessage.fileSize,
            'extension': fileMessage.extension,
            'mimeType': 'image/${fileMessage.extension.replaceAll('.', '')}',
            'type': 'image',
            'isImage': true,
            'createdAt': DateTime.now().toIso8601String(),
          },
          'senderInfo': {
            'userId': 'current_user', // 需要替换为实际用户ID
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        };

        onFileSelected?.call(metadata);
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '${ChatLocalizations.of(context)?.imageProcessingFailed ?? '处理图片失败'}: $e',
            ),
          ),
        );
      }
    }
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          '${ChatLocalizations.of(context)?.imageSelectionFailed ?? '选择图片失败'}: $e',
        ),
      ),
    );
  }
}
