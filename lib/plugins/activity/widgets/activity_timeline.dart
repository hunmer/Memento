import 'package:flutter/material.dart';
import '../models/activity_record.dart';

class ActivityTimeline extends StatelessWidget {
  final Function(DateTime start, DateTime end)? onUnrecordedTimeTap;
  final Function(ActivityRecord)? onDeleteActivity;
  final List<ActivityRecord> activities;
  final Function(ActivityRecord)? onActivityTap;

  const ActivityTimeline({
    super.key,
    required this.activities,
    this.onActivityTap,
    this.onUnrecordedTimeTap,
    this.onDeleteActivity,
  });

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h\n${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildUnrecordedTimeGap(
    BuildContext context,
    DateTime start,
    DateTime end,
    int gapMinutes,
  ) {
    return InkWell(
      onTap: () => onUnrecordedTimeTap?.call(start, end),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 时间线
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: 4,
                              height: double.infinity,
                              color: Colors.grey[400],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _formatDuration(start, end),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 未记录的活动卡片
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.history_toggle_off_rounded,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '这段时间没有被记录',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '点击记录',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimeDisplay(gapMinutes),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeDisplay(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours小时$minutes分钟';
    } else if (hours > 0) {
      return '$hours小时';
    } else {
      return '$minutes分钟';
    }
  }

  List<Widget> _buildTimelineItems(BuildContext context) {
    final List<Widget> items = [];
    final now = DateTime.now();

    // 获取今天的开始时间 (00:00)
    final today = DateTime(now.year, now.month, now.day);

    // 1. 检查一天开始到第一个活动之间的间隙
    if (activities.isNotEmpty) {
      final firstActivity = activities.first;
      final morningGap = firstActivity.startTime.difference(today).inMinutes;

      if (morningGap > 1) {
        items.add(
          _buildUnrecordedTimeGap(
            context,
            today,
            firstActivity.startTime,
            morningGap,
          ),
        );
      }
    }

    // 2. 添加所有活动和活动之间的间隙
    for (int i = 0; i < activities.length; i++) {
      // 添加活动
      items.add(_buildTimelineItem(context, activities[i], i));

      // 如果不是最后一个活动，检查与下一个活动之间的间隙
      if (i < activities.length - 1) {
        final currentActivity = activities[i];
        final nextActivity = activities[i + 1];
        final gap =
            nextActivity.startTime
                .difference(currentActivity.endTime)
                .inMinutes;

        if (gap > 1) {
          items.add(
            _buildUnrecordedTimeGap(
              context,
              currentActivity.endTime,
              nextActivity.startTime,
              gap,
            ),
          );
        }
      }
    }

    // 3. 检查最后一个活动到现在的间隙
    if (activities.isNotEmpty) {
      final lastActivity = activities.last;
      final eveningGap = now.difference(lastActivity.endTime).inMinutes;

      if (eveningGap > 1) {
        items.add(
          _buildUnrecordedTimeGap(
            context,
            lastActivity.endTime,
            now,
            eveningGap,
          ),
        );
      }
    } else {
      // 如果没有活动，显示整天的未记录时间
      final wholeDayGap = now.difference(today).inMinutes;
      if (wholeDayGap > 0) {
        items.add(_buildUnrecordedTimeGap(context, today, now, wholeDayGap));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty &&
        DateTime.now()
                .difference(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                )
                .inMinutes ==
            0) {
      return const Center(
        child: Text(
          '暂无活动记录',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView(children: _buildTimelineItems(context));
  }

  Widget _buildTimelineItem(
    BuildContext context,
    ActivityRecord activity,
    int index,
  ) {
    // 使用GlobalKey来获取卡片的高度
    final cardKey = GlobalKey();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: IntrinsicHeight(
        // 使用IntrinsicHeight使Row的子元素高度一致
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 拉伸子元素以填充高度
          children: [
            // 时间线
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // 分散对齐，使开始和结束时间分别在顶部和底部
                children: [
                  Text(
                    '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    // 使Stack填充中间空间
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 主垂直连接线 - 现在会自动填充整个高度
                        Center(
                          child: Container(
                            width: 4,
                            height: double.infinity, // 使用无限高度，让父级约束决定实际高度
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        // 圆形时间指示器（带背景色覆盖线条）
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatDuration(
                                activity.startTime,
                                activity.endTime,
                              ),
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${activity.endTime.hour.toString().padLeft(2, '0')}:${activity.endTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 活动内容
            Expanded(
              child: Dismissible(
                key: Key('activity_${activity.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('确认删除'),
                        content: Text('确定要删除活动"${activity.title}"吗？'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('删除'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  if (onDeleteActivity != null) {
                    onDeleteActivity!(activity);
                  }
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: InkWell(
                  onTap: () => onActivityTap?.call(activity),
                  child: Card(
                    key: cardKey,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            activity.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (activity.mood != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              activity.mood!,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (activity.description != null &&
                                        activity.description!.isNotEmpty)
                                      Text(
                                        activity.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  activity.formattedDuration,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (activity.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children:
                                  activity.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withAlpha(25),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
