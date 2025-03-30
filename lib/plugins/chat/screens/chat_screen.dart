import 'package:flutter/material.dart';
import 'dart:math';
import '../models/user.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 定义两个测试用户
  final User currentUser = const User(id: '1', username: '我', iconPath: null);
  final User otherUser = const User(id: '2', username: '小明', iconPath: null);

  @override
  void initState() {
    super.initState();
    // 初始化时随机生成一些消息
    final random = Random();
    final List<String> sampleMessages = [
      '你好！',
      '今天天气真不错',
      'Flutter开发真有趣',
      '周末要出去玩吗？',
      '项目进展如何？',
    ];

    for (int i = 0; i < 10; i++) {
      final isReceived = random.nextBool();
      _messages.insert(
        0, // 在列表开头插入示例消息
        Message(
          content: sampleMessages[random.nextInt(sampleMessages.length)],
          user: isReceived ? otherUser : currentUser,
          type: isReceived ? MessageType.received : MessageType.sent,
          date: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
        ),
      );
    }
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(
        0, // 在列表开头插入新消息
        Message(content: text, user: currentUser, type: MessageType.sent),
      );
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('聊天室'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true, // 从底部开始显示
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
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
                        hintText: '输入消息...',
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