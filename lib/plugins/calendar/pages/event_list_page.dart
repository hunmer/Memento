import 'package:flutter/material.dart';
import '../models/event.dart';
import '../widgets/event_detail_card.dart';
import 'package:intl/intl.dart';

class EventListPage extends StatefulWidget {
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventUpdated;
  final Function(CalendarEvent) onEventCompleted;
  final Function(CalendarEvent) onEventDeleted;

  const EventListPage({
    super.key,
    required this.events,
    required this.onEventUpdated,
    required this.onEventCompleted,
    required this.onEventDeleted,
  });

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
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

  String _formatEventTime(CalendarEvent event) {
    final startFormat = DateFormat('MM-dd HH:mm');
    final endFormat = DateFormat('MM-dd HH:mm');

    String timeText = startFormat.format(event.startTime);
    if (event.endTime != null) {
      // 如果是同一天，只显示一次日期
      if (event.startTime.year == event.endTime!.year &&
          event.startTime.month == event.endTime!.month &&
          event.startTime.day == event.endTime!.day) {
        timeText += ' - ${DateFormat('HH:mm').format(event.endTime!)}';
      } else {
        timeText += ' - ${endFormat.format(event.endTime!)}';
      }
    }
    return timeText;
  }

  late List<CalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    // 创建事件列表的副本，按时间排序
    _events = List.from(widget.events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder:
          (context) => EventDetailCard(
            event: event,
            onEdit: () {
              Navigator.pop(context);
              // 编辑事件的逻辑在父组件中处理
              widget.onEventUpdated(event);
            },
            onComplete: () {
              Navigator.pop(context);
              widget.onEventCompleted(event);
              // 从列表中移除已完成的事件
              setState(() {
                _events.remove(event);
              });
            },
            onDelete: () {
              Navigator.pop(context);
              widget.onEventDeleted(event);
              // 从列表中移除已删除的事件
              setState(() {
                _events.remove(event);
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('所有事件')),
      body:
          _events.isEmpty
              ? const Center(child: Text('没有事件'))
              : ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Dismissible(
                    key: Key(event.id),
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // 右滑完成
                        widget.onEventCompleted(event);
                        return true;
                      } else if (direction == DismissDirection.endToStart) {
                        // 左滑删除
                        widget.onEventDeleted(event);
                        return true;
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      setState(() {
                        _events.removeAt(index);
                      });
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(event.icon, color: event.color, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _formatEventTime(event),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (event.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      event.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                  if (event.reminderMinutes != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.notifications,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getReminderText(
                                            event.reminderMinutes!,
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _showEventDetails(event),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
