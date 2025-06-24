import 'store_localizations.dart';

class StoreLocalizationsEn extends StoreLocalizations {
  StoreLocalizationsEn(super.locale);

  @override
  String get confirmUse => 'Use Confirmation';

  @override
  String get confirmUseMessage => 'Are you sure you want to use {productName}?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get pointSettingsTitle => 'Point Reward Settings';

  @override
  String get pointSettingsSubtitle => 'Set point rewards for various actions';

  @override
  String get productQuantity => 'Product Quantity';

  @override
  String get itemQuantity => 'Item Quantity';

  @override
  String get myPoints => 'My Points';

  @override
  String get expiringIn7Days => 'Expiring in 7 Days';

  @override
  String get confirmClearItemsTitle => 'Confirm Clear';

  @override
  String get confirmClearItemsMessage =>
      'Are you sure you want to clear all item records? This action cannot be undone.';

  @override
  String get itemsCleared => 'Item records cleared';

  @override
  String get confirmClearPointsTitle => 'Confirm Clear';

  @override
  String get confirmClearPointsMessage =>
      'Are you sure you want to clear all point records? This action cannot be undone.';

  @override
  String get pointsCleared => 'Point records cleared';

  @override
  String get itemFilterTitle => 'Item Filter';

  @override
  String get allItems => 'All';

  @override
  String get usableItems => 'Usable';

  @override
  String get expiredItems => 'Expired';

  @override
  String get dateRangeSelectionTitle => 'Select Date Range';

  @override
  String get apply => 'Apply';

  @override
  String get sortAndFilterTitle => 'Sort & Filter';

  @override
  String get sortByStock => 'By Stock';

  @override
  String get sortByPrice => 'By Price';

  @override
  String get sortByExpiry => 'By Expiry';

  @override
  String get dateRange => 'Date Range';

  @override
  String get addPointsTitle => 'Add Points';

  @override
  String get confirmArchiveTitle => 'Confirm Archive';

  @override
  String get confirmArchiveMessage =>
      'Are you sure you want to archive this product? Archived products can be viewed in the filter.';

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this product? This action cannot be undone.';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get useSuccess => 'Used successfully';

  @override
  String get itemExpired => 'Item expired';

  @override
  String get redeemSuccess => 'Redeemed successfully';

  @override
  String get redeemFailed => 'Redeem failed, please check points or stock';

  @override
  String get archivedProductsTitle => 'Archived Products';

  @override
  String get noArchivedProducts => 'No archived products';

  @override
  String get confirmRestoreTitle => 'Confirm Restore';

  @override
  String get confirmRestoreMessage =>
      'Are you sure you want to restore this product?';

  @override
  String get restore => 'Restore';

  @override
  String get archivedLabel => 'Archived';

  @override
  String get noItems => 'No items';

  @override
  String get noRecords => 'No records';

  @override
  String get pointsHistoryTitle => 'Points History';

  @override
  String get pointsHistoryEntry => '{value} points ({type})';
}
