/// 积分目标进度小组件 - 使用事件携带数据模式
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../events/store_cache_updated_event_args.dart';

/// 积分目标进度小组件
class PointsGoalProgressWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const PointsGoalProgressWidget({required this.config, super.key});

  @override
  State<PointsGoalProgressWidget> createState() =>
      _PointsGoalProgressWidgetState();
}

class _PointsGoalProgressWidgetState extends State<PointsGoalProgressWidget> {
  // 缓存的最新数据
  List<Map<String, dynamic>> _pointsLogs = [];

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['store_cache_updated'],
      onEventWithData: (EventArgs args) {
        if (args is StoreCacheUpdatedEventArgs) {
          setState(() {
            _pointsLogs = args.pointsLogs;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 解析目标值
    final goal = widget.config['goal'] as int?;
    if (goal == null || goal <= 0) {
      return HomeWidget.buildErrorWidget(context, '目标值无效');
    }

    // 计算今日积分
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayPoints = _pointsLogs
        .where(
          (log) =>
              DateTime.parse(log['timestamp']).isAfter(startOfDay) &&
              DateTime.parse(log['timestamp']).isBefore(endOfDay) &&
              log['type'] == '获得',
        )
        .fold(0, (sum, log) => sum + (log['value'] as int));

    final progress = goal > 0 ? (todayPoints / goal).clamp(0.0, 1.0) : 0.0;
    final isCompleted = todayPoints >= goal;

    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          NavigationHelper.pushNamed(context, '/store/points_history');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted ? Icons.emoji_events : Icons.flag,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '今日积分目标',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Icon(Icons.check_circle, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        '$todayPoints / $goal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
