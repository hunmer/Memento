import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventDetailCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const EventDetailCard({
    Key? key,
    required this.event,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // 时间信息
            _buildInfoRow(
              context,
              Icons.access_time,
              '${DateFormat('yyyy-MM-dd HH:mm').format(event.startTime)}\n${event.endTime != null ? DateFormat('yyyy-MM-dd HH:mm').format(event.endTime!) : ''}',
            ),
            const SizedBox(height: 16),
            
            // 描述
            if (event.description?.isNotEmpty ?? false) ...[
              _buildInfoRow(
                context,
                Icons.description,
                event.description!,
              ),
              const SizedBox(height: 16),
            ],
            
            // 按钮行
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
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}