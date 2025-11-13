import 'dart:io';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleFileSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    // 使用FileService选择文件
    final FileMessage? fileMessage = await fileService.pickFile();

    if (fileMessage != null) {
      try {
        // 获取文件的绝对路径
        final absolutePath = await fileMessage.getAbsolutePath();
        final file = File(absolutePath);

        // 验证文件是否存在
        if (!await file.exists()) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(ChatLocalizations.of(context).fileNotAccessible),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // 标准化文件信息结构
        final Map<String, dynamic> metadata = {
          'fileInfo': {
            'id': fileMessage.id,
            'name': fileMessage.fileName,
            'originalName': fileMessage.originalFileName,
            'path': absolutePath,
            'size': fileMessage.fileSize,
            'extension': fileMessage.extension,
            'type': 'file',
          },
          'senderInfo': {'id': 'current_user', 'name': '我'},
        };

        // 调用回调函数传递文件信息
        onFileSelected?.call(metadata);

        // 显示文件选择成功的提示
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '${ChatLocalizations.of(context).fileSelected}: ${fileMessage.originalFileName}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (processingError) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '${ChatLocalizations.of(context).fileProcessingFailed}: $processingError',
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
          '${ChatLocalizations.of(context).fileSelectionFailed}: $e',
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
