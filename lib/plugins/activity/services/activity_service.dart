import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/storage/storage_manager.dart';
import '../models/activity_record.dart';

class ActivityService {
  final StorageManager _storage;
  final String _pluginDir;

  ActivityService(this._storage, this._pluginDir);

  // 获取特定日期的活动记录文件路径
  String _getActivityFilePath(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$_pluginDir/activities_$dateStr.json';
  }

  // 保存活动记录
  Future<void> saveActivity(ActivityRecord activity) async {
    try {
      final date = activity.startTime;
      final filePath = _getActivityFilePath(date);
      
      // 读取现有活动
      List<ActivityRecord> activities = await getActivitiesForDate(date);
      
      // 添加新活动
      activities.add(activity);
      
      // 按开始时间排序
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      // 保存到文件
      final jsonList = activities.map((e) => e.toJson()).toList();
      await _storage.writeJson(filePath, jsonList);
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
  Future<void> updateActivity(ActivityRecord oldActivity, ActivityRecord newActivity) async {
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
        final index = activities.indexWhere((a) => 
            a.startTime == oldActivity.startTime && 
            a.endTime == oldActivity.endTime &&
            a.title == oldActivity.title);
        
        if (index != -1) {
          activities[index] = newActivity;
          
          // 保存更新后的列表
          final filePath = _getActivityFilePath(date);
          final jsonList = activities.map((e) => e.toJson()).toList();
          await _storage.writeJson(filePath, jsonList);
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
      activities.removeWhere((a) => 
          a.startTime == activity.startTime && 
          a.endTime == activity.endTime &&
          a.title == activity.title);
      
      // 保存更新后的列表
      final jsonList = activities.map((e) => e.toJson()).toList();
      await _storage.writeJson(filePath, jsonList);
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      rethrow;
    }
  }

  // 检查时间段是否有重叠的活动
  Future<bool> hasOverlappingActivities(DateTime start, DateTime end, {ActivityRecord? excludeActivity}) async {
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
      return (start.isBefore(activity.endTime) && end.isAfter(activity.startTime));
    });
  }
}