import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'settings_screen_localizations_en.dart';
import 'settings_screen_localizations_zh.dart';

/// 设置屏幕的本地化支持类
abstract class SettingsScreenLocalizations {
  SettingsScreenLocalizations(String locale) : localeName = locale;

  final String localeName;

  static SettingsScreenLocalizations of(BuildContext context) {
    final localizations = Localizations.of<SettingsScreenLocalizations>(
      context,
      SettingsScreenLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No SettingsScreenLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<SettingsScreenLocalizations> delegate =
      _SettingsScreenLocalizationsDelegate();

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

  // 设置屏幕的本地化字符串
  String get settingsTitle;
  String get languageTitle;
  String get languageSubtitle;
  String get darkModeTitle;
  String get darkModeSubtitle;
  String get exportDataTitle;
  String get exportDataSubtitle;
  String get dataManagementTitle;
  String get dataManagementSubtitle;
  String get importDataTitle;
  String get importDataSubtitle;
  String get fullBackupTitle;
  String get fullBackupSubtitle;
  String get fullRestoreTitle;
  String get fullRestoreSubtitle;
  String get webDAVTitle;
  String get webDAVConnected;
  String get webDAVDisconnected;
  String get floatingBallTitle;
  String get floatingBallEnabled;
  String get floatingBallDisabled;
  String get autoBackupTitle;
  String get autoBackupSubtitle;
  String get autoOpenLastPluginTitle;
  String get autoOpenLastPluginSubtitle;
  String get autoCheckUpdateTitle;
  String get autoCheckUpdateSubtitle;
  String get checkUpdateTitle;
  String get checkUpdateSubtitle;
  String get logSettingsTitle;
  String get logSettingsSubtitle;

  String get updateAvailableTitle;
  String get updateAvailableContent;
  String get updateLaterButton;
  String get updateViewButton;
  String get alreadyLatestVersion;
  String get updateCheckFailed;
  String get checkingForUpdates;
}

class _SettingsScreenLocalizationsDelegate
    extends LocalizationsDelegate<SettingsScreenLocalizations> {
  const _SettingsScreenLocalizationsDelegate();

  @override
  Future<SettingsScreenLocalizations> load(Locale locale) {
    return SynchronousFuture<SettingsScreenLocalizations>(
      lookupSettingsScreenLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SettingsScreenLocalizationsDelegate old) => false;
}

SettingsScreenLocalizations lookupSettingsScreenLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return SettingsScreenLocalizationsEn();
    case 'zh':
      return SettingsScreenLocalizationsZh();
  }

  throw FlutterError(
    'SettingsScreenLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
