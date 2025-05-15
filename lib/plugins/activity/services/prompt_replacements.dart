import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import '../services/activity_service.dart';
import '../../../core/storage/storage_manager.dart';

/// Activity插件的Prompt替换服务
class ActivityPromptReplacements {
  late ActivityService _activityService;
  
  /// 初始化并注册所有prompt替换方法
  void initialize(StorageManager storage, String pluginDir) {
    _activityService = ActivityService(storage, pluginDir);
  }

  /// 获取活动数据并格式化为文本
  Future<String> getActivities(Map<String, dynamic> params) async {
    try {
      // 解析参数
      final String? startDateStr = params['startDate'] as String?;
      final String? endDateStr = params['endDate'] as String?;
      
      DateTime? startDate;
      DateTime? endDate;
      
      // 解析日期字符串
      if (startDateStr != null) {
        try {
          // 尝试多种格式解析日期
          startDate = _parseDate(startDateStr);
        } catch (e) {
          debugPrint('解析开始日期失败: $e');
        }
      }
      
      if (endDateStr != null) {
        try {
          endDate = _parseDate(endDateStr);
        } catch (e) {
          debugPrint('解析结束日期失败: $e');
        }
      }
      
      // 如果没有提供日期，使用当天
      if (startDate == null && endDate == null) {
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (startDate != null && endDate == null) {
        // 如果只提供了开始日期，结束日期设为开始日期的当天结束
        endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
      } else if (startDate == null && endDate != null) {
        // 如果只提供了结束日期，开始日期设为结束日期的当天开始
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
      }
      
      // 查询活动数据
      final activities = await _getActivitiesInRange(startDate!, endDate!);
      
      // 格式化活动数据为文本
      return _formatActivitiesToText(activities);
    } catch (e) {
      debugPrint('获取活动数据失败: $e');
      return '获取活动数据时出错: $e';
    }
  }
  
  /// 获取指定日期范围内的所有活动
  Future<List<ActivityRecord>> _getActivitiesInRange(DateTime start, DateTime end) async {
    List<ActivityRecord> allActivities = [];
    
    // 计算日期范围内的每一天
    for (DateTime date = DateTime(start.year, start.month, start.day); 
         date.isBefore(DateTime(end.year, end.month, end.day).add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      
      // 获取当天的活动
      final dailyActivities = await _activityService.getActivitiesForDate(date);
      
      // 过滤出在时间范围内的活动
      final filteredActivities = dailyActivities.where((activity) {
        return (activity.startTime.isAfter(start) || activity.startTime.isAtSameMomentAs(start)) && 
               (activity.endTime.isBefore(end) || activity.endTime.isAtSameMomentAs(end));
      }).toList();
      
      allActivities.addAll(filteredActivities);
    }
    
    // 按开始时间排序
    allActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    return allActivities;
  }
  
  /// 尝试多种格式解析日期字符串
  DateTime _parseDate(String dateStr) {
    // 尝试解析 yyyy/MM/dd 格式
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]), 
          int.parse(parts[1]), 
          int.parse(parts[2])
        );
      }
    } catch (_) {}
    
    // 尝试解析 yyyy-MM-dd 格式
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]), 
          int.parse(parts[1]), 
          int.parse(parts[2])
        );
      }
    } catch (_) {}
    
    // 尝试使用DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    
    // 如果所有尝试都失败，抛出异常
    throw FormatException('无法解析日期: $dateStr');
  }
  
  /// 格式化活动数据为JSON文本
  String _formatActivitiesToText(List<ActivityRecord> activities) {
    if (activities.isEmpty) {
      return '{"status": "empty", "msg": "在指定时间段内没有找到活动记录。"}';
    }
    
    // 计算总活动时长（分钟）
    int totalDuration = 0;
    for (final activity in activities) {
      totalDuration += activity.durationInMinutes;
    }
    
    // 按标签统计时长（只统计非空标签）
    final Map<String, int> tagStats = {};
    for (final activity in activities) {
      if (activity.tags.isNotEmpty) {
        for (final tag in activity.tags) {
          tagStats[tag] = (tagStats[tag] ?? 0) + activity.durationInMinutes;
        }
      }
    }
    
    // 生成JSON报告
    final Map<String, dynamic> report = {
      'sum': { // summary缩写
        'total': activities.length, // 总活动数
        'tDur': totalDuration, // totalDuration缩写（分钟）
        'avgDur': (totalDuration / activities.length).round(), // 平均时长（分钟）
      }
    };
    
    // 只有存在标签统计时才添加tagStat字段
    if (tagStats.isNotEmpty) {
      report['tagStat'] = tagStats;
    }
    
    // 添加详细活动记录
    final List<Map<String, dynamic>> records = [];
    for (final activity in activities) {
      final Map<String, dynamic> record = {
        'start': activity.startTime.toString().substring(0, 16), // 年-月-日 时:分
        'end': activity.endTime.toString().substring(11, 16),    // 时:分
        'dur': activity.durationInMinutes, // duration缩写（分钟）
        'title': activity.title
      };
      
      // 只添加非空字段
      if (activity.tags.isNotEmpty) {
        record['tags'] = activity.tags;
      }
      if (activity.description?.isNotEmpty == true) {
        record['desc'] = activity.description;
      }
      if (activity.mood?.isNotEmpty == true) {
        record['mood'] = activity.mood;
      }
      
      records.add(record);
    }
    
    // 只有存在记录时才添加records字段
    if (records.isNotEmpty) {
      report['records'] = records;
    }
    
    return _formatJsonString(report);
  }
  
  /// 格式化JSON字符串，移除多余空格和换行符以节省token
  String _formatJsonString(Map<String, dynamic> jsonMap) {
    return jsonMap.toString();
  }
  
  /// 释放资源
  void dispose() {
  }
}