/// 脚本中心主页小组件工具函数
library;

import 'package:flutter/material.dart';

/// 图标名称映射（常用图标）
const Map<String, IconData> iconNameMap = {
  'code': Icons.code,
  'play_arrow': Icons.play_arrow,
  'play_circle': Icons.play_circle,
  'play_circle_outline': Icons.play_circle_outline,
  'settings': Icons.settings,
  'star': Icons.star,
  'favorite': Icons.favorite,
  'home': Icons.home,
  'notifications': Icons.notifications,
  'calendar_today': Icons.calendar_today,
  'schedule': Icons.schedule,
  'check_circle': Icons.check_circle,
  'error': Icons.error,
  'info': Icons.info,
  'warning': Icons.warning,
};

/// 解析图标字符串为 IconData
IconData parseIcon(String? iconString) {
  if (iconString == null || iconString.isEmpty) {
    return Icons.code;
  }

  // 尝试解析为十六进制数字（Material Icons codepoint）
  try {
    final codePoint = int.parse(iconString, radix: 16);
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  } catch (e) {
    // 解析失败，尝试图标名称映射
    return iconNameMap[iconString] ?? Icons.code;
  }
}
