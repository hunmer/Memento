/// 计时器插件主页小组件数据提供者
library;

import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../timer_plugin.dart';
import '../models/timer_task.dart';
import '../../../core/services/timer/models/timer_state.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
    if (plugin == null) return [];

    final tasks = plugin.getTasks();
    final totalCount = tasks.length;
    final runningCount = tasks.where((task) => task.isRunning).length;

    return [
      StatItemData(
        id: 'total_count',
        label: 'timer_totalTimer'.tr,
        value: '$totalCount',
        highlight: false,
      ),
      StatItemData(
        id: 'running_count',
        label: 'timer_running'.tr,
        value: '$runningCount',
        highlight: runningCount > 0,
        color: Colors.blueGrey,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 计时器插件 - 公共小组件数据提供者
class TimerCommandWidgetsProvider {
  /// 获取公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> data,
  ) async {
    final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
    if (plugin == null) return {};

    final tasks = plugin.getTasks();

    return {
      // 环形指标卡片 - 显示所有计时器
      'circularMetricsCard': _buildCircularMetricsCardData(tasks),
    };
  }

  /// 构建环形指标卡片数据
  static Map<String, dynamic> _buildCircularMetricsCardData(List<TimerTask> tasks) {
    final metrics = tasks.take(6).map((task) {
      // 计算进度
      double progress = 0.0;
      final activeTimer = task.activeTimer;
      if (activeTimer != null) {
        if (activeTimer.type == TimerType.countDown) {
          // 倒计时：剩余时长 / 总时长
          progress = activeTimer.remainingDuration.inSeconds / activeTimer.duration.inSeconds;
        } else {
          // 正计时/番茄钟：已完成时长 / 总时长
          progress = activeTimer.completedDuration.inSeconds / activeTimer.duration.inSeconds;
        }
      }

      // 获取任务颜色
      final color = task.color;

      return {
        'icon': task.icon.codePoint,
        'value': _formatDuration(activeTimer?.remainingDuration ?? Duration.zero),
        'label': task.name,
        'progress': progress.clamp(0.0, 1.0),
        'color': color.value,
      };
    }).toList();

    return {
      'title': 'timer_overview'.tr,
      'metrics': metrics,
    };
  }

  /// 格式化时长
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
