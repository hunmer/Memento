import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 消息列表卡片示例
class MessageListCardExample extends StatelessWidget {
  const MessageListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('消息列表卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        child: const Center(
          child: MessageListCardWidget(
            featuredMessage: FeaturedMessageData(
              sender: '系统通知',
              title: '欢迎使用 Memento',
              summary:
                  '感谢您选择 Memento 作为您的个人数据管理助手。在这里您可以...',
              avatarUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
            ),
            messages: [
              MessageData(
                title: '欢迎使用日记功能',
                sender: '小助手',
                channel: '系统消息',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
              ),
              MessageData(
                title: '今日习惯打卡提醒',
                sender: '习惯追踪',
                channel: '提醒',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
              ),
              MessageData(
                title: '数据同步已完成',
                sender: '同步服务',
                channel: '系统',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
              ),
              MessageData(
                title: '新功能介绍：智能数据分析',
                sender: '产品团队',
                channel: '更新',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuD6KABFHDvf-OJ91ym-BlBCJyQVOu9huxnIKUqO8Nb83qArhaBdHRLZWt94nmuaqXVP9oIkm7sY6pPYnHfiTXCkR3Knd4HvSuKL4C1yvVVnugUhs-J3hE3SQ4eFYdY9sF2ohcMhKYWCzJXXOVZlzNUhTQ1ic3nxjb9fmcptTNGNt-m_ECB8WyDin6UL1OlyIO9bux7XIaNrdxS_xRMvbWsGG7J3xknpg2ltFkipD7HXbdfqjVQqO_J-gpbDcA1OGSpFkxwDVlukQWq6',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 置顶消息数据模型
class FeaturedMessageData {
  final String sender;
  final String title;
  final String summary;
  final String avatarUrl;

  const FeaturedMessageData({
    required this.sender,
    required this.title,
    required this.summary,
    required this.avatarUrl,
  });

  /// 从 JSON 创建
  factory FeaturedMessageData.fromJson(Map<String, dynamic> json) {
    return FeaturedMessageData(
      sender: json['sender'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'title': title,
      'summary': summary,
      'avatarUrl': avatarUrl,
    };
  }
}

/// 普通消息数据模型
class MessageData {
  final String title;
  final String sender;
  final String channel;
  final String avatarUrl;

  const MessageData({
    required this.title,
    required this.sender,
    required this.channel,
    required this.avatarUrl,
  });

  /// 从 JSON 创建
  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      title: json['title'] as String? ?? '',
      sender: json['sender'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sender': sender,
      'channel': channel,
      'avatarUrl': avatarUrl,
    };
  }
}

/// 消息列表卡片小组件
class MessageListCardWidget extends StatefulWidget {
  final FeaturedMessageData featuredMessage;
  final List<MessageData> messages;

  const MessageListCardWidget({
    super.key,
    required this.featuredMessage,
    required this.messages,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MessageListCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final featuredMessageJson = props['featuredMessage'] as Map<String, dynamic>?;
    final messagesJson = props['messages'] as List<dynamic>?;

    return MessageListCardWidget(
      featuredMessage: featuredMessageJson != null
          ? FeaturedMessageData.fromJson(featuredMessageJson)
          : const FeaturedMessageData(
              sender: '',
              title: '',
              summary: '',
              avatarUrl: '',
            ),
      messages: messagesJson
              ?.map((e) => MessageData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: 375,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FeaturedSection(
                data: widget.featuredMessage,
                animation: _animation,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MessageListSection(
                messages: widget.messages,
                animation: _animation,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 置顶消息区域
class _FeaturedSection extends StatelessWidget {
  final FeaturedMessageData data;
  final Animation<double> animation;

  const _FeaturedSection({required this.data, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final sectionAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: sectionAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: sectionAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - sectionAnimation.value)),
                child: Row(
                  children: [
                    Icon(
                      Icons.push_pin,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PINNED MESSAGE',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: sectionAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: sectionAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - sectionAnimation.value)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        data.avatarUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.message,
                              color:
                                  isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.sender.toUpperCase(),
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.title,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFFF9FAFB)
                                      : const Color(0xFF111827),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 消息列表区域
class _MessageListSection extends StatelessWidget {
  final List<MessageData> messages;
  final Animation<double> animation;

  const _MessageListSection({required this.messages, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final headerAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
            );
            return Opacity(
              opacity: headerAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - headerAnimation.value)),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      color:
                          isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RECENT MESSAGES',
                      style: TextStyle(
                        color:
                            isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ...List.generate(messages.length, (index) {
          return _MessageListItem(
            data: messages[index],
            animation: animation,
            index: index,
          );
        }),
      ],
    );
  }
}

/// 消息列表项
class _MessageListItem extends StatelessWidget {
  final MessageData data;
  final Animation<double> animation;
  final int index;

  const _MessageListItem({
    required this.data,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.2 + index * 0.1,
        0.6 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data.avatarUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 24,
                            color:
                                isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFFF9FAFB)
                                    : const Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.sender} · ${data.channel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
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
