import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/screens/activity_timeline_screen/controllers/activity_controller.dart';
import 'package:Memento/plugins/activity/screens/activity_timeline_screen/controllers/tag_controller.dart';
import 'package:Memento/plugins/activity/screens/activity_timeline_screen/controllers/view_mode_controller.dart';

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
      leading:
          (Platform.isAndroid || Platform.isIOS)
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
      title: Text(
        viewModeController.isGridMode && viewModeController.selectedMinutes > 0
            ? 'activity_minutesSelected'.trParams({
              'minutes': viewModeController.selectedMinutes.toString(),
            })
            : 'activity_activityTimeline'.tr,
      ),
      actions: [
        // 视图切换按钮
        IconButton(
          icon: Icon(
            viewModeController.isGridMode ? Icons.timeline : Icons.grid_on,
          ),
          onPressed: viewModeController.toggleViewMode,
          tooltip:
              viewModeController.isGridMode
                  ? 'activity_switchToTimelineView'.tr
                  : 'activity_switchToGridView'.tr,
        ),
        // 标签管理按钮
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: () => tagController.showTagManagerDialog(context),
          tooltip: 'activity_tagManagement'.tr,
        ),
        // 排序下拉菜单
        PopupMenuButton<int>(
          icon: const Icon(Icons.sort),
          tooltip: 'activity_sortBy'.tr,
          initialValue: activityController.sortMode,
          onSelected: (int index) {
            activityController.setSortMode(index);
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_upward, size: 16),
                      const SizedBox(width: 8),
                      Text('activity_sortByStartTimeAsc'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 8),
                      Text('activity_sortByDuration'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 16),
                      const SizedBox(width: 8),
                      Text('activity_sortByStartTimeDesc'.tr),
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
