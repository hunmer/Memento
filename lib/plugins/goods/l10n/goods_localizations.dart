import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class GoodsLocalizations {
  final Map<String, String> _localizedStrings;

  GoodsLocalizations(this._localizedStrings);

  static GoodsLocalizations? of(BuildContext context) {
    return Localizations.of<GoodsLocalizations>(context, GoodsLocalizations);
  }

  String get basicInfo => _localizedStrings['basicInfo'] ?? 'Basic Info';
  String get usageRecords =>
      _localizedStrings['usageRecords'] ?? 'Usage Records';
  String get subItems => _localizedStrings['subItems'] ?? 'Sub Items';
  String get addItem => _localizedStrings['addItem'] ?? 'Add Item';
  String get optionalNote =>
      _localizedStrings['optionalNote'] ?? 'Note (optional)';
  String get enterUsageNote =>
      _localizedStrings['enterUsageNote'] ?? 'Enter usage note';
  String get enterProductDescription =>
      _localizedStrings['enterProductDescription'] ??
      'Enter product description';
  String get productDescription =>
      _localizedStrings['productDescription'] ?? 'Product Description';
  String get pleaseEnterProductName =>
      _localizedStrings['pleaseEnterProductName'] ??
      'Please enter product name';
  String get productName => _localizedStrings['productName'] ?? 'Product Name';
  String get enterProductName =>
      _localizedStrings['enterProductName'] ?? 'Enter product name';
  String get allCategories =>
      _localizedStrings['allCategories'] ?? 'All Categories';
  String price(String price) =>
      _localizedStrings['price']?.replaceAll('{price}', price) ?? '\$price';
  String get addField => _localizedStrings['addField'] ?? 'Add Field';
  String get noCustomFields =>
      _localizedStrings['noCustomFields'] ?? 'No Custom Fields';
  String get addCustomField =>
      _localizedStrings['addCustomField'] ?? 'Add Custom Field';
  String get cancel => _localizedStrings['cancel'] ?? 'Cancel';
  String get confirm => _localizedStrings['confirm'] ?? 'Confirm';
  String get fieldNameAndValueCannotBeEmpty =>
      _localizedStrings['fieldNameAndValueCannotBeEmpty'] ??
      'Field name and value cannot be empty';
  String get editCustomField =>
      _localizedStrings['editCustomField'] ?? 'Edit Custom Field';
  String get confirmDelete =>
      _localizedStrings['confirmDelete'] ?? 'Confirm Delete';
  String get confirmDeleteCustomField =>
      _localizedStrings['confirmDeleteCustomField'] ??
      'Are you sure you want to delete this custom field?';
  String get delete => _localizedStrings['delete'] ?? 'Delete';
  String get confirmDeleteItem =>
      _localizedStrings['confirmDeleteItem'] ??
      'Are you sure you want to delete this item? This cannot be undone.';
  String get deleteProduct =>
      _localizedStrings['deleteProduct'] ?? 'Delete Product';
  String selectImageFailed(String error) =>
      _localizedStrings['selectImageFailed']?.replaceAll('{error}', error) ??
      'Failed to select image: $error';
  String get addSubItem => _localizedStrings['addSubItem'] ?? 'Add Sub Item';
  String get noSubItems => _localizedStrings['noSubItems'] ?? 'No Sub Items';
  String get allItems => _localizedStrings['allItems'] ?? 'All Items';
  String get defaultSort => _localizedStrings['defaultSort'] ?? 'Default Sort';
  String get sortByPrice => _localizedStrings['sortByPrice'] ?? 'Sort by Price';
  String get sortByLastUsedTime =>
      _localizedStrings['sortByLastUsedTime'] ?? 'Sort by Last Used Time';
  String get noItems => _localizedStrings['noItems'] ?? 'No Items';
  String get editItem => _localizedStrings['editItem'] ?? 'Edit Item';
  String get save => _localizedStrings['save'] ?? 'Save';
  String get saveFailed => _localizedStrings['saveFailed'] ?? 'Save Failed';
  String get itemNotExist =>
      _localizedStrings['itemNotExist'] ?? 'Item Not Exist';
  String get itemNotFound =>
      _localizedStrings['itemNotFound'] ?? 'Item Not Found';
  String get addTag => _localizedStrings['addTag'] ?? 'Add Tag';
  String get tag => _localizedStrings['tag'] ?? 'Tag';
  String get editWarehouse =>
      _localizedStrings['editWarehouse'] ?? 'Edit Warehouse';
  String get clearWarehouse =>
      _localizedStrings['clearWarehouse'] ?? 'Clear Warehouse';
  String get confirmClearWarehouse =>
      _localizedStrings['confirmClearWarehouse'] ??
      'Are you sure you want to clear all items in this warehouse?';
  String get deleteWarehouse =>
      _localizedStrings['deleteWarehouse'] ?? 'Delete Warehouse';
  String get confirmDeleteWarehouse =>
      _localizedStrings['confirmDeleteWarehouse'] ??
      'Are you sure you want to delete this warehouse?';
  String get addUsageRecord =>
      _localizedStrings['addUsageRecord'] ?? 'Add Record';
  String get noUsageRecords =>
      _localizedStrings['noUsageRecords'] ?? 'No Usage Records';
  String get addUsageRecordTitle =>
      _localizedStrings['addUsageRecordTitle'] ?? 'Add Usage Record';
  String get editUsageRecordTitle =>
      _localizedStrings['editUsageRecordTitle'] ?? 'Edit Usage Record';
  String get confirmDeleteUsageRecord =>
      _localizedStrings['confirmDeleteUsageRecord'] ??
      'Are you sure you want to delete this usage record?';
  String get selectImage => _localizedStrings['selectImage'] ?? 'Select Image';
  String get selectItem => _localizedStrings['selectItem'] ?? 'Select Item';
  String get filterByCategory =>
      _localizedStrings['filterByCategory'] ?? 'Filter by Category';
  String get searchItems => _localizedStrings['searchItems'] ?? 'Search Items';
  String get customFields =>
      _localizedStrings['customFields'] ?? 'Custom Fields';
  String get fieldName => _localizedStrings['fieldName'] ?? 'Field Name';
  String get enterFieldName =>
      _localizedStrings['enterFieldName'] ?? 'Enter field name';
  String get fieldValue => _localizedStrings['fieldValue'] ?? 'Field Value';
  String get enterFieldValue =>
      _localizedStrings['enterFieldValue'] ?? 'Enter field value';
}

class GoodsLocalizationsDelegate
    extends LocalizationsDelegate<GoodsLocalizations> {
  const GoodsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<GoodsLocalizations> load(Locale locale) async {
    String jsonContent = await rootBundle.loadString(
      'lib/plugins/goods/l10n/goods_localizations_${locale.languageCode}.arb',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonContent);

    Map<String, String> localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return GoodsLocalizations(localizedStrings);
  }

  @override
  bool shouldReload(GoodsLocalizationsDelegate old) => false;
}
