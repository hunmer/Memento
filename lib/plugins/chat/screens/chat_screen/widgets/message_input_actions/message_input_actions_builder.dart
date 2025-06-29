import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../services/file_service.dart';
import 'handlers/index.dart';
import 'types.dart';
import 'package:Memento/plugins/openai/widgets/plugin_analysis_dialog.dart';
import '../../../../l10n/chat_localizations.dart';

/// 构建消息输入动作列表
class MessageInputActionsBuilder {
  final BuildContext context;
  final FileService fileService;
  final OnFileSelected? onFileSelected;
  final OnSendMessage? onSendMessage;
  final TextEditingController? textController;

  MessageInputActionsBuilder({
    required this.context,
    required this.fileService,
    this.onFileSelected,
    this.onSendMessage,
    this.textController,
  });

  /// 获取默认的消息输入动作列表（静态方法）
  static List<MessageInputAction> getDefaultActions(
    BuildContext context, {
    OnFileSelected? onFileSelected,
    OnSendMessage? onSendMessage,
    TextEditingController? textController,
  }) {
    // 创建一个FileService实例
    final fileService = FileService();

    // 使用实例方法构建动作列表
    return MessageInputActionsBuilder(
      context: context,
      fileService: fileService,
      onFileSelected: onFileSelected,
      onSendMessage: onSendMessage,
      textController: textController,
    ).buildActions();
  }

  /// 获取所有可用的消息输入动作
  List<MessageInputAction> buildActions() {
    final List<MessageInputAction> actions = [];
    final chatLocalizations = ChatLocalizations.of(context);

    // 添加高级编辑器动作
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.advancedEditor ?? '高级编辑',
        icon: Icons.edit_note,
        onTap:
            () => handleAdvancedEditor(
              context: context,
              onSendMessage: onSendMessage,
            ),
      ),
    );

    // 添加图片选择动作
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.photo ?? '图片',
        icon: Icons.photo,
        onTap:
            () => handleImageSelection(
              context: context,
              fileService: fileService,
              onFileSelected: onFileSelected,
              fromCamera: false,
            ),
      ),
    );

    // 添加拍照动作
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.takePhoto ?? '拍照',
        icon: Icons.camera_alt,
        onTap:
            () => handleImageSelection(
              context: context,
              fileService: fileService,
              onFileSelected: onFileSelected,
              fromCamera: true,
            ),
      ),
    );

    // 添加录像动作
    // 在Web平台上不支持视频拍摄，但我们仍然显示按钮，点击后会提示不支持
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.recordVideo ?? '录像',
        icon: Icons.videocam,
        onTap:
            () => handleVideoSelection(
              context: context,
              fileService: fileService,
              onFileSelected: onFileSelected,
            ),
      ),
    );

    // 添加视频选择动作
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.video ?? '视频',
        icon: Icons.video_library,
        onTap:
            () => handleLocalVideoSelection(
              context: context,
              fileService: fileService,
              onFileSelected: onFileSelected,
            ),
      ),
    );

    // 添加插件分析功能
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.pluginAnalysis ?? '插件分析',
        icon: Icons.analytics,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const PluginAnalysisDialog(),
          );
        },
      ),
    );

    // 添加文件选择动作
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.file ?? '文件',
        icon: Icons.attach_file,
        onTap:
            () => handleFileSelection(
              context: context,
              fileService: fileService,
              onFileSelected: onFileSelected,
            ),
      ),
    );

    // 添加录音动作
    // 仅在非Web平台上添加录音功能
    if (!kIsWeb) {
      actions.add(
        MessageInputAction(
          title: chatLocalizations?.audioRecording ?? '录音',
          icon: Icons.mic,
          onTap:
              () => handleAudioRecording(
                context: context,
                fileService: fileService,
                onFileSelected: onFileSelected,
              ),
        ),
      );
    }

    // 添加智能体动作
    actions.add(
      MessageInputAction(
        title: chatLocalizations?.smartAgent ?? '智能体',
        icon: Icons.smart_toy,
        onTap: () {
          // 直接在文本框末尾添加 @ 符号，这会触发 MessageInput 中的处理逻辑
          if (textController != null) {
            textController!.text = '@';
          }
        },
      ),
    );

    return actions;
  }
}
