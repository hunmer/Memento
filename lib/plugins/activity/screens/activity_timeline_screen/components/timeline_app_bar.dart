import 'package:flutter/material.dart';
import '../controllers/activity_controller.dart';
import '../controllers/tag_controller.dart';
import '../controllers/view_mode_controller.dart';

class TimelineAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TagController tagController;
  final ActivityController activityController;
  final ViewModeController viewModeController;

  const TimelineAppBar({
    super.key,
    required this.tagController,
    required this.activityController,
    required this.viewModeController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // 添加返回按钮
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(viewModeController.isGridMode && viewModeController.selectedMinutes > 0
          ? '${viewModeController.selectedMinutes}分钟已选中'
          : '活动时间线'),
      actions: [
        // 视图切换按钮
        IconButton(
          icon: Icon(viewModeController.isGridMode ? Icons.timeline : Icons.grid_on),
          onPressed: viewModeController.toggleViewMode,
          tooltip: viewModeController.isGridMode ? '切换到时间线视图' : '切换到网格视图',
        ),
        // 标签管理按钮
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: () => tagController.showTagManagerDialog(context),
          tooltip: '标签管理',
        ),
        // 排序下拉菜单
        PopupMenuButton<int>(
          icon: const Icon(Icons.sort),
          tooltip: '排序方式',
          initialValue: activityController.sortMode,
          onSelected: (int index) {
            activityController.setSortMode(index);
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 16),
                      SizedBox(width: 8),
                      Text('按开始时间升序'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16),
                      SizedBox(width: 8),
                      Text('按活动时长排序'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, size: 16),
                      SizedBox(width: 8),
                      Text('按开始时间降序'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}