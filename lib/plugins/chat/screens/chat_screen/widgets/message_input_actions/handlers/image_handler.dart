import 'dart:io';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../../../../../../../utils/image_utils.dart';
import '../../../../../../../widgets/image_picker_dialog.dart';
import '../types.dart';

Future<void> handleImageSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
  required bool fromCamera,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    // 使用 ImagePickerDialog 并启用压缩
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => ImagePickerDialog(
            saveDirectory: 'chat/chat_files',
            enableCompression: true,
            compressionQuality: 85,
          ),
    );

    if (result != null && result['url'] != null) {
      debugPrint('图片选择完成: ${result['url']}');

      try {
        final String relativePath = result['url'] as String;
        final String? thumbUrl = result['thumbUrl'] as String?;
        final absolutePath = await ImageUtils.getAbsolutePath(relativePath);
        final File imageFile = File(absolutePath);

        if (!await imageFile.exists()) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                ChatLocalizations.of(context).imageNotExist,
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final originalFileName = path.basename(absolutePath);
        final fileMessage = await FileMessage.fromFile(
          imageFile,
          originalFileName: originalFileName,
          thumbPath: thumbUrl,
        );

        // 详细的metadata结构
        final Map<String, dynamic> metadata = {
          'fileInfo': {
            'id': fileMessage.id,
            'name': fileMessage.fileName,
            'originalName': fileMessage.originalFileName,
            'path': fileMessage.filePath,
            'thumbPath': fileMessage.thumbPath,
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
              '${ChatLocalizations.of(context).imageProcessingFailed}: $e',
            ),
          ),
        );
      }
    }
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          '${ChatLocalizations.of(context).imageSelectionFailed}: $e',
        ),
      ),
    );
  }
}
