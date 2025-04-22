import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import '../../../../../../../utils/image_utils.dart';
import '../../../../../models/file_message.dart';
import '../../../../../models/message.dart';
import '../../../../../services/file_service.dart';
import '../../record_audio_dialog.dart';
import '../utils.dart';
import '../types.dart';

Future<void> handleAudioRecording({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
  required OnSendMessage? onSendMessage,
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

                  // 调用回调函数发送音频消息
                  onFileSelected?.call(fileMessage);

                  // 如果提供了onSendMessage回调，创建音频类型的消息
                  if (onSendMessage != null) {
                    // 创建音频消息内容
                    final durationText = formatDuration(duration);
                    final fileContent = '🎵 语音消息 ($durationText)';

                    // 创建音频元数据
                    final Map<String, dynamic> fileInfo = {
                      'id': fileMessage.id,
                      'fileName': fileMessage.fileName,
                      'originalFileName': fileMessage.originalFileName,
                      'filePath': fileMessage.filePath,
                      'fileSize': fileMessage.fileSize,
                      'extension': fileMessage.extension,
                      'mimeType':
                          'audio/${fileMessage.extension.replaceAll('.', '')}',
                      'isAudio': true,
                      'duration': duration.inSeconds, // 添加音频时长信息
                    };

                    final fileMetadata = {
                      Message.metadataKeyFileInfo: fileInfo,
                    };

                    // 发送音频消息
                    onSendMessage.call(
                      fileContent,
                      metadata: fileMetadata,
                      type: MessageType.audio,
                    );
                  }

                  // 显示音频发送成功的提示
                  if (scaffoldMessenger.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('已发送语音消息: ${formatDuration(duration)}'),
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
                        content: Text('处理音频失败: $e'),
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
      const SnackBar(
        content: Text('没有录音权限'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
