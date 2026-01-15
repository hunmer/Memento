import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 收件箱消息数据模型
class InboxMessage {
  final String name;
  final String avatarUrl;
  final String preview;
  final String timeAgo;
  /// 图标 codePoint（可选，优先于 avatarUrl 使用）
  final int? iconCodePoint;

  /// 图标背景颜色（可选，配合 iconCodePoint 使用）
  final int? iconBackgroundColor;

  const InboxMessage({
    required this.name,
    required this.avatarUrl,
    required this.preview,
    required this.timeAgo,
    this.iconCodePoint,
    this.iconBackgroundColor,
  });

  /// 从 JSON 创建（用于公共小组件系统）
  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    return InboxMessage(
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int?,
      iconBackgroundColor: json['iconBackgroundColor'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'preview': preview,
      'timeAgo': timeAgo,
      'iconCodePoint': iconCodePoint,
      'iconBackgroundColor': iconBackgroundColor,
    };
  }
}

/// 收件箱消息小组件
class InboxMessageCardWidget extends StatefulWidget {
  final List<InboxMessage> messages;
  final int totalCount;
  final int remainingCount;
  final VoidCallback? onMoreTap;
  final String? title; // 可配置标题
  final Color? primaryColor; // 可配置主色调

  const InboxMessageCardWidget({
    super.key,
    required this.messages,
    required this.totalCount,
    required this.remainingCount,
    this.onMoreTap,
    this.title,
    this.primaryColor,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory InboxMessageCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final messagesList = (props['messages'] as List<dynamic>?)
            ?.map((e) => InboxMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return InboxMessageCardWidget(
      messages: messagesList,
      totalCount: props['totalCount'] as int? ?? 0,
      remainingCount: props['remainingCount'] as int? ?? 0,
      title: props['title'] as String?,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
    );
  }

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

    // 主色调（可配置，默认橙色 #FBBF57）
    final primaryColor = widget.primaryColor ?? const Color(0xFFFBBF57);

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
                borderRadius: BorderRadius.circular(8),
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
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
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
                              widget.title ?? 'Inbox',
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
                  // 消息列表（支持滚动）
                  SizedBox(
                    height: 240,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: SingleChildScrollView(
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
                                style: TextStyle(
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

  /// 构建头像或图标
  Widget _buildAvatarOrIcon(InboxMessage message) {
    // 优先使用图标
    if (message.iconCodePoint != null) {
      final backgroundColor =
          message.iconBackgroundColor != null
              ? Color(message.iconBackgroundColor!)
              : Colors.grey.shade300;
      return Container(
        color: backgroundColor,
        child: Icon(
          IconData(message.iconCodePoint!, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // 如果有 avatarUrl，加载网络图片
    if (message.avatarUrl.isNotEmpty) {
      return Image.network(
        message.avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.grey.shade600),
          );
        },
      );
    }

    // 默认图标
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, color: Colors.grey),
    );
  }

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
                    // 头像或图标
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
                        child: _buildAvatarOrIcon(message),
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
