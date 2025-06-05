import 'package:flutter/material.dart';
import 'calendar_album_localizations_en.dart';
import 'calendar_album_localizations_zh.dart';

class CalendarAlbumLocalizations {
  final Locale locale;

  CalendarAlbumLocalizations(this.locale);

  static CalendarAlbumLocalizations of(BuildContext context) {
    return Localizations.of<CalendarAlbumLocalizations>(
          context, CalendarAlbumLocalizations) ??
        CalendarAlbumLocalizations(const Locale('en'));
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': CalendarAlbumLocalizationsEn.values,
    'zh': CalendarAlbumLocalizationsZh.values,
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class CalendarAlbumLocalizationsDelegate
    extends LocalizationsDelegate<CalendarAlbumLocalizations> {
  const CalendarAlbumLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<CalendarAlbumLocalizations> load(Locale locale) async {
    return CalendarAlbumLocalizations(locale);
  }

  @override
  bool shouldReload(CalendarAlbumLocalizationsDelegate old) => false;
}