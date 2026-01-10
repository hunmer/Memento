import 'package:flutter/material.dart';

/// 收件箱消息卡片示例
class InboxMessageCardExample extends StatelessWidget {
  const InboxMessageCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收件箱消息卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: InboxMessageCardWidget(
            messages: [
              InboxMessage(
                name: 'Salomé Fernán',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                preview: 'How to write advertising article',
                timeAgo: '7 mins ago',
              ),
              InboxMessage(
                name: 'Thanawan Chadee',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDgq5z45_Cg4VhucQoqYGbnnnWGIFykRGb6DPyERRy5bNlYDz_rkyrjtirFhKkgHDXdVXQaMWObeqlm_XioaOJKwDh7mdOXp9UXuLU2bJYke-zLsBqaM5S0kAN8odZ1ojbRq3qRGx5ymmmcflxhwH-6CzL7O8JFfFw1AGYAXNJvHBS9Yvx8P7E758IfBlwIhfp4SpPNUr2iX6ZGBduJ7rmMxEfcn66g6eb3ws4ku0O-otr6Q8jaG2VqeXLSXIpDJPzn90Ycyci8mQ',
                preview: 'Addiction when gambling becomes',
                timeAgo: '10 mins ago',
              ),
              InboxMessage(
                name: 'Diego Morata',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDaBru40HzWPZQazW01u0WkfKyUUs35h33Pfyxxy1gqOIG_TfQoNxMGogpJMtDkiJCPKXB7AehTpjit7GxToJ0bJgL-kWSh9ARe8FYsfWW1jK0sKa3echRSU4koNMhJ_1RXHPkcH8JFbcllw0vF7dOKy_ROFaARuZmy4kOt3Xf-buwnLo6l6nrXhC3ULp1za05sU8rA58bpaFKhX2TqOu5bf16SUZ_ESL0pdGBgPVtpXWAv6RP5-i5sMS6EOlnLBHimsEY79g5hiQ',
                preview: 'Baby monitor technology',
                timeAgo: '20 mins ago',
              ),
              InboxMessage(
                name: 'Neville Griffin',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBUqxBeN7cxqIwcJb4LqqvBXGrQVfeHVLHyg7hVqINu-wj6H5tU9DmCeSNd54MxDNwPAOamdWW5N2X9PDVhG5wW65aL3B8PF5wjYkEYGuN34Yh53bm3OhdrwvaFcRK_286t6oSU0WjXe8QsBpBRhl_ESbXyu1jEBqr9TUF__pvfk43riThGAy7eBv6HdJPq4ZtyMsHl6mU1119WKB6bsQKYcfugjqs7Qnzwi6gyJoOiHVLCzX_Skgn8kmqKShwzTN-mF6-kI6er9w',
                preview: 'Protective preventative maintenance',
                timeAgo: '30 mins ago',
              ),
              InboxMessage(
                name: 'Izabella Tabakova',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2X8X-E5vDfF4d7kbU0_r_3_quLc92NGoC8gsY26g3lEuiaTw1Ol7-8RTtKZ2RVurnF4faslqwgchUXkbEo_7QVzW8pQjoPUk66ZFr7pCuy5kdy4T91WfvgyadQs0ayrSUNRkdntQRDdM9V-2hyfcdmbEjc80f9Bocvu2mMHHshxwMxWf6_J2sySNt22MyzwKDPkTU1nYQ9aZYBbLE7DI9EdgUBBl7I8LTsFKq52vzhIgk_kjBNd2T9vNEtuhe9lpphSL1KNle5A',
                preview: 'Finally a top secret way for marketing',
                timeAgo: '1 hr ago',
              ),
            ],
            totalCount: 16,
            remainingCount: 11,
          ),
        ),
      ),
    );
  }
}

/// 收件箱消息数据模型
class InboxMessage {
  final String name;
  final String avatarUrl;
  final String preview;
  final String timeAgo;

  const InboxMessage({
    required this.name,
    required this.avatarUrl,
    required this.preview,
    required this.timeAgo,
  });
}

/// 收件箱消息小组件
class InboxMessageCardWidget extends StatefulWidget {
  final List<InboxMessage> messages;
  final int totalCount;
  final int remainingCount;
  final VoidCallback? onMoreTap;

  const InboxMessageCardWidget({
    super.key,
    required this.messages,
    required this.totalCount,
    required this.remainingCount,
    this.onMoreTap,
  });

  @override
  State<InboxMessageCardWidget> createState() => _InboxMessageCardWidgetState();
}

class _InboxMessageCardWidgetState extends State<InboxMessageCardWidget>
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

    // 主色调从原型的橙色 (#FBBF57)
    const primaryColor = Color(0xFFFBBF57);

    // 背景色
    final backgroundColor = isDark ? const Color(0xFF374151) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final subTextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dividerColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 340,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.inbox,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Inbox',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.totalCount.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 消息列表
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < widget.messages.length; i++) ...[
                          if (i > 0) const SizedBox(height: 4),
                          _MessageItem(
                            message: widget.messages[i],
                            textColor: textColor,
                            subTextColor: subTextColor,
                            dividerColor: dividerColor,
                            isLast: i == widget.messages.length - 1,
                            animation: _animation,
                            index: i,
                          ),
                        ],
                        const SizedBox(height: 16),
                        // 更多按钮
                        GestureDetector(
                          onTap: widget.onMoreTap,
                          child: Text(
                            '+${widget.remainingCount} more',
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
class _MessageItem extends StatelessWidget {
  final InboxMessage message;
  final Color textColor;
  final Color subTextColor;
  final Color dividerColor;
  final bool isLast;
  final Animation<double> animation;
  final int index;

  const _MessageItem({
    required this.message,
    required this.textColor,
    required this.subTextColor,
    required this.dividerColor,
    required this.isLast,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // 为每个列表项创建延迟动画
    final step = 0.08;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * step,
        0.6 + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? const Color(0xFF374151) : Colors.white;

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: dividerColor,
                          width: 1,
                        ),
                      ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ringColor,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          message.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 内容
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  message.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                message.timeAgo,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.preview,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
