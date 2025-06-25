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

  static TimerLocalizations? of(BuildContext context) {
    return Localizations.of<TimerLocalizations>(context, TimerLocalizations);
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('zh')];

  String get totalTimer;

  String get deleteTimer;

  get deleteTimerConfirmation;
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
