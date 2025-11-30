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

  static ActivityLocalizations of(BuildContext context) {
    final localizations = Localizations.of<ActivityLocalizations>(
      context,
      ActivityLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No ActivityLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<ActivityLocalizations> delegate =
      _ActivityLocalizationsDelegate();

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

  // Plugin information
  String get name;
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
  String get mood;

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

  // New translations
  String get loadingFailed;
  String get noData;
  String get noActivityTimeData;
  String get close;
  String get inputMood;
  String get confirm;
  String get ungrouped;
  String get grouped;
  String get all;
  String get unnamedActivity;

  // Statistics screen
  String get todayRange;
  String get weekRange;
  String get monthRange;
  String get yearRange;
  String get customRange;
  String get timeDistributionTitle;
  String get activityDistributionTitle;
  String get totalDuration;
  String get activityRecords;

  String get to;
  String get hour;

  // New timeline translations
  String get unrecordedTimeText;
  String get tapToRecordText;
  String get noActivitiesText;
  String get minute;

  // Duration field
  String get duration;

  // Form hints
  String get contentHint;

  // Settings page
  String get settings;
  String get notificationSettings;
  String get enableNotificationBar;
  String get lastActivity;
  String get timeSinceLastActivity;
  String get quickActions;
  String get addRecord;
  String get functionDescription;
  String get notificationEnabled;
  String get notificationDisabled;
  String get failedToLoadSettings;
  String get operationFailed;
  String get recentActivityInfo;
  String get onlySupportsAndroid;

  // Notification timing settings
  String get minimumReminderInterval;
  String get minimumReminderIntervalDesc;
  String get updateInterval;
  String get updateIntervalDesc;
  String minutesUnit(int minutes);
}

class _ActivityLocalizationsDelegate
    extends LocalizationsDelegate<ActivityLocalizations> {
  const _ActivityLocalizationsDelegate();

  @override
  Future<ActivityLocalizations> load(Locale locale) {
    return SynchronousFuture<ActivityLocalizations>(
      lookupActivityLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ActivityLocalizationsDelegate old) => false;
}

ActivityLocalizations lookupActivityLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return ActivityLocalizationsEn();
    case 'zh':
      return ActivityLocalizationsZh();
  }

  throw FlutterError(
    'ActivityLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
