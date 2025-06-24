import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventDetailCard extends StatelessWidget {
  String _getReminderText(int minutes) {
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return '提前$days天';
    } else if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return '提前$hours小时';
    } else {
      return '提前$minutes分钟';
    }
  }

  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const EventDetailCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和图标
            Row(
              children: [
                Icon(event.icon, size: 24, color: event.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 时间信息
            _buildInfoRow(
              context,
              Icons.access_time,
              '${DateFormat('yyyy-MM-dd HH:mm').format(event.startTime)}\n${event.endTime != null ? "至\n${DateFormat('yyyy-MM-dd HH:mm').format(event.endTime!)}" : ''}',
            ),
            if (event.reminderMinutes != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.notifications,
                '提醒设置：${_getReminderText(event.reminderMinutes!)}',
              ),
            ],
            const SizedBox(height: 16),

            // 描述
            if (event.description.isNotEmpty) ...[
              _buildInfoRow(context, Icons.description, event.description),
              const SizedBox(height: 16),
            ],

            // 按钮行
            if (event.source == 'default')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    '编辑',
                    Icons.edit,
                    Colors.blue,
                    onEdit,
                  ),
                  _buildActionButton(
                    context,
                    '完成',
                    Icons.check_circle,
                    Colors.green,
                    onComplete,
                  ),
                  _buildActionButton(
                    context,
                    '删除',
                    Icons.delete,
                    Colors.red,
                    onDelete,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: label,
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
