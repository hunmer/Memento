import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/common/memorial_day_card.dart' as common;

/// 纪念日卡片组件
///
/// 用于展示纪念日信息的卡片组件，支持背景颜色、图片、图标和倒计时显示。
/// 提供点击和长按编辑/删除功能。
class MemorialDayCard extends StatelessWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDraggable;

  const MemorialDayCard({
    super.key,
    required this.memorialDay,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果有编辑或删除回调，使用原有组件（保留长按菜单功能）
    if (onEdit != null || onDelete != null) {
      return _MemorialDayCardWithMenu(
        memorialDay: memorialDay,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        isDraggable: isDraggable,
      );
    }

    // 否则使用公共组件
    return common.MemorialDayCardWidget(
      memorialDay: memorialDay,
      onTap: onTap,
      isDraggable: isDraggable,
    );
  }
}

/// 带菜单的纪念日卡片（保留原有长按编辑/删除功能）
class _MemorialDayCardWithMenu extends StatelessWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDraggable;

  const _MemorialDayCardWithMenu({
    required this.memorialDay,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDraggable = false,
  });

  /// 显示底部操作菜单
  void _showBottomSheetMenu(BuildContext context) {
    SmoothBottomSheet.showWithTitle(
      context: context,
      title: memorialDay.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 编辑按钮
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: Text('day_editMemorialDay'.tr),
            onTap: () {
              Navigator.pop(context);
              onEdit?.call();
            },
          ),
          // 删除按钮
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('day_deleteMemorialDay'.tr),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showBottomSheetMenu(context),
      child: common.MemorialDayCardWidget(
        memorialDay: memorialDay,
        onTap: onTap,
        isDraggable: isDraggable,
      ),
    );
  }
}
