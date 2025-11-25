import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';

class GoodsLocalizationsZh extends GoodsLocalizations {
  GoodsLocalizationsZh() : super('zh');

  @override
  String get allCategories => "所有分类";

  @override
  String get price => "￥{price}";

  @override
  String get addField => "添加字段";

  @override
  String get noCustomFields => "暂无自定义字段";

  @override
  String get addCustomField => "添加自定义字段";

  @override
  String get cancel => "取消";

  @override
  String get confirm => "确认";

  @override
  String get fieldNameAndValueCannotBeEmpty => "字段名和字段值不能为空";

  @override
  String get editCustomField => "编辑自定义字段";

  @override
  String get confirmDelete => "确认删除";

  @override
  String get confirmDeleteCustomField => "确定要删除这个自定义字段吗？";

  @override
  String get delete => "删除";

  @override
  String get confirmDeleteItem => "确定要删除这个物品吗？此操作不可恢复。";

  @override
  String get deleteProduct => "删除商品";

  @override
  String get selectImageFailed => "选择图片失败: {error}";

  @override
  String get addSubItem => "添加子物品";

  @override
  String get noSubItems => "暂无子物品";

  @override
  String get allItems => "所有物品";

  @override
  String get defaultSort => "默认排序";

  @override
  String get sortByPrice => "按价格排序";

  @override
  String get sortByLastUsedTime => "按最后使用时间";

  @override
  String get noItems => "没有物品";

  @override
  String get editItem => "编辑物品";

  @override
  String get save => "保存";

  @override
  String get saveFailed => "保存失败";

  @override
  String get itemNotExist => "物品不存在";

  @override
  String get itemNotFound => "未找到指定物品";

  @override
  String get addTag => "添加标签";

  @override
  String get tag => "标签";

  @override
  String get editWarehouse => "编辑仓库";

  @override
  String get clearWarehouse => "清空仓库";

  @override
  String get confirmClearWarehouse => "确定要清空此仓库中的所有物品吗？";

  @override
  String get deleteWarehouse => "删除仓库";

  @override
  String get confirmDeleteWarehouse => "确定要删除此仓库吗？";

  @override
  String get addUsageRecord => "添加记录";

  @override
  String get noUsageRecords => "暂无使用记录";

  @override
  String get addUsageRecordTitle => "添加使用记录";

  @override
  String get editUsageRecordTitle => "编辑使用记录";

  @override
  String get confirmDeleteUsageRecord => "确定要删除这条使用记录吗？";

  @override
  String get selectImage => "选择图片";

  @override
  String get selectItem => "选择物品";

  @override
  String get filterByCategory => "按分类筛选";

  @override
  String get searchItems => "搜索物品";

  @override
  String get customFields => "自定义字段";

  @override
  String get fieldName => "字段名";

  @override
  String get enterFieldName => "输入字段名";

  @override
  String get fieldValue => "字段值";

  @override
  String get enterFieldValue => "输入字段值";

  @override
  String get productName => "商品名称";

  @override
  String get enterProductName => "输入商品名称";

  @override
  String get pleaseEnterProductName => "请输入商品名称";

  @override
  String get enterPrice => "输入价格";

  @override
  String get pleaseEnterPrice => "请输入价格";

  @override
  String get pleaseEnterValidPrice => "请输入有效的价格";

  @override
  String get stock => "库存";

  @override
  String get enterStock => "输入库存";

  @override
  String get pleaseEnterStock => "请输入库存";

  @override
  String get pleaseEnterValidStock => "请输入有效的库存数量";

  @override
  String get basicInfo => "基本信息";

  @override
  String get usageRecords => "使用记录";

  @override
  String get subItems => "子物品";

  @override
  String get addItem => "添加物品";

  @override
  String get optionalNote => "备注（可选）";

  @override
  String get enterUsageNote => "输入使用备注";

  @override
  String get allWarehouses => "所有仓库";

  @override
  String get searchGoods => "搜索物品...";

  @override
  String get close => "关闭";

  @override
  String get filter => "筛选";

  @override
  String get viewAsList => "列表视图";

  @override
  String get viewAsGrid => "网格视图";

  @override
  String get editWarehouseTitle => "编辑仓库";

  @override
  String get clearWarehouseTitle => "清空仓库";

  @override
  String get confirmClearWarehouseMessage => "确定要清空此仓库中的所有物品吗？";

  @override
  String get deleteWarehouseTitle => "删除仓库";

  @override
  String get confirmDeleteWarehouseMessage =>
      "确定要删除仓库\"%s\"吗？\\n删除后将无法恢复，仓库内所有物品也将被删除。";

  @override
  String get sortByDefault => "默认排序";

  @override
  String get addItemButtonLabel => "添加";

  @override
  String get editItemButtonLabel => "编辑";

  @override
  String get deleteItemButtonLabel => "删除";

  @override
  String get confirmDeleteItemMessage => "确定要删除此物品吗？";

  @override
  String get totalQuantity => "总数量";

  @override
  String get totalValue => "总价值";

  @override
  String get oneMonthUnused => "一个月未使用";

  @override
  String get subItemsList => "子物品列表";

  @override
  get enterProductDescription => "输入产品描述";

  @override
  get productDescription => "产品描述";

  @override
  String get priceHint => '价格';

  @override
  String get stockHint => '库存';

  @override
  String get tagName => '标签名';

  @override
  String get tagNameHint => '输入标签名';

  @override
  String get warehouseName => '仓库名';

  @override
  String get warehouseNameHint => '输入仓库名';

  @override
  String get name => '物品管理';

  // Bottom bar strings
  @override
  String? get warehouseTab => '仓库';

  @override
  String? get itemsTab => '物品';

  @override
  String? get createWarehouse => '创建仓库';

  @override
  String? get createItem => '添加物品';

  @override
  String? get warehouseCreated => '仓库已创建';

  @override
  String? get itemCreated => '物品已创建';

  @override
  String? get createWarehouseFirst => '请先创建仓库';

  @override
  String? get createWarehouseFailed => '创建仓库失败';

  @override
  String? get createItemFailed => '创建物品失败';

  @override
  String get dailyCost => "日均成本";

  @override
  String get day => "天";

  @override
  String get days => "天";

  @override
  String get inPlace => "在位";

  @override
  String get times => "次";
}
