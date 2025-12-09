import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/models/channel.dart';

/// Timeline 工具类，提供各种辅助函数
class TimelineUtils {
  /// 获取消息卡片的背景色，基于频道颜色但透明度降低
  static Color getMessageCardBackground(Channel channel, BuildContext context) {
    final channelColor = channel.backgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 根据亮暗主题调整透明度
    final opacity = isDark ? 0.1 : 0.05;
    return channelColor.withValues(alpha: opacity);
  }
  
  /// 将消息分组为按日期排序的列表
  static Map<DateTime, List<Message>> groupMessagesByDate(List<Message> messages) {
    final Map<DateTime, List<Message>> grouped = {};
    
    for (final message in messages) {
      // 创建只包含年月日的日期键
      final dateKey = DateTime(
        message.date.year,
        message.date.month,
        message.date.day,
      );
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      
      grouped[dateKey]!.add(message);
    }
    
    return grouped;
  }
  
  /// 获取消息在时间线中的显示时间
  static String getTimelineDisplayTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}