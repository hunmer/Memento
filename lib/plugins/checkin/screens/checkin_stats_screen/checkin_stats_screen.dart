import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:flutter/material.dart';
import '../../checkin_plugin.dart';
import 'widgets/daily_checkin_chart.dart';
import 'widgets/checkin_streak_ranking.dart';
import 'widgets/checkin_group_pie_chart.dart';

class CheckinStatsScreen extends StatefulWidget {
  final List<CheckinItem> checkinItems;
  
  const CheckinStatsScreen({
    super.key,
    required this.checkinItems,
  });

  @override
  State<CheckinStatsScreen> createState() => _CheckinStatsScreenState();
}

class _CheckinStatsScreenState extends State<CheckinStatsScreen> {
  bool _isMonthly = false; // 控制是显示周视图还是月视图

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 时间范围选择器
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('周'),
                    selected: !_isMonthly,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _isMonthly = false);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('月'),
                    selected: _isMonthly,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _isMonthly = true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 每日打卡数量统计图
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '打卡数量趋势',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: DailyCheckinChart(
                      isMonthly: _isMonthly,
                      checkinItems: widget.checkinItems,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 连续打卡排行榜
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '连续打卡排行榜',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  CheckinStreakRanking(
                    checkinItems: widget.checkinItems,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 打卡分组占比
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '打卡分组占比',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: CheckinGroupPieChart(
                      checkinItems: widget.checkinItems,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}