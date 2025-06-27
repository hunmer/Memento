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
  String get name;
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
  String get dataSync;
  String get downloadAllData;
  String get passwordEmptyError;
  String get saveFailed;
  String get serverAddress;
  String get serverAddressEmptyError;
  String get serverAddressHint;
  String? get serverAddressInvalidError;
  String get title;
  String get uploadAllData;
  String get usernameEmptyError;

  // 状态消息
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

  get rootPathEmptyError;

  String? get rootPathInvalidError;

  String get disconnect;
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
