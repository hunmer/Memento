import 'dart:io';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../../record_audio_dialog.dart';
import '../utils.dart';
import '../types.dart';

Future<void> handleAudioRecording({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {
  // 保存 context 的引用
  final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                  if (scaffoldMessenger.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${ChatLocalizations.of(context).audioRecording}: ${formatDuration(duration)}',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('处理音频时出错: $e');
                  if (scaffoldMessenger.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${ChatLocalizations.of(context).recordingFailed}: $e',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
      );
    }
  } else {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(ChatLocalizations.of(context).recordingFailed),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
