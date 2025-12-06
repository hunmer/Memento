import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/event/event_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../../core/services/plugin_widget_sync_helper.dart';
import 'widgets/goods_bottom_bar.dart';
import 'models/warehouse.dart';
import 'models/goods_item.dart';
import 'models/find_item_result.dart';
import 'l10n/goods_localizations.dart';
import 'sample_data.dart';

/// 物品相关事件的基类
abstract class GoodsEventArgs extends EventArgs {
  final String warehouseId;

  GoodsEventArgs(super.eventName, this.warehouseId);
}

/// 物品添加事件参数
class GoodsItemAddedEventArgs extends GoodsEventArgs {
  final GoodsItem item;

  GoodsItemAddedEventArgs(this.item, String warehouseId)
    : super('goods_item_added', warehouseId);
}

/// 物品删除事件参数
class GoodsItemDeletedEventArgs extends GoodsEventArgs {
  final String itemId;

  GoodsItemDeletedEventArgs(this.itemId, String warehouseId)
    : super('goods_item_deleted', warehouseId);
}

/// 用于递归查找物品及其父物品的结果类
class _ItemSearchResult {
  final GoodsItem? item;
  final GoodsItem? parent;

  _ItemSearchResult(this.item, this.parent);
}

/// 物品管理插件主视图
class GoodsMainView extends StatelessWidget {
  const GoodsMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return GoodsBottomBar(plugin: GoodsPlugin.instance);
  }
}

