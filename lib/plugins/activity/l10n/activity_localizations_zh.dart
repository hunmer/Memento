import 'activity_localizations.dart';

/// Chinese localizations for the Activity plugin
class ActivityLocalizationsZh extends ActivityLocalizations {
  ActivityLocalizationsZh() : super('zh');

  @override
  String get grouped => '已分组';

  @override
  String get name => '活动';

  @override
  String get activityPluginDescription => '活动记录插件';

  @override
  String get timeline => '时间线';

  @override
  String get statistics => '统计';

  @override
  String get todayActivities => '今日活动';

  @override
  String get todayDuration => '今日时长';

  @override
  String get remainingTime => '剩余时间';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get activityName => '活动名称';

  @override
  String get activityDescription => '描述';

  @override
  String get tags => '标签';

  @override
  String get addTag => '添加标签';

  @override
  String get deleteTag => '删除标签';

  String get save => '保存';

  @override
  String get mood => '心情';

  String get cancel => '取消';

  @override
  String get addActivity => '添加活动';

  @override
  String get editActivity => '编辑活动';

  @override
  String get deleteActivity => '删除活动';

  @override
  String get confirmDelete => '确定要删除这个活动吗？';

  @override
  String get noActivities => '这一天没有活动';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String hoursFormat(double hours) => '${hours.toStringAsFixed(1)}小时';

  @override
  String minutesFormat(int minutes) => '$minutes分钟';

  @override
  String get loadingFailed => '加载数据失败';

  @override
  String get noData => '暂无数据';

  @override
  String get noActivityTimeData => '暂无活动时间数据';

  @override
  String get close => '关闭';

  @override
  String get inputMood => '输入心情';

  @override
  String get confirm => '确定';

  @override
  String get all => '所有';

  @override
  String get ungrouped => '未分组';

  String get recentlyUsed => '最近使用';

  String get tagManagement => '标签管理';

  String get tagsHint => '用逗号分隔标签';

  @override
  String get unnamedActivity => '未命名活动';

  @override
  String get contentHint => '输入活动描述';

  @override
  String get todayRange => '本日';

  @override
  String get weekRange => '本周';

  @override
  String get monthRange => '本月';

  @override
  String get yearRange => '本年';

  @override
  String get customRange => '自定义范围';

  @override
  String get timeDistributionTitle => '活动时间分布';

  @override
  String get activityDistributionTitle => '活动占比统计';

  @override
  String get totalDuration => '总时长';

  @override
  String get activityRecords => '活动记录';

  @override
  String get to => '至';

  @override
  String get hour => '时';

  @override
  String get unrecordedTimeText => '这段时间没有被记录';

  @override
  String get tapToRecordText => '点击记录';

  @override
  String get noActivitiesText => '暂无活动记录';

  @override
  String get minute => '分';

  @override
  String get duration => '持续时间';

  // 设置页面
  @override
  String get settings => '设置';
  @override
  String get notificationSettings => '通知栏设置';
  @override
  String get enableNotificationBar => '启用通知栏显示';
  @override
  String get lastActivity => '最后记录的活动';
  @override
  String get timeSinceLastActivity => '距离上次记录已经过了多久';
  @override
  String get quickActions => '快捷操作';
  @override
  String get addRecord => '添加记录';
  @override
  String get functionDescription => '功能说明';
  @override
  String get notificationEnabled => '活动通知已启用';
  @override
  String get notificationDisabled => '活动通知已禁用';
  @override
  String get failedToLoadSettings => '加载设置失败';
  @override
  String get operationFailed => '操作失败';
  @override
  String get recentActivityInfo => '最近活动信息';
  @override
  String get onlySupportsAndroid => '通知栏显示功能仅支持 Android 平台';

  @override
  String get minimumReminderInterval => '最小提醒间隔';

  @override
  String get minimumReminderIntervalDesc => '距离上次活动至少多久后才显示提醒';

  @override
  String get updateInterval => '通知更新频率';

  @override
  String get updateIntervalDesc => '通知内容更新的时间间隔';

  @override
  String minutesUnit(int minutes) => '$minutes 分钟';

  // 新增遗漏的国际化字符串
  @override
  String get notificationTestResult => '活动通知功能测试结果';

  @override
  String get configDailyWidget => '配置日视图小组件';

  @override
  String get configWeeklyWidget => '配置周视图小组件';

  // 新增的硬编码文本
  @override
  String get morning => '上午';

  @override
  String get afternoon => '下午';

  @override
  String get sortByStartTimeAsc => '按开始时间升序';

  @override
  String get sortByDuration => '按持续时间';

  @override
  String get sortByStartTimeDesc => '按开始时间降序';

  @override
  String activityNotificationTestResult(String error) =>
      '活动通知功能测试结果\n错误信息: $error';
}
