import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'diary_localizations_en.dart';
import 'diary_localizations_zh.dart';

/// 日记插件的本地化支持类
abstract class DiaryLocalizations {
  DiaryLocalizations(String locale) : localeName = locale;

  final String localeName;

  static DiaryLocalizations? of(BuildContext context) {
    return Localizations.of<DiaryLocalizations>(context, DiaryLocalizations);
  }

  static const LocalizationsDelegate<DiaryLocalizations> delegate = _DiaryLocalizationsDelegate();

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

  // 日记插件的本地化字符串
  String get diaryPluginName;
  String get diaryPluginDescription;
  
  // 统计信息
  String get todayWordCount;
  String get monthWordCount;
  String get monthProgress;

  // 日记编辑器
  String get titleHint;
  String get contentHint;
  String get selectMood;
  String get clearSelection;
  String get close;
  String get moodSelectorTooltip;

  // Activity form translations
  String get addActivity;
  String get editActivity;
  String get cancel;
  String get save;
  String get activityName;
  String get unnamedActivity;
  String get activityDescription;
  String get startTime;
  String get endTime;
  String get interval;
  String get minutes;
  String get tags;
  String get tagsHint;
  String get tagsHelperText;
  String get editInterval;
  String get confirmButton;
  String get cancelButton;
  String get endTimeError;
  String get minDurationError;
  String get dayEndError;

  // Timeline app bar translations
  String get activityTimeline;
  String get minutesSelected;
  String get switchToTimelineView;
  String get switchToGridView;
  String get tagManagement;
  String get sortBy;
  String get sortByStartTimeAsc;
  String get sortByDuration;
  String get sortByStartTimeDesc;
  String get mood;
}

class _DiaryLocalizationsDelegate extends LocalizationsDelegate<DiaryLocalizations> {
  const _DiaryLocalizationsDelegate();

  @override
  Future<DiaryLocalizations> load(Locale locale) {
    return SynchronousFuture<DiaryLocalizations>(lookupDiaryLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_DiaryLocalizationsDelegate old) => false;
}

DiaryLocalizations lookupDiaryLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en': return DiaryLocalizationsEn();
    case 'zh': return DiaryLocalizationsZh();
  }

  throw FlutterError(
    'DiaryLocalizations.delegate failed to load unsupported locale \"$locale\". This is likely '
    'an issue with the localization\'s implementation.'
  );
}