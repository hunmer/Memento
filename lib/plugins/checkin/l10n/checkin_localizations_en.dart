import 'checkin_localizations.dart';

/// 英文本地化实现
class CheckinLocalizationsEn extends CheckinLocalizations {
  CheckinLocalizationsEn() : super('en');

  @override
  String get checkinPluginName => 'Check-in';

  @override
  String get checkinPluginDescription => 'Manage daily check-in items';

  @override
  String get todayCheckin => 'Today';

  @override
  String get totalCheckinCount => 'Total';

  @override
  String get createCheckin => 'Create Check-in';

  @override
  String get editCheckin => 'Edit Check-in';

  @override
  String get deleteCheckin => 'Delete Check-in';

  @override
  String get checkinName => 'Check-in Name';

  @override
  String get checkinIcon => 'Check-in Icon';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this check-in item?';

  @override
  String get checkinRecords => 'Check-in Records';

  @override
  String get noRecords => 'No records yet';

  // 默认打卡项目名称
  @override
  String get wakeUpEarly => 'Wake Up Early';

  @override
  String get sleepEarly => 'Sleep Early';

  @override
  String get exercise => 'Exercise';

  // 分组排序对话框
  @override
  String get groupSortTitle => 'Group Sorting';

  @override
  String get reverseSort => 'Reverse Sort';

  @override
  String get confirm => 'Confirm';

  // 删除对话框
  @override
  String get deleteCheckinItemTitle => 'Delete Check-in Item';

  // 重置对话框
  @override
  String get resetCheckinRecordsTitle => 'Reset Check-in Records';
  @override
  String get resetCheckinRecordsMessage =>
      'Are you sure you want to reset all check-in records for this item? This will clear all historical data and cannot be undone.';

  // 打卡成功对话框
  @override
  String get checkinSuccessTitle => 'Check-in Success';
  @override
  String get timeRangeLabel => 'Time Range';
  @override
  String get noteLabel => 'Note';
  @override
  String get consecutiveDaysLabel => 'Consecutive Days';

  // 分组管理对话框配置
  @override
  String get manageGroupsTitle => 'Manage Groups';
  @override
  String get addGroupHint => 'Enter group name';
  @override
  String get addTagHint => 'Enter check-in item name';
  @override
  String get editGroupHint => 'Enter new group name';
  @override
  String get allTagsLabel => 'All Check-in Items';
  @override
  String get newGroupLabel => 'New Group';

  // 操作菜单项
  @override
  String get editCheckinItem => 'Edit Check-in Item';
  @override
  String get resetCheckinRecords => 'Reset Check-in Records';

  // 确认按钮
  @override
  String get confirmReset => 'Confirm Reset';
  // 操作结果提示
  @override
  String get resetSuccessMessage => 'Check-in records for "%s" have been reset';
  @override
  String get deleteSuccessMessage => '"%s" has been deleted';
}
