import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'widgets/circular_progress_card.dart';
import 'widgets/activity_progress_card.dart';
import 'widgets/half_gauge_card.dart';
import 'widgets/task_progress_card.dart';

/// 公共小组件 ID 枚举
enum CommonWidgetId {
  circularProgressCard,
  activityProgressCard,
  halfGaugeCard,
  taskProgressCard,
}

/// 公共小组件元数据
class CommonWidgetMetadata {
  final CommonWidgetId id;
  final String name;
  final String description;
  final IconData icon;
  final HomeWidgetSize defaultSize;
  final List<HomeWidgetSize> supportedSizes;

  const CommonWidgetMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.defaultSize,
    required this.supportedSizes,
  });
}

/// 公共小组件注册表
class CommonWidgetsRegistry {
  static const Map<CommonWidgetId, CommonWidgetMetadata> metadata = {
    CommonWidgetId.circularProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.circularProgressCard,
      name: '圆形进度卡片',
      description: '显示百分比进度，带圆形进度环',
      icon: Icons.circle_outlined,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.activityProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.activityProgressCard,
      name: '活动进度卡片',
      description: '显示活动数值、单位、活动数和进度点',
      icon: Icons.directions_run,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    ),
    CommonWidgetId.halfGaugeCard: CommonWidgetMetadata(
      id: CommonWidgetId.halfGaugeCard,
      name: '半圆形仪表盘',
      description: '显示预算/余额的半圆形仪表盘',
      icon: Icons.speed,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.taskProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.taskProgressCard,
      name: '任务进度卡片',
      description: '显示任务进度、待办列表',
      icon: Icons.task_alt,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
  };

  /// 获取元数据
  static CommonWidgetMetadata getMetadata(CommonWidgetId id) {
    return metadata[id]!;
  }

  /// 获取所有元数据
  static List<CommonWidgetMetadata> getAllMetadata() {
    return metadata.values.toList();
  }

  /// 根据 ID 字符串获取枚举值
  static CommonWidgetId? fromString(String id) {
    return CommonWidgetId.values.asNameMap()[id];
  }
}

/// 公共小组件构建器
class CommonWidgetBuilder {
  /// 构建公共小组件
  static Widget build(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    switch (widgetId) {
      case CommonWidgetId.circularProgressCard:
        return CircularProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.activityProgressCard:
        return ActivityProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.halfGaugeCard:
        return HalfGaugeCardWidget.fromProps(props, size);
      case CommonWidgetId.taskProgressCard:
        return TaskProgressCardWidget.fromProps(props, size);
    }
  }
}
