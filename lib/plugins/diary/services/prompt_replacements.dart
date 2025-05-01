import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/diary_utils.dart';

class DiaryPromptReplacements {
  
  void initialize() {
    // 初始化服务，如果需要的话
    debugPrint('DiaryPromptReplacements 初始化完成');
  }
  
  void dispose() {
    // 清理资源，如果需要的话
    debugPrint('DiaryPromptReplacements 资源已清理');
  }
  
  /// 获取指定日期范围内的日记
  /// 
  /// [params] 必须包含 "startDate" 和 "endDate" 两个字段，格式为 "YYYY-MM-DD"
  /// 返回格式为 JSON 字符串，包含日期范围内的所有日记条目
  Future<String> getDiaries(Map<String, dynamic> params) async {
    try {
      // 验证参数
      if (!params.containsKey('startDate') || !params.containsKey('endDate')) {
        return jsonEncode({
          'error': '缺少必要参数',
          'message': '需要提供 startDate 和 endDate 参数',
        });
      }
      
      // 解析日期
      DateTime startDate;
      DateTime endDate;
      
      try {
        startDate = DateTime.parse(params['startDate']);
        endDate = DateTime.parse(params['endDate']);
      } catch (e) {
        return jsonEncode({
          'error': '日期格式错误',
          'message': '日期格式应为 YYYY-MM-DD',
        });
      }
      
      // 确保开始日期不晚于结束日期
      if (startDate.isAfter(endDate)) {
        return jsonEncode({
          'error': '日期范围错误',
          'message': '开始日期不能晚于结束日期',
        });
      }
      
      // 加载所有日记条目
      final entries = await DiaryUtils.loadDiaryEntries();
      
      // 过滤出指定日期范围内的日记
      final filteredEntries = <Map<String, dynamic>>[];
      
      for (final entry in entries.values) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (!entryDate.isBefore(startDate) && !entryDate.isAfter(endDate)) {
          filteredEntries.add({
            'date': entryDate.toIso8601String().split('T')[0],
            'title': entry.title,
            'content': entry.content,
            'mood': entry.mood,
          });
        }
      }
      
      // 按日期排序
      filteredEntries.sort((a, b) => a['date'].compareTo(b['date']));
      
      return jsonEncode({
        'diaries': filteredEntries,
        'count': filteredEntries.length,
      });
    } catch (e) {
      debugPrint('获取日记时出错: $e');
      return jsonEncode({
        'error': '内部错误',
        'message': e.toString(),
      });
    }
  }
}