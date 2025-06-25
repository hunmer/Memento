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

  static BillLocalizations? of(BuildContext context) {
    return Localizations.of<BillLocalizations>(context, BillLocalizations);
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
  String get pluginName;
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
