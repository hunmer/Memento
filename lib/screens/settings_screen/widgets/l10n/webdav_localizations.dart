import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'webdav_localizations_en.dart';
import 'webdav_localizations_zh.dart';

/// WebDAV设置的本地化支持类
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

  // WebDAV设置相关本地化字符串
  String get pluginName;
  String get serverUrl;
  String get serverUrlHint;
  String get username;
  String get usernameHint;
  String get password;
  String get passwordHint;
  String get testConnection;
  String get connectionSuccess;
  String get connectionFailed;
  String get saveSettings;
  String get settingsSaved;
  String get settingsSaveFailed;
  String get rootPath;
  String get rootPathHint;
  String get syncInterval;
  String get syncIntervalHint;
  String get enableAutoSync;
  String get lastSyncTime;
  String get syncNow;
  String get syncInProgress;
  String get syncCompleted;
  String get syncFailed;
  String get invalidUrl;
  String get invalidCredentials;
  String get serverUnreachable;
  String get permissionDenied;
  String get sslCertificateError;
  String get advancedSettings;
  String get connectionTimeout;
  String get connectionTimeoutHint;
  String get useHTTPS;
  String get verifyCertificate;
  String get maxRetries;
  String get maxRetriesHint;
  String get retryInterval;
  String get retryIntervalHint;

  get passwordEmptyError;

  get saveFailed;

  String get title;

  get serverAddress;

  get serverAddressHint;

  get serverAddressEmptyError;

  String? get serverAddressInvalidError;

  get usernameEmptyError;

  String get dataSync;

  String get uploadAllData;

  String get downloadAllData;
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
