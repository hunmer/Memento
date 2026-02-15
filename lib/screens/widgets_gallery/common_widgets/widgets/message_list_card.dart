import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const MessageListCardWidget({
    super.key,
    required this.featuredMessage,
    required this.messages,
    this.inline = false,
    this.size = const MediumSize(),
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
      inline: props['inline'] as bool? ?? false,
      size: size,
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
        width: widget.inline ? double.maxFinite : 375,
        height: widget.inline ? double.maxFinite : 600,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: widget.size.getPadding().top),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size.getPadding().left),
              child: _FeaturedSection(
                data: widget.featuredMessage,
                animation: _animation,
                size: widget.size,
              ),
            ),
            SizedBox(height: widget.size.getTitleSpacing()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size.getPadding().left),
              child: _MessageListSection(
                messages: widget.messages,
                animation: _animation,
                size: widget.size,
              ),
            ),
            SizedBox(height: widget.size.getPadding().bottom),
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
  final HomeWidgetSize size;

  const _FeaturedSection({
    required this.data,
    required this.animation,
    required this.size,
  });

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
                        width: size.getIconSize() * 3,
                        height: size.getIconSize() * 3,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: size.getIconSize() * 3,
                            height: size.getIconSize() * 3,
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
                    SizedBox(width: size.getItemSpacing()),
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
                              fontSize: size.getLegendFontSize() - 2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: size.getSmallSpacing()),
                          Text(
                            data.title,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFFF9FAFB)
                                      : const Color(0xFF111827),
                              fontSize: size.getTitleFontSize(),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: size.getSmallSpacing()),
                          Text(
                            data.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                              fontSize: size.getLegendFontSize(),
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
  final HomeWidgetSize size;

  const _MessageListSection({
    required this.messages,
    required this.animation,
    required this.size,
  });

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
                      size: size.getIconSize() * 0.7,
                    ),
                    SizedBox(width: size.getSmallSpacing()),
                    Text(
                      'RECENT MESSAGES',
                      style: TextStyle(
                        color:
                            isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                        fontSize: size.getLegendFontSize() - 2,
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
        SizedBox(height: size.getItemSpacing()),
        Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(messages.length, (index) {
                return _MessageListItem(
                  data: messages[index],
                  animation: animation,
                  index: index,
                  size: size,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// 消息列表项
class _MessageListItem extends StatelessWidget {
  final MessageData data;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _MessageListItem({
    required this.data,
    required this.animation,
    required this.index,
    required this.size,
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
              padding: EdgeInsets.only(bottom: size.getItemSpacing()),
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
