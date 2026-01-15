import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 提醒事项数据模型
class ReminderItem {
  /// 提醒文本内容
  final String text;

  /// 是否已完成
  final bool isCompleted;

  const ReminderItem({
    required this.text,
    this.isCompleted = false,
  });

  /// 创建副本
  ReminderItem copyWith({
    String? text,
    bool? isCompleted,
  }) {
    return ReminderItem(
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 从 JSON 创建
  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      text: json['text'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCompleted': isCompleted,
    };
  }
}

/// 提醒列表卡片组件
///
/// 用于显示提醒事项列表，支持动画效果和主题适配。
/// 显示项目总数和列表内容，支持浅色/深色模式切换。
///
/// 使用示例：
/// ```dart
/// ReminderListCard(
///   itemCount: 18,
///   items: [
///     ReminderItem(text: 'Pick up arts & crafts supplies'),
///     ReminderItem(text: 'Send cookie recipe to Rigo'),
///     ReminderItem(text: 'Book club prep'),
///   ],
///   title: 'Reminders',
/// )
/// ```
class ReminderListCard extends StatefulWidget {
  /// 提醒事项总数
  final int itemCount;

  /// 提醒事项列表
  final List<ReminderItem> items;

  /// 标题（可选）
  final String? title;

  /// 宽度（可选）
  final double? width;

  /// 高度（可选）
  final double? height;

  /// 圆角半径（可选）
  final double? borderRadius;

  /// 项目点击回调（可选）
  final ValueChanged<ReminderItem>? onItemTap;

  /// 操作按钮点击回调（可选）
  final VoidCallback? onActionTap;

  const ReminderListCard({
    super.key,
    required this.itemCount,
    required this.items,
    this.title,
    this.width,
    this.height,
    this.borderRadius,
    this.onItemTap,
    this.onActionTap,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ReminderListCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = (props['items'] as List<dynamic>?)
            ?.map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ReminderListCard(
      itemCount: props['itemCount'] as int? ?? itemsList.length,
      items: itemsList,
      title: props['title'] as String?,
    );
  }

  @override
  State<ReminderListCard> createState() => _ReminderListCardState();
}

class _ReminderListCardState extends State<ReminderListCard>
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
              width: widget.width ?? 380,
              height: widget.height ?? 520,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 32),
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
                            onTap: widget.onActionTap,
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
                    child: Stack(
                      children: [
                        ListView.separated(
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
                                      onTap: widget.onItemTap != null
                                          ? () => widget.onItemTap!(item)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
  final VoidCallback? onTap;

  const _ReminderItemTile({
    required this.item,
    required this.textColor,
    required this.borderColor,
    required this.primaryColor,
    this.onTap,
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
        onTap: widget.onTap,
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
