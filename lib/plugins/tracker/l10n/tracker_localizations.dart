import 'package:Memento/plugins/tracker/l10n/tracker_localizations_en.dart';
import 'package:Memento/plugins/tracker/l10n/tracker_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class TrackerLocalizations {
  TrackerLocalizations(String locale) : localeName = locale;

  final String localeName;

  static const LocalizationsDelegate<TrackerLocalizations> delegate =
      _TrackerLocalizationsDelegate();

  static TrackerLocalizations? of(BuildContext context) {
    return Localizations.of<TrackerLocalizations>(
      context,
      TrackerLocalizations,
    );
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('zh')];

  // Goals
  String get goalsTitle;
  String get recordsTitle;
  String get createGoal;
  String get editGoal;
  String get goalName;
  String get goalNameHint;
  String get unitType;
  String get unitTypeHint;
  String get targetValue;
  String get dateSettings;
  String get reminder;
  String get dailyReset;
  String get save;
  String get cancel;
  String get addRecord;
  String get recordValue;
  String get note;
  String get noteHint;
  String get daily;
  String get weekly;
  String get monthly;
  String get dateRange;
  String get selectDays;
  String get selectDate;
  String get startDate;
  String get endDate;
  String get progress;
  String get history;
  String get todayRecords;
  String get totalGoals;
  String get goalTracking;
  String get all;
  String get inProgress;
  String get completed;
  String get recent;
  String get thisWeek;
  String get thisMonth;
  String get confirmDeletion;
  String get goalDeleted;
  String get totalTimer;
  String get timerTitle;
  String get quickRecordTitle;
  String get recordTitle;
  String get calculateDifference;
  String get confirm;
  String get confirmClear;
  String get confirmClearMessage;
  String get recordsCleared;
  String get currentProgress;
  String get reminderTime;
  String get recordHistory;
  String get noRecords;
  String get confirmDelete;
  String get recordDeleted;
  String get todayComplete;
  String get thisMonthComplete;
  String get thisMonthNew;
}

class _TrackerLocalizationsDelegate
    extends LocalizationsDelegate<TrackerLocalizations> {
  const _TrackerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<TrackerLocalizations> load(Locale locale) {
    return SynchronousFuture<TrackerLocalizations>(
      lookupTrackerLocalizations(locale),
    );
  }

  @override
  bool shouldReload(_TrackerLocalizationsDelegate old) => false;
}

TrackerLocalizations lookupTrackerLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return TrackerLocalizationsEn(locale.languageCode);
    case 'zh':
      return TrackerLocalizationsZh(locale.languageCode);
  }

  throw FlutterError(
    'TrackerLocalizations.delegate failed to load unsupported locale "$locale". '
    'This is likely an issue with the localizations setup.',
  );
}
