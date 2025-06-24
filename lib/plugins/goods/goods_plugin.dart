import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/event/event_manager.dart';
import 'screens/goods_main_screen.dart';
import 'models/warehouse.dart';
import 'models/goods_item.dart';
import 'models/find_item_result.dart';

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
class GoodsMainView extends StatefulWidget {
  const GoodsMainView({super.key});
  @override
  State<GoodsMainView> createState() => _GoodsMainViewState();
}

class _GoodsMainViewState extends State<GoodsMainView> {
  @override
  Widget build(BuildContext context) {
    return const GoodsMainScreen();
  }
}

class GoodsPlugin extends BasePlugin {
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
  String get name => '物品管理';

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
      }
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
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

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return GoodsMainView();
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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color ?? theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                name,
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
                      Text('总数量', style: theme.textTheme.bodyMedium),
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
                      Text('总价值', style: theme.textTheme.bodyMedium),
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
                      Text('一个月未使用', style: theme.textTheme.bodyMedium),
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
}
