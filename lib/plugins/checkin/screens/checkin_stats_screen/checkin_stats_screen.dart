import 'package:Memento/widgets/statistics/statistics.dart';
import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
import 'package:Memento/plugins/checkin/l10n/checkin_localizations.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/daily_checkin_chart.dart';
import 'widgets/checkin_streak_ranking.dart';
import 'widgets/checkin_group_pie_chart.dart';

/// 加载打卡统计数据
Future<StatisticsData> loadStatisticsData(
  List<CheckinItem> checkinItems,
  DateRangeOption range,
  DateTime? startDate,
  DateTime? endDate,
) async {
  if (startDate == null || endDate == null) {
    throw Exception('Start date and end date are required');
  }

  // 计算指定日期范围内的打卡统计
  int totalCheckins = 0;
  int completedItems = 0;
  final Map<String, int> groupStats = {};

  for (var item in checkinItems) {
    bool hasCheckin = false;
    final itemGroup = item.group.isEmpty ? 'Ungrouped' : item.group;

    // 遍历日期范围检查是否有打卡记录
    for (
      var date = DateTime(startDate.year, startDate.month, startDate.day);
      date.isBefore(DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))
    ) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (item.checkInRecords.containsKey(dateStr) &&
          item.checkInRecords[dateStr]!.isNotEmpty) {
        totalCheckins += item.checkInRecords[dateStr]!.length;
        hasCheckin = true;

        // 统计分组数据
        groupStats[itemGroup] = (groupStats[itemGroup] ?? 0) + item.checkInRecords[dateStr]!.length;
      }
    }

    if (hasCheckin) {
      completedItems++;
    }
  }

  // 转换为分布数据
  final distributionData = groupStats.entries
      .map((entry) => DistributionData(
            label: entry.key,
            value: entry.value.toDouble(),
          ))
      .toList();

  // 为分布数据分配颜色
  final coloredDistributionData = StatisticsCalculator.assignColorsToDistribution(
    distributionData,
    const [
      Color(0xFF60A5FA), // blue-400
      Color(0xFF4ADE80), // green-400
      Color(0xFF818CF8), // indigo-400
      Color(0xFFFB923C), // orange-400
      Color(0xFFF87171), // red-400
      Color(0xFFFACC15), // yellow-400
      Color(0xFF2DD4BF), // teal-400
      Color(0xFFA78BFA), // purple-400
    ],
  );

  // 计算排行榜数据（按连续天数排序）
  final rankingData = checkinItems.map((item) {
    final consecutiveDays = item.getConsecutiveDays();
    return RankingData(
      label: item.name,
      value: consecutiveDays.toDouble(),
      icon: item.icon.codePoint.toString(),
      color: item.color,
      extraData: {
        'id': item.id,
        'group': item.group,
      },
    );
  }).toList();

  // 为排行榜数据分配颜色
  final coloredRankingData = StatisticsCalculator.assignColorsToRanking(
    rankingData,
    const [
      Color(0xFF60A5FA), // blue-400
      Color(0xFF4ADE80), // green-400
      Color(0xFF818CF8), // indigo-400
      Color(0xFFFB923C), // orange-400
      Color(0xFFF87171), // red-400
      Color(0xFFFACC15), // yellow-400
      Color(0xFF2DD4BF), // teal-400
      Color(0xFFA78BFA), // purple-400
    ],
  );

  return StatisticsData(
    title: 'Checkin Statistics',
    startDate: startDate,
    endDate: endDate,
    totalValue: totalCheckins.toDouble(),
    totalValueLabel: 'checkins',
    distributionData: coloredDistributionData,
    rankingData: coloredRankingData,
    extraData: {
      'totalItems': checkinItems.length,
      'completedItems': completedItems,
      'completionRate': checkinItems.isNotEmpty
          ? (completedItems / checkinItems.length * 100).toStringAsFixed(1) + '%'
          : '0%',
    },
  );
}

/// 打卡统计页面 - 使用通用统计组件
class CheckinStatsScreen extends StatefulWidget {
  final List<CheckinItem> checkinItems;

  const CheckinStatsScreen({super.key, required this.checkinItems});

  @override
  State<CheckinStatsScreen> createState() => _CheckinStatsScreenState();
}

class _CheckinStatsScreenState extends State<CheckinStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return StatisticsScreen(
      config: const StatisticsConfig(
        type: StatisticsType.checkins,
        title: 'Checkin Statistics',
        show24hDistribution: false,
        availableRanges: [
          DateRangeOption.today,
          DateRangeOption.thisWeek,
          DateRangeOption.thisMonth,
          DateRangeOption.thisYear,
          DateRangeOption.custom,
        ],
        defaultRange: DateRangeOption.thisWeek,
        chartColors: [
          Color(0xFF60A5FA), // blue-400
          Color(0xFF4ADE80), // green-400
          Color(0xFF818CF8), // indigo-400
          Color(0xFFFB923C), // orange-400
          Color(0xFFF87171), // red-400
          Color(0xFFFACC15), // yellow-400
          Color(0xFF2DD4BF), // teal-400
          Color(0xFFA78BFA), // purple-400
        ],
      ),
      dataLoader: (range, startDate, endDate) async {
        return await loadStatisticsData(widget.checkinItems, range, startDate, endDate);
      },
      customSections: (context, statsData) {
        return [
          // 打卡趋势图（使用原有的图表组件）
          buildStatisticsCard(
            context: context,
            title: CheckinLocalizations.of(context).checkinTrendTitle,
            child: SizedBox(
              height: 200,
              child: DailyCheckinChart(
                isMonthly: _isMonthlyRange(statsData.startDate, statsData.endDate),
                checkinItems: widget.checkinItems,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 连续打卡排行榜（使用原有的图表组件）
          buildStatisticsCard(
            context: context,
            title: CheckinLocalizations.of(context).checkinRankingTitle,
            child: CheckinStreakRanking(checkinItems: widget.checkinItems),
          ),
          const SizedBox(height: 16),

          // 打卡分组占比（使用原有的图表组件）
          buildStatisticsCard(
            context: context,
            title: CheckinLocalizations.of(context).checkinGroupPieTitle,
            child: SizedBox(
              height: 200,
              child: CheckinGroupPieChart(
                checkinItems: widget.checkinItems,
              ),
            ),
          ),
        ];
      },
    );
  }

  /// 判断是否为月度或年度范围（用于图表显示）
  bool _isMonthlyRange(DateTime startDate, DateTime endDate) {
    final diff = endDate.difference(startDate).inDays;
    return diff >= 28; // 约等于一个月或更长时间
  }
}
