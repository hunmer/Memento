import 'package:flutter/material.dart';
import 'package:Memento/widgets/adaptive_switch.dart';
import '../../models/reminder.dart';

/// 提醒卡片组件
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 图片缩略图
                  if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          reminder.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 24,
                                ),
                              ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration:
                                      reminder.isEnabled
                                          ? null
                                          : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 启用开关
                            AdaptiveSwitch(
                              value: reminder.isEnabled,
                              onChanged: (_) => onToggle?.call(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reminder.getFrequencyDisplayText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (reminder.nextTriggerAt != null) ...[
                    Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatNextTrigger(reminder.nextTriggerAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNextTrigger(DateTime nextTrigger) {
    final now = DateTime.now();
    final difference = nextTrigger.difference(now);

    if (difference.inMinutes < 1) {
      return '即将触发';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟后';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时后';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天后';
    } else {
      return '${nextTrigger.month}/${nextTrigger.day}';
    }
  }
}
