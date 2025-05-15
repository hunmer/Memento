import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../controllers/day_controller.dart';

/// Day插件的Prompt替换服务
class DayPromptReplacements {
  final DayController _dayController = DayController();
  
  /// 初始化并注册所有prompt替换方法
  void initialize() {
    // 确保DayController已初始化
    _dayController.initialize().catchError((e) {
      debugPrint('初始化DayController失败: $e');
    });
  }

  /// 获取纪念日数据并格式化为文本
  Future<String> getDays(Map<String, dynamic> params) async {
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
      
      // 获取所有纪念日
      final memorialDays = _dayController.memorialDays;
      
      // 根据日期范围过滤
      final filteredDays = memorialDays.where((day) {
        final targetDate = day.targetDate;
        
        if (startDate != null && targetDate.isBefore(startDate)) {
          return false;
        }
        
        if (endDate != null && targetDate.isAfter(endDate)) {
          return false;
        }
        
        return true;
      }).toList();
      
      // 格式化纪念日数据为文本
      return _formatDaysToText(filteredDays);
    } catch (e) {
      debugPrint('获取纪念日数据失败: $e');
      return '获取纪念日数据时出错: $e';
    }
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
  
  /// 格式化纪念日数据为JSON文本
  String _formatDaysToText(List<MemorialDay> days) {
    if (days.isEmpty) {
      return '{"status": "empty", "msg": "在指定时间段内没有找到纪念日记录。"}';
    }
    
    // 生成JSON报告
    final Map<String, dynamic> report = {};
    
    // 添加非空的详细纪念日记录
    if (days.isNotEmpty) {
      final List<Map<String, dynamic>> records = [];
      for (final day in days) {
        final Map<String, dynamic> record = {
          'date': day.formattedTargetDate,
          'title': day.title,
          'daysRemaining': day.daysRemaining,
        };
        
        // 只有当备注非空时才添加notes字段
        if (day.notes.isNotEmpty) {
          record['notes'] = day.notes;
        }
        
        records.add(record);
      }
      report['records'] = records;
    }
    
    return report.toString();
  }
  
  /// 释放资源
  void dispose() {
  }
}