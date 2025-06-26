import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'webdav_localizations_en.dart';
import 'webdav_localizations_zh.dart';

/// WebDAV设置对话框的本地化支持类
abstract class WebDAVLocalizations {
  WebDAVLocalizations(String locale) : localeName = locale;

  final String localeName;

  static WebDAVLocalizations of(BuildContext context) {
    final localizations = Localizations.of<WebDAVLocalizations>(
      context,
      WebDAVLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No WebDAVLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<WebDAVLocalizations> delegate =
      _WebDAVLocalizationsDelegate();

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

  // WebDAV设置对话框的本地化字符串
  String get settingsTitle;
  String get serverAddressLabel;
  String get serverAddressHint;
  String get serverAddressEmptyError;
  String get serverAddressInvalidError;
  String get usernameLabel;
  String get usernameEmptyError;
  String get passwordLabel;
  String get passwordEmptyError;
  String get dataPathLabel;
  String get dataPathHint;
  String get dataPathEmptyError;
  String get dataPathInvalidError;
  String get autoSyncLabel;
  String get autoSyncSubtitle;
  String get testConnectionButton;
  String get disconnectButton;
  String get downloadButton;
  String get uploadButton;
  String get connectingStatus;
  String get connectionSuccessStatus;
  String get connectionFailedStatus;
  String get connectionErrorStatus;
  String get disconnectingStatus;
  String get disconnectedStatus;
  String get uploadingStatus;
  String get uploadSuccessStatus;
  String get uploadFailedStatus;
  String get downloadingStatus;
  String get downloadSuccessStatus;
  String get downloadFailedStatus;
  String get autoSyncEnabledStatus;
  String get autoSyncDisabledStatus;
  String get settingsSavedMessage;
}

class _WebDAVLocalizationsDelegate
    extends LocalizationsDelegate<WebDAVLocalizations> {
  const _WebDAVLocalizationsDelegate();

  @override
  Future<WebDAVLocalizations> load(Locale locale) {
    return SynchronousFuture<WebDAVLocalizations>(
      lookupWebDAVLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_WebDAVLocalizationsDelegate old) => false;
}

WebDAVLocalizations lookupWebDAVLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return WebDAVLocalizationsEn();
    case 'zh':
      return WebDAVLocalizationsZh();
  }

  throw FlutterError(
    'WebDAVLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}