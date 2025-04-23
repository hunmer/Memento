import 'package:flutter/material.dart';
import '../../../models/activity_record.dart';
import '../../../services/activity_service.dart';
import '../../../widgets/activity_form.dart';

class ActivityController {
  final ActivityService activityService;
  final VoidCallback onActivitiesChanged;
  
  List<ActivityRecord> activities = [];
  int sortMode = 0;

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

  Future<void> deleteActivity(ActivityRecord activity) async {
    await activityService.deleteActivity(activity);
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
    return showDialog(
      context: context,
      builder: (context) => ActivityForm(
        selectedDate: selectedDate,
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
        onSave: (ActivityRecord activity) async {
          await activityService.saveActivity(activity);
          if (activity.tags.isNotEmpty) {
            onTagsUpdated(activity.tags);
          }
          await loadActivities(selectedDate);
        },
      ),
    );
  }

  void editActivity(BuildContext context, ActivityRecord activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityForm(
        activity: activity,
        onSave: (ActivityRecord updatedActivity) async {
          await activityService.updateActivity(
            activity,
            updatedActivity,
          );
          if (updatedActivity.tags.isNotEmpty) {
            // 更新最近使用的标签
            await activityService.saveRecentTags(updatedActivity.tags);
          }
          await loadActivities(activity.startTime);
        },
        selectedDate: activity.startTime,
      ),
    );
  }
}