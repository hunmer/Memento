/// 待办插件主页小组件工具函数
library;

import 'package:flutter/material.dart';

/// 根据优先级获取颜色
Color getPriorityColor(int priority) {
  switch (priority) {
    case 0: // low
      return Colors.green;
    case 2: // high
      return Colors.red;
    default: // medium
      return Colors.orange;
  }
}

/// 根据状态获取图标
IconData getStatusIcon(int status) {
  switch (status) {
    case 1: // inProgress
      return Icons.play_circle_outline;
    case 2: // done
      return Icons.check_circle_outline;
    default: // todo
      return Icons.radio_button_unchecked;
  }
}
