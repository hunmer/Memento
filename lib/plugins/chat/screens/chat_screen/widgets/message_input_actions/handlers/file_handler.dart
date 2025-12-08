import 'dart:io';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/models/file_message.dart';
import 'package:Memento/plugins/chat/services/file_service.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/types.dart';
import '../../../../../../../../core/services/toast_service.dart';

Future<void> handleFileSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {

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
          toastService.showToast(ChatLocalizations.of(context).fileNotAccessible);
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
        toastService.showToast('${ChatLocalizations.of(context).fileSelected}: ${fileMessage.originalFileName}');
      } catch (processingError) {
        toastService.showToast('${ChatLocalizations.of(context).fileProcessingFailed}: $processingError');
      }
    }
  } catch (e) {
    toastService.showToast('${ChatLocalizations.of(context).fileSelectionFailed}: $e');
  }
}
