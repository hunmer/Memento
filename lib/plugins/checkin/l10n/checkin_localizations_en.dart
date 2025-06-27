import 'checkin_localizations.dart';

/// 英文本地化实现
class CheckinLocalizationsEn extends CheckinLocalizations {
  CheckinLocalizationsEn() : super('en');

  @override
  String get name => 'Check-in';

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

  // 表单相关
  @override
  String get addCheckinItem => 'Add Check-in Item';
  @override
  String get editCheckinItemTitle => 'Edit Check-in Item';
  @override
  String get nameLabel => 'Name';
  @override
  String get nameHint => 'Enter check-in item name';
  @override
  String get nameRequiredError => 'Please enter a name';
  @override
  String get nameExistsError => 'This name already exists';
  @override
  String get groupLabel => 'Group (optional)';
  @override
  String get groupHint => 'Enter group name';
  @override
  String get reminderTypeLabel => 'Reminder Type';
  @override
  String get noReminder => 'No Reminder';
  @override
  String get weeklyReminder => 'Weekly Reminder';
  @override
  String get monthlyReminder => 'Monthly Reminder';
  @override
  String get specificDateReminder => 'Specific Date Reminder';
  @override
  String get monthlyReminderDayLabel => 'Monthly Reminder Day';
  @override
  String get selectDate => 'Select Date';
  @override
  String get selectTime => 'Select Time';

  // 星期和日期相关
  @override
  String get sunday => 'Sunday';
  @override
  String get monday => 'Monday';
  @override
  String get tuesday => 'Tuesday';
  @override
  String get wednesday => 'Wednesday';
  @override
  String get thursday => 'Thursday';
  @override
  String get friday => 'Friday';
  @override
  String get saturday => 'Saturday';
  @override
  String get daySuffix => '';

  // 新增字段
  @override
  String get checkinRecordsTitle => '%s\'s Check-in Records';
  @override
  String get deleteCheckinRecordTitle => 'Delete Check-in Record';
  @override
  String get deleteCheckinRecordMessage =>
      'Are you sure you want to delete this check-in record? This cannot be undone.';
  @override
  String get deleteCheckinRecordSimpleMessage =>
      'Are you sure you want to delete this check-in record?';
  @override
  String get checkinButton => 'Check-in';
  @override
  String get saveFailedMessage => 'Save failed: %s';
  @override
  String get formValidationMessage => 'Please fill out the form correctly';
  @override
  String get errorMessage => 'Error: %s';
  @override
  String get saveFirstMessage => 'Please save the contact information first';
  @override
  String get selectContactTitle => 'Select Contact';
  @override
  String get separator => ' - ';
  @override
  String get uncontactedDaysLabel => 'Uncontacted Days:';
  @override
  String get tagsLabel => 'Tags:';
  @override
  String get resetButton => 'Reset';

  @override
  String get addCheckinRecord => 'Add Check-in Record';

  @override
  String get addSpecificDateCheckin => 'Add Check-in for Specific Date';

  @override
  String get checkinDateLabel => 'Check-in Date';

  @override
  String get checkinTimeLabel => 'Check-in Time';

  @override
  String get noteHint => 'Add notes (optional)';

  // 统计页面标题
  @override
  String get checkinTrendTitle => 'Check-in Trend';
  @override
  String get checkinRankingTitle => 'Check-in Ranking';
  @override
  String get checkinGroupPieTitle => 'Check-in Group Distribution';

  @override
  get checkinList => 'List';

  @override
  get checkinStats => 'Statistics';

  @override
  String get dateAdded => 'Date';

  @override
  String get frequency => 'Frequency';

  @override
  String get upcoming => 'Upcoming';
}
