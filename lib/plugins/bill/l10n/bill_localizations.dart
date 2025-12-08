import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bill_localizations_en.dart';
import 'bill_localizations_zh.dart';

/// 账单插件的本地化支持类
abstract class BillLocalizations {
  BillLocalizations(String locale) : localeName = locale;

  final String localeName;

  static BillLocalizations of(BuildContext context) {
    final localizations = Localizations.of<BillLocalizations>(
      context,
      BillLocalizations,
    );
    assert(localizations != null, 'No BillLocalizations found in context');
    return localizations!;
  }

  static const LocalizationsDelegate<BillLocalizations> delegate =
      _BillLocalizationsDelegate();

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

  // 账单插件的本地化字符串
  String get name;
  String get billList;
  String get newBill;
  String get editBill;
  String get deleteBill;
  String get amount;
  String get category;
  String get date;
  String get note;
  String get income;
  String get expense;
  String get transfer;
  String get save;
  String get cancel;
  String get confirmDelete;
  String get deleteBillConfirmation;
  String get selectCategory;
  String get selectDate;
  String get addNote;
  String get statistics;
  String get monthlyReport;
  String get yearlyReport;
  String get byCategory;
  String get byTime;
  String get allCategories;
  String get noBillsYet;
  String get noBillsFound;
  String get searchBills;
  String get filter;
  String get clearFilter;
  String get fromDate;
  String get toDate;
  String get minAmount;
  String get maxAmount;
  String get type;
  String get allTypes;
  String get billSaved;
  String get billSaveFailed;
  String get billDeleted;
  String get billDeleteFailed;
  String get invalidAmount;
  String get invalidDate;
  String get requiredField;
  String get accountName;
  String get accountManagement;
  String get accountDeleted;
  String get noAccounts;
  String get noBills;
  String get todayFinance;
  String get monthFinance;
  String get monthBills;
  String get accountTitle;
  String get thisWeek;
  String get thisMonth;
  String get thisYear;
  String get all;
  String get custom;
  String get delete;
  String get deleteAccount;
  String get enterAccountName;
  String get confirmDeleteAccountWithBills;

  String get noBillsClickToAdd;
  String get balance;
  String get timeRange;

  String get title => 'Title';
  String get enterTitle => 'Enter title';
  String get enterAmount => 'Enter amount';
  String get enterValidAmount => 'Enter valid amount';
  String get time => 'Time';

  // 新增遗漏的国际化字符串
  String get statisticsAnalysis => '统计分析';
  String get confirmDeleteThisBill => '确定要删除这条账单吗？';
  String get shortcutsAccountingConfig => '快捷记账配置';
  String get configDailyWidget => '配置日视图小组件';
  String get configWeeklyWidget => '配置周视图小组件';
  String get saveConfig => '保存配置';
  String get quickBookkeepingConfig => '快捷记账配置';
  String get income => '收入';
  String get save => '保存';
  String get addQuickPreset => '添加快捷预设';
  String get quickAccountingPreview => '快捷记账预览';
  String get noQuickPresets => '暂无快捷预设';
  String get clickToAddQuickPreset => '点击右下角的 + 按钮添加快捷预设';
  String get editQuickPreset => '编辑快捷预设';
  String get presetName => '预设名称';
  String get presetNameHint => '例如: 早餐、打车';
  String get pleaseEnterPresetName => '请输入预设名称';
  String get presetAmount => '预设金额(可选)';
  String get presetAmountHint => '留空则每次手动输入';
  String get expense => '支出';
  String get add => '添加';
  String get edit => '编辑';
}

class _BillLocalizationsDelegate
    extends LocalizationsDelegate<BillLocalizations> {
  const _BillLocalizationsDelegate();

  @override
  Future<BillLocalizations> load(Locale locale) {
    return SynchronousFuture<BillLocalizations>(
      lookupBillLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_BillLocalizationsDelegate old) => false;
}

BillLocalizations lookupBillLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return BillLocalizationsEn();
    case 'zh':
      return BillLocalizationsZh();
  }

  throw FlutterError(
    'BillLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
