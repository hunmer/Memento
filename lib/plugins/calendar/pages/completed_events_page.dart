import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/calendar/utils/date_utils.dart';

class CompletedEventsPage extends StatelessWidget {
  final List<CalendarEvent> completedEvents;

  const CompletedEventsPage({super.key, required this.completedEvents});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('calendar_completedEvents'.tr),
      ),
      body:
          completedEvents.isEmpty
              ? Center(
                child: Text(
                  'calendar_noCompletedEvents'.tr,
                ),
              )
              : ListView.builder(
                itemCount: completedEvents.length,
                itemBuilder: (context, index) {
                  final event = completedEvents[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: event.color,
                      child: Icon(event.icon, color: Colors.white, size: 20),
                    ),
                    title: Text(event.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.description.isNotEmpty)
                          Text(event.description),
                        Text(
                          CalendarDateUtils.formatTimeRange(
                            event.startTime,
                            event.endTime,
                          ),
                        ),
                        Text(
                          '完成时间: ${CalendarDateUtils.formatDateTime(event.completedTime!)}',
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
