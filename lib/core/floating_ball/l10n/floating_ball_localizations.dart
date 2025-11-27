import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'floating_ball_localizations_en.dart';
import 'floating_ball_localizations_zh.dart';

/// 悬浮球的本地化支持类
abstract class FloatingBallLocalizations {
  FloatingBallLocalizations(String locale) : localeName = locale;

  final String localeName;

  static FloatingBallLocalizations? of(BuildContext context) {
    return Localizations.of<FloatingBallLocalizations>(
      context,
      FloatingBallLocalizations,
    );
  }

  static const LocalizationsDelegate<FloatingBallLocalizations> delegate =
      _FloatingBallLocalizationsDelegate();

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

  // 悬浮球的本地化字符串
  String get noRecentPlugin;
  String get pageRefreshed;
  String get floatingBallSettings;
  String get enableFloatingBall;
  String get small;
  String get large;
  String get positionReset;
  String get resetPosition;
  String get notSet;
  String get noAction;
  String get tapGesture;
  String get swipeUpGesture;
  String get swipeDownGesture;
  String get swipeLeftGesture;
  String get swipeRightGesture;
  String get resetOverlayPosition;
  String get overlayPositionReset;
}

class _FloatingBallLocalizationsDelegate
    extends LocalizationsDelegate<FloatingBallLocalizations> {
  const _FloatingBallLocalizationsDelegate();

  @override
  Future<FloatingBallLocalizations> load(Locale locale) {
    return SynchronousFuture<FloatingBallLocalizations>(
      lookupFloatingBallLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_FloatingBallLocalizationsDelegate old) => false;
}

FloatingBallLocalizations lookupFloatingBallLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return FloatingBallLocalizationsEn(locale.toLanguageTag());
    case 'zh':
      return FloatingBallLocalizationsZh(locale.toLanguageTag());
  }

  throw FlutterError(
    'FloatingBallLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
