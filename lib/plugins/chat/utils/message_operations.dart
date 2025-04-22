import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat_plugin.dart';
import '../models/message.dart';
import '../models/channel.dart';

/// 统一管理消息操作的处理器
class MessageOperations {
  final ChatPlugin _chatPlugin;
  final BuildContext context;

  MessageOperations(this.context) : _chatPlugin = ChatPlugin.instance;

  /// 编辑消息
  Future<void> editMessage(Message message) async {
    final channel = _findMessageChannel(message);
    if (channel == null) return;

    final controller = TextEditingController(text: message.content);

    // 显示编辑对话框
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('编辑消息'),
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
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('保存'),
              ),
            ],
          ),
    );

    if (result == true && controller.text.isNotEmpty) {
      final updatedMessage = await message.copyWith(content: controller.text);
      final index = channel.messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        // 更新消息
        channel.messages[index] = updatedMessage;
        // 保存更新后的消息列表
        await _chatPlugin.saveMessages(channel.id, channel.messages);
      }
    }

    controller.dispose();
  }

  /// 删除消息
  Future<void> deleteMessage(Message message) async {
    final channel = _findMessageChannel(message);
    if (channel == null) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除消息'),
            content: const Text('确定要删除这条消息吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // 获取消息的索引
        final index = channel.messages.indexWhere((m) => m.id == message.id);
        if (index == -1) return;

        // 从频道的消息列表中删除消息
        final updatedMessages = List<Message>.from(channel.messages)
          ..removeAt(index);

        // 保存更新后的消息列表
        await _chatPlugin.saveMessages(channel.id, updatedMessages);

        // 更新频道的消息列表
        channel.messages.clear();
        channel.messages.addAll(updatedMessages);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除消息失败: ${e.toString()}')));
        }
      }
    }
  }

  /// 复制消息内容
  void copyMessage(Message message) {
    if (message.type == MessageType.received ||
        message.type == MessageType.sent) {
      Clipboard.setData(ClipboardData(text: message.content));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
    }
  }

  /// 设置固定符号
  Future<void> setFixedSymbol(Message message, String? symbol) async {
    final channel = _findMessageChannel(message);
    if (channel == null) return;

    final updatedMessage = await message.copyWith(fixedSymbol: symbol);
    final index = channel.messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      // 更新消息
      channel.messages[index] = updatedMessage;
      // 保存更新后的消息列表
      await _chatPlugin.saveMessages(channel.id, channel.messages);
    }
  }

  /// 设置气泡颜色
  Future<void> setBubbleColor(Message message, Color? color) async {
    final channel = _findMessageChannel(message);
    if (channel == null) return;

    final updatedMessage = await message.copyWith(bubbleColor: color);
    final index = channel.messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      // 更新消息
      channel.messages[index] = updatedMessage;
      // 保存更新后的消息列表
      await _chatPlugin.saveMessages(channel.id, channel.messages);
    }
  }

  /// 根据消息找到对应的频道
  Channel? _findMessageChannel(Message message) {
    // 如果消息中包含频道信息（时间线视图），则直接使用
    final channelId = message.metadata?['channelId'] as String?;
    if (channelId != null) {
      try {
        return _chatPlugin.channels.firstWhere((c) => c.id == channelId);
      } catch (_) {
        // 如果找不到频道，继续尝试其他方法
      }
    }

    // 遍历所有频道查找消息
    for (final channel in _chatPlugin.channels) {
      if (channel.messages.any((m) => m.id == message.id)) {
        return channel;
      }
    }

    // 如果找不到对应的频道，显示错误提示
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法找到消息所属的频道')));
    return null;
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
