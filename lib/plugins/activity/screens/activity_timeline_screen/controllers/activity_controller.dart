import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';
import 'package:Memento/plugins/activity/screens/activity_edit_screen.dart';

class ActivityController {
  final ActivityService activityService;
  final VoidCallback onActivitiesChanged;

  List<ActivityRecord> activities = [];
  int sortMode = 0;

  static const int maxRecentItems = 10;
  List<String> recentMoods = [];
  List<String> recentTags = [];

  ActivityController({
    required this.activityService,
    required this.onActivitiesChanged,
  });

  void setSortMode(int mode) {
    sortMode = mode;
    _sortActivities();
    onActivitiesChanged();
  }

  void _sortActivities() {
    switch (sortMode) {
      case 1: // 按活动时长排序
        activities.sort(
          (a, b) => b.endTime
              .difference(b.startTime)
              .compareTo(a.endTime.difference(a.startTime)),
        );
        break;
      case 2: // 按起始时间排序（降序）
        activities.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case 0: // 默认按起始时间排序（升序）
      default:
        activities.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
    }
  }

  Future<void> loadActivities(DateTime date) async {
    activities = await activityService.getActivitiesForDate(date);
    _sortActivities();
    onActivitiesChanged();
  }

  Future<void> loadRecentMoodsAndTags() async {
    recentMoods = await activityService.getRecentMoods();
    recentTags = await activityService.getRecentTags();
  }

  // 发送事件通知
  void _notifyEvent(String action, ActivityRecord activity) {
    final eventArgs = ItemEventArgs(
      eventName: 'activity_$action',
      itemId: activity.id,
      title: activity.title,
      action: action,
    );
    EventManager.instance.broadcast('activity_$action', eventArgs);
  }

  Future<void> deleteActivity(ActivityRecord activity) async {
    await activityService.deleteActivity(activity);
    // 发送活动删除事件
    _notifyEvent('deleted', activity);
    activities.remove(activity);
    _sortActivities();
    onActivitiesChanged();
  }

  /// 显示活动编辑界面（用于创建新活动）
  /// 使用 SmoothBottomSheet 显示 ActivityEditScreen
  /// [start] 和 [end] 可选，用于预填充时间
  static Future<void> showAddActivityScreen(
    BuildContext context, {
    DateTime? start,
    DateTime? end,
  }) {
    return SmoothBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final contentHeight = screenHeight * 0.85;

        return SizedBox(
          height: contentHeight,
          child: ActivityEditScreen(
            showAsBottomSheet: true,
            startTime: start,
            endTime: end,
          ),
        );
      },
    );
  }

  /// 显示活动编辑界面（用于编辑现有活动）
  void editActivity(BuildContext context, ActivityRecord activity) {
    SmoothBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final contentHeight = screenHeight * 0.85;

        return SizedBox(
          height: contentHeight,
          child: ActivityEditScreen(
            activity: activity,
            showAsBottomSheet: true,
          ),
        );
      },
    );
  }
}
