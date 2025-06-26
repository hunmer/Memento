import 'package:Memento/widgets/l10n/location_picker_localizations_en.dart';
import 'package:Memento/widgets/l10n/location_picker_localizations_zh.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class LocationPickerLocalizations {
  LocationPickerLocalizations(String locale) : localeName = locale;

  final String localeName;

  static LocationPickerLocalizations? of(BuildContext context) {
    return Localizations.of<LocationPickerLocalizations>(
      context,
      LocationPickerLocalizations,
    );
  }

  static const LocalizationsDelegate<LocationPickerLocalizations> delegate =
      _LocationPickerLocalizationsDelegate();

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

  String get searchLocation;
  String get getCurrentLocation;
  String get noAddressInfo;
}

class _LocationPickerLocalizationsDelegate
    extends LocalizationsDelegate<LocationPickerLocalizations> {
  const _LocationPickerLocalizationsDelegate();

  @override
  Future<LocationPickerLocalizations> load(Locale locale) {
    return SynchronousFuture<LocationPickerLocalizations>(
      lookupLocationPickerLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LocationPickerLocalizationsDelegate old) => false;
}

LocationPickerLocalizations lookupLocationPickerLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return LocationPickerLocalizationsEn(locale.languageCode);
    case 'zh':
      return LocationPickerLocalizationsZh(locale.languageCode);
  }

  throw FlutterError(
    'LocationPickerLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
