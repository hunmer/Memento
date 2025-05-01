import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'activity_localizations_en.dart';
import 'activity_localizations_zh.dart';

/// Activity plugin localization support class
abstract class ActivityLocalizations {
  ActivityLocalizations(String locale) : localeName = locale;

  final String localeName;

  static ActivityLocalizations? of(BuildContext context) {
    return Localizations.of<ActivityLocalizations>(context, ActivityLocalizations);
  }

  static const LocalizationsDelegate<ActivityLocalizations> delegate = _ActivityLocalizationsDelegate();

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

  // Plugin information
  String get activityPluginName;
  String get activityPluginDescription;
  
  // Navigation and titles
  String get timeline;
  String get statistics;
  
  // Card view labels
  String get todayActivities;
  String get todayDuration;
  String get remainingTime;
  
  // Activity form
  String get startTime;
  String get endTime;
  String get activityName;
  String get activityDescription;
  String get tags;
  String get addTag;
  String get deleteTag;
  String get save;
  String get mood;
  String get cancel;
  
  // Timeline screen
  String get addActivity;
  String get editActivity;
  String get deleteActivity;
  String get confirmDelete;
  String get noActivities;
  
  // Time formatting
  String get today;
  String get yesterday;
  String hoursFormat(double hours);
  String minutesFormat(int minutes);
}

class _ActivityLocalizationsDelegate extends LocalizationsDelegate<ActivityLocalizations> {
  const _ActivityLocalizationsDelegate();

  @override
  Future<ActivityLocalizations> load(Locale locale) {
    return SynchronousFuture<ActivityLocalizations>(lookupActivityLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ActivityLocalizationsDelegate old) => false;
}

ActivityLocalizations lookupActivityLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return ActivityLocalizationsEn();
    case 'zh': return ActivityLocalizationsZh();
  }

  throw FlutterError(
    'ActivityLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.'
  );
}