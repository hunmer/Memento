import 'activity_localizations.dart';

/// English localizations for the Activity plugin
class ActivityLocalizationsEn extends ActivityLocalizations {
  ActivityLocalizationsEn() : super('en');

  @override
  String get name => 'Activity';

  @override
  String get activityPluginDescription => 'Activity tracking plugin';

  @override
  String get timeline => 'Timeline';

  @override
  String get statistics => 'Statistics';

  @override
  String get todayActivities => 'Activities';

  @override
  String get todayDuration => 'Duration';

  @override
  String get remainingTime => 'Remaining Time';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get activityName => 'Activity Name';

  @override
  String get activityDescription => 'Description';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add Tag';

  @override
  String get deleteTag => 'Delete Tag';

  @override
  String get mood => 'Mood';

  @override
  String get addActivity => 'Add Activity';

  @override
  String get editActivity => 'Edit Activity';

  @override
  String get deleteActivity => 'Delete Activity';

  @override
  String get confirmDelete => 'Are you sure you want to delete this activity?';

  @override
  String get noActivities => 'No activities for this day';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String hoursFormat(double hours) => '${hours.toStringAsFixed(1)}H';

  @override
  String minutesFormat(int minutes) => '$minutes M';

  @override
  String get loadingFailed => 'Failed to load data';

  @override
  String get noData => 'No data available';

  @override
  String get noActivityTimeData => 'No activity time data';

  @override
  String get close => 'Close';

  @override
  String get inputMood => 'Enter mood';

  @override
  String get confirm => 'Confirm';

  @override
  String get all => 'All';

  @override
  String get ungrouped => 'Ungrouped';

  @override
  String get unnamedActivity => 'Unnamed Activity';

  @override
  String get grouped => 'Grouped';

  @override
  String get todayRange => 'Today';

  @override
  String get weekRange => 'This Week';

  @override
  String get monthRange => 'This Month';

  @override
  String get yearRange => 'This Year';

  @override
  String get customRange => 'Custom Range';

  @override
  String get timeDistributionTitle => 'Activity Time Distribution';

  @override
  String get activityDistributionTitle => 'Activity Distribution';

  @override
  String get totalDuration => 'Total Duration';

  @override
  String get activityRecords => 'Activity Records';

  @override
  String get to => 'to';

  @override
  String get hour => 'h';

  @override
  String get unrecordedTimeText => 'This time period was not recorded';

  @override
  String get tapToRecordText => 'Tap to record';

  @override
  String get noActivitiesText => 'No activity records';

  @override
  String get minute => 'm';

  @override
  String get duration => 'Duration';

  @override
  String get contentHint => 'Enter activity description';

  // Settings page
  @override
  String get settings => 'Settings';
  @override
  String get notificationSettings => 'Notification Bar Settings';
  @override
  String get enableNotificationBar => 'Enable Notification Bar';
  @override
  String get lastActivity => 'Last Activity';
  @override
  String get timeSinceLastActivity => 'Time Since Last Activity';
  @override
  String get quickActions => 'Quick Actions';
  @override
  String get addRecord => 'Add Record';
  @override
  String get functionDescription => 'Function Description';
  @override
  String get notificationEnabled => 'Activity notification enabled';
  @override
  String get notificationDisabled => 'Activity notification disabled';
  @override
  String get failedToLoadSettings => 'Failed to load settings';
  @override
  String get operationFailed => 'Operation failed';
  @override
  String get recentActivityInfo => 'Recent Activity Info';
  @override
  String get onlySupportsAndroid => 'Notification bar display is only supported on Android';

  @override
  String get minimumReminderInterval => 'Minimum Reminder Interval';

  @override
  String get minimumReminderIntervalDesc => 'Show reminder only after this duration since last activity';

  @override
  String get updateInterval => 'Update Frequency';

  @override
  String get updateIntervalDesc => 'How often to update notification content';

  @override
  String minutesUnit(int minutes) => '$minutes min';
}
