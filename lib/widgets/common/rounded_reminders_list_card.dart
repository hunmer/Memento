import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 提醒事项数据模型
class ReminderItem {
  /// 提醒文本内容
  final String text;

  /// 是否已完成
  final bool isCompleted;

  const ReminderItem({required this.text, this.isCompleted = false});

  /// 创建副本
  ReminderItem copyWith({String? text, bool? isCompleted}) {
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
    return {'text': text, 'isCompleted': isCompleted};
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
///   size: const MediumSize(),
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
  /// 小组件尺寸
  final HomeWidgetSize size;

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

  /// 项目点击回调（可选）
  final ValueChanged<ReminderItem>? onItemTap;

  /// 操作按钮点击回调（可选）
  final VoidCallback? onActionTap;

  /// 复选框状态变更回调（可选）
  final ValueChanged<int>? onCheckboxChanged;

  const ReminderListCard({
    super.key,
    required this.itemCount,
    required this.items,
    this.title,
    this.width,
    this.height,
    this.onItemTap,
    this.onActionTap,
    this.onCheckboxChanged,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ReminderListCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList =
        (props['items'] as List<dynamic>?)
            ?.map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ReminderListCard(
      size: size,
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

    // 根据 size 计算尺寸
    final padding = widget.size.getPadding();
    final subtitleFontSize = widget.size.getSubtitleFontSize();
    final largeFontSize = widget.size.getLargeFontSize() * 0.8;
    final iconSize = widget.size.getIconSize();
    final smallSpacing = widget.size.getSmallSpacing();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
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
                    padding: padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: largeFontSize + smallSpacing * 2,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  AnimatedFlipCounter(
                                    value:
                                        widget.itemCount.toDouble() *
                                        _animation.value,
                                    textStyle: TextStyle(
                                      color: textColor,
                                      fontSize: largeFontSize,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: smallSpacing),
                            SizedBox(
                              height: subtitleFontSize + smallSpacing,
                              child: Text(
                                widget.title ?? 'Reminders',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Material(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(iconSize * 0.8),
                          child: InkWell(
                            onTap: widget.onActionTap,
                            borderRadius: BorderRadius.circular(iconSize * 0.8),
                            child: Container(
                              width: iconSize * 1.8,
                              height: iconSize * 1.8,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.format_list_bulleted_rounded,
                                color: Colors.white,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 分隔线
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding.left),
                    child: Container(
                      height: smallSpacing * 0.5,
                      color: dividerColor,
                    ),
                  ),
                  // 列表区域
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            padding.left,
                            smallSpacing,
                            padding.right,
                            smallSpacing,
                          ),
                          itemCount: widget.items.length,
                          separatorBuilder:
                              (context, index) => Padding(
                                padding: EdgeInsets.only(
                                  left: iconSize * 2 + smallSpacing * 2,
                                  top: 0,
                                  bottom: 0,
                                ),
                                child: Container(
                                  height: smallSpacing * 0.5,
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
                                      size: widget.size,
                                      textColor: textColor,
                                      borderColor: borderColor,
                                      primaryColor: primaryColor,
                                      onTap:
                                          widget.onItemTap != null
                                              ? () => widget.onItemTap!(item)
                                              : null,
                                      onCheckboxChanged:
                                          widget.onCheckboxChanged != null
                                              ? (completed) => widget
                                                  .onCheckboxChanged!(index)
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
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Container(
                              height: iconSize * 2,
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
  final HomeWidgetSize size;
  final Color textColor;
  final Color borderColor;
  final Color primaryColor;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onCheckboxChanged;

  const _ReminderItemTile({
    required this.item,
    required this.size,
    required this.textColor,
    required this.borderColor,
    required this.primaryColor,
    this.onTap,
    this.onCheckboxChanged,
  });

  @override
  State<_ReminderItemTile> createState() => _ReminderItemTileState();
}

class _ReminderItemTileState extends State<_ReminderItemTile> {
  bool _isHoveringCheckbox = false;

  @override
  Widget build(BuildContext context) {
    // 根据 size 计算尺寸
    final iconSize = widget.size.getIconSize();
    final checkboxSize = iconSize * 0.9;
    final smallSpacing = widget.size.getSmallSpacing();
    final fontSize = widget.size.getSubtitleFontSize() + 1;
    final spacingBetween = iconSize * 0.7;
    final isCompleted = widget.item.isCompleted;

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: smallSpacing * 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 圆形复选框
            Padding(
              padding: EdgeInsets.only(top: smallSpacing),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHoveringCheckbox = true),
                onExit: (_) => setState(() => _isHoveringCheckbox = false),
                child: GestureDetector(
                  onTap: () {
                    if (widget.onCheckboxChanged != null) {
                      widget.onCheckboxChanged!(!isCompleted);
                    }
                  },
                  child: Container(
                    width: checkboxSize,
                    height: checkboxSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isCompleted
                              ? widget.primaryColor
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            _isHoveringCheckbox
                                ? widget.primaryColor
                                : (isCompleted
                                    ? widget.primaryColor
                                    : widget.borderColor),
                        width: 1.5,
                      ),
                    ),
                    child:
                        isCompleted
                            ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: checkboxSize * 0.6,
                            )
                            : null,
                  ),
                ),
              ),
            ),
            SizedBox(width: spacingBetween),
            // 文本内容
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: smallSpacing * 2),
                child: Text(
                  widget.item.text,
                  style: TextStyle(
                    color:
                        isCompleted
                            ? widget.textColor.withOpacity(0.5)
                            : widget.textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
