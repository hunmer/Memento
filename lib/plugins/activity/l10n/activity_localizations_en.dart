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
  String get todayActivities => 'Today\'s Activities';
  
  @override
  String get todayDuration => 'Today\'s Duration';
  
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
  String get save => 'Save';
  
  @override
  String get cancel => 'Cancel';
  
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
}