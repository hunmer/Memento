import 'package:flutter/material.dart';
import '../../../models/activity_record.dart';
import '../../../services/activity_service.dart';
import '../../../widgets/activity_form.dart';
import '../../../../../core/event/event_manager.dart';
import '../../../../../core/event/item_event_args.dart';

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
      eventName: 'activity_${action}',
      itemId: activity.id,
      title: activity.title,
      action: action,
    );
    EventManager.instance.broadcast('activity_${action}', eventArgs);
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
    }
    
    // 加载最近使用的心情和标签
    await loadRecentMoodsAndTags();
    
    return showDialog(
      context: context,
      builder: (context) => ActivityForm(
        selectedDate: selectedDate,
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
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
    );
  }

  void editActivity(BuildContext context, ActivityRecord activity) {
    // 加载最近使用的心情和标签
    loadRecentMoodsAndTags().then((_) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => ActivityForm(
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
            if (updatedActivity.mood != null && updatedActivity.mood!.isNotEmpty) {
              await _updateRecentMood(updatedActivity.mood!);
            }
            await loadActivities(activity.startTime);
          },
          selectedDate: activity.startTime,
        ),
      );
    });
  }
}