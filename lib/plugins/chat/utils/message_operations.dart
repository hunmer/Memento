import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat_plugin.dart';
import '../models/message.dart';
import '../models/channel.dart';
import '../../../core/event/event.dart';

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
      builder: (context) => AlertDialog(
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
      builder: (context) => AlertDialog(
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
        // 获取频道ID
        final channelId = message.channelId;
        if (channelId == null) {
          throw Exception('消息没有关联的频道ID');
        }
        
        // 获取频道
        final channel = _chatPlugin.channelService.channels
            .firstWhere((c) => c.id == channelId);
        
        // 从频道的消息列表中删除消息
        final updatedMessages = List<Message>.from(channel.messages)
          ..removeWhere((m) => m.id == message.id);
        
        // 更新频道的消息列表
        channel.messages.clear();
        channel.messages.addAll(updatedMessages);
        
        // 保存更新后的消息列表
        await _chatPlugin.channelService.saveMessages(
          channelId,
          updatedMessages,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除消息失败: ${e.toString()}')),
          );
        }
      }
    }
  }

  /// 复制消息内容
  void copyMessage(Message message) {
    if (message.type == MessageType.received ||
        message.type == MessageType.sent) {
      Clipboard.setData(ClipboardData(text: message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(metadata['isFavorite'] ? '已添加到收藏' : '已从收藏中移除'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 根据消息找到对应的频道
  Channel? _findMessageChannel(Message message) {
    // 如果消息中包含频道信息（时间线视图），则直接使用
    final channelId = message.channelId;
    if (channelId != null) {
      try {
        return _chatPlugin.channelService.channels
            .firstWhere((c) => c.id == channelId);
      } catch (_) {
        // 如果找不到频道，继续尝试其他方法
      }
    }

    // 遍历所有频道查找消息
    for (final channel in _chatPlugin.channelService.channels) {
      if (channel.messages.any((m) => m.id == message.id)) {
        return channel;
      }
    }

    // 如果找不到对应的频道，显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('无法找到消息所属的频道')),
    );
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
        offset: selection.baseOffset +
            style.length * 2 +
            selection.textInside(text).length,
      ),
    );
  }
}