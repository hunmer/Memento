import 'diary_localizations.dart';

/// 中文本地化实现
class DiaryLocalizationsZh extends DiaryLocalizations {
  DiaryLocalizationsZh() : super('zh');
  @override
  String get monthProgress => '本月完成度';

  @override
  String get titleHint => '给今天的日记起个标题...';

  @override
  String get contentHint => '写下今天的故事...';

  @override
  String get selectMood => '选择今天的心情';

  @override
  String get clearSelection => '清除选择';

  @override
  String get close => '关闭';

  @override
  String get moodSelectorTooltip => '选择心情';
  String get diaryPluginName => '日记';

  @override
  String get diaryPluginDescription => '日记管理插件';

  @override
  String get todayWordCount => '今日文字数';

  @override
  String get monthWordCount => '本月文字数';

}