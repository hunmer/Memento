/// Store plugin Japanese translations
const Map<String, String> storeTranslationsJp = {
  // Basic info
  'store_name': 'ポイントショップ',
  'store_storeTitle': 'ポイントショップ',

  // Confirmations
  'store_confirmUse': '使用確認',
  'store_confirmUseMessage': '@productNameを使用してもよろしいですか？',
  'store_confirmUseItem': 'このアイテムを使用してもよろしいですか？',
  'store_confirmArchiveTitle': 'アーカイブ確認',
  'store_confirmArchiveMessage':
      'この商品をアーカイブしてもよろしいですか？アーカイブした商品はフィルターで確認できます。',
  'store_confirmDeleteTitle': '削除確認',
  'store_confirmDeleteMessage':
      'この商品を削除してもよろしいですか？この操作は取り消せません。',
  'store_confirmRestoreTitle': '復元確認',
  'store_confirmRestoreMessage': 'この商品を復元してもよろしいですか？',
  'store_confirmClearTitle': 'クリア確認',
  'store_confirmClearItemsTitle': 'クリア確認',
  'store_confirmClearItemsMessage':
      'すべてのアイテム記録をクリアしてもよろしいですか？この操作は取り消せません。',
  'store_confirmClearPointsTitle': 'クリア確認',
  'store_confirmClearPointsMessage':
      'すべてのポイント記録をクリアしてもよろしいですか？この操作は取り消せません。',
  'store_confirmClearPointsHistory':
      'すべてのポイント履歴をクリアしてもよろしいですか？この操作は取り消せません。',
  'store_redeemConfirmation': 'このアイテムと交換してもよろしいですか？',
  'store_redeemConfirmationMessage':
      '%sと交換してもよろしいですか？%dポイント消費します',
  'store_insufficientPoints': 'ポイント不足',

  // Points settings
  'store_pointSettingsTitle': 'ポイント報酬設定',
  'store_pointSettingsSubtitle': 'さまざまなアクションに対するポイント報酬を設定',
  'store_storeSettings': 'ショップ設定',
  'store_enablePointsNotification': 'ポイント変更通知',
  'store_enablePointsNotificationDescription':
      'ポイントが変更されたときに通知を表示',
  'store_enableExpiringReminder': '期限切れリマインダー',
  'store_enableExpiringReminderDescription':
      'アイテムの期限が近づくとリマインダーを送信',
  'store_addPointsTitle': 'ポイント加算',
  'store_addPointsDialogTitle': 'ポイント加算',
  'store_pointsAmountLabel': 'ポイント数',
  'store_pointsAmount': 'ポイント数',
  'store_reasonLabel': '理由',
  'store_pointsReason': '理由',
  'store_pointsAdjustmentDefaultReason': 'ポイント調整',
  'store_myPoints': 'ポイント',
  'store_points': 'ポイント',
  'store_pointsAdded': 'ポイント加算完了',
  'store_earnPointsTip': 'アプリでアクティビティを完了してポイントを獲得',
  'store_resetToDefault': 'デフォルトに戻す',
  'store_saveSettings': '設定を保存',

  // Quantity stats
  'store_productQuantity': '商品',
  'store_itemQuantity': 'アイテム',
  'store_expiringIn7Days': '期限切れ予定',

  // Clear operations
  'store_itemsCleared': 'アイテム記録をクリアしました',
  'store_pointsCleared': 'ポイント記録をクリアしました',
  'store_clear': 'クリア',
  'store_clearPointsHistory': 'ポイント履歴をクリア',

  // Filter related
  'store_itemFilterTitle': 'アイテムフィルター',
  'store_itemFilter': 'アイテムフィルター',
  'store_itemStatus': 'アイテムステータス',
  'store_allItems': 'すべて',
  'store_all': 'すべて',
  'store_usableItems': '使用可能',
  'store_usable': '使用可能',
  'store_expiredItems': '期限切れ',
  'store_expired': '期限切れ',
  'store_nameFilter': '名前フィルター',
  'store_nameFilterHint': '名前でフィルター',
  'store_priceRange': '価格帯',
  'store_priceRangeHint': '価格帯を入力',
  'store_dateRange': '日付範囲',
  'store_dateRangeTitle': '日付範囲',
  'store_dateRangeSelectionTitle': '日付範囲を選択',
  'store_dateRangeSelectionHint': '日付範囲を選択',
  'store_filterConditions': 'フィルター条件',
  'store_notSelected': '未選択',
  'store_apply': '適用',

  // Sort related
  'store_sortAndFilterTitle': '並べ替えとフィルター',
  'store_sortAndFilter': '並べ替えとフィルター',
  'store_sortMethod': '並べ替え方法',
  'store_sortByStock': '在庫順',
  'store_byStock': '在庫順',
  'store_sortByPrice': '価格順',
  'store_byPrice': '価格順',
  'store_sortByExpiry': '期限順',
  'store_byExpiry': '期限順',
  'store_defaultSort': 'デフォルト順',
  'store_sortByExpiryDate': '期限日で並べ替え',

  // Product related
  'store_addProductTitle': '商品追加',
  'store_productNameLabel': '商品名',
  'store_productNameRequired': '商品名を入力してください',
  'store_priceLabel': '価格（ポイント）',
  'store_priceRequired': '価格を入力してください',
  'store_priceInvalid': '有効な数値を入力してください',
  'store_stockLabel': '在庫数',
  'store_stockRequired': '在庫数を入力してください',
  'store_stockInvalid': '有効な数値を入力してください',
  'store_descriptionLabel': '商品説明',
  'store_productAdded': '商品追加完了',
  'store_noProducts': '商品なし',
  'store_productList': '商品リスト',

  // Success/failure operations
  'store_useSuccess': '使用完了',
  'store_useSuccessMessage': '使用完了',
  'store_itemExpired': 'アイテム期限切れ',
  'store_itemExpiredMessage': 'アイテムの期限が切れています',
  'store_redeemSuccess': '交換完了',
  'store_redeemFailed': '交換に失敗しました。ポイントまたは在庫を確認してください',

  // Archive related
  'store_archivedProductsTitle': 'アーカイブ済み商品',
  'store_noArchivedProducts': 'アーカイブ済み商品なし',
  'store_archivedLabel': 'アーカイブ済み',
  'store_viewArchivedProducts': 'アーカイブ済み商品を表示',
  'store_restore': '復元',

  // Item related
  'store_noItems': 'アイテムなし',
  'store_myItems': 'マイアイテム',
  'store_itemDetailsTitle': 'アイテム詳細',
  'store_useConfirmationTitle': '使用確認',
  'store_useConfirmationMessage': '%sを使用してもよろしいですか？',
  'store_purchaseDateLabel': '購入日',
  'store_expiryDateLabel': '期限日',
  'store_purchasePriceLabel': '購入価格',
  'store_remainingQuantityLabel': '残りの数',
  'store_viewProductInfo': '商品情報を表示',
  'store_productNotFound': '商品が見つからないか、削除されています',
  'store_confirmDeleteItemMessage':
      'このアイテムを削除してもよろしいですか？この操作は取り消せません。',

  // Records related
  'store_noRecords': '記録なし',
  'store_pointsHistoryTitle': 'ポイント履歴',
  'store_pointsHistory': 'ポイント履歴',
  'store_pointsHistoryEntry': '{value}ポイント（{type}）',
  'store_viewRedeemHistory': '交換履歴を表示',

  // Buttons
  'store_deleteButton': '削除',
  'store_archiveButton': 'アーカイブ',
  'store_saveButton': '保存',
  'store_cancel': 'キャンセル',
  'store_add': '追加',

  // Utility methods
  'store_labelColon': '@label: ',

  // Search placeholders
  'store_searchItemPlaceholder': 'アイテム名または説明を検索',
  'store_searchProductPlaceholder': '商品名または説明を検索',

  // Home Widget Strings
  'store_widgetName': 'ショップ',
  'store_widgetDescription': 'ショップへのクイックアクセス',
  'store_overviewName': 'ショップ概要',
  'store_overviewDescription': 'ポイントと商品の統計を表示',

  // Selector Widget Strings
  'store_productSelectorName': '商品を選択',
  'store_productSelectorDesc': '交換したアイテムを表示する商品を選択',
  'store_selectProduct': '商品を選択',
  'store_productQuickAccess': '商品のクイックアクセス',
  'store_productQuickAccessDesc': '特定の商品アイテムリストへのクイックアクセス',
  'store_outOfStock': '在庫切れ',
  'store_userItemSelectorName': 'アイテムを選択',
  'store_userItemSelectorDesc': '詳細を表示するアイテムを選択',
  'store_selectUserItem': 'アイテムを選択',
  'store_userItemQuickAccess': 'アイテムのクイックアクセス',
  'store_userItemQuickAccessDesc': 'アイテム詳細へのクイックアクセス',
  'store_times': '回',
  'store_expireIn': '期限まで',
  'store_days': '日',

  // Points history search and filter
  'store_searchReason': '理由を検索',
  'store_type': 'タイプ',
  'store_selectDateRange': '日付範囲を選択',
  'store_sort': '並べ替え',
  'store_newestFirst': '新しい順',
  'store_oldestFirst': '古い順',
};
