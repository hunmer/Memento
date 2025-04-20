import 'package:flutter/material.dart';
import '../../../services/file_service.dart';
import 'message_input_actions/index.dart';

/// 消息输入动作工具栏
/// 提供各种消息输入方式，如图片、视频、文件等
class MessageInputActions extends StatelessWidget {
  final FileService fileService;
  final OnFileSelected? onFileSelected;
  final OnSendMessage? onSendMessage;

  const MessageInputActions({
    super.key,
    required this.fileService,
    this.onFileSelected,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        // 创建动作构建器
        final actionsBuilder = MessageInputActionsBuilder(
          context: context,
          fileService: fileService,
          onFileSelected: onFileSelected,
          onSendMessage: onSendMessage,
        );

        // 获取所有可用的动作
        final actions = actionsBuilder.buildActions();

        // 显示底部抽屉
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder:
              (context) => MessageInputActionsDrawer(
                actions: actions,
                onFileSelected: onFileSelected,
                onSendMessage: onSendMessage,
              ),
        );
      },
    );
  }
}
