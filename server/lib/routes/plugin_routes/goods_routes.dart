import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../services/plugin_data_service.dart';

/// Goods 插件 HTTP 路由
class GoodsRoutes {
  final PluginDataService _dataService;
  final _uuid = const Uuid();

  GoodsRoutes(this._dataService);

  Router get router {
    final router = Router();

    // ==================== 仓库 API ====================
    router.get('/warehouses', _getWarehouses);
    router.get('/warehouses/<id>', _getWarehouse);
    router.post('/warehouses', _createWarehouse);
    router.put('/warehouses/<id>', _updateWarehouse);
    router.delete('/warehouses/<id>', _deleteWarehouse);

    // ==================== 物品 API ====================
    router.get('/items', _getItems);
    router.get('/items/<id>', _getItem);
    router.post('/items', _createItem);
    router.put('/items/<id>', _updateItem);
    router.delete('/items/<id>', _deleteItem);

    // ==================== 统计/搜索 API ====================
    router.get('/stats', _getStats);
    router.get('/search', _searchItems);

    return router;
  }

  // ==================== 辅助方法 ====================

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  Response _successResponse(dynamic data) {
    return Response.ok(
      jsonEncode({
        'success': true,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _paginatedResponse(List<dynamic> data, {int offset = 0, int count = 100}) {
    final paginated = _dataService.paginate(data, offset: offset, count: count);
    return Response.ok(
      jsonEncode({
        'success': true,
        ...paginated,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 读取仓库列表
  Future<List<Map<String, dynamic>>> _readWarehouses(String userId) async {
    final data = await _dataService.readPluginData(userId, 'goods', 'warehouses.json');
    if (data == null) return [];
    final warehouses = data['warehouses'] as List<dynamic>? ?? [];
    return warehouses.cast<Map<String, dynamic>>();
  }

  /// 保存仓库列表
  Future<void> _saveWarehouses(String userId, List<Map<String, dynamic>> warehouses) async {
    await _dataService.writePluginData(userId, 'goods', 'warehouses.json', {'warehouses': warehouses});
  }

  /// 读取仓库物品
  Future<List<Map<String, dynamic>>> _readWarehouseItems(String userId, String warehouseId) async {
    final data = await _dataService.readPluginData(userId, 'goods', 'warehouse_$warehouseId.json');
    if (data == null) return [];
    final items = data['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// 保存仓库物品
  Future<void> _saveWarehouseItems(String userId, String warehouseId, List<Map<String, dynamic>> items) async {
    await _dataService.writePluginData(userId, 'goods', 'warehouse_$warehouseId.json', {'items': items});
  }

  // ==================== 仓库处理方法 ====================

  Future<Response> _getWarehouses(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final warehouses = await _readWarehouses(userId);
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(warehouses, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(warehouses);
    } catch (e) {
      return _errorResponse(500, '获取仓库失败: $e');
    }
  }

  Future<Response> _getWarehouse(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final warehouses = await _readWarehouses(userId);
      final warehouse = warehouses.firstWhere((w) => w['id'] == id, orElse: () => <String, dynamic>{});
      if (warehouse.isEmpty) return _errorResponse(404, '仓库不存在');
      return _successResponse(warehouse);
    } catch (e) {
      return _errorResponse(500, '获取仓库失败: $e');
    }
  }

  Future<Response> _createWarehouse(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final name = data['name'] as String?;
      if (name == null || name.isEmpty) return _errorResponse(400, '缺少必需参数: name');

      final warehouseId = data['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();
      final warehouse = {
        'id': warehouseId,
        'name': name,
        'description': data['description'],
        'icon': data['icon'],
        'color': data['color'],
        'createdAt': now,
        'updatedAt': now,
      };

      final warehouses = await _readWarehouses(userId);
      warehouses.add(warehouse);
      await _saveWarehouses(userId, warehouses);

      // 初始化空物品列表
      await _saveWarehouseItems(userId, warehouseId, []);

      return _successResponse(warehouse);
    } catch (e) {
      return _errorResponse(500, '创建仓库失败: $e');
    }
  }

  Future<Response> _updateWarehouse(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final warehouses = await _readWarehouses(userId);
      final index = warehouses.indexWhere((w) => w['id'] == id);
      if (index == -1) return _errorResponse(404, '仓库不存在');

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;
      final warehouse = Map<String, dynamic>.from(warehouses[index]);

      if (updates.containsKey('name')) warehouse['name'] = updates['name'];
      if (updates.containsKey('description')) warehouse['description'] = updates['description'];
      if (updates.containsKey('icon')) warehouse['icon'] = updates['icon'];
      if (updates.containsKey('color')) warehouse['color'] = updates['color'];
      warehouse['updatedAt'] = DateTime.now().toIso8601String();

      warehouses[index] = warehouse;
      await _saveWarehouses(userId, warehouses);
      return _successResponse(warehouse);
    } catch (e) {
      return _errorResponse(500, '更新仓库失败: $e');
    }
  }

  Future<Response> _deleteWarehouse(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final warehouses = await _readWarehouses(userId);
      final initialLength = warehouses.length;
      warehouses.removeWhere((w) => w['id'] == id);
      if (warehouses.length == initialLength) return _errorResponse(404, '仓库不存在');

      await _saveWarehouses(userId, warehouses);
      await _dataService.deletePluginFile(userId, 'goods', 'warehouse_$id.json');
      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除仓库失败: $e');
    }
  }

  // ==================== 物品处理方法 ====================

  Future<Response> _getItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final warehouseId = request.url.queryParameters['warehouseId'];

    try {
      List<Map<String, dynamic>> allItems = [];

      if (warehouseId != null) {
        allItems = await _readWarehouseItems(userId, warehouseId);
      } else {
        // 获取所有仓库的物品
        final warehouses = await _readWarehouses(userId);
        for (final warehouse in warehouses) {
          final items = await _readWarehouseItems(userId, warehouse['id'] as String);
          for (final item in items) {
            item['warehouseId'] = warehouse['id'];
            item['warehouseName'] = warehouse['name'];
          }
          allItems.addAll(items);
        }
      }

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(allItems, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(allItems);
    } catch (e) {
      return _errorResponse(500, '获取物品失败: $e');
    }
  }

  Future<Response> _getItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final warehouses = await _readWarehouses(userId);
      for (final warehouse in warehouses) {
        final items = await _readWarehouseItems(userId, warehouse['id'] as String);
        final item = items.firstWhere((i) => i['id'] == id, orElse: () => <String, dynamic>{});
        if (item.isNotEmpty) {
          item['warehouseId'] = warehouse['id'];
          return _successResponse(item);
        }
      }
      return _errorResponse(404, '物品不存在');
    } catch (e) {
      return _errorResponse(500, '获取物品失败: $e');
    }
  }

  Future<Response> _createItem(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final warehouseId = data['warehouseId'] as String?;
      if (name == null || warehouseId == null) {
        return _errorResponse(400, '缺少必需参数: name, warehouseId');
      }

      final itemId = data['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();
      final item = {
        'id': itemId,
        'name': name,
        'description': data['description'],
        'quantity': data['quantity'] ?? 1,
        'category': data['category'],
        'tags': data['tags'] ?? <String>[],
        'customFields': data['customFields'],
        'createdAt': now,
        'updatedAt': now,
      };

      final items = await _readWarehouseItems(userId, warehouseId);
      items.add(item);
      await _saveWarehouseItems(userId, warehouseId, items);

      return _successResponse(item);
    } catch (e) {
      return _errorResponse(500, '创建物品失败: $e');
    }
  }

  Future<Response> _updateItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;
      final warehouseId = updates['warehouseId'] as String?;

      if (warehouseId == null) return _errorResponse(400, '缺少参数: warehouseId');

      final items = await _readWarehouseItems(userId, warehouseId);
      final index = items.indexWhere((i) => i['id'] == id);
      if (index == -1) return _errorResponse(404, '物品不存在');

      final item = Map<String, dynamic>.from(items[index]);
      if (updates.containsKey('name')) item['name'] = updates['name'];
      if (updates.containsKey('description')) item['description'] = updates['description'];
      if (updates.containsKey('quantity')) item['quantity'] = updates['quantity'];
      if (updates.containsKey('category')) item['category'] = updates['category'];
      if (updates.containsKey('tags')) item['tags'] = updates['tags'];
      if (updates.containsKey('customFields')) item['customFields'] = updates['customFields'];
      item['updatedAt'] = DateTime.now().toIso8601String();

      items[index] = item;
      await _saveWarehouseItems(userId, warehouseId, items);
      return _successResponse(item);
    } catch (e) {
      return _errorResponse(500, '更新物品失败: $e');
    }
  }

  Future<Response> _deleteItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final warehouseId = request.url.queryParameters['warehouseId'];
    if (warehouseId == null) return _errorResponse(400, '缺少参数: warehouseId');

    try {
      final items = await _readWarehouseItems(userId, warehouseId);
      final initialLength = items.length;
      items.removeWhere((i) => i['id'] == id);
      if (items.length == initialLength) return _errorResponse(404, '物品不存在');

      await _saveWarehouseItems(userId, warehouseId, items);
      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除物品失败: $e');
    }
  }

  // ==================== 统计/搜索 ====================

  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final warehouses = await _readWarehouses(userId);
      var totalItems = 0;
      var totalQuantity = 0;

      for (final warehouse in warehouses) {
        final items = await _readWarehouseItems(userId, warehouse['id'] as String);
        totalItems += items.length;
        for (final item in items) {
          totalQuantity += (item['quantity'] as int? ?? 1);
        }
      }

      return _successResponse({
        'warehouseCount': warehouses.length,
        'itemCount': totalItems,
        'totalQuantity': totalQuantity,
      });
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }

  Future<Response> _searchItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final keyword = request.url.queryParameters['keyword'];
    final warehouseId = request.url.queryParameters['warehouseId'];

    try {
      List<Map<String, dynamic>> allItems = [];

      if (warehouseId != null) {
        allItems = await _readWarehouseItems(userId, warehouseId);
      } else {
        final warehouses = await _readWarehouses(userId);
        for (final warehouse in warehouses) {
          final items = await _readWarehouseItems(userId, warehouse['id'] as String);
          for (final item in items) {
            item['warehouseId'] = warehouse['id'];
          }
          allItems.addAll(items);
        }
      }

      if (keyword != null && keyword.isNotEmpty) {
        final lowerKeyword = keyword.toLowerCase();
        allItems = allItems.where((item) {
          final name = (item['name'] as String? ?? '').toLowerCase();
          final desc = (item['description'] as String? ?? '').toLowerCase();
          return name.contains(lowerKeyword) || desc.contains(lowerKeyword);
        }).toList();
      }

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(allItems, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(allItems);
    } catch (e) {
      return _errorResponse(500, '搜索物品失败: $e');
    }
  }
}
