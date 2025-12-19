import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/plugins/activity/sample_data.dart';
import 'package:Memento/widgets/tag_manager_dialog.dart';

class ActivityService {
  final StorageManager _storage;
  final String _pluginDir;

  ActivityService(this._storage, this._pluginDir);

  // 获取标签组文件路径
  String get _tagGroupsFilePath => '$_pluginDir/tag_groups.json';

  // 获取最近使用标签文件路径
  String get _recentTagsFilePath => '$_pluginDir/recent_tags.json';

  // 获取最近使用心情文件路径
  String get _recentMoodsFilePath => '$_pluginDir/recent_moods.json';

  // 获取特定日期的活动记录文件路径
  String _getActivityFilePath(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$_pluginDir/activities_$dateStr.json';
  }

  // 保存活动记录
  Future<void> saveActivity(ActivityRecord activity) async {
    try {
      final date = activity.startTime;
      final filePath = _getActivityFilePath(date);

      // 读取现有活动
      List<ActivityRecord> activities = await getActivitiesForDate(date);

      // 检查是否存在重叠的活动
      final overlappingIndex = activities.indexWhere(
        (a) =>
            a.startTime.isBefore(activity.endTime) &&
            a.endTime.isAfter(activity.startTime),
      );

      if (overlappingIndex != -1) {
        // 如果存在重叠，替换原有的活动
        activities[overlappingIndex] = activity;
      } else {
        // 如果不存在重叠，添加新活动
        activities.add(activity);
      }

      // 按开始时间排序
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      // 保存到文件
      final jsonList = activities.map((e) => e.toJson()).toList();
      await _storage.writeJson(filePath, jsonList);

      // 同步到小组件
      await _syncWidget();
    } catch (e) {
      debugPrint('Error saving activity: $e');
      rethrow;
    }
  }

