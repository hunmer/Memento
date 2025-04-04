import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../utils/date_formatter.dart';
import '../screens/user_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Function(Message) onEdit;
  final Function(Message) onDelete;
  final Function(Message) onCopy;
  final Function(Message, String?) onSetFixedSymbol;
  final Color? channelColor;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onSelect;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onSetFixedSymbol,
    this.channelColor,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onSelect,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // 获取最近使用的表情列表
  Future<List<String>> _getRecentEmojis() async {
    // 默认表情列表
    const defaultEmojis = ['👍', '❤️', '😊', '🎉', '🔥', '👀'];

    try {
      // 尝试从本地存储获取保存的表情列表
      final prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList('recentEmojis');
      if (saved != null && saved.isNotEmpty) {
        // 确保不超过默认表情数量
        return saved.take(defaultEmojis.length).toList();
      }
    } catch (_) {
      // 处理错误
    }
    return defaultEmojis;
  }

  // 保存最近使用的表情
  Future<void> _saveRecentEmoji(String emoji) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentList =
          prefs.getStringList('recentEmojis') ?? [];

      // 如果表情已存在，先移除它
      currentList.remove(emoji);

      // 将新表情添加到列表开头
      currentList.insert(0, emoji);

      // 保留最多6个表情
      final updatedList = currentList.take(6).toList();

      // 保存到本地存储
      await prefs.setStringList('recentEmojis', updatedList);
    } catch (_) {
      // 处理错误
    }
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      // 今天的消息只显示时间
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨天的消息显示"昨天"和时间
      return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      // 更早的消息显示完整日期和时间
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSentMessage = widget.message.type == MessageType.sent;
    // 使用频道颜色或默认颜色
    final backgroundColor =
        isSentMessage
            ? (widget.channelColor ?? Theme.of(context).colorScheme.primary)
            : Colors.grey.shade200;

    // 根据背景色亮度自动调整文字颜色
    final textColor =
        isSentMessage
            ? (widget.channelColor != null
                ? (widget.channelColor!.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white)
                : Colors.white)
            : Colors.black87;

    return GestureDetector(
      onTap: widget.isMultiSelectMode ? widget.onSelect : null,
      onLongPress:
          widget.isMultiSelectMode ? null : () => _showMessageOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        color:
            widget.isSelected ? Colors.blue.withAlpha(25) : Colors.transparent,
        child: Row(
          mainAxisAlignment:
              isSentMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isSentMessage)
              _buildAvatar(widget.message.user, showAvatar: true),
            if (!isSentMessage) const SizedBox(width: 8),
            if (widget.message.fixedSymbol != null && !isSentMessage)
              _buildFixedSymbol(),
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isSentMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundDecoration:
                        widget.isSelected
                            ? BoxDecoration(
                              color: Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                            )
                            : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 使用 MarkdownBody 渲染 Markdown 格式的消息
                        MarkdownBody(
                          data: widget.message.content,
                          selectable: false,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: textColor),
                            strong: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            em: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: textColor,
                            ),
                            del: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: textColor,
                            ),
                            a: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.grey.shade200,
                              color:
                                  isSentMessage
                                      ? Colors.black87
                                      : Colors.black87,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              Clipboard.setData(ClipboardData(text: href));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('链接已复制: $href'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        if (widget.message.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '(已编辑)',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color:
                                    isSentMessage
                                        ? Colors.white70
                                        : Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.message.fixedSymbol != null && isSentMessage)
                    _buildFixedSymbol(),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _formatMessageDate(widget.message.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (isSentMessage &&
                _buildAvatar(widget.message.user, showAvatar: false)
                    is! SizedBox)
              const SizedBox(width: 8),
            if (isSentMessage)
              _buildAvatar(widget.message.user, showAvatar: false),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedSymbol() {
    return Container(
      margin: EdgeInsets.only(
        left: widget.message.type == MessageType.sent ? 4 : 0,
        right: widget.message.type == MessageType.received ? 4 : 0,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        widget.message.fixedSymbol!,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑消息'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit(widget.message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除消息'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(widget.message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制消息'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onCopy(widget.message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: const Text('设置固定符号'),
                onTap: () {
                  Navigator.pop(context);
                  _showSetFixedSymbolDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('查看原始文本'),
                onTap: () {
                  Navigator.pop(context);
                  _showRawTextDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRawTextDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('原始文本'),
            content: SingleChildScrollView(
              child: SelectableText(
                widget.message.content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  widget.onCopy(widget.message);
                  Navigator.of(context).pop();
                },
                child: const Text('复制'),
              ),
            ],
          ),
    );
  }

  void _showSetFixedSymbolDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: widget.message.fixedSymbol,
    );

    showDialog<void>(
      context: context,
      builder:
          (context) => FutureBuilder<List<String>>(
            future: _getRecentEmojis(),
            builder: (context, snapshot) {
              // 默认表情列表，在数据加载前或加载失败时使用
              final defaultEmojis = ['👍', '❤️', '😊', '🎉', '🔥', '👀'];

              // 获取表情列表（如果可用）
              final emojiList = snapshot.data ?? defaultEmojis;

              return AlertDialog(
                title: const Text('设置固定符号'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '输入固定符号（通常为表情）',
                      ),
                      maxLength: 2,
                    ),
                    const SizedBox(height: 16),
                    snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              emojiList.map((emoji) {
                                return ElevatedButton(
                                  onPressed: () {
                                    controller.text = emoji;
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    minimumSize: const Size(40, 40),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                );
                              }).toList(),
                        ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      final symbol =
                          controller.text.isEmpty ? null : controller.text;
                      if (symbol != null) {
                        _saveRecentEmoji(symbol);
                      }
                      widget.onSetFixedSymbol(widget.message, symbol);
                      Navigator.of(context).pop();
                    },
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildAvatar(User user, {required bool showAvatar}) {
    // 如果是自己发送的消息，且不显示头像，则返回空的Widget
    if (!showAvatar && widget.message.type == MessageType.sent) {
      return const SizedBox.shrink(); // 不占用任何空间
    }

    Widget avatar;
    if (user.iconPath != null) {
      avatar = CircleAvatar(
        backgroundImage: AssetImage(user.iconPath!),
        radius: 16,
      );
    } else {
      avatar = CircleAvatar(radius: 16, child: Text(user.username[0]));
    }

    return Builder(
      builder:
          (context) => GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(user: user),
                ),
              );
            },
            child: avatar,
          ),
    );
  }
}
