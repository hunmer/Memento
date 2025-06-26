import 'package:Memento/screens/settings_screen/l10n/log_settings_localizations_en.dart';
import 'package:Memento/screens/settings_screen/l10n/log_settings_localizations_zh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class LogSettingsLocalizations {
  String get title;
  String get enableLogging;
  String get enableLoggingSubtitle;
  String get viewLogHistory;
  String get viewLogHistorySubtitle;
  String get clearAllLogs;
  String get clearAllLogsSubtitle;
  String get logHistoryTitle;
  String get close;
  String get clearLogs;
  String get logsCleared;
  String get allLogsCleared;

  static LogSettingsLocalizations of(BuildContext context) {
    final localizations = Localizations.of<LogSettingsLocalizations>(
      context,
      LogSettingsLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No LogSettingsLocalizations found in context');
    }
    return localizations;
  }
}

class LogSettingsLocalizationsDelegate
    extends LocalizationsDelegate<LogSettingsLocalizations> {
  const LogSettingsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<LogSettingsLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return SynchronousFuture<LogSettingsLocalizations>(
          LogSettingsLocalizationsZh(),
        );
      case 'en':
      default:
        return SynchronousFuture<LogSettingsLocalizations>(
          LogSettingsLocalizationsEn(),
        );
    }
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<LogSettingsLocalizations> old,
  ) => false;

  static LogSettingsLocalizations of(BuildContext context) {
    return Localizations.of<LogSettingsLocalizations>(
      context,
      LogSettingsLocalizations,
    )!;
  }
}
