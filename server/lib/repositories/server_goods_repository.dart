/// Goods 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件
library;

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Goods Repository 实现
class ServerGoodsRepository extends IGoodsRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'goods';

  ServerGoodsRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有仓库
  Future<List<WarehouseDto>> _readAllWarehouses() async {
    final warehousesData = await dataService.readPluginData(
      userId,
      _pluginId,
      'warehouses.json',
    );
    if (warehousesData == null) return [];

    final warehouses = warehousesData['warehouses'] as List<dynamic>? ?? [];
    return warehouses
        .map((w) => WarehouseDto.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  /// 保存所有仓库
  Future<void> _saveAllWarehouses(List<WarehouseDto> warehouses) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'warehouses.json',
      {'warehouses': warehouses.map((w) => w.toJson()).toList()},
    );
  }

  /// 读取仓库物品
  Future<List<GoodsItemDto>> _readWarehouseItems(String warehouseId) async {
    final itemsData = await dataService.readPluginData(
      userId,
      _pluginId,
      'warehouse_$warehouseId.json',
    );
    if (itemsData == null) return [];

    final items = itemsData['items'] as List<dynamic>? ?? [];
    return items
        .map((i) => GoodsItemDto.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  /// 保存仓库物品
  Future<void> _saveWarehouseItems(
      String warehouseId, List<GoodsItemDto> items) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'warehouse_$warehouseId.json',
      {'items': items.map((i) => i.toJson()).toList()},
    );
  }

  // ============ 仓库操作 ============

  @override
  Future<Result<List<WarehouseDto>>> getWarehouses({
    PaginationParams? pagination,
  }) async {
    try {
      var warehouses = await _readAllWarehouses();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          warehouses,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(warehouses);
    } catch (e) {
      return Result.failure('获取仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<WarehouseDto?>> getWarehouseById(String id) async {
    try {
      final warehouses = await _readAllWarehouses();
      final warehouse = warehouses.where((w) => w.id == id).firstOrNull;
      return Result.success(warehouse);
    } catch (e) {
      return Result.failure('获取仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<WarehouseDto>> createWarehouse(WarehouseDto warehouse) async {
    try {
      final warehouses = await _readAllWarehouses();
      warehouses.add(warehouse);
      await _saveAllWarehouses(warehouses);

      // 初始化空物品列表
      await _saveWarehouseItems(warehouse.id, []);

      return Result.success(warehouse);
    } catch (e) {
      return Result.failure('创建仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<WarehouseDto>> updateWarehouse(
      String id, WarehouseDto warehouse) async {
    try {
      final warehouses = await _readAllWarehouses();
      final index = warehouses.indexWhere((w) => w.id == id);

      if (index == -1) {
        return Result.failure('仓库不存在', code: ErrorCodes.notFound);
      }

      warehouses[index] = warehouse;
      await _saveAllWarehouses(warehouses);
      return Result.success(warehouse);
    } catch (e) {
      return Result.failure('更新仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteWarehouse(String id) async {
    try {
      final warehouses = await _readAllWarehouses();
      final initialLength = warehouses.length;
      warehouses.removeWhere((w) => w.id == id);

      if (warehouses.length == initialLength) {
        return Result.failure('仓库不存在', code: ErrorCodes.notFound);
      }

      await _saveAllWarehouses(warehouses);

      // 删除仓库物品文件
      await dataService.deletePluginFile(
          userId, _pluginId, 'warehouse_$id.json');

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 物品操作 ============

  @override
  Future<Result<List<GoodsItemDto>>> getItems({
    String? warehouseId,
    PaginationParams? pagination,
  }) async {
    try {
      List<GoodsItemDto> allItems = [];

      if (warehouseId != null) {
        // 获取特定仓库的物品
        allItems = await _readWarehouseItems(warehouseId);
      } else {
        // 获取所有仓库的物品
        final warehouses = await _readAllWarehouses();
        for (final warehouse in warehouses) {
          final items = await _readWarehouseItems(warehouse.id);
          allItems.addAll(items);
        }
      }

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          allItems,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(allItems);
    } catch (e) {
      return Result.failure('获取物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoodsItemDto?>> getItemById(String id) async {
    try {
      final warehouses = await _readAllWarehouses();
      for (final warehouse in warehouses) {
        final items = await _readWarehouseItems(warehouse.id);
        final item = items.where((i) => i.id == id).firstOrNull;
        if (item != null) {
          return Result.success(item);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoodsItemDto>> createItem(
      String warehouseId, GoodsItemDto item) async {
    try {
      final items = await _readWarehouseItems(warehouseId);
      items.add(item);
      await _saveWarehouseItems(warehouseId, items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('创建物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoodsItemDto>> updateItem(
      String warehouseId, String id, GoodsItemDto item) async {
    try {
      final items = await _readWarehouseItems(warehouseId);
      final index = items.indexWhere((i) => i.id == id);

      if (index == -1) {
        return Result.failure('物品不存在', code: ErrorCodes.notFound);
      }

      items[index] = item;
      await _saveWarehouseItems(warehouseId, items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('更新物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteItem(String warehouseId, String id) async {
    try {
      final items = await _readWarehouseItems(warehouseId);
      final initialLength = items.length;
      items.removeWhere((i) => i.id == id);

      if (items.length == initialLength) {
        return Result.failure('物品不存在', code: ErrorCodes.notFound);
      }

      await _saveWarehouseItems(warehouseId, items);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<GoodsItemDto>>> searchItems(GoodsItemQuery query) async {
    try {
      List<GoodsItemDto> items = [];

      if (query.warehouseId != null) {
        // 搜索特定仓库
        items = await _readWarehouseItems(query.warehouseId!);
      } else {
        // 搜索所有仓库
        final warehouses = await _readAllWarehouses();
        for (final warehouse in warehouses) {
          final warehouseItems = await _readWarehouseItems(warehouse.id);
          items.addAll(warehouseItems);
        }
      }

      // 按关键词过滤
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lowerKeyword = query.keyword!.toLowerCase();
        items = items.where((item) {
          final name = item.name.toLowerCase();
          final desc = (item.description ?? '').toLowerCase();
          return name.contains(lowerKeyword) || desc.contains(lowerKeyword);
        }).toList();
      }

      // 按分类过滤
      if (query.category != null && query.category!.isNotEmpty) {
        items = items.where((item) => item.category == query.category).toList();
      }

      // 按标签过滤
      if (query.tags != null && query.tags!.isNotEmpty) {
        items = items.where((item) {
          return query.tags!.any((tag) => item.tags.contains(tag));
        }).toList();
      }

      // 通用字段查找
      if (query.field != null && query.value != null) {
        items = items.where((item) {
          final json = item.toJson();
          final fieldValue = json[query.field]?.toString() ?? '';
          if (query.fuzzy) {
            return fieldValue
                .toLowerCase()
                .contains(query.value!.toLowerCase());
          }
          return fieldValue == query.value;
        }).toList();
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('搜索物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<Map<String, dynamic>>> getStats() async {
    try {
      final warehouses = await _readAllWarehouses();
      var totalItems = 0;
      var totalQuantity = 0;

      for (final warehouse in warehouses) {
        final items = await _readWarehouseItems(warehouse.id);
        totalItems += items.length;
        for (final item in items) {
          totalQuantity += item.quantity;
        }
      }

      return Result.success({
        'warehouseCount': warehouses.length,
        'itemCount': totalItems,
        'totalQuantity': totalQuantity,
      });
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
    }
  }
}
