import 'package:flutter/material.dart';

/// 新闻更新卡片示例
class NewsUpdateCardExample extends StatelessWidget {
  const NewsUpdateCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('新闻更新卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: NewsUpdateCardWidget(
            icon: Icons.bolt,
            title: '"I confess." The Belarusian pro-governmental telegram channel published a video of Roman Protasevich',
            timestamp: '4 minutes ago',
            currentIndex: 0,
            totalItems: 4,
          ),
        ),
      ),
    );
  }
}

/// 新闻更新数据模型
class NewsUpdateData {
  final String title;
  final String timestamp;

  const NewsUpdateData({
    required this.title,
    required this.timestamp,
  });
}

/// 新闻更新卡片小组件
class NewsUpdateCardWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String timestamp;
  final int currentIndex;
  final int totalItems;
  final VoidCallback? onTap;

  const NewsUpdateCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.timestamp,
    this.currentIndex = 0,
    this.totalItems = 4,
    this.onTap,
  });

  @override
  State<NewsUpdateCardWidget> createState() => _NewsUpdateCardWidgetState();
}

class _NewsUpdateCardWidgetState extends State<NewsUpdateCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final iconBackgroundColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black;
    final timestampColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    // 适配主题颜色 - 橙色可以保留原型颜色，因为它与其他主题色有差异
    final primaryColor = isDark
        ? const Color(0xFFFF9F0A)  // iOS System Orange
        : Theme.of(context).colorScheme.primary == const Color(0xFFFF9F0A)
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFFF9F0A);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * _slideAnimation.value.dy),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 340,
                constraints: const BoxConstraints(
                  minHeight: 170,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部行：图标和分页指示器
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图标容器
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: iconBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        // 分页指示器
                        Expanded(
                          child: _buildPaginationIndicator(
                            currentIndex: widget.currentIndex,
                            totalItems: widget.totalItems,
                            activeColor: textColor,
                            inactiveColor: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 标题
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 时间戳
                    Text(
                      widget.timestamp,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: timestampColor,
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

  /// 构建分页指示器
  Widget _buildPaginationIndicator({
    required int currentIndex,
    required int totalItems,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(totalItems, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == currentIndex ? activeColor : inactiveColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
