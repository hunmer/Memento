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

  String get close => '关闭';

  @override
  String get moodSelectorTooltip => '选择心情';
  @override
  String get name => '日记';

  @override
  String get diaryPluginDescription => '日记管理插件';

  @override
  String get todayWordCount => '今日文字数';

  @override
  String get monthWordCount => '本月文字数';

  // Activity form translations
  @override
  String get addActivity => '添加活动';

  @override
  String get editActivity => '编辑活动';

  @override
  // ignore: override_on_non_overriding_member
  String get cancel => '取消';

  String get save => '保存';

  @override
  String get activityName => '活动名称';

  @override
  String get unnamedActivity => '未命名活动';

  @override
  String get activityDescription => '活动描述';

  String get startTime => '开始时间';

  String get endTime => '结束时间';

  String get interval => '间隔';

  String get minutes => '分钟';

  String get tags => '标签';

  @override
  String get tagsHint => '例如: 工作, 学习, 运动';

  @override
  String get tagsHelperText => '可以直接输入新标签，将自动保存到未分组';

  @override
  String get editInterval => '修改时间间隔';

  @override
  String get confirmButton => '确定';

  @override
  String get cancelButton => '取消';

  @override
  String get endTimeError => '结束时间必须晚于开始时间';

  @override
  String get minDurationError => '活动时间必须至少为1分钟';

  @override
  String get dayEndError => '活动结束时间不能超过当天23:59';

  // Timeline app bar translations
  @override
  String get activityTimeline => '活动时间线';

  @override
  String get minutesSelected => '{minutes}分钟已选中';

  @override
  String get switchToTimelineView => '切换到时间线视图';

  @override
  String get switchToGridView => '切换到网格视图';

  @override
  String get tagManagement => '标签管理';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortByStartTimeAsc => '按开始时间升序';

  @override
  String get sortByDuration => '按活动时长排序';

  @override
  String get sortByStartTimeDesc => '按开始时间降序';

  @override
  String get mood => '心情';

  @override
  String get cannotSelectFutureDate => '不能选择未来的日期';

  @override
  String get myDiary => '我的日记';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get deleteDiary => '删除日记';

  @override
  String get confirmDeleteDiary => '确认删除';

  @override
  String get deleteDiaryMessage => '确定要删除这篇日记吗？此操作无法撤销。';
}
