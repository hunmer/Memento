import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 圆角提醒事项列表卡片示例
class RoundedRemindersListExample extends StatelessWidget {
  const RoundedRemindersListExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角提醒事项列表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: RoundedRemindersListWidget(
            itemCount: 18,
            items: [
              ReminderItem(text: 'Pick up arts & crafts supplies'),
              ReminderItem(text: 'Send cookie recipe to Rigo'),
              ReminderItem(text: 'Book club prep'),
              ReminderItem(text: 'Hike with Darla'),
              ReminderItem(text: 'Schedule car maintenance'),
              ReminderItem(text: 'Cancel membership'),
              ReminderItem(text: 'Check spare tire'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 提醒事项数据模型
class ReminderItem {
  final String text;
  final bool isCompleted;

  const ReminderItem({required this.text, this.isCompleted = false});
}

/// 圆角提醒事项列表小组件
class RoundedRemindersListWidget extends StatefulWidget {
  final int itemCount;
  final List<ReminderItem> items;
  final String? title;

  const RoundedRemindersListWidget({
    super.key,
    required this.itemCount,
    required this.items,
    this.title,
  });

  @override
  State<RoundedRemindersListWidget> createState() =>
      _RoundedRemindersListWidgetState();
}

class _RoundedRemindersListWidgetState extends State<RoundedRemindersListWidget>
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
    final primaryColor = Theme.of(context).colorScheme.error;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor =
        isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8);
    final dividerColor =
        isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 380,
              height: 520,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 标题区域
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 58,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 140,
                                    height: 56,
                                    child: AnimatedFlipCounter(
                                      value:
                                          widget.itemCount.toDouble() *
                                          _animation.value,
                                      textStyle: TextStyle(
                                        color: textColor,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 22,
                              child: Text(
                                widget.title ?? 'Reminders',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Material(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.format_list_bulleted_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 分隔线
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(height: 1, color: dividerColor),
                  ),
                  // 列表区域
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      itemCount: widget.items.length,
                      separatorBuilder:
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(
                              left: 42,
                              top: 0,
                              bottom: 0,
                            ),
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        isDark
                                            ? const Color(0xFF48484A)
                                            : const Color(0xFFE5E5EA),
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final itemAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            index * 0.08,
                            0.4 + index * 0.08,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                        return AnimatedBuilder(
                          animation: itemAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: itemAnimation.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  10 * (1 - itemAnimation.value),
                                ),
                                child: _ReminderItemTile(
                                  item: item,
                                  textColor: textColor,
                                  borderColor: borderColor,
                                  primaryColor: primaryColor,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // 底部渐变遮罩
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            backgroundColor.withOpacity(0),
                            backgroundColor,
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

/// 单个提醒事项项
class _ReminderItemTile extends StatefulWidget {
  final ReminderItem item;
  final Color textColor;
  final Color borderColor;
  final Color primaryColor;

  const _ReminderItemTile({
    required this.item,
    required this.textColor,
    required this.borderColor,
    required this.primaryColor,
  });

  @override
  State<_ReminderItemTile> createState() => _ReminderItemTileState();
}

class _ReminderItemTileState extends State<_ReminderItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 圆形复选框
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          _isHovered ? widget.primaryColor : widget.borderColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 文本内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.item.text,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
