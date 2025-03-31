import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../utils/date_formatter.dart';
import '../screens/user_profile_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(Message) onEdit;
  final Function(Message) onDelete;
  final Function(Message) onCopy;
  final Function(Message, String?) onSetFixedSymbol;
  final Color? channelColor; // 添加频道颜色参数

  const MessageBubble({
    super.key,
    required this.message,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
    required this.onSetFixedSymbol,
    this.channelColor, // 可选的频道颜色参数
  });

  @override
  Widget build(BuildContext context) {
    final isSentMessage = message.type == MessageType.sent;
    // 使用频道颜色或默认颜色
    final backgroundColor =
        isSentMessage
            ? (channelColor ?? Theme.of(context).colorScheme.primary)
            : Colors.grey.shade200;

    // 根据背景色亮度自动调整文字颜色
    final textColor =
        isSentMessage
            ? (channelColor != null
                ? (channelColor!.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white)
                : Colors.white)
            : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isSentMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSentMessage) _buildAvatar(message.user, showAvatar: true),
          if (!isSentMessage) const SizedBox(width: 8),
          if (message.fixedSymbol != null && !isSentMessage)
            _buildFixedSymbol(),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSentMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(color: textColor),
                        ),
                        if (message.isEdited)
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
                ),
                if (message.fixedSymbol != null && isSentMessage)
                  _buildFixedSymbol(),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    DateFormatter.formatDateTime(message.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (isSentMessage) const SizedBox(width: 8),
          if (isSentMessage) _buildAvatar(message.user, showAvatar: false),
        ],
      ),
    );
  }

  Widget _buildFixedSymbol() {
    return Container(
      margin: EdgeInsets.only(
        left: message.type == MessageType.sent ? 4 : 0,
        right: message.type == MessageType.received ? 4 : 0,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(message.fixedSymbol!, style: const TextStyle(fontSize: 12)),
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
                  onEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('删除消息'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制消息'),
                onTap: () {
                  Navigator.pop(context);
                  onCopy(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: Text('${message.fixedSymbol == null ? '设置' : '移除'}固定符号'),
                onTap: () {
                  Navigator.pop(context);
                  _showSetFixedSymbolDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetFixedSymbolDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: message.fixedSymbol,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('设置固定符号'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: '输入固定符号（通常为表情）'),
                  maxLength: 2,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      ['👍', '❤️', '😊', '🎉', '🔥', '👀'].map((emoji) {
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
                  onSetFixedSymbol(message, symbol);
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  Widget _buildAvatar(User user, {required bool showAvatar}) {
    // 如果是自己发送的消息，且不显示头像，则返回空的SizedBox
    if (!showAvatar && message.type == MessageType.sent) {
      return const SizedBox(width: 32); // 保持宽度一致，但不显示头像
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
