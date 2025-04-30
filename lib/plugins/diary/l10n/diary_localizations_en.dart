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

}