class GoodsPlugin extends BasePlugin with JSBridgePlugin {
  static GoodsPlugin? _instance;
  static GoodsPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
      if (_instance == null) {
        throw StateError('GoodsPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  final List<Warehouse> _warehouses = [];
  final List<Function()> _listeners = [];

  List<Warehouse> get warehouses => _warehouses;

  Warehouse? getWarehouse(String id) {
    try {
      return _warehouses.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 在所有仓库中查找指定ID的物品
  ///
  /// 如果找到物品，返回包含物品和所属仓库ID的结果
  /// 如果未找到，返回null
  FindItemResult? findGoodsItemById(String itemId) {
    for (final warehouse in _warehouses) {
      // 首先在仓库的顶级物品中查找
      final item = _findItemRecursively(warehouse.items, itemId);
      if (item != null) {
        return FindItemResult(item: item, warehouseId: warehouse.id);
      }
    }
    return null;
  }

  /// 递归查找物品及其子物品，同时返回父物品（如果存在）
  _ItemSearchResult _findItemAndParentRecursively(
    List<GoodsItem> items,
    String itemId, [
    GoodsItem? parent,
  ]) {
    // 在当前层级查找
    for (final item in items) {
      if (item.id == itemId) {
        return _ItemSearchResult(item, parent);
      }

      // 递归查找子物品
      if (item.subItems.isNotEmpty) {
        final result = _findItemAndParentRecursively(
          item.subItems,
          itemId,
          item,
        );
        if (result.item != null) {
          return result;
        }
      }
    }
    return _ItemSearchResult(null, null);
  }

  /// 递归查找物品及其子物品
  GoodsItem? _findItemRecursively(List<GoodsItem> items, String itemId) {
    return _findItemAndParentRecursively(items, itemId, null).item;
  }

  /// 在所有仓库中查找指定ID的物品的父物品
  FindItemResult? findParentGoodsItem(String itemId) {
    for (final warehouse in _warehouses) {
      final result = _findItemAndParentRecursively(warehouse.items, itemId);
      if (result.parent != null) {
        return FindItemResult(item: result.parent!, warehouseId: warehouse.id);
      }
    }
    return null;
  }

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  @override
  String get id => 'goods';

  @override
  Color get color => const Color.fromARGB(255, 207, 77, 116);

  @override
  IconData get icon => Icons.inventory_2;

  // 用于存储用户的排序偏好
  final Map<String, String> _warehouseSortPreferences = {};

  // 获取特定仓库的排序偏好
  String getSortPreference(String warehouseId) {
    return _warehouseSortPreferences[warehouseId] ?? 'none';
  }

  // 保存特定仓库的排序偏好
  Future<void> saveSortPreference(String warehouseId, String sortBy) async {
    _warehouseSortPreferences[warehouseId] = sortBy;
    await storage.write('goods/preferences', {
      'warehouseSortPreferences': _warehouseSortPreferences,
    });
  }

  @override
  Future<void> initialize() async {
    // 确保物品管理数据目录存在
    await storage.createDirectory('goods');

    // 加载仓库数据
    await _loadWarehouses();

    // 加载排序偏好
    await _loadSortPreferences();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  Future<void> _loadSortPreferences() async {
    try {
      final preferencesData = await storage.read('goods/preferences');
      if (preferencesData.isNotEmpty &&
          preferencesData.containsKey('warehouseSortPreferences')) {
        final Map<String, dynamic> sortPrefs = Map<String, dynamic>.from(
          preferencesData['warehouseSortPreferences'],
        );

        _warehouseSortPreferences.clear();
        sortPrefs.forEach((key, value) {
          _warehouseSortPreferences[key] = value.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading sort preferences: $e');
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      _warehouses.clear();

      final warehousesData = await storage.read('goods/warehouses');
      if (warehousesData.isNotEmpty &&
          warehousesData.containsKey('warehouses')) {
        final List<String> warehouseIds = List<String>.from(
          warehousesData['warehouses'],
        );

        for (var warehouseId in warehouseIds) {
          final data = await storage.read('goods/warehouse/$warehouseId');
          if (data.isNotEmpty && data.containsKey('warehouse')) {
            final warehouse = Warehouse.fromJson(data['warehouse']);
            _warehouses.add(warehouse);
          }
        }
      } else {
        // 没有仓库数据，创建示例仓库
        await _createSampleWarehouses();
      }
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
    }
  }

  /// 创建示例仓库数据
  Future<void> _createSampleWarehouses() async {
    try {
      // 获取示例仓库数据
      final sampleWarehouses = GoodsSampleData.getSampleWarehouses();

      // 保存示例仓库
      for (final warehouse in sampleWarehouses) {
        await saveWarehouse(warehouse);
      }

      debugPrint('Created ${sampleWarehouses.length} sample warehouses');
    } catch (e) {
      debugPrint('Error creating sample warehouses: $e');
    }
  }

  Future<void> saveWarehouse(Warehouse warehouse) async {
    try {
      // 更新内存中的仓库信息
      final index = _warehouses.indexWhere((w) => w.id == warehouse.id);
      if (index != -1) {
        // 保持现有物品列表，除非明确要求更新
        final existingWarehouse = _warehouses[index];
        final updatedWarehouse = warehouse.copyWith(
          items:
              warehouse.items.isEmpty
                  ? existingWarehouse.items
                  : warehouse.items,
        );
        _warehouses[index] = updatedWarehouse;
        warehouse = updatedWarehouse; // 更新引用以保存正确的数据
      } else {
        _warehouses.add(warehouse);
      }

      // 保存仓库信息
      await storage.write('goods/warehouse/${warehouse.id}', {
        'warehouse': warehouse.toJson(),
      });

      // 更新仓库列表
      final warehouseIds = _warehouses.map((w) => w.id).toList();
      await storage.write('goods/warehouses', {'warehouses': warehouseIds});

      notifyListeners();

      // 同步小组件数据
      await _syncWidget();
    } catch (e) {
      debugPrint('Error saving warehouse: $e');
      rethrow;
    }
  }

  Future<void> deleteWarehouse(String warehouseId) async {
    try {
      await storage.delete('goods/warehouse/$warehouseId');
      _warehouses.removeWhere((w) => w.id == warehouseId);

      final warehouseIds = _warehouses.map((w) => w.id).toList();
      await storage.write('goods/warehouses', {'warehouses': warehouseIds});

      notifyListeners();

      // 同步小组件数据
      await _syncWidget();
    } catch (e) {
      debugPrint('Error deleting warehouse: $e');
      rethrow;
    }
  }

  Future<void> saveGoodsItem(String warehouseId, GoodsItem item) async {
    try {
      final warehouse = _warehouses.firstWhere((w) => w.id == warehouseId);

      // 递归更新物品或其子物品
      bool updated = _updateItemRecursively(warehouse.items, item);

      // 如果没有找到要更新的物品，则作为新物品添加到仓库
      if (!updated) {
        warehouse.items.add(item);
        // 广播物品添加事件
        EventManager.instance.broadcast(
          'goods_item_added',
          GoodsItemAddedEventArgs(item, warehouseId),
        );
      }
      await saveWarehouse(warehouse);

      // 同步小组件数据
      await _syncWidget();
    } catch (e) {
      debugPrint('Error saving goods item: $e');
      rethrow;
    }
  }

  /// 递归更新物品及其子物品
  /// 返回是否找到并更新了物品
  bool _updateItemRecursively(List<GoodsItem> items, GoodsItem updatedItem) {
    // 在当前层级查找
    for (var i = 0; i < items.length; i++) {
      if (items[i].id == updatedItem.id) {
        items[i] = updatedItem;
        return true;
      }

      // 递归查找子物品
      if (items[i].subItems.isNotEmpty) {
        if (_updateItemRecursively(items[i].subItems, updatedItem)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> deleteGoodsItem(String warehouseId, String itemId) async {
    try {
      final warehouse = _warehouses.firstWhere((w) => w.id == warehouseId);

      // 尝试递归删除物品
      bool deleted = _deleteItemRecursively(warehouse.items, itemId);

      if (!deleted) {
        // 如果递归删除失败，尝试直接从顶级物品中删除
        warehouse.items.removeWhere((item) => item.id == itemId);
      }

      // 广播物品删除事件
      EventManager.instance.broadcast(
        'goods_item_deleted',
        GoodsItemDeletedEventArgs(itemId, warehouseId),
      );

      await saveWarehouse(warehouse);

      // 同步小组件数据
      await _syncWidget();
    } catch (e) {
      debugPrint('Error deleting goods item: $e');
      rethrow;
    }
  }

  /// 递归删除物品及其子物品
  /// 返回是否找到并删除了物品
  bool _deleteItemRecursively(List<GoodsItem> items, String itemId) {
    // 直接从当前层级删除
    int initialLength = items.length;
    items.removeWhere((item) => item.id == itemId);
    if (items.length < initialLength) {
      return true;
    }

    // 递归查找子物品
    for (var item in items) {
      if (item.subItems.isNotEmpty) {
        if (_deleteItemRecursively(item.subItems, itemId)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> clearWarehouse(String warehouseId) async {
    try {
      final warehouse = _warehouses.firstWhere((w) => w.id == warehouseId);
      // 创建一个新的仓库对象，但清空物品列表
      final clearedWarehouse = warehouse.copyWith(items: []);
      await saveWarehouse(clearedWarehouse);
    } catch (e) {
      debugPrint('Error clearing warehouse: $e');
      rethrow;
    }
  }

  // 获取所有物品的总数量
  int getTotalItemsCount() {
    int count = 0;
    for (var warehouse in _warehouses) {
      count += warehouse.items.length;
    }
    return count;
  }

  // 获取所有物品的总价值
  double getTotalItemsValue() {
    double total = 0;
    for (var warehouse in _warehouses) {
      for (var item in warehouse.items) {
        if (item.purchasePrice != null) {
          total += item.purchasePrice!;
        }
      }
    }
    return total;
  }

  // 获取一个月未使用的物品数量
  int getUnusedItemsCount() {
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    int count = 0;
    for (var warehouse in _warehouses) {
      for (var item in warehouse.items) {
        final lastUsed = item.lastUsedDate;
        if (lastUsed == null || lastUsed.isBefore(oneMonthAgo)) {
          count++;
        }
      }
    }
    return count;
  }

  // 获取今日使用记录数量
  int getTodayUsageCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    int count = 0;
    for (var warehouse in _warehouses) {
      count += _countTodayUsageRecursively(
        warehouse.items,
        startOfDay,
        endOfDay,
      );
    }
    return count;
  }

  // 递归统计今日使用记录（包含子物品）
  int _countTodayUsageRecursively(
    List<GoodsItem> items,
    DateTime startOfDay,
    DateTime endOfDay,
  ) {
    int count = 0;
    for (var item in items) {
      // 统计当前物品的今日使用记录
      for (var record in item.usageRecords) {
        if (record.date.isAfter(startOfDay) && record.date.isBefore(endOfDay)) {
          count++;
        }
      }
      // 递归统计子物品
      if (item.subItems.isNotEmpty) {
        count += _countTodayUsageRecursively(
          item.subItems,
          startOfDay,
          endOfDay,
        );
      }
    }
    return count;
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  String? getPluginName(context) {
    return GoodsLocalizations.of(context).name;
  }

  @override
  Widget buildMainView(BuildContext context) {
    return GoodsBottomBar(plugin: this);
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                GoodsLocalizations.of(context).name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 物品总数量和总价值
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 物品总数量
                  Column(
                    children: [
                      Text(
                        GoodsLocalizations.of(context).totalQuantity,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${getTotalItemsCount()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 物品总价值
                  Column(
                    children: [
                      Text(
                        GoodsLocalizations.of(context).totalValue,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '¥${getTotalItemsValue().toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 第二行 - 一个月未使用
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        GoodsLocalizations.of(context).oneMonthUnused,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '${getUnusedItemsCount()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              getUnusedItemsCount() > 0
                                  ? theme.colorScheme.error
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 仓库相关
      'getWarehouses': _jsGetWarehouses,
      'getWarehouse': _jsGetWarehouse,
      'createWarehouse': _jsCreateWarehouse,
      'updateWarehouse': _jsUpdateWarehouse,
      'deleteWarehouse': _jsDeleteWarehouse,
      'clearWarehouse': _jsClearWarehouse,

      // 物品相关
      'getGoods': _jsGetGoods,
      'getGoodsItem': _jsGetGoodsItem,
      'createGoodsItem': _jsCreateGoodsItem,
      'updateGoodsItem': _jsUpdateGoodsItem,
      'deleteGoodsItem': _jsDeleteGoodsItem,

      // 使用记录相关
      'addUsageRecord': _jsAddUsageRecord,

      // 统计相关
      'getStatistics': _jsGetStatistics,
    };
  }

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================
  /// 获取所有仓库列表
  /// 支持分页参数: offset, count
  /// 返回: JSON数组，包含所有仓库信息（不含物品）
  Future<String> _jsGetWarehouses(Map<String, dynamic> params) async {
    final warehousesJson =
        _warehouses.map((w) {
          final json = w.toJson();
          // 不返回物品列表，减少数据量
          json.remove('items');
          return json;
        }).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        warehousesJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(warehousesJson);
  }

  /// 获取指定仓库的详细信息（包含物品）
  Future<String> _jsGetWarehouse(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? warehouseId = params['warehouseId'];
    if (warehouseId == null || warehouseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: warehouseId'});
    }

    final warehouse = getWarehouse(warehouseId);
    if (warehouse == null) {
      return jsonEncode({'error': '仓库不存在', 'warehouseId': warehouseId});
    }

    return jsonEncode(warehouse.toJson());
  }

  /// 创建新仓库
  Future<String> _jsCreateWarehouse(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    try {
      // 可选参数
      final String? id = params['id'];
      final int? iconCode = params['iconCode'];
      final int? colorValue = params['colorValue'];

      // 生成ID（如果没有提供）
      String warehouseId =
          id ?? const Uuid().v4();

      // 检查ID是否已存在
      if (getWarehouse(warehouseId) != null) {
        return jsonEncode({'error': '仓库ID已存在: $warehouseId'});
      }

      final warehouse = Warehouse(
        id: warehouseId,
        title: title,
        icon:
            iconCode != null
                ? IconData(iconCode, fontFamily: 'MaterialIcons')
                : Icons.inventory_2,
        iconColor: colorValue != null ? Color(colorValue) : color,
      );

      await saveWarehouse(warehouse);

      final json = warehouse.toJson();
      json.remove('items'); // 新建仓库没有物品
      return jsonEncode(json);
    } catch (e) {
      return jsonEncode({'error': '创建仓库失败: ${e.toString()}'});
    }
  }

  /// 更新仓库信息
  Future<String> _jsUpdateWarehouse(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? warehouseId = params['warehouseId'];
    if (warehouseId == null || warehouseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: warehouseId'});
    }

    final warehouse = getWarehouse(warehouseId);
    if (warehouse == null) {
      return jsonEncode({'error': '仓库不存在', 'warehouseId': warehouseId});
    }

    // 可选参数
    final String? title = params['title'];
    final int? iconCode = params['iconCode'];
    final int? colorValue = params['colorValue'];

    final updatedWarehouse = warehouse.copyWith(
      title: title,
      icon:
          iconCode != null
              ? IconData(iconCode, fontFamily: 'MaterialIcons')
              : null,
      iconColor: colorValue != null ? Color(colorValue) : null,
    );

    await saveWarehouse(updatedWarehouse);
    return jsonEncode(updatedWarehouse.toJson());
  }

  /// 删除仓库
  Future<String> _jsDeleteWarehouse(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? warehouseId = params['warehouseId'];
    if (warehouseId == null || warehouseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: warehouseId'});
    }

    try {
      await deleteWarehouse(warehouseId);
      return jsonEncode({'success': true, 'warehouseId': warehouseId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 清空仓库（删除所有物品）
  Future<String> _jsClearWarehouse(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? warehouseId = params['warehouseId'];
    if (warehouseId == null || warehouseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: warehouseId'});
    }

    try {
      await clearWarehouse(warehouseId);
      return jsonEncode({'success': true, 'warehouseId': warehouseId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取物品列表
  /// 支持分页参数: offset, count
  Future<String> _jsGetGoods(Map<String, dynamic> params) async {
    // 可选参数
    final String? warehouseId = params['warehouseId'];

    List<Map<String, dynamic>> goodsJsonList = [];

    if (warehouseId != null && warehouseId.isNotEmpty) {
      // 获取指定仓库的物品
      final warehouse = getWarehouse(warehouseId);
      if (warehouse != null) {
        goodsJsonList = warehouse.items.map((item) => item.toJson()).toList();
      }
    } else {
      // 获取所有仓库的所有物品
      for (var warehouse in _warehouses) {
        goodsJsonList.addAll(warehouse.items.map((item) => item.toJson()));
      }
    }

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        goodsJsonList,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(goodsJsonList);
  }

  /// 获取指定物品的详细信息
  Future<String> _jsGetGoodsItem(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    final result = findGoodsItemById(itemId);
    if (result == null) {
      return jsonEncode({'error': '物品不存在', 'itemId': itemId});
    }

    final itemJson = result.item.toJson();
    itemJson['warehouseId'] = result.warehouseId; // 添加仓库ID信息
    return jsonEncode(itemJson);
  }

  /// 创建新物品
  Future<String> _jsCreateGoodsItem(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? warehouseId = params['warehouseId'];
    final String? itemDataStr = params['itemData'];

    if (warehouseId == null || warehouseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: warehouseId'});
    }
    if (itemDataStr == null || itemDataStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemData'});
    }

    try {
      final data = jsonDecode(itemDataStr) as Map<String, dynamic>;

      // 确保有ID和标题
      if (!data.containsKey('title') || data['title'] == null) {
        return jsonEncode({'error': '物品名称不能为空'});
      }

      // 生成ID（如果没有提供）
      data['id'] =
          data['id'] ?? const Uuid().v4();

      // 检查ID是否已存在（跨所有仓库）
      final existingItem = findGoodsItemById(data['id']);
      if (existingItem != null) {
        return jsonEncode({'error': '物品ID已存在: ${data['id']}'});
      }

      // 创建物品
      final item = GoodsItem.fromJson(data);
      await saveGoodsItem(warehouseId, item);

      return jsonEncode(item.toJson());
    } catch (e) {
      return jsonEncode({'error': '创建物品失败: ${e.toString()}'});
    }
  }

  /// 更新物品
  Future<String> _jsUpdateGoodsItem(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? itemId = params['itemId'];
    final String? itemDataStr = params['itemData'];

    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }
    if (itemDataStr == null || itemDataStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemData'});
    }

    try {
      // 查找物品
      final result = findGoodsItemById(itemId);
      if (result == null) {
        return jsonEncode({'error': '物品不存在', 'itemId': itemId});
      }

      // 解析更新数据
      final updateData = jsonDecode(itemDataStr) as Map<String, dynamic>;

      // 合并现有数据和更新数据
      final currentJson = result.item.toJson();
      currentJson.addAll(updateData);
      currentJson['id'] = itemId; // 确保ID不被修改

      // 创建更新后的物品
      final updatedItem = GoodsItem.fromJson(currentJson);
      await saveGoodsItem(result.warehouseId, updatedItem);

      return jsonEncode(updatedItem.toJson());
    } catch (e) {
      return jsonEncode({'error': '更新物品失败: ${e.toString()}'});
    }
  }

  /// 删除物品
  Future<String> _jsDeleteGoodsItem(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    try {
      // 查找物品所在的仓库
      final result = findGoodsItemById(itemId);
      if (result == null) {
        return jsonEncode({'error': '物品不存在', 'itemId': itemId});
      }

      await deleteGoodsItem(result.warehouseId, itemId);
      return jsonEncode({
        'success': true,
        'itemId': itemId,
        'warehouseId': result.warehouseId,
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 添加使用记录
  Future<String> _jsAddUsageRecord(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    // 可选参数
    final String? dateStr = params['dateStr'];
    final String? note = params['note'];

    try {
      // 查找物品
      final result = findGoodsItemById(itemId);
      if (result == null) {
        return jsonEncode({'error': '物品不存在', 'itemId': itemId});
      }

      // 解析日期
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

      // 添加使用记录
      final updatedItem = result.item.addUsageRecord(date, note: note);
      await saveGoodsItem(result.warehouseId, updatedItem);

      return jsonEncode(updatedItem.toJson());
    } catch (e) {
      return jsonEncode({'error': '添加使用记录失败: ${e.toString()}'});
    }
  }

  /// 获取统计信息
  /// 返回: 包含总数量、总价值、未使用物品数的统计数据
  Future<String> _jsGetStatistics(Map<String, dynamic> params) async {
    return jsonEncode({
      'totalCount': getTotalItemsCount(),
      'totalValue': getTotalItemsValue(),
      'unusedCount': getUnusedItemsCount(),
      'warehouseCount': _warehouses.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncGoods();
  }
}
