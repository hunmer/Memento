part of 'goods_plugin.dart';

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
    'getItems': _jsGetGoods, // 别名，与工具模板保持一致
    'getItemById': _jsGetGoodsItem, // 别名
    'createGoodsItem': _jsCreateGoodsItem,
    'createItem': _jsCreateGoodsItem, // 别名，与工具模板保持一致
    'updateGoodsItem': _jsUpdateGoodsItem,
    'updateItem': _jsUpdateGoodsItem, // 别名
    'deleteGoodsItem': _jsDeleteGoodsItem,
    'deleteItem': _jsDeleteGoodsItem, // 别名

    // 使用记录相关
    'addUsageRecord': _jsAddUsageRecord,

    // 统计相关
    'getStatistics': _jsGetStatistics,
    'getStats': _jsGetStatistics, // 别名
  };
}

// ==================== JS API 实现 ====================
/// 获取所有仓库列表
/// 支持分页参数: offset, count
/// 返回: JSON数组，包含所有仓库信息（不含物品）
Future<String> _jsGetWarehouses(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.getWarehouses(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '获取仓库失败: ${e.toString()}'});
  }
}

/// 获取指定仓库的详细信息（包含物品）
Future<String> _jsGetWarehouse(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.getWarehouseById(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    if (result.dataOrNull == null) {
      return jsonEncode({'error': '仓库不存在'});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '获取仓库失败: ${e.toString()}'});
  }
}

/// 创建新仓库
Future<String> _jsCreateWarehouse(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.createWarehouse(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '创建仓库失败: ${e.toString()}'});
  }
}

/// 更新仓库信息
Future<String> _jsUpdateWarehouse(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.updateWarehouse(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '更新仓库失败: ${e.toString()}'});
  }
}

/// 删除仓库
Future<String> _jsDeleteWarehouse(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.deleteWarehouse(params);

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true, 'warehouseId': params['id']});
  } catch (e) {
    return jsonEncode({'success': false, 'error': e.toString()});
  }
}

/// 清空仓库（删除所有物品）
Future<String> _jsClearWarehouse(Map<String, dynamic> params) async {
  try {
    final String? warehouseId = params['warehouseId'] ?? params['id'];
    if (warehouseId == null || warehouseId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: warehouseId'});
    }

    await clearWarehouse(warehouseId);
    return jsonEncode({'success': true, 'warehouseId': warehouseId});
  } catch (e) {
    return jsonEncode({'success': false, 'error': e.toString()});
  }
}

/// 获取物品列表
/// 支持分页参数: offset, count
/// 支持 get_http_image 参数：是否将图片路径转换为 HTTP URL
Future<String> _jsGetGoods(Map<String, dynamic> params) async {
  try {
    // 提取图片转换参数
    final getHttpImage = params['get_http_image'] == true;
    params.remove('get_http_image');

    final result = await _useCase.getItems(params);

    var items = result.dataOrNull ?? [];

    // 处理图片路径转换（使用简化方法）
    if (getHttpImage) {
      items = await LocalHttpServer.convertImagesWithAutoConfig(
        items: items,
        pluginId: id,
        imageKey: 'imageUrl',
        storageManager: storage,
      );
    }

    return jsonEncode({
      'success': true,
      'data': items,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    return jsonEncode({
      'success': false,
      'error': '获取物品失败: ${e.toString()}',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

/// 获取指定物品的详细信息
Future<String> _jsGetGoodsItem(Map<String, dynamic> params) async {
  try {
    final result = await _useCase.getItemById(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    if (result.dataOrNull == null) {
      return jsonEncode({'error': '物品不存在'});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '获取物品失败: ${e.toString()}'});
  }
}

/// 创建新物品
Future<String> _jsCreateGoodsItem(Map<String, dynamic> params) async {
  try {
    // 转换参数格式
    final String? itemDataStr = params['itemData'];
    if (itemDataStr == null || itemDataStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemData'});
    }

    final data = jsonDecode(itemDataStr) as Map<String, dynamic>;

    // 确保有ID和标题
    if (!data.containsKey('title') || data['title'] == null) {
      return jsonEncode({'error': '物品名称不能为空'});
    }

    // 生成ID（如果没有提供）
    data['id'] = data['id'] ?? const Uuid().v4();

    // 构建 UseCase 需要的参数
    final useCaseParams = {
      'id': data['id'],
      'name': data['title'],
      'description': data['notes'] ?? data['description'],
      'quantity': data['quantity'] ?? 1,
      'category': data['category'],
      'tags': data['tags'] ?? [],
      'customFields': data['customFields'],
      'warehouseId': params['warehouseId'],
    };

    final result = await _useCase.createItem(useCaseParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '创建物品失败: ${e.toString()}'});
  }
}

/// 更新物品
Future<String> _jsUpdateGoodsItem(Map<String, dynamic> params) async {
  try {
    // 必需参数验证
    final String? itemId = params['itemId'];
    final String? itemDataStr = params['itemData'];

    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }
    if (itemDataStr == null || itemDataStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemData'});
    }

    // 查找物品所在的仓库
    final existingItem = findGoodsItemById(itemId);
    if (existingItem == null) {
      return jsonEncode({'error': '物品不存在', 'itemId': itemId});
    }

    // 解析更新数据
    final updateData = jsonDecode(itemDataStr) as Map<String, dynamic>;

    // 构建 UseCase 需要的参数
    final useCaseParams = {
      'id': itemId,
      'name': updateData['title'],
      'description': updateData['notes'] ?? updateData['description'],
      'quantity': updateData['quantity'],
      'category': updateData['category'],
      'tags': updateData['tags'],
      'customFields': updateData['customFields'],
      'warehouseId': existingItem.warehouseId,
    };

    final result = await _useCase.updateItem(useCaseParams);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '更新物品失败: ${e.toString()}'});
  }
}

/// 删除物品
Future<String> _jsDeleteGoodsItem(Map<String, dynamic> params) async {
  try {
    // 查找物品所在的仓库
    final String? itemId = params['itemId'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    final existingItem = findGoodsItemById(itemId);
    if (existingItem == null) {
      return jsonEncode({'error': '物品不存在', 'itemId': itemId});
    }

    // 构建 UseCase 需要的参数
    final useCaseParams = {
      'id': itemId,
      'warehouseId': existingItem.warehouseId,
    };

    final result = await _useCase.deleteItem(useCaseParams);

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({
      'success': true,
      'itemId': itemId,
      'warehouseId': existingItem.warehouseId,
    });
  } catch (e) {
    return jsonEncode({'success': false, 'error': e.toString()});
  }
}

/// 添加使用记录
Future<String> _jsAddUsageRecord(Map<String, dynamic> params) async {
  try {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    // 可选参数
    final String? dateStr = params['dateStr'];
    final String? note = params['note'];

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
  try {
    final result = await _useCase.getStats(params);

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode({'error': '获取统计失败: ${e.toString()}'});
  }
}
