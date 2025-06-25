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

  // 分组排序对话框
  @override
  String get groupSortTitle => '分组排序方式';

  @override
  String get reverseSort => '反向排序';

  @override
  String get confirm => '确定';

  // 删除对话框
  @override
  String get deleteCheckinItemTitle => '删除打卡项';

  // 重置对话框
  @override
  String get resetCheckinRecordsTitle => '重置打卡记录';
  @override
  String get resetCheckinRecordsMessage => '确定要重置此项目的所有打卡记录吗？这将清除所有历史数据且无法恢复。';

  // 打卡成功对话框
  @override
  String get checkinSuccessTitle => '打卡成功';
  @override
  String get timeRangeLabel => '时间段';
  @override
  String get noteLabel => '备注';
  @override
  String get consecutiveDaysLabel => '连续打卡天数';

  // 分组管理对话框配置
  @override
  String get manageGroupsTitle => '管理分组';
  @override
  String get addGroupHint => '请输入分组名称';
  @override
  String get addTagHint => '请输入打卡项目名称';
  @override
  String get editGroupHint => '请输入新的分组名称';
  @override
  String get allTagsLabel => '所有打卡项目';
  @override
  String get newGroupLabel => '新建分组';

  // 操作菜单项
  @override
  String get editCheckinItem => '编辑打卡项目';
  @override
  String get resetCheckinRecords => '重置打卡记录';

  // 确认按钮
  @override
  String get confirmReset => '确定重置';

  // 操作结果提示
  @override
  String get resetSuccessMessage => '已重置"%s"的打卡记录';
  @override
  String get deleteSuccessMessage => '已删除"%s"';
}
