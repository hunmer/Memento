import 'diary_localizations.dart';

/// 英文本地化实现
class DiaryLocalizationsEn extends DiaryLocalizations {
  DiaryLocalizationsEn() : super('en');
  @override
  String get monthProgress => 'Month Progress';

  @override
  String get titleHint => 'Give today\'s diary a title...';

  @override
  String get contentHint => 'Write down today\'s story...';

  @override
  String get selectMood => 'Select Today\'s Mood';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get close => 'Close';

  @override
  String get moodSelectorTooltip => 'Select Mood';
  String get diaryPluginName => 'Diary';

  @override
  String get diaryPluginDescription => 'Diary management plugin';

  @override
  String get todayWordCount => 'Today\'s word count';

  @override
  String get monthWordCount => 'Month\'s word count';

  // Activity form translations
  @override
  String get addActivity => 'Add Activity';
  
  @override
  String get editActivity => 'Edit Activity';
  
  @override
  String get cancel => 'Cancel';
  
  @override
  String get save => 'Save';
  
  @override
  String get activityName => 'Activity Name';
  
  @override
  String get unnamedActivity => 'Unnamed Activity';
  
  @override
  String get activityDescription => 'Activity Description';
  
  @override
  String get startTime => 'Start Time';
  
  @override
  String get endTime => 'End Time';
  
  @override
  String get interval => 'Interval';
  
  @override
  String get minutes => 'minutes';
  
  @override
  String get tags => 'Tags';
  
  @override
  String get tagsHint => 'e.g.: Work, Study, Exercise';
  
  @override
  String get tagsHelperText => 'You can directly enter new tags, they will be automatically saved to Ungrouped';
  
  @override
  String get editInterval => 'Edit Interval';
  
  @override
  String get confirmButton => 'Confirm';
  
  @override
  String get cancelButton => 'Cancel';
  
  @override
  String get endTimeError => 'End time must be later than start time';
  
  @override
  String get minDurationError => 'Activity time must be at least 1 minute';
  
  @override
  String get dayEndError => 'Activity end time cannot exceed 23:59 of the day';

  // Timeline app bar translations
  @override
  String get activityTimeline => 'Activity Timeline';
  
  @override
  String get minutesSelected => '{minutes} minutes selected';
  
  @override
  String get switchToTimelineView => 'Switch to timeline view';
  
  @override
  String get switchToGridView => 'Switch to grid view';
  
  @override
  String get tagManagement => 'Tag Management';
  
  @override
  String get sortBy => 'Sort by';
  
  @override
  String get sortByStartTimeAsc => 'Sort by start time (ascending)';
  
  @override
  String get sortByDuration => 'Sort by activity duration';
  
  @override
  String get sortByStartTimeDesc => 'Sort by start time (descending)';
}