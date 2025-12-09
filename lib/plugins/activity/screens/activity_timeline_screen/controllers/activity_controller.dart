import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/plugins/activity/widgets/activity_form.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';

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

  Future<void> _updateRecentMood(String mood) async {
    if (mood.isEmpty) return;

    // 将新心情添加到列表开头
    recentMoods.remove(mood); // 如果已存在，先移除
    recentMoods.insert(0, mood);

    // 保持列表最大长度为10
    if (recentMoods.length > maxRecentItems) {
      recentMoods = recentMoods.sublist(0, maxRecentItems);
    }

    await activityService.saveRecentMoods(recentMoods);
  }

  Future<void> _updateRecentTags(List<String> tags) async {
    if (tags.isEmpty) return;

    // 将新标签添加到列表开头
    for (final tag in tags.reversed) {
      recentTags.remove(tag); // 如果已存在，先移除
      recentTags.insert(0, tag);
    }

    // 保持列表最大长度为10
    if (recentTags.length > maxRecentItems) {
      recentTags = recentTags.sublist(0, maxRecentItems);
    }

    await activityService.saveRecentTags(recentTags);
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

  Future<void> addActivity(
    BuildContext context,
    DateTime selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Function(List<String>) onTagsUpdated,
  ) async {
    DateTime? initialStartTime;
    DateTime? initialEndTime;
    DateTime? lastActivityEndTime;

    if (startTime != null && endTime != null) {
      initialStartTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );
      initialEndTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      // 智能调整开始时间，避免与已有活动重叠
      // 确保已加载当天活动数据
      if (activities.isEmpty) {
        await loadActivities(selectedDate);
      }

      // 按开始时间排序活动
      final sortedActivities = List<ActivityRecord>.from(activities)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // 查找与初始时间段重叠的最后一个活动
      ActivityRecord? lastOverlappingActivity;
      for (final activity in sortedActivities) {
        // 如果活动结束时间 > 初始开始时间，说明可能重叠
        if (activity.endTime.isAfter(initialStartTime)) {
          // 检查是否真的重叠（活动开始时间 < 初始结束时间）
          if (activity.startTime.isBefore(initialEndTime)) {
            lastOverlappingActivity = activity;
          }
        }
      }

      // 如果找到重叠的活动，调整开始时间为该活动的结束时间
      if (lastOverlappingActivity != null) {
        initialStartTime = lastOverlappingActivity.endTime;
        lastActivityEndTime = lastOverlappingActivity.endTime;
      }
    } else {
      // 设置默认时间：开始时间为最后一个活动的结束时间，结束时间为当前时间
      final now = DateTime.now();

      // 确保已加载当天活动数据
      if (activities.isEmpty) {
        await loadActivities(selectedDate);
      }

      // 找到当天最后一个活动的结束时间
      if (activities.isNotEmpty) {
        // 按开始时间排序，找到最后一个活动
        final sortedActivities = List.from(activities)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        lastActivityEndTime = sortedActivities.last.endTime;
      }

      // 设置开始时间为最后一个活动的结束时间，如果没有活动则为当前时间前1小时
      initialStartTime =
          lastActivityEndTime ?? now.subtract(const Duration(hours: 1));

      // 设置结束时间为当前时间
      initialEndTime = now;
    }

    // 加载最近使用的心情和标签
    await loadRecentMoodsAndTags();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9, // 初始高度为屏幕高度的90%
            maxChildSize: 0.95, // 最大高度为屏幕高度的95%
            minChildSize: 0.5, // 最小高度为屏幕高度的50%
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ActivityForm(
                    selectedDate: selectedDate,
                    initialStartTime: initialStartTime,
                    initialEndTime: initialEndTime,
                    lastActivityEndTime: lastActivityEndTime,
                    recentMoods: recentMoods,
                    recentTags: recentTags,
                    onSave: (ActivityRecord activity) async {
                      await activityService.saveActivity(activity);
                      if (activity.tags.isNotEmpty) {
                        onTagsUpdated(activity.tags);
                        await _updateRecentTags(activity.tags);
                      }
                      if (activity.mood != null && activity.mood!.isNotEmpty) {
                        await _updateRecentMood(activity.mood!);
                      }
                      // 发送活动添加事件
                      _notifyEvent('added', activity);
                      await loadActivities(selectedDate);
                    },
                  ),
                ),
          ),
    );
  }

  void editActivity(BuildContext context, ActivityRecord activity) {
    // 加载最近使用的心情和标签
    loadRecentMoodsAndTags().then((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => DraggableScrollableSheet(
              initialChildSize: 0.9, // 初始高度为屏幕高度的90%
              maxChildSize: 0.95, // 最大高度为屏幕高度的95%
              minChildSize: 0.5, // 最小高度为屏幕高度的50%
              expand: false,
              builder:
                  (context, scrollController) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: ActivityForm(
                      activity: activity,
                      recentMoods: recentMoods,
                      recentTags: recentTags,
                      onSave: (ActivityRecord updatedActivity) async {
                        await activityService.updateActivity(
                          activity,
                          updatedActivity,
                        );
                        if (updatedActivity.tags.isNotEmpty) {
                          await _updateRecentTags(updatedActivity.tags);
                        }
                        if (updatedActivity.mood != null &&
                            updatedActivity.mood!.isNotEmpty) {
                          await _updateRecentMood(updatedActivity.mood!);
                        }
                        await loadActivities(activity.startTime);
                      },
                      selectedDate: activity.startTime,
                    ),
                  ),
            ),
      );
    });
  }
}
