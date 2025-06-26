import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'database_localizations_en.dart';
import 'database_localizations_zh.dart';

/// 数据库插件的本地化支持类
abstract class DatabaseLocalizations {
  DatabaseLocalizations(String locale) : localeName = locale;

  final String localeName;

  static DatabaseLocalizations of(BuildContext context) {
    final localizations = Localizations.of<DatabaseLocalizations>(
      context,
      DatabaseLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No DatabaseLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<DatabaseLocalizations> delegate =
      _DatabaseLocalizationsDelegate();

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

  // 插件基本信息
  String get pluginName;
  String get pluginDescription;

  // 记录相关
  String get deleteRecordTitle;
  String get deleteRecordMessage;
  String get untitledRecord;

  // 通用操作
  String get edit;
  String get delete;
  String get cancel;

  String get editDatabaseTitle;

  String get informationTabTitle;

  String get fieldsTabTitle;

  String get databaseNameLabel;

  String get uploadCoverImage;

  String get descriptionLabel;

  String get defaultValueLabel;

  String get selectFieldTypeTitle;

  String get fieldNameLabel;

  String get saveFailedMessage;

  String get newFieldTitle;

  String get databaseListTitle;

  get newDatabaseDefaultName;

  String get loadFailedMessage;

  String get noDatabasesMessage;

  String get addDatabaseHint;

  String get confirmDeleteTitle;

  get confirmDeleteMessage;

  String get deleteSuccessMessage;

  get deleteFailedMessage;
}

class _DatabaseLocalizationsDelegate
    extends LocalizationsDelegate<DatabaseLocalizations> {
  const _DatabaseLocalizationsDelegate();

  @override
  Future<DatabaseLocalizations> load(Locale locale) {
    return SynchronousFuture<DatabaseLocalizations>(
      lookupDatabaseLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_DatabaseLocalizationsDelegate old) => false;
}

DatabaseLocalizations lookupDatabaseLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return DatabaseLocalizationsEn();
    case 'zh':
      return DatabaseLocalizationsZh();
  }

  throw FlutterError(
    'DatabaseLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
