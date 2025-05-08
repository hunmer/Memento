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
  String get deleteConfirmMessage => 'Are you sure you want to delete this check-in item?';

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
}