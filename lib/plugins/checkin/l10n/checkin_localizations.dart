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

  static CheckinLocalizations? of(BuildContext context) {
    return Localizations.of<CheckinLocalizations>(context, CheckinLocalizations);
  }

  static const LocalizationsDelegate<CheckinLocalizations> delegate = _CheckinLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
  String get checkinPluginName;
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
}

class _CheckinLocalizationsDelegate extends LocalizationsDelegate<CheckinLocalizations> {
  const _CheckinLocalizationsDelegate();

  @override
  Future<CheckinLocalizations> load(Locale locale) {
    return SynchronousFuture<CheckinLocalizations>(lookupCheckinLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_CheckinLocalizationsDelegate old) => false;
}

CheckinLocalizations lookupCheckinLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en': return CheckinLocalizationsEn();
    case 'zh': return CheckinLocalizationsZh();
  }

  throw FlutterError(
    'CheckinLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.'
  );
}