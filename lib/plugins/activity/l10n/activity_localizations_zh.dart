import 'activity_localizations.dart';

/// Chinese localizations for the Activity plugin
class ActivityLocalizationsZh extends ActivityLocalizations {
  ActivityLocalizationsZh() : super('zh');

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
}