  // 获取指定日期的所有活动
  Future<List<ActivityRecord>> getActivitiesForDate(DateTime date) async {
    try {
      final filePath = _getActivityFilePath(date);

      // 检查文件是否存在
      if (!await _storage.fileExists(filePath)) {
        return [];
      }

      // 读取并解析文件
      final jsonString = await _storage.readString(filePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      return jsonList.map((json) => ActivityRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading activities: $e');
      return [];
    }
  }

  // 更新活动记录
  Future<void> updateActivity(
    ActivityRecord oldActivity,
    ActivityRecord newActivity,
  ) async {
    try {
      // 如果日期改变，需要从旧日期文件删除并添加到新日期文件
      if (oldActivity.startTime.year != newActivity.startTime.year ||
          oldActivity.startTime.month != newActivity.startTime.month ||
          oldActivity.startTime.day != newActivity.startTime.day) {
        // 从旧日期文件删除
        await deleteActivity(oldActivity);

        // 添加到新日期文件
        await saveActivity(newActivity);
      } else {
        // 同一天内更新
        final date = oldActivity.startTime;
        final activities = await getActivitiesForDate(date);

        // 查找并替换活动
        final index = activities.indexWhere(
          (a) =>
              a.startTime == oldActivity.startTime &&
              a.endTime == oldActivity.endTime &&
              a.title == oldActivity.title,
        );

        if (index != -1) {
          activities[index] = newActivity;

          // 保存更新后的列表
          final filePath = _getActivityFilePath(date);
          final jsonList = activities.map((e) => e.toJson()).toList();
          await _storage.writeJson(filePath, jsonList);

          // 同步到小组件
          await _syncWidget();
        }
      }
    } catch (e) {
      debugPrint('Error updating activity: $e');
      rethrow;
    }
  }

  // 删除活动记录
  Future<void> deleteActivity(ActivityRecord activity) async {
    try {
      final date = activity.startTime;
      final filePath = _getActivityFilePath(date);

      // 读取现有活动
      List<ActivityRecord> activities = await getActivitiesForDate(date);

      // 查找并删除活动
      activities.removeWhere(
        (a) =>
            a.startTime == activity.startTime &&
            a.endTime == activity.endTime &&
            a.title == activity.title,
      );

      // 保存更新后的列表
      final jsonList = activities.map((e) => e.toJson()).toList();
      await _storage.writeJson(filePath, jsonList);

      // 同步到小组件
      await _syncWidget();
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      rethrow;
    }
  }

  // 检查时间段是否有重叠的活动
  Future<bool> hasOverlappingActivities(
    DateTime start,
    DateTime end, {
    ActivityRecord? excludeActivity,
  }) async {
    final date = start;
    final activities = await getActivitiesForDate(date);

    return activities.any((activity) {
      // 排除自身
      if (excludeActivity != null &&
          activity.startTime == excludeActivity.startTime &&
          activity.endTime == excludeActivity.endTime &&
          activity.title == excludeActivity.title) {
        return false;
      }

      // 检查重叠
      return (start.isBefore(activity.endTime) &&
          end.isAfter(activity.startTime));
    });
  }

  // 保存标签组
  Future<void> saveTagGroups(List<TagGroup> groups) async {
    try {
      final jsonList =
          groups
              .map((group) => {'name': group.name, 'tags': group.tags})
              .toList();
      await _storage.writeJson(_tagGroupsFilePath, jsonList);
    } catch (e) {
      debugPrint('Error saving tag groups: $e');
      rethrow;
    }
  }

  // 获取标签组
  Future<List<TagGroup>> getTagGroups() async {
    try {
      if (!await _storage.fileExists(_tagGroupsFilePath)) {
        return [];
      }
      final jsonString = await _storage.readString(_tagGroupsFilePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map(
            (json) => TagGroup(
              name: json['name'],
              tags: List<String>.from(json['tags']),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading tag groups: $e');
      return [];
    }
  }

  // 保存最近使用的标签
  Future<void> saveRecentTags(List<String> tags) async {
    try {
      await _storage.writeJson(_recentTagsFilePath, tags);
    } catch (e) {
      debugPrint('Error saving recent tags: $e');
      rethrow;
    }
  }

  // 获取最近使用的标签
  Future<List<String>> getRecentTags() async {
    try {
      if (!await _storage.fileExists(_recentTagsFilePath)) {
        return [];
      }
      final jsonString = await _storage.readString(_recentTagsFilePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return List<String>.from(jsonList);
    } catch (e) {
      debugPrint('Error loading recent tags: $e');
      return [];
    }
  }

  // 保存最近使用的心情
  Future<void> saveRecentMoods(List<String> moods) async {
    try {
      await _storage.writeJson(_recentMoodsFilePath, moods);
    } catch (e) {
      debugPrint('Error saving recent moods: $e');
      rethrow;
    }
  }

  // 获取最近使用的心情
  Future<List<String>> getRecentMoods() async {
    try {
      if (!await _storage.fileExists(_recentMoodsFilePath)) {
        return [];
      }
      final jsonString = await _storage.readString(_recentMoodsFilePath);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return List<String>.from(jsonList);
    } catch (e) {
      debugPrint('Error loading recent moods: $e');
      return [];
    }
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    try {
      // 同步基础活动小组件
      await PluginWidgetSyncHelper.instance.syncActivity();

      // 同步活动周视图小组件
      await PluginWidgetSyncHelper.instance.syncActivityWeeklyWidget();
    } catch (e) {
      // 静默处理小组件同步错误，不影响主要功能
      debugPrint('Failed to sync activity widget: $e');
    }
  }

  /// 初始化默认数据
  /// 当插件首次使用时（没有任何JSON文件存在），自动插入示例数据
  Future<void> initializeDefaultData() async {
    try {
      // 检查是否已存在任何数据文件
      final tagGroupsExists = await _storage.fileExists(_tagGroupsFilePath);
      final recentTagsExists = await _storage.fileExists(_recentTagsFilePath);
      final recentMoodsExists = await _storage.fileExists(_recentMoodsFilePath);

      // 如果标签相关文件都不存在，说明是首次使用，插入默认数据
      final isFirstTime = !tagGroupsExists && !recentTagsExists && !recentMoodsExists;

      if (isFirstTime) {
        debugPrint('[ActivityService] 检测到首次使用，正在插入默认数据...');

        // 1. 插入默认标签分组
        final defaultTagGroups = ActivitySampleData.defaultTagGroups;
        await saveTagGroups(defaultTagGroups);
        debugPrint('[ActivityService] 已插入 ${defaultTagGroups.length} 个默认标签分组');

        // 2. 插入默认最近使用标签
        final defaultRecentTags = ActivitySampleData.defaultRecentTags;
        await saveRecentTags(defaultRecentTags);
        debugPrint('[ActivityService] 已插入 ${defaultRecentTags.length} 个默认最近标签');

        // 3. 插入默认最近使用心情
        final defaultRecentMoods = ActivitySampleData.defaultRecentMoods;
        await saveRecentMoods(defaultRecentMoods);
        debugPrint('[ActivityService] 已插入 ${defaultRecentMoods.length} 个默认最近心情');

        // 4. 插入今日示例活动
        final todaySampleActivities = ActivitySampleData.getSampleActivities();
        for (final activity in todaySampleActivities) {
          await saveActivity(activity);
        }
        debugPrint('[ActivityService] 已插入 ${todaySampleActivities.length} 个今日示例活动');

        // 5. 插入昨日示例活动
        final yesterdaySampleActivities = ActivitySampleData.getYesterdaySampleActivities();
        for (final activity in yesterdaySampleActivities) {
          await saveActivity(activity);
        }
        debugPrint('[ActivityService] 已插入 ${yesterdaySampleActivities.length} 个昨日示例活动');

        debugPrint('[ActivityService] 默认数据初始化完成！');
      } else {
        debugPrint('[ActivityService] 检测到已有数据，跳过默认数据插入');
      }
    } catch (e) {
      debugPrint('[ActivityService] 初始化默认数据失败: $e');
      // 不抛出异常，避免影响插件正常初始化
    }
  }
}
