import 'dart:io' show Platform;
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/diary/l10n/diary_localizations.dart';
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
      automaticallyImplyLeading: false,
      leading:
          (Platform.isAndroid || Platform.isIOS)
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
      title: Text(
        viewModeController.isGridMode && viewModeController.selectedMinutes > 0
            ? DiaryLocalizations.of(context).minutesSelected.replaceAll(
              '{minutes}',
              viewModeController.selectedMinutes.toString(),
            )
            : DiaryLocalizations.of(context).activityTimeline,
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
                  ? DiaryLocalizations.of(context).switchToTimelineView
                  : DiaryLocalizations.of(context).switchToGridView,
        ),
        // 标签管理按钮
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: () => tagController.showTagManagerDialog(context),
          tooltip: DiaryLocalizations.of(context).tagManagement,
        ),
        // 排序下拉菜单
        PopupMenuButton<int>(
          icon: const Icon(Icons.sort),
          tooltip: DiaryLocalizations.of(context).sortBy,
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
                      Text(DiaryLocalizations.of(context).sortByStartTimeAsc),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 8),
                      Text(DiaryLocalizations.of(context).sortByDuration),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 16),
                      const SizedBox(width: 8),
                      Text(DiaryLocalizations.of(context).sortByStartTimeDesc),
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
