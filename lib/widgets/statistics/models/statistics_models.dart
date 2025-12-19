import 'package:flutter/material.dart';

/// 通用统计数据类型
enum StatisticsType {
  activities,
  checkins,
  custom,
}

/// 日期范围选项
enum DateRangeOption {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

/// 分布数据（用于饼图）
class DistributionData {
  final String label;
  final double value;
  final Color? color;
  final String? icon;

  const DistributionData({
    required this.label,
    required this.value,
    this.color,
    this.icon,
  });
}

/// 排行榜数据
class RankingData {
  final String label;
  final double value;
  final Color? color;
  final String? icon;
  final int? order;
  final Map<String, dynamic>? extraData;

  const RankingData({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.order,
    this.extraData,
  });
}

/// 时间序列数据点
class TimeSeriesPoint {
  final DateTime date;
  final double value;

  const TimeSeriesPoint({
    required this.date,
    required this.value,
  });
}

/// 时间序列数据（用于趋势图）
class TimeSeriesData {
  final String label;
  final List<TimeSeriesPoint> points;
  final Color? color;

  const TimeSeriesData({
    required this.label,
    required this.points,
    this.color,
  });
}

/// 通用统计屏幕配置
class StatisticsConfig {
  /// 统计类型
  final StatisticsType type;

  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 是否显示日期范围
  final bool showDateRange;

  /// 可用的日期范围选项
  final List<DateRangeOption> availableRanges;

  /// 默认日期范围
  final DateRangeOption defaultRange;

  /// 图表颜色主题
  final List<Color> chartColors;

  /// 是否显示24小时分布（仅对单日数据有效）
  final bool show24hDistribution;

  /// 加载状态时的占位组件
  final Widget? loadingWidget;

  /// 空数据时的占位组件
  final Widget? emptyWidget;

  const StatisticsConfig({
    required this.type,
    required this.title,
    this.subtitle,
    this.showDateRange = true,
    this.availableRanges = const [
      DateRangeOption.today,
      DateRangeOption.thisWeek,
      DateRangeOption.thisMonth,
      DateRangeOption.thisYear,
      DateRangeOption.custom,
    ],
    this.defaultRange = DateRangeOption.thisWeek,
    this.chartColors = const [
      Color(0xFF60A5FA), // blue-400
      Color(0xFF4ADE80), // green-400
      Color(0xFF818CF8), // indigo-400
      Color(0xFFFB923C), // orange-400
      Color(0xFFF87171), // red-400
      Color(0xFFFACC15), // yellow-400
      Color(0xFF2DD4BF), // teal-400
      Color(0xFFA78BFA), // purple-400
    ],
    this.show24hDistribution = false,
    this.loadingWidget,
    this.emptyWidget,
  });
}

/// 通用统计数据
class StatisticsData {
  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 日期范围
  final DateTime startDate;
  final DateTime endDate;

  /// 总量统计
  final double? totalValue;
  final String? totalValueLabel;

  /// 分布数据（饼图）
  final List<DistributionData>? distributionData;

  /// 排行榜数据
  final List<RankingData>? rankingData;

  /// 时间序列数据（趋势图）
  final List<TimeSeriesData>? timeSeriesData;

  /// 24小时分布数据（仅单日有效）
  final List<TimeSeriesPoint>? hourlyDistribution;

  /// 24小时分布的主要标签（可选，用于显示标签名称）
  final Map<int, String>? hourlyMainTags;

  /// 额外数据
  final Map<String, dynamic>? extraData;

  const StatisticsData({
    required this.title,
    this.subtitle,
    required this.startDate,
    required this.endDate,
    this.totalValue,
    this.totalValueLabel,
    this.distributionData,
    this.rankingData,
    this.timeSeriesData,
    this.hourlyDistribution,
    this.hourlyMainTags,
    this.extraData,
  });

  /// 是否为单日数据
  bool get isSingleDay {
    return startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;
  }
}

/// 日期范围选择器状态
class DateRangeState {
  final DateRangeOption selectedRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;

  const DateRangeState({
    required this.selectedRange,
    this.startDate,
    this.endDate,
    this.isLoading = false,
  });

  DateRangeState copyWith({
    DateRangeOption? selectedRange,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
  }) {
    return DateRangeState(
      selectedRange: selectedRange ?? this.selectedRange,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
