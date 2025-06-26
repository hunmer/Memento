import 'activity_localizations.dart';

/// English localizations for the Activity plugin
class ActivityLocalizationsEn extends ActivityLocalizations {
  ActivityLocalizationsEn() : super('en');

  @override
  String get activityPluginName => 'Activity';

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
  String minutesFormat(int minutes) => '$minutes min';

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
  String get recentlyUsed => 'Recently Used';

  @override
  String get tagManagement => 'Tag Management';

  @override
  String get tagsHint => 'Separate tags with commas';

  @override
  String get unnamedActivity => 'Unnamed Activity';

  @override
  String get contentHint => 'Enter activity description';

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
  String get hour => 'hour';
}
