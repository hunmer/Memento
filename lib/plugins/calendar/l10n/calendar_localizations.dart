import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'calendar_localizations_en.dart';
import 'calendar_localizations_zh.dart';

/// 日历插件的本地化支持类
abstract class CalendarLocalizations {
  CalendarLocalizations(String locale) : localeName = locale;

  final String localeName;

  static CalendarLocalizations of(BuildContext context) {
    final localizations = Localizations.of<CalendarLocalizations>(
      context,
      CalendarLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No CalendarLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<CalendarLocalizations> delegate =
      _CalendarLocalizationsDelegate();

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

  // 日历插件的本地化字符串
  String get name;
  String get calendar;
  String get eventCount;
  String get weekEvents;
  String get expiredEvents;
  String get allEvents;
  String get completedEvents;
  String get backToToday;
  String get addEvent;
  String get editEvent;
  String get deleteEvent;
  String get completeEvent;
  String get eventTitle;
  String get eventDescription;
  String get startTime;
  String get endTime;
  String get confirmDeleteEvent;
  String get noEvents;
  String get dayView;
  String get weekView;
  String get workWeekView;
  String get monthView;
  String get timelineDayView;
  String get timelineWeekView;
  String get timelineWorkWeekView;
  String get scheduleView;
  String get noCompletedEvents;

  String get reminderSettings;

  String get selectReminderTime;

  String get selectDateRangeFirst;

  String get enterEventTitle;

  String get endTimeCannotBeEarlier;

  String get dateRange;
  String get complete => '完成';
}

class _CalendarLocalizationsDelegate
    extends LocalizationsDelegate<CalendarLocalizations> {
  const _CalendarLocalizationsDelegate();

  @override
  Future<CalendarLocalizations> load(Locale locale) {
    return SynchronousFuture<CalendarLocalizations>(
      lookupCalendarLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_CalendarLocalizationsDelegate old) => false;
}

CalendarLocalizations lookupCalendarLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return CalendarLocalizationsEn(locale.languageCode);
    case 'zh':
      return CalendarLocalizationsZh(locale.languageCode);
  }

  throw FlutterError(
    'CalendarLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
