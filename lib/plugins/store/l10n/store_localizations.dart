import 'package:Memento/plugins/store/l10n/store_localizations_en.dart';
import 'package:Memento/plugins/store/l10n/store_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class StoreLocalizations {
  StoreLocalizations(String locale) : localeName = locale;

  final String localeName;

  String get confirmUse;
  String get confirmUseMessage;

  String get pointSettingsTitle;
  String get pointSettingsSubtitle;
  String get productQuantity;
  String get itemQuantity;
  String get myPoints;
  String get expiringIn7Days;
  String get confirmClearItemsTitle;
  String get confirmClearItemsMessage;
  String get itemsCleared;
  String get confirmClearPointsTitle;
  String get confirmClearPointsMessage;
  String get pointsCleared;
  String get itemFilterTitle;
  String get allItems;
  String get usableItems;
  String get expiredItems;
  String get dateRangeSelectionTitle;
  String get apply;
  String get sortAndFilterTitle;
  String get sortByStock;
  String get sortByPrice;
  String get sortByExpiry;
  String get dateRange;
  String get addPointsTitle;
  String get confirmArchiveTitle;
  String get confirmArchiveMessage;
  String get confirmDeleteTitle;
  String get confirmDeleteMessage;
  String get addProductTitle;
  String get useSuccess;
  String get itemExpired;
  String get redeemSuccess;
  String get redeemFailed;
  String get archivedProductsTitle;
  String get noArchivedProducts;
  String get confirmRestoreTitle;
  String get confirmRestoreMessage;
  String get restore;
  String get archivedLabel;
  String get noItems;
  String get noRecords;
  String get pointsHistoryTitle;
  String get pointsHistoryEntry;
  String get points;

  static const LocalizationsDelegate<StoreLocalizations> delegate =
      _StoreLocalizationsDelegate();

  static StoreLocalizations? of(BuildContext context) {
    return Localizations.of<StoreLocalizations>(context, StoreLocalizations);
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('zh')];

  String get redeemConfirmation;

  get confirmUseItem => null;
}

class _StoreLocalizationsDelegate
    extends LocalizationsDelegate<StoreLocalizations> {
  const _StoreLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<StoreLocalizations> load(Locale locale) {
    return SynchronousFuture<StoreLocalizations>(
      lookupStoreLocalizations(locale),
    );
  }

  @override
  bool shouldReload(_StoreLocalizationsDelegate old) => false;
}

StoreLocalizations lookupStoreLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return StoreLocalizationsEn(locale.languageCode);
    case 'zh':
      return StoreLocalizationsZh(locale.languageCode);
  }

  throw FlutterError(
    'StoreLocalizations.delegate failed to load unsupported locale "$locale". '
    'This is likely an issue with the localizations setup.',
  );
}
