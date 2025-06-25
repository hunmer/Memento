import 'package:flutter/material.dart';

import 'calendar_localizations.dart';

class CalendarLocalizationsEn extends CalendarLocalizations {
  CalendarLocalizationsEn(super.locale);

  @override
  String get pluginName => 'Calendar';

  @override
  String get calendar => 'Calendar';

  @override
  String get eventCount => 'Total events';

  @override
  String get weekEvents => 'Events in 7 days';

  @override
  String get expiredEvents => 'Expired events';

  @override
  String get allEvents => 'All events';

  @override
  String get completedEvents => 'Completed events';

  @override
  String get backToToday => 'Back to today';

  @override
  String get addEvent => 'Add event';

  @override
  String get editEvent => 'Edit event';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String get completeEvent => 'Complete event';

  @override
  String get eventTitle => 'Event title';

  @override
  String get eventDescription => 'Description';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteEvent =>
      'Are you sure you want to delete this event?';

  @override
  String get noEvents => 'No events';

  @override
  String get dayView => 'Day';

  @override
  String get weekView => 'Week';

  @override
  String get workWeekView => 'Work week';

  @override
  String get monthView => 'Month';

  @override
  String get timelineDayView => 'Timeline day';

  @override
  String get timelineWeekView => 'Timeline week';

  @override
  String get timelineWorkWeekView => 'Timeline work week';

  @override
  String get scheduleView => 'Schedule';

  @override
  String get noCompletedEvents => 'No completed events';

  @override
  // TODO: implement reminderSettings
  String get reminderSettings => throw UnimplementedError();

  @override
  // TODO: implement selectDateRangeFirst
  String get selectDateRangeFirst => throw UnimplementedError();

  @override
  // TODO: implement selectReminderTime
  String get selectReminderTime => throw UnimplementedError();

  @override
  // TODO: implement enterEventTitle
  String get enterEventTitle => throw UnimplementedError();

  @override
  // TODO: implement endTimeCannotBeEarlier
  String get endTimeCannotBeEarlier => throw UnimplementedError();
}
