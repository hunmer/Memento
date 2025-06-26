import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'import_localizations_en.dart';
import 'import_localizations_zh.dart';

/// 导入功能的本地化支持类
abstract class ImportLocalizations {
  ImportLocalizations(String locale) : localeName = locale;

  final String localeName;

  static ImportLocalizations of(BuildContext context) {
    final localizations = Localizations.of<ImportLocalizations>(
      context,
      ImportLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No ImportLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<ImportLocalizations> delegate =
      _ImportLocalizationsDelegate();

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

  // 导入功能的本地化字符串
  String get filePathError;
  String get noPluginsFound;
  String get importSuccess;
  String get importSuccessContent;
  String get restartLater;
  String get restartNow;
  String get importFailed;
}

class _ImportLocalizationsDelegate
    extends LocalizationsDelegate<ImportLocalizations> {
  const _ImportLocalizationsDelegate();

  @override
  Future<ImportLocalizations> load(Locale locale) {
    return SynchronousFuture<ImportLocalizations>(
      lookupImportLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_ImportLocalizationsDelegate old) => false;
}

ImportLocalizations lookupImportLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return ImportLocalizationsEn();
    case 'zh':
      return ImportLocalizationsZh();
  }

  throw FlutterError(
    'ImportLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}