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

  static CalendarLocalizations? of(BuildContext context) {
    return Localizations.of<CalendarLocalizations>(
      context,
      CalendarLocalizations,
    );
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
  String get pluginName;
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

  // 辅助方法，用于直接获取本地化文本
  static String getText(BuildContext context, String key) {
    final localizations = of(context);
    if (localizations == null) {
      debugPrint('CalendarLocalizations not found in context');
      return key;
    }

    switch (key) {
      case 'pluginName':
        return localizations.pluginName;
      case 'calendar':
        return localizations.calendar;
      case 'eventCount':
        return localizations.eventCount;
      case 'weekEvents':
        return localizations.weekEvents;
      case 'expiredEvents':
        return localizations.expiredEvents;
      case 'allEvents':
        return localizations.allEvents;
      case 'completedEvents':
        return localizations.completedEvents;
      case 'backToToday':
        return localizations.backToToday;
      case 'addEvent':
        return localizations.addEvent;
      case 'editEvent':
        return localizations.editEvent;
      case 'deleteEvent':
        return localizations.deleteEvent;
      case 'completeEvent':
        return localizations.completeEvent;
      case 'eventTitle':
        return localizations.eventTitle;
      case 'eventDescription':
        return localizations.eventDescription;
      case 'startTime':
        return localizations.startTime;
      case 'endTime':
        return localizations.endTime;
      case 'save':
        return localizations.save;
      case 'cancel':
        return localizations.cancel;
      case 'delete':
        return localizations.delete;
      case 'confirmDeleteEvent':
        return localizations.confirmDeleteEvent;
      case 'noEvents':
        return localizations.noEvents;
      case 'dayView':
        return localizations.dayView;
      case 'weekView':
        return localizations.weekView;
      case 'workWeekView':
        return localizations.workWeekView;
      case 'monthView':
        return localizations.monthView;
      case 'timelineDayView':
        return localizations.timelineDayView;
      case 'timelineWeekView':
        return localizations.timelineWeekView;
      case 'timelineWorkWeekView':
        return localizations.timelineWorkWeekView;
      case 'scheduleView':
        return localizations.scheduleView;
      default:
        debugPrint('Unknown localization key: $key');
        return key;
    }
  }
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
      return CalendarLocalizationsEn();
    case 'zh':
      return CalendarLocalizationsZh();
  }

  throw FlutterError(
    'CalendarLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
