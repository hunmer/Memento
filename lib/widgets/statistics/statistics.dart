/// 通用统计组件库
///
/// 这个库提供了一套可复用的统计图表和屏幕组件，可以被所有插件使用。
///
/// ## 主要组件
///
/// - [StatisticsScreen] - 通用统计屏幕
/// - [StatisticsConfig] - 统计屏幕配置
/// - [StatisticsData] - 统计数据模型
/// - [DateRangeSelector] - 日期范围选择器
/// - [DistributionPieChart] - 分布饼图
/// - [RankingList] - 排行榜列表
/// - [TimeSeriesChart] - 时间序列趋势图
/// - [StatisticsCalculator] - 统计计算工具
library;

export 'models/statistics_models.dart';
export 'components/statistics_screen.dart';
export 'components/date_range_selector.dart';
export 'components/chart_components.dart';
export 'utils/statistics_calculator.dart';
