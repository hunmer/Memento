import 'tracker_localizations.dart';

class TrackerLocalizationsZh extends TrackerLocalizations {
  TrackerLocalizationsZh(super.locale);

  @override
  String get goalsTitle => '目标';

  @override
  String get recordsTitle => '记录';

  @override
  String get createGoal => '创建目标';

  @override
  String get editGoal => '编辑目标';

  @override
  String get goalName => '目标名称';

  @override
  String get goalNameHint => '输入目标名称';

  @override
  String get unitType => '单位';

  @override
  String get unitTypeHint => '如 ml, 页, 分钟';

  @override
  String get targetValue => '目标总量';

  @override
  String get dateSettings => '日期设置';

  @override
  String get reminder => '提醒';

  @override
  String get dailyReset => '每日重置';

  @override
  String get save => '保存';

  @override
  String get quickRecordTitle => '快速记录 - {goalName}';

  @override
  String get recordTitle => '记录 {goalName}';

  @override
  String get calculateDifference => '计算差值';

  @override
  String get confirm => '确认';

  @override
  String get confirmClear => '确认清空';

  @override
  String get confirmClearMessage => '确定要清空所有记录吗？此操作不可撤销。';

  @override
  String get recordsCleared => '记录已清空';

  @override
  String get currentProgress => '当前进度: {currentValue}/{targetValue}';

  @override
  String get reminderTime => '提醒时间: {reminderTime}';

  @override
  String get recordHistory => '记录历史';

  @override
  String get noRecords => '暂无记录';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get confirmDeleteRecordMessage => '确定要删除这条记录吗？';

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get todayComplete => '今日完成';

  @override
  String get thisMonthComplete => '本月完成';

  @override
  String get quickRecord => '快速记录';
  @override
  String get createGroup => '新建分组';
  @override
  String get timer => '计时';

  @override
  String get cancel => '取消';

  @override
  String get addRecord => '添加记录';

  @override
  String get recordValue => '记录值';

  @override
  String recordValueDisplay(double value) => '$value';

  @override
  String get note => '备注';

  @override
  String get noteHint => '可选备注';

  @override
  String get daily => '每日';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get dateRange => '日期范围';

  @override
  String get selectDays => '选择日期';

  @override
  String get selectDate => '选择日期';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get progress => '进度';

  @override
  String get history => '历史记录';

  @override
  String get todayRecords => '今日记录';

  @override
  String get totalGoals => '目标总数';

  @override
  String get goalTracking => '目标跟踪';

  @override
  String get all => '全部';

  @override
  String get inProgress => '进行中';

  @override
  String get completed => '已完成';

  @override
  String get recent => '最近';

  @override
  String get thisWeek => '本周';

  @override
  String get thisMonth => '本月';

  @override
  String get confirmDeletion => '确认删除';

  @override
  String get goalDeleted => '已删除目标';

  @override
  String get totalTimer => '总计时器';

  @override
  String get timerTitle => '计时 - {goalName}';

  @override
  get selectGroup => '选择分组';

  @override
  String get incrementValueWithUnit => '增加值 (\${unit})';

  @override
  String get inputTargetValue => '输入目标值';

  @override
  String get recordValueWithUnit => '记录值 (\${unit})';

  @override
  String get name => '进度';

  // Widget configuration
  @override
  String get configureGoalProgressBarWidget => '配置目标进度条小组件';

  @override
  String get configureGoalTrackingWidget => '配置目标追踪小组件';

  @override
  String get backgroundColor => '背景色';

  @override
  String get accentColor => '强调色';

  @override
  String get progressBarColor => '进度条颜色';

  @override
  String get configured => '已配置';

  @override
  String get configurationFailed => '配置失败';
}
