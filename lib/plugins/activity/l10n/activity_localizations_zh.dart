import 'activity_localizations.dart';

/// Chinese localizations for the Activity plugin
class ActivityLocalizationsZh extends ActivityLocalizations {
  ActivityLocalizationsZh() : super('zh');

  @override
  String get grouped => '已分组';

  @override
  String get activityPluginName => '活动';

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

  @override
  String get save => '保存';

  @override
  String get mood => '心情';

  @override
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

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get tagManagement => '标签管理';

  @override
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
}
