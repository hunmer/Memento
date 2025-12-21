import 'package:Memento/widgets/statistics/statistics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'tag_statistics_screen.dart';

/// 加载活动统计数据
Future<StatisticsData> loadStatisticsData(
  ActivityService activityService,
  DateRangeOption range,
  DateTime? startDate,
  DateTime? endDate,
) async {
  // 由于 StatisticsScreen 总是会传入有效的日期，这里进行断言检查
  assert(
    startDate != null && endDate != null,
    'Start date and end date must not be null',
  );

  // 收集指定日期范围内的所有活动
  final allActivities = <Map<String, dynamic>>[];

  for (
    var date = DateTime(startDate!.year, startDate.month, startDate.day);
    date.isBefore(
      DateTime(
        endDate!.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1)),
    );
    date = date.add(const Duration(days: 1))
  ) {
    final dailyActivities = await activityService.getActivitiesForDate(date);
    for (var activity in dailyActivities) {
      // 如果活动有标签，为每个标签创建一条记录用于统计
      if (activity.tags.isNotEmpty) {
        // 将时长平分到每个标签
        final durationPerTag =
            activity.durationInMinutes.toDouble() / activity.tags.length;
        for (var tag in activity.tags) {
          allActivities.add({
            'title': activity.title,
            'startTime': activity.startTime.toIso8601String(),
            'endTime': activity.endTime.toIso8601String(),
            'duration': durationPerTag, // 平分后的时长
            'tags': tag, // 单个标签字符串
            'description': activity.description ?? '',
            'mood': activity.mood ?? '',
          });
        }
      } else {
        // 如果活动没有标签，创建一条记录标记为"未分类"
        allActivities.add({
          'title': activity.title,
          'startTime': activity.startTime.toIso8601String(),
          'endTime': activity.endTime.toIso8601String(),
          'duration': activity.durationInMinutes.toDouble(),
          'tags': '未分类',
          'description': activity.description ?? '',
          'mood': activity.mood ?? '',
        });
      }
    }
  }

  // 计算统计指标
  final distributionData = StatisticsCalculator.calculateDistributionByTag(
    allActivities,
    tagField: 'tags',
    valueField: 'duration',
    totalMinutes: null,
  );

  // 为分布数据分配颜色
  final coloredDistributionData =
      StatisticsCalculator.assignColorsToDistribution(distributionData, const [
        Color(0xFF60A5FA), // blue-400
        Color(0xFF4ADE80), // green-400
        Color(0xFF818CF8), // indigo-400
        Color(0xFFFB923C), // orange-400
        Color(0xFFF87171), // red-400
        Color(0xFFFACC15), // yellow-400
        Color(0xFF2DD4BF), // teal-400
        Color(0xFFA78BFA), // purple-400
      ]);

  // 基于已聚合的分布数据生成排行榜数据
  final rankingData =
      coloredDistributionData
          .map(
            (item) => RankingData(
              label: item.label,
              value: item.value,
              color: item.color,
              icon: item.icon,
            ),
          )
          .toList();

  // 为排行榜数据分配颜色和排序
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

  // 计算24小时分布（仅单日有效）
  List<TimeSeriesPoint>? hourlyDistribution;
  Map<int, String>? hourlyMainTags;
  final isSingleDay =
      startDate.year == endDate.year &&
      startDate.month == endDate.month &&
      startDate.day == endDate.day;

  if (isSingleDay) {
    hourlyDistribution = StatisticsCalculator.calculateHourlyDistribution(
      allActivities,
      dateField: 'startTime',
      valueField: 'duration',
    );
    hourlyMainTags = StatisticsCalculator.calculateHourlyMainTags(
      allActivities,
      dateField: 'startTime',
      valueField: 'duration',
      tagField: 'tags',
    );
  }

  // 计算总时长
  final totalDuration = allActivities.fold(
    0.0,
    (sum, activity) => sum + activity['duration'],
  );

  return StatisticsData(
    title: 'activity_activityStatistics'.tr,
    startDate: startDate,
    endDate: endDate,
    totalValue: totalDuration / 60, // 转换为小时
    totalValueLabel: 'activity_hours'.tr,
    distributionData: coloredDistributionData,
    rankingData: coloredRankingData,
    hourlyDistribution: hourlyDistribution,
    hourlyMainTags: hourlyMainTags,
    extraData: {
      'totalActivities': allActivities.length,
      'averageDuration':
          allActivities.isNotEmpty
              ? allActivities.fold(0.0, (sum, a) => sum + a['duration']) /
                  allActivities.length /
                  60
              : 0,
    },
  );
}

/// 活动统计页面 - 使用通用统计组件
class ActivityStatisticsScreen extends StatelessWidget {
  final ActivityService activityService;

  const ActivityStatisticsScreen({super.key, required this.activityService});

  @override
  Widget build(BuildContext context) {
    return StatisticsScreen(
      config: StatisticsConfig(
        type: StatisticsType.activities,
        title: 'activity_activityStatistics'.tr,
        show24hDistribution: true,
        availableRanges: [
          DateRangeOption.today,
          DateRangeOption.thisWeek,
          DateRangeOption.thisMonth,
          DateRangeOption.thisYear,
          DateRangeOption.custom,
        ],
        defaultRange: DateRangeOption.thisWeek,
      ),
      dataLoader: (range, startDate, endDate) async {
        return await loadStatisticsData(
          activityService,
          range,
          startDate,
          endDate,
        );
      },
      onDateRangeChanged: (state) {
        // 可以在这里处理日期范围变化事件
      },
      onRankingItemTap: (data) {
        // 点击排行榜项目时的处理
        if (data.label.isNotEmpty) {
          // 跳转到标签统计页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TagStatisticsScreen(
                    tagName: data.label,
                    activityService: activityService,
                  ),
            ),
          );
        }
      },
      customSections: (context, statsData) {
        // 返回空列表，使用默认的通用组件布局
        return [];
      },
    );
  }
}
