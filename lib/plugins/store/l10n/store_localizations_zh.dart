import 'store_localizations.dart';

class StoreLocalizationsZh extends StoreLocalizations {
  StoreLocalizationsZh(super.locale);

  @override
  String get confirmUse => '使用确认';

  @override
  String get confirmUseMessage => '确定要使用 {productName} 吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get pointSettingsTitle => '积分奖励设置';

  @override
  String get pointSettingsSubtitle => '设置各项行为的积分奖励';

  @override
  String get productQuantity => '商品数量';

  @override
  String get itemQuantity => '物品数量';

  @override
  String get myPoints => '我的积分';

  @override
  String get expiringIn7Days => '七天到期';

  @override
  String get confirmClearItemsTitle => '确认清空';

  @override
  String get confirmClearItemsMessage => '确定要清空所有物品记录吗？此操作不可撤销。';

  @override
  String get itemsCleared => '已清空物品记录';

  @override
  String get confirmClearPointsTitle => '确认清空';

  @override
  String get confirmClearPointsMessage => '确定要清空所有积分记录吗？此操作不可撤销。';

  @override
  String get pointsCleared => '已清空积分记录';

  @override
  String get itemFilterTitle => '物品筛选';

  @override
  String get allItems => '全部';

  @override
  String get usableItems => '可使用';

  @override
  String get expiredItems => '已过期';

  @override
  String get dateRangeSelectionTitle => '选择日期范围';

  @override
  String get apply => '应用';

  @override
  String get sortAndFilterTitle => '排序与筛选';

  @override
  String get sortByStock => '按库存数';

  @override
  String get sortByPrice => '按单价';

  @override
  String get sortByExpiry => '按有效兑换期';

  @override
  String get dateRange => '日期范围';

  @override
  String get addPointsTitle => '添加积分';

  @override
  String get confirmArchiveTitle => '确认存档';

  @override
  String get confirmArchiveMessage => '确定要将这个商品存档吗？存档后可以在筛选器中查看。';

  @override
  String get confirmDeleteTitle => '确认删除';

  @override
  String get confirmDeleteMessage => '确定要删除这个商品吗？此操作不可撤销。';

  @override
  String get addProductTitle => '添加商品';

  @override
  String get useSuccess => '使用成功';

  @override
  String get itemExpired => '物品已过期';

  @override
  String get redeemSuccess => '兑换成功';

  @override
  String get redeemFailed => '兑换失败，请检查积分或库存';

  @override
  String get archivedProductsTitle => '存档商品';

  @override
  String get noArchivedProducts => '没有存档商品';

  @override
  String get confirmRestoreTitle => '确认恢复';

  @override
  String get confirmRestoreMessage => '确定要恢复这个商品吗？';

  @override
  String get restore => '恢复';

  @override
  String get archivedLabel => '已存档';

  @override
  String get noItems => '暂无物品';

  @override
  String get noRecords => '暂无记录';

  @override
  String get pointsHistoryTitle => '积分历史';

  @override
  String get pointsHistoryEntry => '{value}积分 ({type})';

  @override
  String get points => '积分';

  @override
  String get redeemConfirmation => '确定要兑换这个商品吗？';
}
