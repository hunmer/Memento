import 'package:flutter/material.dart';
import 'dart:math';
import '../l10n/chat_localizations.dart';
import '../models/user.dart';
import '../models/message.dart';
import 'chat_screen/widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final User currentUser = const User(id: '1', username: '我', iconPath: null);
  final Random _random = Random();

  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1000)}';
  }

  @override
  void initState() {
    super.initState();
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(
        0, // 在列表开头插入新消息
        Message(
          id: _generateMessageId(),
          content: text,
          user: currentUser,
          type: MessageType.sent,
        ),
      );
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ChatLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatRoom), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true, // 从底部开始显示
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message,
                  isSelected: false,
                  isMultiSelectMode: false,
                  onEdit: () {},
                  onDelete: () {},
                  onCopy: () {},
                  onSetFixedSymbol: (_) {},
                  showAvatar: true,
                  currentUserId: currentUser.id,
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.emoji_emotions),
                    onPressed: () {}, // 表情功能预留
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: l10n.enterMessage,
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
