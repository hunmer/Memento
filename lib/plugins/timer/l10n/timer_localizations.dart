import 'package:Memento/plugins/timer/l10n/timer_localizations_en.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class TimerLocalizations {
  TimerLocalizations(String locale) : localeName = locale;

  final String localeName;

  static const LocalizationsDelegate<TimerLocalizations> delegate =
      _TimerLocalizationsDelegate();

  static TimerLocalizations of(BuildContext context) {
    final localizations = Localizations.of<TimerLocalizations>(
      context,
      TimerLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No TimerLocalizations found in context');
    }
    return localizations;
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('zh')];

  String get name;
  String get totalTimer;
  String get deleteTimer;
  String get deleteTimerConfirmation;
  String get countUpTimer;
  String get countDownTimer;
  String get pomodoroTimer;
  String get enableNotification;
  String get addTimer;
  String get reset;

  // 新增计时器相关本地化键
  String get timerName;
  String get timerDescription;
  String get timerType;
  String get repeatCount;
  String get hours;
  String get minutes;
  String get seconds;
  String get workDuration;
  String get breakDuration;
  String get cycleCount;
  String get taskName;
  String get selectGroup;

  // 新增缺失的字符串
  String get cancelTimer;
  String get pauseTimerConfirm;
  String get continueTimer;
  String get confirmCancel;
  String get completeTimer;
  String get completeTimerConfirm;
  String get timerNotePrefix;
  String get continueAdjust;
  String get confirmComplete;
}

class _TimerLocalizationsDelegate
    extends LocalizationsDelegate<TimerLocalizations> {
  const _TimerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<TimerLocalizations> load(Locale locale) {
    return SynchronousFuture<TimerLocalizations>(
      lookupTimerLocalizations(locale),
    );
  }

  @override
  bool shouldReload(_TimerLocalizationsDelegate old) => false;
}

TimerLocalizations lookupTimerLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return TimerLocalizationsEn();
    case 'zh':
      return TimerLocalizationsZh();
  }

  throw FlutterError(
    'TimerLocalizations.delegate failed to load unsupported locale "$locale". '
    'This is likely an issue with the localizations setup.',
  );
}
