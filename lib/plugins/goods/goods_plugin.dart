import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/warehouse_list_screen.dart';
import 'screens/goods_main_screen.dart';
import 'models/warehouse.dart';
import 'models/goods_item.dart';

class GoodsPlugin extends BasePlugin {
  static final GoodsPlugin instance = GoodsPlugin._internal();
  GoodsPlugin._internal();

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
  String get version => '1.0.0';

  @override
  String get description => '管理各种物品的存储位置和使用记录';

  @override
  String get author => 'Zhuanz';

  @override
  IconData get icon => Icons.inventory_2;

  @override
  Future<void> initialize() async {
    // 确保物品管理数据目录存在
    await storage.createDirectory('goods');

    // 加载仓库数据
    await _loadWarehouses();
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
      final itemIndex = warehouse.items.indexWhere((i) => i.id == item.id);

      if (itemIndex != -1) {
        warehouse.items[itemIndex] = item;
      } else {
        warehouse.items.add(item);
      }

      await saveWarehouse(warehouse);
    } catch (e) {
      debugPrint('Error saving goods item: $e');
      rethrow;
    }
  }

  Future<void> deleteGoodsItem(String warehouseId, String itemId) async {
    try {
      final warehouse = _warehouses.firstWhere((w) => w.id == warehouseId);
      warehouse.items.removeWhere((item) => item.id == itemId);
      await saveWarehouse(warehouse);
    } catch (e) {
      debugPrint('Error deleting goods item: $e');
      rethrow;
    }
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
    await pluginManager.registerPlugin(this);
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': {'theme': 'light'},
    });
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const GoodsMainScreen();
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
                child: Icon(
                  icon ?? Icons.inventory_2,
                  size: 24,
                  color: color ?? theme.primaryColor,
                ),
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
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 物品总数量
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('物品总数量', style: theme.textTheme.bodyMedium),
                    Text(
                      '${getTotalItemsCount()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 物品总价值
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('物品总价值', style: theme.textTheme.bodyMedium),
                    Text(
                      '¥${getTotalItemsValue().toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                // 一个月未使用
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          ),
        ],
      ),
    );
  }
}
