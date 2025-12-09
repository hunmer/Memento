/// 日记插件英文翻译
class DiaryTranslationsEn {
  static const Map<String, String> translations = {
    // 插件基本信息
    'diary_name': 'Diary',
    'diary_diaryPluginDescription': 'Diary management plugin',

    // Widget related
    'diary_widgetName': 'Diary',
    'diary_widgetDescription': 'Quick access to diary',
    'diary_overviewName': 'Diary Overview',
    'diary_overviewDescription': 'Display today\'s word count and monthly progress',

    // 统计信息
    'diary_todayWordCount': '1d word',
    'diary_monthWordCount': '30d word',
    'diary_monthProgress': 'Month Progress',

    // 日记编辑器
    'diary_titleHint': 'Give today\'s diary a title...',
    'diary_contentHint': 'Write down today\'s story...',
    'diary_selectMood': 'Select Today\'s Mood',
    'diary_clearSelection': 'Clear Selection',
    'diary_moodSelectorTooltip': 'Select Mood',

    // Activity form translations
    'diary_addActivity': 'Add Activity',
    'diary_editActivity': 'Edit Activity',
    'diary_activityName': 'Activity Name',
    'diary_unnamedActivity': 'Unnamed Activity',
    'diary_activityDescription': 'Activity Description',
    'diary_tagsHint': 'e.g.: Work, Study, Exercise',
    'diary_tagsHelperText':
        'You can directly enter new tags, they will be automatically saved to Ungrouped',
    'diary_editInterval': 'Edit Interval',
    'diary_confirmButton': 'Confirm',
    'diary_cancelButton': 'Cancel',
    'diary_endTimeError': 'End time must be later than start time',
    'diary_minDurationError': 'Activity time must be at least 1 minute',
    'diary_dayEndError': 'Activity end time cannot exceed 23:59 of the day',

    // Timeline app bar translations
    'diary_activityTimeline': 'Activity Timeline',
    'diary_minutesSelected': '@minutes minutes selected',
    'diary_switchToTimelineView': 'Switch to timeline view',
    'diary_switchToGridView': 'Switch to grid view',
    'diary_tagManagement': 'Tag Management',
    'diary_sortBy': 'Sort by',
    'diary_sortByStartTimeAsc': 'Sort by start time (ascending)',
    'diary_sortByDuration': 'Sort by activity duration',
    'diary_sortByStartTimeDesc': 'Sort by start time (descending)',

    // 心情与日记管理
    'diary_mood': 'Mood',
    'diary_cannotSelectFutureDate': 'Cannot select future date',
    'diary_myDiary': 'My Diary',
    'diary_recentlyUsed': 'Recently Used',
    'diary_deleteDiary': 'Delete Diary',
    'diary_confirmDeleteDiary': 'Confirm Delete',
    'diary_deleteDiaryMessage':
        'Are you sure you want to delete this diary? This action cannot be undone.',
    'diary_noDiaryForDate': 'No diary for this date',

    // 按钮文本
    'diary_edit': 'Edit',
    'diary_create': 'Create',

    // 额外的翻译（在实现类中但未在抽象类中声明）
    'diary_cancel': 'Cancel',
    'diary_save': 'Save',
    'diary_close': 'Close',
    'diary_startTime': 'Start Time',
    'diary_endTime': 'End Time',
    'diary_interval': 'Interval',
    'diary_minutes': 'minutes',
    'diary_tags': 'Tags',
  };
}
