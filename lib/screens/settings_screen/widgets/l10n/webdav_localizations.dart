import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'webdav_localizations_en.dart';
import 'webdav_localizations_zh.dart';

abstract class WebDAVLocalizations {
  String get title;
  String get serverAddress;
  String get serverAddressHint;
  String get serverAddressEmptyError;
  String get serverAddressInvalidError;
  String get username;
  String get usernameEmptyError;
  String get password;
  String get passwordEmptyError;
  String get saveSettings;
  String get dataSync;
  String get uploadAllData;
  String get downloadAllData;
  String get settingsSaved;
  String get saveFailed;

  static WebDAVLocalizations of(BuildContext context) {
    return Localizations.of<WebDAVLocalizations>(context, WebDAVLocalizations)!;
  }
}

class WebDAVLocalizationsDelegate
    extends LocalizationsDelegate<WebDAVLocalizations> {
  const WebDAVLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<WebDAVLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh':
        return SynchronousFuture<WebDAVLocalizations>(
          const WebDAVLocalizationsZh() as WebDAVLocalizations,
        );
      default:
        return SynchronousFuture<WebDAVLocalizations>(
          const WebDAVLocalizationsEn() as WebDAVLocalizations,
        );
    }
  }

  @override
  bool shouldReload(WebDAVLocalizationsDelegate old) => false;
}
