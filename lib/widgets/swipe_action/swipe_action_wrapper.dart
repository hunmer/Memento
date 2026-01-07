import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';

/// SwipeAction 配置选项
class SwipeActionOption {
  /// 显示文本
  final String label;

  /// 图标
  final IconData? icon;

  /// 背景颜色
  final Color backgroundColor;

  /// 文本颜色
  final Color textColor;

  /// 点击回调
  final VoidCallback onTap;

  /// 是否为删除操作（会显示确认对话框）
  final bool isDestructive;

  /// 是否使用圆形按钮样式
  final bool useCircleButton;

  /// 圆形按钮大小
  final double circleButtonSize;

  const SwipeActionOption({
    required this.label,
    this.icon,
    this.backgroundColor = Colors.grey,
    this.textColor = Colors.white,
    required this.onTap,
    this.isDestructive = false,
    this.useCircleButton = false,
    this.circleButtonSize = 50,
  });
}

/// SwipeAction 包装器组件
///
/// 封装 flutter_swipe_action_cell 包，提供更简洁的 API
/// 支持左滑和右滑操作，自动处理删除确认对话框
class SwipeActionWrapper extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 左滑操作列表（从左到右显示）
  final List<SwipeActionOption>? leadingActions;

  /// 右滑操作列表（从右到左显示）
  final List<SwipeActionOption>? trailingActions;

  /// 是否启用全滑动执行第一个操作（类似微信）
  /// 设置为 true 时，完全滑动会自动执行第一个操作
  final bool performFirstActionWithFullSwipe;

  /// 删除确认对话框标题
  final String deleteConfirmTitle;

  /// 删除确认对话框内容
  final String deleteConfirmContent;

  /// 编辑模式 - 禁用滑动操作
  final bool isEditMode;

  /// 单元格背景颜色
  final Color? backgroundColor;

  const SwipeActionWrapper({
    super.key,
    required this.child,
    this.leadingActions,
    this.trailingActions,
    this.performFirstActionWithFullSwipe = false,
    this.deleteConfirmTitle = '确认删除',
    this.deleteConfirmContent = '确定要删除此项吗？',
    this.isEditMode = false,
    this.backgroundColor,
  });

  /// 构建滑动操作按钮
  SwipeAction _buildSwipeAction(SwipeActionOption option, BuildContext context, {bool isFirst = false}) {
    // 圆形按钮样式
    if (option.useCircleButton) {
      return SwipeAction(
        color: Colors.transparent,
        content: _buildCircleButton(option),
        performsFirstActionWithFullSwipe: isFirst && performFirstActionWithFullSwipe,
        nestedAction: option.isDestructive
            ? SwipeNestedAction(
                content: _buildNestedConfirmButton(option),
              )
            : null,
        onTap: (handler) async {
          option.onTap();
          await handler(false);
        },
      );
    }

    // 默认矩形按钮样式
    return SwipeAction(
      title: option.label,
      icon: option.icon != null ? Icon(option.icon, color: option.textColor, size: 20) : null,
      style: TextStyle(
        color: option.textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      color: option.backgroundColor,
      performsFirstActionWithFullSwipe: isFirst && performFirstActionWithFullSwipe,
      nestedAction: option.isDestructive
          ? SwipeNestedAction(
              title: deleteConfirmContent,
            )
          : null,
      onTap: (handler) async {
        option.onTap();
        await handler(false);
      },
    );
  }

  /// 构建圆形按钮
  Widget _buildCircleButton(SwipeActionOption option) {
    return Container(
      width: option.circleButtonSize,
      height: option.circleButtonSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(option.circleButtonSize / 2),
        color: option.backgroundColor,
      ),
      child: Icon(
        option.icon ?? Icons.circle,
        color: option.textColor,
        size: option.circleButtonSize * 0.5,
      ),
    );
  }

  /// 构建嵌套确认按钮（圆角矩形）
  Widget _buildNestedConfirmButton(SwipeActionOption option) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: option.backgroundColor,
      ),
      width: 130,
      height: 60,
      child: OverflowBox(
        maxWidth: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon ?? Icons.delete,
              color: option.textColor,
            ),
            const SizedBox(width: 4),
            Text(
              deleteConfirmContent,
              style: TextStyle(
                color: option.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 编辑模式下禁用滑动
    if (isEditMode) {
      return child;
    }

    return SwipeActionCell(
      key: key ?? ObjectKey(this),
      backgroundColor: backgroundColor ?? Colors.transparent,

      // 左滑操作（trailing actions - 从右侧滑出）
      trailingActions: trailingActions?.asMap().entries.map((entry) {
        return _buildSwipeAction(entry.value, context, isFirst: entry.key == 0);
      }).toList(),

      // 右滑操作（leading actions - 从左侧滑出）
      leadingActions: leadingActions?.asMap().entries.map((entry) {
        return _buildSwipeAction(entry.value, context, isFirst: entry.key == 0);
      }).toList(),

      // 子组件
      child: child,
    );
  }
}

/// 预定义的常用操作
class SwipeActionPresets {
  /// 删除操作（红色背景）
  static SwipeActionOption delete({
    required VoidCallback onTap,
    String label = '删除',
    bool showConfirm = true,
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.delete,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      onTap: onTap,
      isDestructive: showConfirm,
    );
  }

  /// 编辑操作（蓝色背景）
  static SwipeActionOption edit({
    required VoidCallback onTap,
    String label = '编辑',
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.edit,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  /// 分享操作（绿色背景）
  static SwipeActionOption share({
    required VoidCallback onTap,
    String label = '分享',
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.share,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  /// 归档操作（橙色背景）
  static SwipeActionOption archive({
    required VoidCallback onTap,
    String label = '归档',
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.archive,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  /// 置顶操作（紫色背景）
  static SwipeActionOption pin({
    required VoidCallback onTap,
    String label = '置顶',
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.push_pin,
      backgroundColor: Colors.purple,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  /// 标记为已读（灰色背景）
  static SwipeActionOption markAsRead({
    required VoidCallback onTap,
    String label = '已读',
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.done,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      onTap: onTap,
    );
  }

  /// 更多操作（深灰色背景）
  static SwipeActionOption more({
    required VoidCallback onTap,
    String label = '更多',
  }) {
    return SwipeActionOption(
      label: label,
      icon: Icons.more_horiz,
      backgroundColor: Colors.grey.shade700,
      textColor: Colors.white,
      onTap: onTap,
    );
  }
}
