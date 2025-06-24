import 'package:flutter/material.dart';
import '../models/event.dart';
import '../utils/date_utils.dart';

class CompletedEventsPage extends StatelessWidget {
  final List<CalendarEvent> completedEvents;

  const CompletedEventsPage({super.key, required this.completedEvents});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CalendarLocalizations.getText(context, 'completedEvents')),
      ),
      body:
          completedEvents.isEmpty
              ? const Center(
                child: Text(
                  CalendarLocalizations.getText(context, 'noCompletedEvents'),
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
