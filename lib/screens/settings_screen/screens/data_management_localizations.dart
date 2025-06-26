import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data_management_localizations_en.dart';
import 'data_management_localizations_zh.dart';

abstract class DataManagementLocalizations {
  DataManagementLocalizations(String locale) : localeName = locale;

  final String localeName;

  static DataManagementLocalizations of(BuildContext context) {
    final localizations = Localizations.of<DataManagementLocalizations>(
      context,
      DataManagementLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No DataManagementLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<DataManagementLocalizations> delegate =
      _DataManagementLocalizationsDelegate();

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

  // Data management screen strings
  String get dataManagementTitle;
  String get refresh;
  String get importFiles;
  String get deleteSelected;
  String get moveSelected;
  String get exportSelected;
  String get newFolder;
  String get newFile;
  String get confirmDelete;
  String get delete;
  String get cancel;
  String get create;
  String get rename;
  String get edit;
  String get select;
  String get move;
  String get export;
  String get import;
  String get deleteSuccess;
  String get moveSuccess;
  String get exportSuccess;
  String get importSuccess;
  String get importFailed;
  String get exportFailed;
  String get moveFailed;
  String get deleteFailed;
  String get renameFailed;
  String get createFailed;
  String get directoryLoadFailed;
  String get directoryAccessFailed;
  String get editNotImplemented;
  String get confirmDeleteItems;
}

class _DataManagementLocalizationsDelegate
    extends LocalizationsDelegate<DataManagementLocalizations> {
  const _DataManagementLocalizationsDelegate();

  @override
  Future<DataManagementLocalizations> load(Locale locale) {
    return SynchronousFuture<DataManagementLocalizations>(
      lookupDataManagementLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_DataManagementLocalizationsDelegate old) => false;
}

DataManagementLocalizations lookupDataManagementLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return DataManagementLocalizationsEn();
    case 'zh':
      return DataManagementLocalizationsZh();
  }

  throw FlutterError(
    'DataManagementLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
