import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'calendar_album_localizations_en.dart';
import 'calendar_album_localizations_zh.dart';

/// 日历相册插件的本地化支持类
abstract class CalendarAlbumLocalizations {
  CalendarAlbumLocalizations(String locale) : localeName = locale;

  final String localeName;

  static CalendarAlbumLocalizations of(BuildContext context) {
    final localizations = Localizations.of<CalendarAlbumLocalizations>(
      context,
      CalendarAlbumLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No CalendarAlbumLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<CalendarAlbumLocalizations> delegate =
      _CalendarAlbumLocalizationsDelegate();

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

  // 日历相册插件的本地化字符串
  String get name;
  String get createAlbum;
  String get deleteAlbum;
  String get albumList;
  String get addPhotos;
  String get selectDate;
  String get noPhotosYet;
  String get photoCount;
  String get viewAllPhotos;
  String get editAlbumInfo;
  String get albumCover;
  String get saveChanges;
  String get cancel;
  String get confirmDeleteAlbum;
  String get albumCreated;
  String get albumDeleted;
  String get photoAdded;
  String get photoRemoved;
  String get selectPhotos;
  String get createNewAlbum;
  String get albumSettings;
  String get changeCover;
  String get sortByDate;
  String get sortByName;
  String get searchAlbums;
  String get noAlbumsFound;
  String get sharedAlbums;
  String get myAlbums;
  String get shareAlbum;
  String get stopSharing;
  String get sharedWith;
  String get privacySettings;
  String get publicAlbum;
  String get privateAlbum;
  String get sharedWithSelected;

  String get todayDiary;

  get entriesUnit;

  String get sevenDayDiary;

  String get allDiaries;

  String get tagCount;

  get itemsUnit;

  String get allPhotos;

  String get noPhotos;

  String get calendarDiary;

  String get createEntry;

  get weather;

  get mood;

  get location;

  get wordCount;

  get content;

  get title;

  String get edit;

  String get newEntry;

  get calendar;

  get tags;

  get album;

  get tagManagement;

  get tagsHint;

  String get noEntriesForDate;

  String get noTags;

  String get selectTag;

  String get deleteEntry;

  String get noEntries;
}

class _CalendarAlbumLocalizationsDelegate
    extends LocalizationsDelegate<CalendarAlbumLocalizations> {
  const _CalendarAlbumLocalizationsDelegate();

  @override
  Future<CalendarAlbumLocalizations> load(Locale locale) {
    return SynchronousFuture<CalendarAlbumLocalizations>(
      lookupCalendarAlbumLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_CalendarAlbumLocalizationsDelegate old) => false;
}

CalendarAlbumLocalizations lookupCalendarAlbumLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return CalendarAlbumLocalizationsEn();
    case 'zh':
      return CalendarAlbumLocalizationsZh();
  }

  throw FlutterError(
    'CalendarAlbumLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
