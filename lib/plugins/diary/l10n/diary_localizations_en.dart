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

  String get close => 'Close';

  @override
  String get moodSelectorTooltip => 'Select Mood';
  @override
  String get name => 'Diary';

  @override
  String get diaryPluginDescription => 'Diary management plugin';

  @override
  String get todayWordCount => '1d word';

  @override
  String get monthWordCount => '30d word';

  // Activity form translations
  @override
  String get addActivity => 'Add Activity';

  @override
  String get editActivity => 'Edit Activity';

  String get cancel => 'Cancel';

  String get save => 'Save';

  @override
  String get activityName => 'Activity Name';

  @override
  String get unnamedActivity => 'Unnamed Activity';

  @override
  String get activityDescription => 'Activity Description';

  String get startTime => 'Start Time';

  String get endTime => 'End Time';

  String get interval => 'Interval';

  String get minutes => 'minutes';

  String get tags => 'Tags';

  @override
  String get tagsHint => 'e.g.: Work, Study, Exercise';

  @override
  String get tagsHelperText =>
      'You can directly enter new tags, they will be automatically saved to Ungrouped';

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

  @override
  String get mood => 'Mood';

  @override
  String get cannotSelectFutureDate => 'Cannot select future date';

  @override
  String get myDiary => 'My Diary';

  @override
  String get recentlyUsed => 'Recently Used';

  @override
  String get deleteDiary => 'Delete Diary';

  @override
  String get confirmDeleteDiary => 'Confirm Delete';

  @override
  String get deleteDiaryMessage => 'Are you sure you want to delete this diary? This action cannot be undone.';

  @override
  String get noDiaryForDate => 'No diary for this date';
}
