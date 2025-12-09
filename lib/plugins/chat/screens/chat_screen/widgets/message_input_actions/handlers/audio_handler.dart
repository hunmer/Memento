import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/chat/models/file_message.dart';
import 'package:Memento/plugins/chat/services/file_service.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/record_audio_dialog.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/utils.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/widgets/message_input_actions/types.dart';
import '../../../../../../../../core/services/toast_service.dart';

Future<void> handleAudioRecording({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {

  // 创建录音实例
  final recorder = AudioRecorder();

  // 确保初始化录音器
  await recorder.dispose();

  // 检查录音权限
  if (await recorder.hasPermission()) {
    // 显示录音对话框
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => RecordAudioDialog(
              onStop: (File audioFile, Duration duration) async {
                try {
                  debugPrint(
                    '音频录制完成: ${audioFile.path}, 时长: ${duration.inSeconds}秒',
                  );

                  // 获取原始文件名
                  final originalFileName = path.basename(audioFile.path);

                  // 保存音频到应用目录
                  debugPrint('开始保存音频...');
                  await recorder.dispose(); // 确保释放录音资源
                  final savedFile = await fileService.saveAudio(audioFile);
                  debugPrint('音频已保存: ${savedFile.path}');

                  // 创建文件消息
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
                      'mimeType':
                          'audio/${fileMessage.extension.replaceAll('.', '')}',
                      'type': 'audio',
                      'isAudio': true,
                      'duration': duration.inSeconds,
                      'createdAt': DateTime.now().toIso8601String(),
                    },
                    'senderInfo': {
                      'userId': 'current_user_id',
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    },
                  };

                  // 调用回调函数
                  onFileSelected?.call(metadata);

                  // 显示音频发送成功的提示
                  toastService.showToast('${'chat_audioRecording'.tr}: ${formatDuration(duration)}');
                } catch (e) {
                  debugPrint('处理音频时出错: $e');
                  toastService.showToast('${'chat_recordingFailed'.tr}: $e');
                }
              },
            ),
      );
    }
  } else {
    toastService.showToast('chat_recordingFailed'.tr);
  }
}
