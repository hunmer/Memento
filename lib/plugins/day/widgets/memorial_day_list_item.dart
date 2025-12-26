import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/widgets/swipe_action/swipe_action_wrapper.dart';

class MemorialDayListItem extends StatelessWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDraggable;

  const MemorialDayListItem({
    super.key,
    required this.memorialDay,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: _buildLeadingIcon(),
        trailing: isDraggable ? const Icon(Icons.drag_handle) : null,
        title: Text(memorialDay.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(memorialDay.formattedTargetDate),
            Text(
              memorialDay.isExpired
                  ? 'day_daysPassed'.trParams({'count': memorialDay.daysPassed.toString()})
                  : 'day_daysRemaining'.trParams({'count': memorialDay.daysRemaining.toString()}),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ),
    );

    // 在编辑模式下禁用滑动操作
    if (isDraggable) {
      return MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: content,
      );
    }

    // 如果没有配置操作，则不使用滑动包装器
    if (onEdit == null && onDelete == null) {
      return content;
    }

    // 使用滑动操作包装器
    return SwipeActionWrapper(
      // 左边滑出：编辑操作
      leadingActions: [
        SwipeActionPresets.edit(
          label: 'day_editMemorialDay'.tr,
          onTap: () => onEdit?.call(),
        ),
      ],
      // 右边滑出：删除操作
      trailingActions: [
        SwipeActionPresets.delete(
          label: 'day_deleteMemorialDay'.tr,
          onTap: () => onDelete?.call(),
        ),
      ],
      child: content,
    );
  }

  Widget _buildLeadingIcon() {
    // 如果有自定义图标，使用图标
    if (memorialDay.icon != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: memorialDay.iconColor ?? memorialDay.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          memorialDay.icon,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // 否则使用文字占位符
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: memorialDay.backgroundColor,
        shape: BoxShape.circle,
        image: memorialDay.backgroundImageUrl != null
            ? DecorationImage(
                image: NetworkImage(memorialDay.backgroundImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Center(
        child: Text(
          memorialDay.isExpired ? '过' : memorialDay.isToday ? '今' : '待',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (memorialDay.isToday) {
      return Colors.green;
    } else if (memorialDay.isExpired) {
      return Colors.grey;
    } else if (memorialDay.daysRemaining <= 7) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}