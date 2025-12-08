import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'nfc_localizations_en.dart';
import 'nfc_localizations_zh.dart';

/// NFC插件的本地化支持类
abstract class NfcLocalizations {
  NfcLocalizations(String locale) : localeName = locale;

  final String localeName;

  static NfcLocalizations of(BuildContext context) {
    final localizations = Localizations.of<NfcLocalizations>(
      context,
      NfcLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No NfcLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<NfcLocalizations> delegate =
      _NfcLocalizationsDelegate();

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

  // NFC插件的本地化字符串
  String get pleaseBringPhoneNearNFC;
  String get writeNFCData;
  String get cancel;
  String get startWriting;
  String get nfcData;
  String get close;
  String get copyData;
  String get nfcController;
  String get enableNFC;

  // Timer Dialog 相关
  String get cancelTimer;
  String get continueTimer;
  String get confirmCancel;
  String get completeTimer;
  String get continueAdjust;
  String get confirmComplete;
  String get quickNotes;
  String get addQuickNote;
  String get pause;
  String get start;
  String get cancelBtn;
  String get complete;
  String get pauseTimerConfirm;
  String get completeTimerConfirm;
  String get timerNotePrefix;
  String get timerWarning;
  String get timerSuccess;
}

class _NfcLocalizationsDelegate
    extends LocalizationsDelegate<NfcLocalizations> {
  const _NfcLocalizationsDelegate();

  @override
  Future<NfcLocalizations> load(Locale locale) {
    return SynchronousFuture<NfcLocalizations>(
      lookupNfcLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_NfcLocalizationsDelegate old) => false;
}

NfcLocalizations lookupNfcLocalizations(Locale locale) {
  // 支持的语言代码
  switch (locale.languageCode) {
    case 'en':
      return NfcLocalizationsEn();
    case 'zh':
      return NfcLocalizationsZh();
  }

  throw FlutterError(
    'NfcLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}