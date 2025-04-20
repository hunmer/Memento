import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../../../../../widgets/markdown_editor/index.dart';
import '../../../services/file_service.dart';
import '../../../models/file_message.dart';
import '../../../models/message.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../../../utils/image_utils.dart'; // 导入 PathUtils 类
import 'package:record/record.dart'; // 导入录音功能
import 'package:path_provider/path_provider.dart';
import 'record_audio_dialog.dart'; // 导入录音对话框组件

class MessageInputAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  MessageInputAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

typedef OnFileSelected = void Function(FileMessage fileMessage);
typedef OnSendMessage =
    void Function(
      String content, {
      Map<String, dynamic>? metadata,
      MessageType? type,
    });

class MessageInputActionsDrawer extends StatelessWidget {
  final List<MessageInputAction> actions;
  final OnFileSelected? onFileSelected;
  final OnSendMessage? onSendMessage;

  const MessageInputActionsDrawer({
    super.key,
    required this.actions,
    this.onFileSelected,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        top: 16.0 + MediaQuery.of(context).padding.top,
        bottom: 16.0 + MediaQuery.of(context).padding.bottom,
        left: 16.0,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '选择操作',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 24.0,
              ),
              itemCount: actions.length,
              itemBuilder:
                  (context, index) => _buildActionItem(context, actions[index]),
            ),
          ),
        ],
      ),
    );
  }

  // 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildActionItem(BuildContext context, MessageInputAction action) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // 关闭抽屉
        action.onTap();
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Icon(
              action.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            action.title,
            style: TextStyle(
              fontSize: 14.0,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 预定义的操作列表
List<MessageInputAction> getDefaultMessageInputActions(
  BuildContext context, {
  OnFileSelected? onFileSelected,
  OnSendMessage? onSendMessage,
}) {
  // 创建FileService实例
  final fileService = FileService();

  // 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  return [
    MessageInputAction(
      title: '录制音频',
      icon: Icons.mic,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // 创建录音实例
        final recorder = AudioRecorder();

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
                        final savedFile = await fileService.saveAudio(
                          audioFile,
                        );
                        debugPrint('音频已保存: ${savedFile.path}');

                        // 获取相对路径
                        final relativePath = await PathUtils.toRelativePath(
                          savedFile.path,
                        );
                        debugPrint('相对路径: $relativePath');

                        // 创建文件消息
                        final fileMessage = await FileMessage.fromFile(
                          savedFile,
                          relativePath: relativePath,
                          originalFileName: originalFileName,
                        );

                        // 调用回调函数发送音频消息
                        onFileSelected?.call(fileMessage);

                        // 如果提供了onSendMessage回调，创建音频类型的消息
                        if (onSendMessage != null) {
                          // 创建音频消息内容
                          final durationText = _formatDuration(duration);
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
                              content: Text(
                                '已发送语音消息: ${_formatDuration(duration)}',
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
      },
    ),
    MessageInputAction(
      title: '高级编辑',
      icon: Icons.text_fields,
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: MarkdownEditor(
                    showTitle: false,
                    contentHint: '在此输入消息内容...',
                    showPreviewButton: true,
                    onSave: (_, content) {
                      if (content.isNotEmpty) {
                        // 发送消息
                        onSendMessage?.call(content, type: MessageType.sent);
                      }
                      Navigator.of(context).pop();
                    },
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
        );
      },
    ),
    MessageInputAction(
      title: '文件',
      icon: Icons.attach_file,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        final fileMessage = await fileService.pickFile();
        if (fileMessage != null) {
          // 调用回调函数发送文件消息
          onFileSelected?.call(fileMessage);

          // 如果提供了onSendMessage回调，创建文件类型的消息
          if (onSendMessage != null) {
            // 创建文件消息内容
            final fileContent =
                '📎 ${fileMessage.fileName} (${fileMessage.formattedSize})';

            // 创建文件元数据，使用相对路径
            final fileMetadata = {
              Message.metadataKeyFileInfo: {
                'id': fileMessage.id,
                'fileName': fileMessage.fileName,
                'originalFileName': fileMessage.originalFileName,
                'filePath':
                    fileMessage.filePath, // FileService.pickFile() 已经返回相对路径
                'fileSize': fileMessage.fileSize,
                'extension': fileMessage.extension,
                'mimeType': fileMessage.mimeType,
              },
            };

            // 发送文件消息
            onSendMessage(
              fileContent,
              metadata: fileMetadata,
              type: MessageType.file,
            );
          }

          // 显示文件选择成功的提示
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('已发送文件: ${fileMessage.fileName}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
    MessageInputAction(
      title: '图片',
      icon: Icons.image,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          // 使用ImagePicker选择图片
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80, // 图片质量
          );

          if (image != null) {
            // 将图片转换为文件
            final File imageFile = File(image.path);
            final originalFileName = path.basename(image.path);

            // 保存图片到应用目录
            final savedFile = await fileService.saveImage(imageFile);
            // 获取相对路径
            final relativePath = await PathUtils.toRelativePath(savedFile.path);
            final fileMessage = await FileMessage.fromFile(
              savedFile,
              relativePath: relativePath,
              originalFileName: originalFileName,
            );
            // 调用回调函数发送图片消息
            onFileSelected?.call(fileMessage);

            // 如果提供了onSendMessage回调，创建图片类型的消息
            if (onSendMessage != null) {
              // 创建图片占位内容，不包含实际路径
              final fileContent = '[图片] ${fileMessage.fileName}';

              // 创建图片元数据
              final fileMetadata = {
                Message.metadataKeyFileInfo: {
                  'id': fileMessage.id,
                  'fileName': fileMessage.fileName,
                  'originalFileName': fileMessage.originalFileName,
                  'filePath': fileMessage.filePath, // 存储相对路径
                  'fileSize': fileMessage.fileSize,
                  'extension': fileMessage.extension,
                  'mimeType':
                      'image/${fileMessage.extension.replaceAll('.', '')}',
                  'isImage': true,
                },
              };

              // 发送图片消息，类型为image
              onSendMessage(
                fileContent,
                metadata: fileMetadata,
                type: MessageType.image,
              );
            }

            // 显示图片选择成功的提示
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('已发送图片: ${path.basename(image.path)}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('选择图片失败: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
    MessageInputAction(
      title: '选择视频',
      icon: Icons.video_library,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          // 使用ImagePicker选择视频
          final ImagePicker picker = ImagePicker();
          final XFile? video = await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 10), // 限制视频长度
          );

          if (video != null) {
            // 将视频转换为文件
            final File videoFile = File(video.path);
            final originalFileName = path.basename(video.path);

            // 保存视频到应用目录
            final savedFile = await fileService.saveVideo(videoFile);
            // 获取相对路径
            final relativePath = await PathUtils.toRelativePath(savedFile.path);
            final fileMessage = await FileMessage.fromFile(
              savedFile,
              relativePath: relativePath,
              originalFileName: originalFileName,
            );
            debugPrint('保存视频文件: ${savedFile.path}');
            // 调用回调函数发送视频消息
            onFileSelected?.call(fileMessage);

            // 如果提供了onSendMessage回调，创建视频类型的消息
            if (onSendMessage != null) {
              // 尝试获取视频封面
              String? thumbnailPath;
              // try {
              //   thumbnailPath = await fileService.getVideoThumbnail(
              //     savedFile.path,
              //   );
              // } catch (e) {
              //   logger.warning('获取视频封面失败: $e');
              //   // 如果获取封面失败，使用默认视频图标
              //   thumbnailPath = null;
              // }

              // 创建Markdown格式的视频消息内容
              String fileContent;
              if (thumbnailPath != null) {
                // 如果有封面，使用封面图片
                fileContent =
                    '[![${fileMessage.fileName}](${thumbnailPath} "${fileMessage.fileName} - 点击播放")](${fileMessage.filePath})';
              } else {
                // 如果没有封面，使用纯文本格式
                fileContent =
                    '🎥 ${fileMessage.fileName} (${fileMessage.formattedSize})';
              }

              // 创建视频元数据，包含封面路径（如果有的话）
              final Map<String, dynamic> fileInfo = {
                'id': fileMessage.id,
                'fileName': fileMessage.fileName,
                'originalFileName': fileMessage.originalFileName,
                'filePath': fileMessage.filePath,
                'fileSize': fileMessage.fileSize,
                'extension': fileMessage.extension,
                'mimeType':
                    'video/${fileMessage.extension.replaceAll('.', '')}',
                'isVideo': true,
              };

              // 只有在成功生成缩略图的情况下才添加缩略图路径
              if (thumbnailPath != null) {
                fileInfo['thumbnailPath'] = thumbnailPath;
              }

              final fileMetadata = {Message.metadataKeyFileInfo: fileInfo};

              // 发送视频消息
              onSendMessage(
                fileContent,
                metadata: fileMetadata,
                type: MessageType.video,
              );
            }

            // 显示视频选择成功的提示
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('已发送视频: ${path.basename(video.path)}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('选择视频失败: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
    MessageInputAction(
      title: '拍摄视频',
      icon: Icons.videocam,
      onTap: () async {
        // 保存 context 的引用
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          print('开始拍摄视频...');
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

              // 获取相对路径
              final relativePath = await PathUtils.toRelativePath(
                savedFile.path,
              );
              debugPrint('相对路径: $relativePath');

              debugPrint('创建文件消息...');
              final fileMessage = await FileMessage.fromFile(
                savedFile,
                relativePath: relativePath,
                originalFileName: originalFileName,
              );
              debugPrint('文件消息已创建: ${fileMessage.id}');

              // 调用回调函数发送视频消息
              debugPrint('调用onFileSelected回调...');
              onFileSelected?.call(fileMessage);
              debugPrint('onFileSelected回调已调用');

              // 如果提供了onSendMessage回调，创建视频类型的消息
              if (onSendMessage != null) {
                debugPrint('准备发送消息...');
                // 创建纯文本格式的视频消息内容
                final fileContent =
                    '🎥 ${fileMessage.fileName} (${fileMessage.formattedSize})';
                debugPrint('消息内容: $fileContent');

                // 创建视频元数据
                final Map<String, dynamic> fileInfo = {
                  'id': fileMessage.id,
                  'fileName': fileMessage.fileName,
                  'originalFileName': fileMessage.originalFileName,
                  'filePath': fileMessage.filePath,
                  'fileSize': fileMessage.fileSize,
                  'extension': fileMessage.extension,
                  'mimeType':
                      'video/${fileMessage.extension.replaceAll('.', '')}',
                  'isVideo': true,
                };

                final fileMetadata = {Message.metadataKeyFileInfo: fileInfo};
                debugPrint('元数据已创建');

                // 发送视频消息
                debugPrint('调用onSendMessage回调...');
                try {
                  onSendMessage.call(
                    fileContent,
                    metadata: fileMetadata,
                    type: MessageType.video,
                  );
                  debugPrint('消息已发送');
                } catch (sendError) {
                  debugPrint('错误：发送消息时出错: $sendError');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('发送消息失败: $sendError'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                debugPrint('警告：onSendMessage回调为null');
              }

              // 显示视频拍摄成功的提示
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
      },
    ),
  ];
}
