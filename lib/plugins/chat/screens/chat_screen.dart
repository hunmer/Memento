import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:Memento/plugins/chat/models/user.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'chat_screen/widgets/message_bubble.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';

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
    return SuperCupertinoNavigationWrapper(
      title: Text('chat_chatRoom'.tr),
      largeTitle: 'chat_chatRoom'.tr,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
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
        ],
      ),
      enableBottomBar: true,
      bottomBarHeight: 60,
      bottomBarChild: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {}, // 表情功能预留
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'chat_enterMessage'.tr,
                    border: InputBorder.none,
                  ),
                  onSubmitted: _handleSubmitted,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ],
          ),
        ),
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
