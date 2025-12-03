import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_record.dart';

// Custom painter for the dashed timeline
class DashedLinePainter extends CustomPainter {
  final BuildContext context;
  DashedLinePainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Theme.of(context).dividerColor
      ..strokeWidth = 1.5; // Increased stroke width

    const double dashHeight = 4.0;
    const double dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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

  Color _getPrimaryColor(BuildContext context) => const Color(0xfff472b6);

  Color _getColorFromTag(BuildContext context, ActivityRecord activity) {
    if (activity.tags.isEmpty) {
      return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
    }
    final colors = [
      Colors.blue.shade100,
      Colors.indigo.shade100,
      Colors.orange.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.red.shade100,
      Colors.amber.shade100,
      Colors.cyan.shade100,
    ];
    final hashCode = activity.tags.first.hashCode;
    return colors[hashCode.abs() % colors.length];
  }

  IconData _getActivityIcon(ActivityRecord activity) {
    final title = activity.title.toLowerCase();
    if (title.contains('phone') || title.contains('手机')) return Icons.phone_iphone;
    if (title.contains('sleep') || title.contains('睡觉')) return Icons.bed_outlined;
    if (title.contains('eat') || title.contains('food') || title.contains('吃饭')) return Icons.restaurant_outlined;
    if (title.contains('sport') || title.contains('run') || title.contains('运动')) return Icons.fitness_center_outlined;
    if (title.contains('work') || title.contains('工作')) return Icons.work_outline;
    if (title.contains('study') || title.contains('学习')) return Icons.book_outlined;
    if (title.contains('game') || title.contains('游戏')) return Icons.games_outlined;
    if (title.contains('shower') || title.contains('洗澡')) return Icons.shower_outlined;
    if (title.contains('clean') || title.contains('打扫')) return Icons.cleaning_services_outlined;
    if (title.contains('read') || title.contains('阅读') || title.contains('bible')) return Icons.menu_book_outlined;
    if (title.contains('rise') || title.contains('get up') || title.contains('起床')) return Icons.alarm;
    return Icons.local_activity_outlined;
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inMinutes == 0) return '';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours h $minutes min';
    } else if (hours > 0) {
      return '$hours h';
    } else {
      return '$minutes min';
    }
  }

  Widget _buildTimelineItem(BuildContext context, ActivityRecord activity) {
    final primaryColor = _getPrimaryColor(context);
    final icon = _getActivityIcon(activity);
    final duration = activity.endTime.difference(activity.startTime);
    final showDuration = duration.inMinutes > 0;
    
    final double height = (duration.inMinutes * 1.5).clamp(64.0, 400.0);
    final capsuleColor = _getColorFromTag(context, activity);

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
                    '${ActivityLocalizations.of(context).confirmDelete.replaceFirst('确定要删除', '确定要删除活动 ')}"${activity.title}"吗?',
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
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: InkWell(
            onTap: () => onActivityTap?.call(activity),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 1. Time Column
                SizedBox(
                    width: 40,
                    child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                        DateFormat('H:mm').format(activity.startTime),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        ),
                    ),
                    ),
                ),
                const SizedBox(width: 8),

                // 2. Content Column
                Expanded(
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        // Icon with timeline capsule
                        SizedBox(
                          height: height,
                          child: Center(
                            child: Container(
                                width: 48,
                                height: height * 0.8,
                                decoration: BoxDecoration(
                                    color: capsuleColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor,
                                        width: 1.5,
                                    )
                                ),
                                child: Center(
                                    child: Icon(
                                    icon,
                                    color: primaryColor,
                                    size: 28,
                                    fill: 1.0,
                                    ),
                                ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Text content
                        Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                if (showDuration)
                                Text(
                                    '${DateFormat('H:mm').format(activity.startTime)} - ${DateFormat('H:mm').format(activity.endTime)} (${_formatDuration(activity.startTime, activity.endTime)})',
                                    style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                ),
                                Text(
                                activity.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                ),
                                ),
                                if (activity.description != null && activity.description!.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                    activity.description!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    ),
                                ),
                                if (activity.tags.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Wrap(
                                      spacing: 6.0,
                                      runSpacing: 4.0,
                                      children: activity.tags
                                          .map((tag) => Chip(
                                                label: Text(tag),
                                                labelStyle: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                                backgroundColor: capsuleColor.withOpacity(0.7),
                                                padding: EdgeInsets.zero,
                                                labelPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                visualDensity: VisualDensity.compact,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                            ],
                            ),
                        ),
                        ),
                    ],
                    ),
                ),
                
                // 3. Right side mood emoji
                SizedBox(
                    width: 30,
                    height: 48,
                    child: Center(
                    child: (activity.mood != null && activity.mood!.isNotEmpty)
                        ? Text(
                            activity.mood!,
                            style: const TextStyle(fontSize: 20),
                          )
                        : const SizedBox.shrink(),
                    ),
                ),
                ],
            ),
            ),
        ),
    );
  }

  Widget _buildUnrecordedTimeGap(BuildContext context, DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inMinutes <= 1) return const SizedBox.shrink();
    
    final double height = (duration.inMinutes * 1.5).clamp(64.0, 400.0);
    final capsuleColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return InkWell(
      onTap: () => onUnrecordedTimeTap?.call(start, end),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Time Column
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  DateFormat('H:mm').format(start),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 2. Content Column
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with timeline capsule
                  SizedBox(
                    height: height,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: height * 0.8,
                        decoration: BoxDecoration(
                          color: capsuleColor,
                          borderRadius: BorderRadius.circular(24),
                           border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1.5,
                            )
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text content
                  Expanded(
                    child: Text(
                      '${ActivityLocalizations.of(context).unrecordedTimeText} (${_formatDuration(start, end)})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineSlices(BuildContext context) {
    final List<Widget> items = [];
    if (activities.isEmpty) return items;

    final dayStart = DateTime(activities.first.startTime.year, activities.first.startTime.month, activities.first.startTime.day);
    DateTime lastEventEnd = dayStart;

    if (activities.first.startTime.isAfter(lastEventEnd)) {
      items.add(_buildUnrecordedTimeGap(context, lastEventEnd, activities.first.startTime));
    }

    for (int i = 0; i < activities.length; i++) {
      final currentActivity = activities[i];
      
      if (currentActivity.startTime.isAfter(lastEventEnd)) {
        items.add(_buildUnrecordedTimeGap(context, lastEventEnd, currentActivity.startTime));
      }

      items.add(_buildTimelineItem(context, currentActivity));
      lastEventEnd = currentActivity.endTime;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (lastEventEnd.year == today.year && lastEventEnd.month == today.month && lastEventEnd.day == today.day) {
        if (now.isAfter(lastEventEnd)) {
            items.add(_buildUnrecordedTimeGap(context, lastEventEnd, now));
        }
    }


    return items;
  }

  @override
  Widget build(BuildContext context) {
    final slices = _buildTimelineSlices(context);

    if (slices.isEmpty) {
      return Center(
        child: Text(
          ActivityLocalizations.of(context).noActivitiesText,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
        ),
      );
    }

    const double timeColWidth = 40;
    const double timeGapWidth = 8;
    const double iconWidth = 48;
    const double listHorizontalPadding = 12;
    const double lineStrokeWidth = 1.5;

    return Stack(
      children: [
        Positioned(
          top: 16,
          left: listHorizontalPadding + timeColWidth + timeGapWidth + (iconWidth / 2) - (lineStrokeWidth / 2),
          bottom: 0,
          child: CustomPaint(
            size: const Size(lineStrokeWidth, double.infinity),
            painter: DashedLinePainter(context: context),
          ),
        ),
        ListView(
            padding: const EdgeInsets.symmetric(horizontal: listHorizontalPadding, vertical: 16.0),
            children: slices,
        ),
      ],
    );
  }
}
