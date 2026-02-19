/// 目标追踪插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../tracker_plugin.dart';
import 'utils.dart';

/// 从选择器数据数组中提取小组件需要的数据
Map<String, dynamic> extractGoalData(List<dynamic> dataArray) {
  Map<String, dynamic> itemData = {};
  final rawData = dataArray[0];

  if (rawData is Map<String, dynamic>) {
    itemData = rawData;
  } else if (rawData is dynamic && rawData.toJson != null) {
    final jsonResult = rawData.toJson();
    if (jsonResult is Map<String, dynamic>) {
      itemData = jsonResult;
    }
  }

  final result = <String, dynamic>{};
  result['id'] = itemData['id'] as String?;
  result['name'] = itemData['name'] as String?;
  result['icon'] = itemData['icon'] as String?;
  result['iconColor'] = itemData['iconColor'] as int?;
  result['currentValue'] = itemData['currentValue'] as double?;
  result['targetValue'] = itemData['targetValue'] as double?;
  result['unitType'] = itemData['unitType'] as String?;
  return result;
}

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin =
        PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
    if (plugin == null) return [];

    final controller = plugin.controller;
    final todayComplete = controller.getTodayCompletedGoals();
    final monthComplete = controller.getMonthCompletedGoals();

    return [
      StatItemData(
        id: 'today_complete',
        label: 'tracker_todayComplete'.tr,
        value: '$todayComplete',
        highlight: todayComplete > 0,
      ),
      StatItemData(
        id: 'month_complete',
        label: 'tracker_thisMonthComplete'.tr,
        value: '$monthComplete',
        highlight: monthComplete > 0,
        color: Colors.red,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 公共小组件提供者函数
Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
  Map<String, dynamic> data,
) async {
  // data 包含：id, name, icon, iconColor, currentValue, targetValue, unitType
  final name = (data['name'] as String?) ?? '目标';
  final currentValue = (data['currentValue'] as double?) ?? 0.0;
  final targetValue = (data['targetValue'] as double?) ?? 1.0;
  final unitType = (data['unitType'] as String?) ?? '';
  final progress = (targetValue > 0 ? (currentValue / targetValue) : 0).clamp(
    0.0,
    1.0,
  );
  final percentage = (progress * 100).toInt();

  return {
    // 圆形进度卡片：显示目标完成度
    'circularProgressCard': {
      'title': name,
      'subtitle': '已完 $currentValue / $targetValue $unitType',
      'percentage': percentage.toDouble(),
      'progress': progress,
    },

    // 活动进度卡片：显示目标统计
    'activityProgressCard': {
      'title': name,
      'subtitle': '今日进度',
      'value': currentValue,
      'unit': unitType,
      'activities': 1,
      'totalProgress': 10,
      'completedProgress': (percentage / 10).clamp(0, 10).toInt(),
    },

    // 里程碑卡片：显示目标追踪
    'milestoneCard': {
      'imageUrl': null,
      'title': name,
      'date': formatDate(DateTime.now()),
      'daysCount': percentage,
      'value': currentValue.toStringAsFixed(1),
      'unit': unitType,
      'suffix': '/ $targetValue',
    },

    // 图标圆形进度卡片
    'iconCircularProgressCard': {
      'progress': progress,
      'icon': 0xe25b, // Icons.track_changes codePoint
      'title': name,
      'subtitle': '已完 $currentValue / $targetValue $unitType',
      'showNotification': false,
    },

    // 半仪表盘卡片
    'halfGaugeCard': {
      'title': name,
      'totalBudget': targetValue,
      'remaining': (targetValue - currentValue).clamp(0, double.infinity),
      'currency': unitType,
    },

    // 月度进度点卡片
    'monthlyProgressDotsCard': {
      'month': '${DateTime.now().month}月',
      'currentDay': DateTime.now().day,
      'totalDays': daysInMonth(DateTime.now()),
      'percentage': percentage,
    },
  };
}

/// 导航到目标详情页面
void navigateToGoalDetail(BuildContext context, SelectorResult result) {
  final goalData = result.data as Map<String, dynamic>;
  // id 可能是 int 或 String，需要统一处理
  final goalId = goalData['id']?.toString();

  if (goalId != null) {
    // 使用 navigatorKey.currentContext 确保导航正常工作
    final navContext = navigatorKey.currentContext ?? context;
    NavigationHelper.pushNamed(
      navContext,
      '/tracker',
      arguments: {'goalId': goalId},
    );
  }
}
