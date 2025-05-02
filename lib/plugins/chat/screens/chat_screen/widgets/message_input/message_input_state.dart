import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/event/event.dart';
import '../../../../models/message.dart';

class MessageInputState {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode keyboardListenerFocusNode;
  final List<Map<String, String>> selectedAgents;
  final Map<String, dynamic>? selectedFile;
  final bool showAgentList;
  final Message? replyTo;
  final Map<String, dynamic>? metadata;
  final Function(String) onSaveDraft;
  final Function(
    String, {
    Map<String, dynamic>? metadata,
    String type,
    Message? replyTo,
  })
  onSendMessage;

  // 清空文件选择的回调函数
  final VoidCallback? onClearFile;

  MessageInputState({
    required this.controller,
    required this.focusNode,
    required this.keyboardListenerFocusNode,
    required this.selectedAgents,
    required this.selectedFile,
    required this.showAgentList,
    required this.replyTo,
    required this.onSaveDraft,
    required this.onSendMessage,
    this.onClearFile,
    this.metadata,
  });

  void sendMessage() {
    final messageText = controller.text.trim();
    final hasFile = selectedFile != null;
    final hasMessage = messageText.isNotEmpty;
    final currentChannel = ChatPlugin.instance.channelService.currentChannel;

    // 检查是否有当前频道
    if (currentChannel == null) {
      debugPrint('无法发送消息：当前没有选择频道');
      return;
    }

    if (hasFile || hasMessage) {
      Map<String, dynamic>? metadata = {};

      // 如果有文件，先发送文件
      if (hasFile) {
        final fileInfo = selectedFile!['fileInfo'] as Map<String, dynamic>?;
        if (fileInfo != null) {
          metadata['file'] = fileInfo;
          onSendMessage(
            fileInfo['path'] as String,
            type: fileInfo['type'] as String,
            metadata: selectedFile,
          );
        } else {
          debugPrint('文件路径或类型为空，无法发送文件');
        }
      }

      // 如果有消息文本，再发送消息
      if (hasMessage) {
        // 如果有预设的元数据，先添加
        if (this.metadata != null) {
          metadata.addAll(this.metadata!);
        }
        
        // 添加智能体信息（如果元数据中没有）
        if (selectedAgents.isNotEmpty && !metadata.containsKey('agents')) {
          metadata['agents'] = selectedAgents.map((agent) => agent).toList();
        }
        
        // 确保上下文数量存在（如果元数据中没有）
        if (selectedAgents.isNotEmpty && !metadata.containsKey('contextCount')) {
          metadata['contextCount'] = 20; // 默认上下文数量
        }
        // 创建用户对象
        final user = ChatPlugin.instance.userService.currentUser;
        // 创建消息对象
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: controller.text.trim(),
          user: user,
          type: MessageType.sent,
          replyTo: replyTo,
          metadata: metadata,
          channelId: currentChannel.id,
        );

        // 发送消息
        onSendMessage(
          message.content,
          type: 'sent',
          replyTo: message.replyTo,
          metadata: message.metadata,
        );

        // 广播消息事件
        EventManager.instance.broadcast(
          'onMessageSent',
          Value<Message>(message),
        );

        // 清空输入框并保持焦点
        controller.clear();
        focusNode.requestFocus();

        // 清空文件选择
        if (onClearFile != null) {
          onClearFile!();
        }
      }
    }
  }

  KeyEventResult handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isControlPressed) {
          // Ctrl+Enter: 插入换行符
          final currentText = controller.text;
          final selection = controller.selection;
          final newText = currentText.replaceRange(
            selection.start,
            selection.end,
            '\n',
          );
          controller.value = controller.value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: selection.start + 1),
          );
        } else if (!HardwareKeyboard.instance.isShiftPressed) {
          sendMessage();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
