import 'checkin_localizations.dart';

/// 中文本地化实现
class CheckinLocalizationsZh extends CheckinLocalizations {
  CheckinLocalizationsZh() : super('zh');

  @override
  String get checkinPluginName => '打卡';

  @override
  String get checkinPluginDescription => '管理日常打卡项目';

  @override
  String get todayCheckin => '今日打卡';

  @override
  String get totalCheckinCount => '总打卡数';

  @override
  String get createCheckin => '创建打卡';

  @override
  String get editCheckin => '编辑打卡';

  @override
  String get deleteCheckin => '删除打卡';

  @override
  String get checkinName => '打卡名称';

  @override
  String get checkinIcon => '打卡图标';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get deleteConfirmMessage => '确定要删除这个打卡项目吗？';

  @override
  String get checkinRecords => '打卡记录';

  @override
  String get noRecords => '暂无记录';

  // 默认打卡项目名称
  @override
  String get wakeUpEarly => '早起';

  @override
  String get sleepEarly => '早睡';

  @override
  String get exercise => '运动';
}