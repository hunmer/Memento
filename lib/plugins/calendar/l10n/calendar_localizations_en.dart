
import 'calendar_localizations.dart';

class CalendarLocalizationsEn extends CalendarLocalizations {
  CalendarLocalizationsEn(super.locale);

  @override
  String get name => 'Calendar';

  @override
  String get calendar => 'Calendar';

  @override
  String get eventCount => 'Total';

  @override
  String get weekEvents => '7 days';

  @override
  String get expiredEvents => 'Expired';

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

  String get save => 'Save';

  String get cancel => 'Cancel';

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
  String get reminderSettings => 'Reminder settings';

  @override
  String get selectDateRangeFirst => 'Please select date range first';

  @override
  String get selectReminderTime => 'Select reminder time';

  @override
  String get enterEventTitle => 'Please enter event title';

  @override
  String get endTimeCannotBeEarlier =>
      'End time cannot be earlier than start time';

  @override
  String get dateRange => 'Date range';
}
