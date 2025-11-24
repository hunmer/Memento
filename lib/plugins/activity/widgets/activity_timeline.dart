import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
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

  Color _getActivityColor(ActivityRecord activity) {
    // Generate a consistent color based on the activity title
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.redAccent,
    ];
    final hashCode = activity.title.hashCode;
    return colors[hashCode.abs() % colors.length];
  }

  IconData _getActivityIcon(ActivityRecord activity) {
    // Simple mapping based on title keywords, fallback to default
    final title = activity.title.toLowerCase();
    if (title.contains('phone') || title.contains('手机')) return Icons.phone_iphone;
    if (title.contains('sleep') || title.contains('睡觉')) return Icons.bed;
    if (title.contains('eat') || title.contains('food') || title.contains('吃饭')) return Icons.restaurant;
    if (title.contains('sport') || title.contains('run') || title.contains('运动')) return Icons.fitness_center;
    if (title.contains('work') || title.contains('工作')) return Icons.work;
    if (title.contains('study') || title.contains('学习')) return Icons.book;
    if (title.contains('game') || title.contains('游戏')) return Icons.games;
    return Icons.local_activity;
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours小时$minutes分钟';
    } else if (hours > 0) {
      return '$hours小时';
    } else {
      return '$minutes分钟';
    }
  }

  Widget _buildTimeColumn(BuildContext context, DateTime start, DateTime end) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Theme.of(context).dividerColor,
            ),
          ),
          Text(
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.only(bottom: 16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimeColumn(context, start, end),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withAlpha(150),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          color: Theme.of(context).hintColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ActivityLocalizations.of(context).unrecordedTimeText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                ActivityLocalizations.of(context).tapToRecordText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
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
                            color: Theme.of(context).dividerColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDuration(start, end),
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
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

  Widget _buildTimelineItem(
    BuildContext context,
    ActivityRecord activity,
    int index,
  ) {
    final color = _getActivityColor(activity);
    final icon = _getActivityIcon(activity);

    return Dismissible(
      key: Key('activity_${activity.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(ActivityLocalizations.of(context).confirmDelete),
              content: Text(
                '${ActivityLocalizations.of(context).confirmDelete.replaceFirst('确定要删除', '确定要删除活动')}"${activity.title}"吗？',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(ActivityLocalizations.of(context).deleteActivity),
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
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () => onActivityTap?.call(activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimeColumn(context, activity.startTime, activity.endTime),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Colored Bar
                        Container(
                          width: 6,
                          color: color.withAlpha(200),
                        ),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Title
                                    Expanded(
                                      child: Text(
                                        activity.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Mood (if any)
                                    if (activity.mood != null) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          activity.mood!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                    // Duration
                                    Text(
                                      _formatDuration(
                                        activity.startTime,
                                        activity.endTime,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).hintColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                // Description
                                if (activity.description != null && activity.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      activity.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ),
                                // Tags
                                if (activity.tags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: activity.tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: color.withAlpha(200),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTimelineItems(BuildContext context) {
    final List<Widget> items = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Padding top
    items.add(const SizedBox(height: 24)); // pt-6

    if (activities.isNotEmpty) {
      final firstActivity = activities.first;
      // Check if we are viewing a past date or future date to handle "start of day"
      // For simplicity, we use the activity's date as the "day" base
      final activityDate = DateTime(firstActivity.startTime.year, firstActivity.startTime.month, firstActivity.startTime.day);
      
      // 1. Morning Gap (from 00:00 to first activity)
      final morningGap = firstActivity.startTime.difference(activityDate).inMinutes;
      if (morningGap > 1) {
        items.add(_buildUnrecordedTimeGap(context, activityDate, firstActivity.startTime, morningGap));
      }
    }

    for (int i = 0; i < activities.length; i++) {
      items.add(_buildTimelineItem(context, activities[i], i));

      if (i < activities.length - 1) {
        final current = activities[i];
        final next = activities[i + 1];
        final gap = next.startTime.difference(current.endTime).inMinutes;
        if (gap > 1) {
          items.add(_buildUnrecordedTimeGap(context, current.endTime, next.startTime, gap));
        }
      }
    }

    // End Gap (only if today and showing "now", or if we want to show 'til end of day?)
    // The original code showed gap to 'now' if it's today.
    if (activities.isNotEmpty) {
      final lastActivity = activities.last;
      // If it's today, show gap to now
      if (lastActivity.endTime.year == now.year && 
          lastActivity.endTime.month == now.month && 
          lastActivity.endTime.day == now.day && 
          now.isAfter(lastActivity.endTime)) {
          
          final endGap = now.difference(lastActivity.endTime).inMinutes;
          if (endGap > 1) {
             items.add(_buildUnrecordedTimeGap(context, lastActivity.endTime, now, endGap));
          }
      }
    } else {
       // No activities. Show whole day gap if it's today?
       // Original code had this.
       if (now.year == today.year && now.month == today.month && now.day == today.day) {
         final gap = now.difference(today).inMinutes;
         if (gap > 0) {
           items.add(_buildUnrecordedTimeGap(context, today, now, gap));
         }
       }
    }

    // Padding bottom
    items.add(const SizedBox(height: 96)); // pb-24

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty &&
        DateTime.now().difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inMinutes == 0) {
      return Center(
        child: Text(
          ActivityLocalizations.of(context).noActivitiesText,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // px-4
      child: ListView(
        children: _buildTimelineItems(context),
      ),
    );
  }
}
