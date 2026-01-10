import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 邮件/消息列表卡片示例
class MessageListCardExample extends StatelessWidget {
  const MessageListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('邮件列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MessageListCardWidget(
            messages: [
              MessageData(
                sender: 'Kenzie Lawson',
                subject: 'Meeting Reminder',
                preview: 'Hi Adi, Just a reminder that we have a meeting...',
                time: '9:03 AM',
              ),
              MessageData(
                sender: 'ByteWorks Support',
                subject: 'Account Update',
                preview: 'Your account information has been updated....',
                time: '8:59 AM',
              ),
              MessageData(
                sender: 'Nevaeh Simmons',
                subject: 'Invitation to Networking Event',
                preview: "Hi Adi, I'm inviting you to a networking event tha...",
                time: '8:45 AM',
              ),
              MessageData(
                sender: 'Heelz Footwear',
                subject: 'Special Offer',
                preview: 'Get 20% off your next purchase when you use...',
                time: '8:40 AM',
              ),
            ],
            totalCount: 1064,
            title: 'All Inboxes',
          ),
        ),
      ),
    );
  }
}

/// 消息数据模型
class MessageData {
  final String sender;
  final String subject;
  final String preview;
  final String time;

  const MessageData({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
  });
}

/// 邮件/消息列表小组件
class MessageListCardWidget extends StatefulWidget {
  final List<MessageData> messages;
  final int totalCount;
  final String title;

  const MessageListCardWidget({
    super.key,
    required this.messages,
    required this.totalCount,
    this.title = 'All Inboxes',
  });

  @override
  State<MessageListCardWidget> createState() => _MessageListCardWidgetState();
}

class _MessageListCardWidgetState extends State<MessageListCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.all_inbox,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                        AnimatedFlipCounter(
                          value: widget.totalCount.toDouble(),
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 消息列表
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.messages.length,
                        (index) {
                          final itemAnimation = CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.08,
                              0.5 + index * 0.08,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return _MessageItemWidget(
                            message: widget.messages[index],
                            animation: itemAnimation,
                            isLast: index == widget.messages.length - 1,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 消息列表项组件
class _MessageItemWidget extends StatelessWidget {
  final MessageData message;
  final Animation<double> animation;
  final bool isLast;
  final bool isDark;

  const _MessageItemWidget({
    required this.message,
    required this.animation,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animation.value)),
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFE5E5EA),
                        ),
                      ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          message.sender,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        message.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.subject,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.grey.shade200
                          : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.preview,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
