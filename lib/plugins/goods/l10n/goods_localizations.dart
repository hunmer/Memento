import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'goods_localizations_en.dart';
import 'goods_localizations_zh.dart';

/// 物品管理插件的本地化支持类
abstract class GoodsLocalizations {
  GoodsLocalizations(String locale) : localeName = locale;

  final String localeName;

  static GoodsLocalizations of(BuildContext context) {
    final localizations = Localizations.of<GoodsLocalizations>(
      context,
      GoodsLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No GoodsLocalizations found in context');
    }
    return localizations;
  }

  static const LocalizationsDelegate<GoodsLocalizations> delegate =
      _GoodsLocalizationsDelegate();

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

  // 物品管理插件的本地化字符串
  String get allCategories;
  String get price;
  String get addField;
  String get noCustomFields;
  String get addCustomField;
  String get cancel;
  String get confirm;
  String get fieldNameAndValueCannotBeEmpty;
  String get editCustomField;
  String get confirmDelete;
  String get confirmDeleteCustomField;
  String get delete;
  String get confirmDeleteItem;
  String get deleteProduct;
  String get selectImageFailed;
  String get addSubItem;
  String get noSubItems;
  String get allItems;
  String get defaultSort;
  String get sortByPrice;
  String get sortByLastUsedTime;
  String get noItems;
  String get editItem;
  String get save;
  String get saveFailed;
  String get itemNotExist;
  String get itemNotFound;
  String get addTag;
  String get tag;
  String get editWarehouse;
  String get clearWarehouse;
  String get confirmClearWarehouse;
  String get deleteWarehouse;
  String get confirmDeleteWarehouse;
  String get addUsageRecord;
  String get noUsageRecords;
  String get addUsageRecordTitle;
  String get editUsageRecordTitle;
  String get confirmDeleteUsageRecord;
  String get selectImage;
  String get selectItem;
  String get filterByCategory;
  String get searchItems;
  String get customFields;
  String get fieldName;
  String get enterFieldName;
  String get fieldValue;
  String get enterFieldValue;
  String get productName;
  String get enterProductName;
  String get pleaseEnterProductName;
  String get enterPrice;
  String get pleaseEnterPrice;
  String get pleaseEnterValidPrice;
  String get stock;
  String get enterStock;
  String get pleaseEnterStock;
  String get pleaseEnterValidStock;
  String get basicInfo;
  String get usageRecords;
  String get subItems;
  String get addItem;
  String get optionalNote;
  String get enterUsageNote;
  String get allWarehouses;
  String get searchGoods;
  String get close;
  String get filter;
  String get viewAsList;
  String get viewAsGrid;
  String get editWarehouseTitle;
  String get clearWarehouseTitle;
  String get confirmClearWarehouseMessage;
  String get deleteWarehouseTitle;
  String get confirmDeleteWarehouseMessage;
  String get sortByDefault;
  String get addItemButtonLabel;
  String get editItemButtonLabel;
  String get deleteItemButtonLabel;
  String get confirmDeleteItemMessage;

  get productDescription;

  get enterProductDescription;

  String get totalQuantity;

  String get totalValue;

  String get oneMonthUnused;

  String get subItemsList;

  String get tagName => 'Tag Name';
  String get tagNameHint => 'Enter tag name';
  String get priceHint => 'Enter price';
  String get stockHint => 'Enter stock quantity';
  String get warehouseName => 'Warehouse Name';
  String get warehouseNameHint => 'Enter warehouse name';
}

class _GoodsLocalizationsDelegate
    extends LocalizationsDelegate<GoodsLocalizations> {
  const _GoodsLocalizationsDelegate();

  @override
  Future<GoodsLocalizations> load(Locale locale) {
    return SynchronousFuture<GoodsLocalizations>(
      lookupGoodsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_GoodsLocalizationsDelegate old) => false;
}

GoodsLocalizations lookupGoodsLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return GoodsLocalizationsEn();
    case 'zh':
      return GoodsLocalizationsZh();
  }

  throw FlutterError(
    'GoodsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localization\'s implementation.',
  );
}
