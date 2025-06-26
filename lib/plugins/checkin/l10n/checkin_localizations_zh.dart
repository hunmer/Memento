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

  // 表单相关
  @override
  String get addCheckinItem => '添加打卡项目';
  @override
  String get editCheckinItemTitle => '编辑打卡项目';
  @override
  String get nameLabel => '名称';
  @override
  String get nameHint => '请输入打卡项目名称';
  @override
  String get nameRequiredError => '请输入名称';
  @override
  String get nameExistsError => '该名称已存在';
  @override
  String get groupLabel => '分组 (可选)';
  @override
  String get groupHint => '请输入分组名称';
  @override
  String get reminderTypeLabel => '提醒类型';
  @override
  String get noReminder => '不设置提醒';
  @override
  String get weeklyReminder => '每周提醒';
  @override
  String get monthlyReminder => '每月提醒';
  @override
  String get specificDateReminder => '特定日期提醒';
  @override
  String get monthlyReminderDayLabel => '每月提醒日期';
  @override
  String get selectDate => '选择日期';
  @override
  String get selectTime => '选择提醒时间';

  // 星期和日期相关
  @override
  String get sunday => '周日';
  @override
  String get monday => '周一';
  @override
  String get tuesday => '周二';
  @override
  String get wednesday => '周三';
  @override
  String get thursday => '周四';
  @override
  String get friday => '周五';
  @override
  String get saturday => '周六';
  @override
  String get daySuffix => '日';

  // 新增字段
  @override
  String get checkinRecordsTitle => '%s的打卡记录';
  @override
  String get deleteCheckinRecordTitle => '删除打卡记录';
  @override
  String get deleteCheckinRecordMessage => '确定要删除这条打卡记录吗？此操作不可恢复。';
  @override
  String get deleteCheckinRecordSimpleMessage => '确定要删除这条打卡记录吗？';
  @override
  String get checkinButton => '打卡';
  @override
  String get saveFailedMessage => '保存失败: %s';
  @override
  String get formValidationMessage => '请正确填写表单';
  @override
  String get errorMessage => '错误: %s';
  @override
  String get saveFirstMessage => '请先保存联系人信息';
  @override
  String get selectContactTitle => '选择联系人';
  @override
  String get separator => ' - ';
  @override
  String get uncontactedDaysLabel => '未联系天数:';
  @override
  String get tagsLabel => '标签:';
  @override
  String get resetButton => '重置';

  @override
  String get addCheckinRecord => '添加打卡记录';

  @override
  String get addSpecificDateCheckin => '添加指定日期打卡';

  @override
  String get checkinDateLabel => '打卡日期';

  @override
  String get checkinTimeLabel => '打卡时间';

  @override
  String get noteHint => '添加备注(可选)';

  // 统计页面标题
  @override
  String get checkinTrendTitle => '打卡数量趋势';
  @override
  String get checkinRankingTitle => '连续打卡排行榜';
  @override
  String get checkinGroupPieTitle => '打卡分组占比';
}
