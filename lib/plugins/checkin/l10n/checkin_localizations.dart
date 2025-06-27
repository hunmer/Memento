import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'checkin_localizations_en.dart';
import 'checkin_localizations_zh.dart';

/// 打卡插件的本地化支持类
abstract class CheckinLocalizations {
  CheckinLocalizations(String locale) : localeName = locale;

  final String localeName;

  static CheckinLocalizations of(BuildContext context) {
    final localizations = Localizations.of<CheckinLocalizations>(
      context,
      CheckinLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No CheckinLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<CheckinLocalizations> delegate =
      _CheckinLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  // 打卡插件的本地化字符串
  String get name;
  String get checkinPluginDescription;
  String get todayCheckin;
  String get totalCheckinCount;
  String get createCheckin;
  String get editCheckin;
  String get deleteCheckin;
  String get checkinName;
  String get checkinIcon;
  String get save;
  String get cancel;
  String get confirmDelete;
  String get deleteConfirmMessage;
  String get checkinRecords;
  String get noRecords;

  // 默认打卡项目名称
  String get wakeUpEarly;
  String get sleepEarly;
  String get exercise;

  // 分组排序对话框
  String get groupSortTitle;
  String get reverseSort;
  String get confirm;

  // 删除对话框
  String get deleteCheckinItemTitle;

  // 重置对话框
  String get resetCheckinRecordsTitle;
  String get resetCheckinRecordsMessage;

  // 打卡成功对话框
  String get checkinSuccessTitle;
  String get timeRangeLabel;
  String get noteLabel;
  String get consecutiveDaysLabel;

  // 分组管理对话框配置
  String get manageGroupsTitle;
  String get addGroupHint;
  String get addTagHint;
  String get editGroupHint;
  String get allTagsLabel;
  String get newGroupLabel;

  // 操作菜单项
  String get editCheckinItem;
  String get resetCheckinRecords;

  // 确认按钮
  String get confirmReset;

  // 操作结果提示
  String get resetSuccessMessage;
  String get deleteSuccessMessage;

  // 表单相关
  String get addCheckinItem;
  String get editCheckinItemTitle;
  String get nameLabel;
  String get nameHint;
  String get nameRequiredError;
  String get nameExistsError;
  String get groupLabel;
  String get groupHint;
  String get reminderTypeLabel;
  String get noReminder;
  String get weeklyReminder;
  String get monthlyReminder;
  String get specificDateReminder;
  String get monthlyReminderDayLabel;
  String get selectDate;
  String get selectTime;

  // 星期和日期相关
  String get sunday;
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get daySuffix;

  // 新增字段
  String get checkinRecordsTitle;
  String get deleteCheckinRecordTitle;
  String get deleteCheckinRecordMessage;
  String get deleteCheckinRecordSimpleMessage;
  String get checkinButton;
  String get saveFailedMessage;
  String get formValidationMessage;
  String get errorMessage;
  String get saveFirstMessage;
  String get selectContactTitle;
  String get separator;
  String get uncontactedDaysLabel;
  String get tagsLabel;
  String get resetButton;

  String get addSpecificDateCheckin;

  String get addCheckinRecord;

  String get noteHint;

  String get checkinDateLabel;

  String get checkinTimeLabel;

  String get checkinTrendTitle;

  String get checkinRankingTitle;

  String get checkinGroupPieTitle;

  get checkinList;

  get checkinStats;

  String get upcoming;

  String get frequency;

  String get dateAdded;
}

class _CheckinLocalizationsDelegate
    extends LocalizationsDelegate<CheckinLocalizations> {
  const _CheckinLocalizationsDelegate();

  @override
  Future<CheckinLocalizations> load(Locale locale) {
    return SynchronousFuture<CheckinLocalizations>(
      lookupCheckinLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_CheckinLocalizationsDelegate old) => false;
}

CheckinLocalizations lookupCheckinLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return CheckinLocalizationsEn();
    case 'zh':
      return CheckinLocalizationsZh();
  }

  throw FlutterError(
    'CheckinLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
