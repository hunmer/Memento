import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/warehouse_list_screen.dart';
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
        _warehouses[index] = warehouse;
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
    return const WarehouseListScreen();
  }
}
