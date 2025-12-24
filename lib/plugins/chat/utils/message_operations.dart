import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 统一管理消息操作的处理器
class MessageOperations {
  final ChatPlugin _chatPlugin;
  final BuildContext context;

  MessageOperations(this.context) : _chatPlugin = ChatPlugin.instance;

  /// 编辑消息
  Future<void> editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);

    // 显示编辑对话框
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('chat_editMessage'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: null,
                  decoration: const InputDecoration(hintText: '输入新的消息内容...'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () => _insertMarkdownStyle(controller, '**'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic),
                      onPressed: () => _insertMarkdownStyle(controller, '*'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_strikethrough),
                      onPressed: () => _insertMarkdownStyle(controller, '~~'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underline),
                      onPressed: () => _insertMarkdownStyle(controller, '__'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('app_save'.tr),
              ),
            ],
          ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final updatedMessage = await message.copyWith(
        content: controller.text,
        editedAt: DateTime.now(),
      );

      // 直接调用 updateMessage 方法更新消息
      await _chatPlugin.channelService.updateMessage(updatedMessage);
    }

    controller.dispose();
  }

  /// 删除消息
  Future<void> deleteMessage(Message message) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('chat_deleteMessage'.tr),
            content: Text(
              'chat_deleteMessageConfirmation'.tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('chat_delete'.tr),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // 获取频道ID
      final channelId = message.channelId;
      if (channelId == null) {
        return;
      }

      // 获取频道
      final channel = _chatPlugin.channelService.channels.firstWhere(
        (c) => c.id == channelId,
      );

      // 从频道的消息列表中删除消息
      final updatedMessages = List<Message>.from(channel.messages)
        ..removeWhere((m) => m.id == message.id);

      // 更新频道的消息列表
      channel.messages.clear();
      channel.messages.addAll(updatedMessages);

      // 保存更新后的消息列表
      await _chatPlugin.channelService.saveMessages(channelId, updatedMessages);

      // 触发 UI 更新
      _chatPlugin.refresh();
    }
  }

  /// 复制消息内容
  void copyMessage(Message message) {
    if (message.type == MessageType.received ||
        message.type == MessageType.sent) {
      Clipboard.setData(ClipboardData(text: message.content));
      toastService.showToast('chat_copiedToClipboard'.tr);
    }
  }

  /// 设置固定符号
  Future<void> setFixedSymbol(Message message, String? symbol) async {
    final updatedMessage = await message.copyWith(fixedSymbol: symbol);
    // 直接调用 updateMessage 方法更新消息
    await _chatPlugin.channelService.updateMessage(updatedMessage);
  }

  /// 设置气泡颜色
  Future<void> setBubbleColor(Message message, Color? color) async {
    final updatedMessage = await message.copyWith(bubbleColor: color);
    // 直接调用 updateMessage 方法更新消息
    await _chatPlugin.channelService.updateMessage(updatedMessage);
  }

  /// 收藏/取消收藏消息
  Future<void> toggleFavorite(Message message) async {
    // 获取当前消息的metadata，如果不存在则创建一个新的
    final metadata = Map<String, dynamic>.from(message.metadata ?? {});

    // 切换收藏状态
    final isFavorite = metadata['isFavorite'] as bool? ?? false;
    metadata['isFavorite'] = !isFavorite;

    // 如果收藏，添加收藏时间
    if (metadata['isFavorite'] == true) {
      metadata['favoritedAt'] = DateTime.now().toIso8601String();
    } else {
      // 如果取消收藏，移除收藏时间
      metadata.remove('favoritedAt');
    }

    // 更新消息
    final updatedMessage = await message.copyWith(metadata: metadata);

    // 直接调用 updateMessage 方法更新消息
    await _chatPlugin.channelService.updateMessage(updatedMessage);

    // 显示操作结果
    if (context.mounted) {
      toastService.showToast(metadata['isFavorite'] ? '已添加到收藏' : '已从收藏中移除');
    }
  }

  /// 插入 Markdown 样式
  void _insertMarkdownStyle(TextEditingController controller, String style) {
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$style${selection.textInside(text)}$style',
    );
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            selection.baseOffset +
            style.length * 2 +
            selection.textInside(text).length,
      ),
    );
  }
}
