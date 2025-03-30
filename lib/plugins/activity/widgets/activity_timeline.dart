import 'package:flutter/material.dart';
import '../models/activity_record.dart';

class ActivityTimeline extends StatelessWidget {
  final List<ActivityRecord> activities;
  final Function(ActivityRecord)? onActivityTap;

  const ActivityTimeline({
    super.key,
    required this.activities,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildTimelineItem(context, activity, index);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, ActivityRecord activity, int index) {
    return InkWell(
      onTap: () => onActivityTap?.call(activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间线
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 活动内容
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '持续时间: ${activity.formattedDuration}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (activity.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          activity.description!,
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      if (activity.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: activity.tags.map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          )).toList(),
                        ),
                      ],
                    ],
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