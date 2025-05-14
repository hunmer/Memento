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
    Key? key,
    required this.events,
    required this.onEventUpdated,
    required this.onEventCompleted,
    required this.onEventDeleted,
  }) : super(key: key);

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
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
      builder: (context) => EventDetailCard(
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
      appBar: AppBar(
        title: const Text('所有事件'),
      ),
      body: _events.isEmpty
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
                    child: const Icon(Icons.check_circle, color: Colors.white),
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
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(event.startTime),
                    ),
                    onTap: () => _showEventDetails(event),
                  ),
                );
              },
            ),
    );
  }
}