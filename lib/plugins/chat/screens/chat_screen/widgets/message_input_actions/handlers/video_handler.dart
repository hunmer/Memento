import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../../models/file_message.dart';
import '../../../../../services/file_service.dart';
import '../types.dart';

Future<void> handleVideoSelection({
  required BuildContext context,
  required FileService fileService,
  required OnFileSelected? onFileSelected,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // 检查是否在Web平台上
  if (kIsWeb) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Web平台不支持视频拍摄功能'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // 检查是否在macOS平台上
  if (Platform.isMacOS) {
    try {
      debugPrint('在macOS上使用文件选择器选择视频...');
      // 在macOS上使用图片选择器从相册选择视频
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        debugPrint('视频选择完成: ${video.path}');

        try {
          // 将视频转换为文件
          final File videoFile = File(video.path);
          if (!await videoFile.exists()) {
            debugPrint('警告：视频文件不存在: ${video.path}');
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('视频文件不存在'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final originalFileName = path.basename(video.path);
          debugPrint('原始文件名: $originalFileName');

          // 保存视频到应用目录
          debugPrint('开始保存视频...');
          final savedFile = await fileService.saveVideo(videoFile);
          debugPrint('视频已保存: ${savedFile.path}');

          debugPrint('创建文件消息...');
          final fileMessage = await FileMessage.fromFile(
            savedFile,
            originalFileName: originalFileName,
          );
          debugPrint('文件消息已创建: ${fileMessage.id}');

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
          debugPrint('调用onFileSelected回调...');
          onFileSelected?.call(metadata);
          debugPrint('onFileSelected回调已调用');
        } catch (processingError) {
          debugPrint('错误：处理视频时出错: $processingError');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('处理视频失败: $processingError'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('未获取到视频文件，可能是用户取消了选择');
      }
    } catch (e) {
      debugPrint('错误：选择视频过程中出错: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('选择视频失败: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return; // 在 macOS 上处理完成后返回，不执行下面的相机拍摄代码
  }

  try {
    debugPrint('开始拍摄视频...');
    // 使用ImagePicker启动相机拍摄视频
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 10), // 限制视频长度为10分钟
    );

    if (video != null) {
      debugPrint('视频拍摄完成: ${video.path}');

      try {
        // 将视频转换为文件
        final File videoFile = File(video.path);
        if (!await videoFile.exists()) {
          debugPrint('警告：视频文件不存在: ${video.path}');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('视频文件不存在'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final originalFileName = path.basename(video.path);
        debugPrint('原始文件名: $originalFileName');

        // 保存视频到应用目录
        debugPrint('开始保存视频...');
        final savedFile = await fileService.saveVideo(videoFile);
        debugPrint('视频已保存: ${savedFile.path}');

        debugPrint('创建文件消息...');
        final fileMessage = await FileMessage.fromFile(
          savedFile,
          originalFileName: originalFileName,
        );
        debugPrint('文件消息已创建: ${fileMessage.id}');

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
        debugPrint('调用onFileSelected回调...');
        onFileSelected?.call(metadata);
        debugPrint('onFileSelected回调已调用');

        // 显示视频选择成功的提示
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('已发送视频: ${path.basename(video.path)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (processingError) {
        debugPrint('错误：处理视频时出错: $processingError');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('处理视频失败: $processingError'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      debugPrint('未获取到视频文件，可能是用户取消了拍摄或拍摄过程中出现问题');
      // 不显示取消提示，因为这可能是完成拍摄后的正常流程
    }
  } catch (e) {
    debugPrint('错误：拍摄视频过程中出错: $e');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('拍摄视频失败: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
