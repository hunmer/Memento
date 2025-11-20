import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'habits_localizations_en.dart';
import 'habits_localizations_zh.dart';

/// 习惯插件的本地化支持类
abstract class HabitsLocalizations {
  HabitsLocalizations(String locale) : localeName = locale;

  final String localeName;

  static HabitsLocalizations of(BuildContext context) {
    final localizations = Localizations.of<HabitsLocalizations>(
      context,
      HabitsLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No HabitsLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<HabitsLocalizations> delegate =
      _HabitsLocalizationsDelegate();

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

  // 习惯插件的本地化字符串
  String get name;
  String get habitsList;
  String get newHabit;
  String get editHabit;
  String get deleteHabit;
  String get habitName;
  String get habitNameHint;
  String get habitDescription;
  String get habitDescriptionHint;
  String get habitFrequency;
  String get daily;
  String get weekly;
  String get monthly;
  String get habitReminder;
  String get habitReminderHint;
  String get habitColor;
  String get habitIcon;
  String get habitStreak;
  String get habitHistory;
  String get habitStatistics;
  String get habitCompletion;
  String get habitCompletionHint;
  String get habitCreated;
  String get habitUpdated;
  String get habitDeleted;
  String get habitNotFound;
  String get habitAlreadyExists;
  String get habitNameCannotBeEmpty;
  String get habitDescriptionCannotBeEmpty;
  String get habitFrequencyCannotBeEmpty;
  String get habitReminderCannotBeEmpty;
  String get habitColorCannotBeEmpty;
  String get habitIconCannotBeEmpty;
  String get habitStreakCannotBeEmpty;
  String get habitHistoryCannotBeEmpty;
  String get habitStatisticsCannotBeEmpty;
  String get habitCompletionCannotBeEmpty;
  String get habitCreatedCannotBeEmpty;
  String get habitUpdatedCannotBeEmpty;
  String get habitDeletedCannotBeEmpty;
  String get habitNotFoundCannotBeEmpty;
  String get habitAlreadyExistsCannotBeEmpty;

  String get deleteHabitConfirmation =>
      'Are you sure you want to delete habit "\${habit.name}"? This action cannot be undone.';

  String get habits;

  String get skills;

  get recordDeleted;

  String get deleteRecord;

  String get deleteRecordMessage;

  get completions;

  get totalDuration;

  get title;

  get pleaseEnterTitle;

  get notes;

  get group;

  get duration;

  get minutes;

  get skill;

  String get selectSkill;

  String get save;

  String get history;

  String get cancel;

  String get delete;

  String get clearAllRecords;

  String get createHabit;

  get records;

  get statistics;

  String get editSkill;

  String get deleteSkill;

  String get deleteSkillConfirmation;

  get skillName;

  get skillDescription;

  get skillGroup;

  get maxDuration;

  get noLimitHint;

  String get sortByName;

  String get sortByCompletions;

  String get sortByDuration;

  String get createSkill;

  String get totalCompletions;

  String get statisticsChartsPlaceholder;

  get habit;

  String daysStreak(int days);
  String weeksStreak(int weeks);
  String monthsStreak(int months);
  String habitCompletionPercentage(int percentage);
}

class _HabitsLocalizationsDelegate
    extends LocalizationsDelegate<HabitsLocalizations> {
  const _HabitsLocalizationsDelegate();

  @override
  Future<HabitsLocalizations> load(Locale locale) {
    return SynchronousFuture<HabitsLocalizations>(
      lookupHabitsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_HabitsLocalizationsDelegate old) => false;
}

HabitsLocalizations lookupHabitsLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return HabitsLocalizationsEn();
    case 'zh':
      return HabitsLocalizationsZh();
  }

  throw FlutterError(
    'HabitsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
