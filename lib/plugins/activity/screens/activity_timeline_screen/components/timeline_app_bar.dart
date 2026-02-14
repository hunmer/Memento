import 'package:universal_platform/universal_platform.dart';
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
          (UniversalPlatform.isAndroid || UniversalPlatform.isIOS)
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
      title: Text('activity_activityTimeline'.tr),
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
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
