import 'package:flutter/material.dart';
import '../checkin_plugin.dart';

class CheckinPromptReplacements {
  /// 获取指定日期范围内的打卡记录
  Future<String> getCheckinHistory(Map<String, dynamic> params) async {
    try {
      final startDate = DateTime.parse(params['startDate'] as String);
      final endDate = DateTime.parse(params['endDate'] as String);
      
      // 获取所有打卡项目
      final checkinItems = CheckinPlugin.instance.checkinItems;
      
      // 构建记录列表
      final records = <Map<String, dynamic>>[];
      
      for (final item in checkinItems) {
        // 筛选指定日期范围内的记录
        final dateRangeRecords = item.checkInRecords.entries
            .where((entry) {
              // 解析日期字符串为DateTime对象
              final dateParts = entry.key.split('-');
              if (dateParts.length != 3) return false;
              
              final date = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
              
              return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
                     date.isBefore(endDate.add(const Duration(days: 1)));
            })
            .expand((entry) => entry.value) // 展开List<CheckinRecord>
            .map((record) {
                  final map = <String, dynamic>{
                    // 不需要key字段，因为它是内部使用的
                    'name': item.name,
                    'group': item.group.isNotEmpty ? item.group : null,
                    'date': record.checkinTime, // 添加日期字段用于排序
                    'done': _formatDate(record.checkinTime),
                    'note': record.note?.isNotEmpty == true ? record.note : null,
                  };
                  
                  // 只有当开始时间和结束时间相差至少1分钟时才添加这两个字段
                  if (record.startTime != null && record.endTime != null) {
                    final difference = record.endTime!.difference(record.startTime!).inMinutes;
                    if (difference >= 1) {
                      map['start'] = _formatDate(record.startTime!);
                      map['end'] = _formatDate(record.endTime!);
                    }
                  }
                  
                  return map;
                })
            .toList();
            
        records.addAll(dateRangeRecords);
      }
      
      // 按日期排序
      records.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      
      // 排序后移除用于排序的原始日期字段
      for (var record in records) {
        record.remove('date');
      }
      
      return records.isEmpty 
          ? '在指定日期范围内没有找到打卡记录。'
          : _removeEmptyFields(records).toString();
          
    } catch (e) {
      debugPrint('获取打卡记录时出错: $e');
      return '获取打卡记录失败: $e';
    }
  }

  /// 格式化日期为 y/m/d h:m 格式
  String _formatDate(DateTime dateTime) {
    // 确保月、日、小时和分钟始终是两位数
    String month = dateTime.month.toString().padLeft(2, '0');
    String day = dateTime.day.toString().padLeft(2, '0');
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '${dateTime.year}/$month/$day $hour:$minute';
  }
  
  /// 移除记录中的空字段
  List<Map<String, dynamic>> _removeEmptyFields(List<Map<String, dynamic>> records) {
    return records.map((record) {
      return Map<String, dynamic>.fromEntries(
        record.entries.where((entry) => entry.value != null)
      );
    }).toList();
  }
  
  void initialize() {
    // 初始化时的其他操作（如果需要）
  }

  void dispose() {
    // 清理资源（如果需要）
  }
}