import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'widgets/circular_progress_card.dart';
import 'widgets/activity_progress_card.dart';
import 'widgets/half_gauge_card.dart';
import 'widgets/task_progress_card.dart';
import '../screens/segmented_progress_card_example.dart';
import '../screens/milestone_card_example.dart';
import '../screens/monthly_progress_with_dots_card_example.dart';
import '../screens/contribution_heatmap_card_example.dart';
import '../screens/smooth_line_chart_card_example.dart';

/// 公共小组件 ID 枚举
enum CommonWidgetId {
  circularProgressCard,
  activityProgressCard,
  halfGaugeCard,
  taskProgressCard,
  segmentedProgressCard,
  milestoneCard,
  monthlyProgressDotsCard,
  contributionHeatmapCard,
  smoothLineChartCard,
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
    CommonWidgetId.segmentedProgressCard: CommonWidgetMetadata(
      id: CommonWidgetId.segmentedProgressCard,
      name: '分段进度条卡片',
      description: '多类别分段统计卡片',
      icon: Icons.bar_chart,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.milestoneCard: CommonWidgetMetadata(
      id: CommonWidgetId.milestoneCard,
      name: '里程碑追踪卡片',
      description: '时间里程碑追踪展示卡片',
      icon: Icons.flag,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.monthlyProgressDotsCard: CommonWidgetMetadata(
      id: CommonWidgetId.monthlyProgressDotsCard,
      name: '月度进度圆点卡片',
      description: '圆点矩阵月度进度卡片',
      icon: Icons.calendar_month,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.contributionHeatmapCard: CommonWidgetMetadata(
      id: CommonWidgetId.contributionHeatmapCard,
      name: '贡献热力图卡片',
      description: '活跃度热力图网格展示卡片',
      icon: Icons.grid_on,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
    ),
    CommonWidgetId.smoothLineChartCard: CommonWidgetMetadata(
      id: CommonWidgetId.smoothLineChartCard,
      name: '平滑折线图卡片',
      description: '带渐变填充的平滑折线图卡片',
      icon: Icons.show_chart,
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
      case CommonWidgetId.segmentedProgressCard:
        return SegmentedProgressCardWidget.fromProps(props, size);
      case CommonWidgetId.milestoneCard:
        return MilestoneCardWidget.fromProps(props, size);
      case CommonWidgetId.monthlyProgressDotsCard:
        return MonthlyProgressWithDotsCardWidget.fromProps(props, size);
      case CommonWidgetId.contributionHeatmapCard:
        return ContributionHeatmapCardWidget.fromProps(props, size);
      case CommonWidgetId.smoothLineChartCard:
        return SmoothLineChartCardWidget.fromProps(props, size);
    }
  }
}
