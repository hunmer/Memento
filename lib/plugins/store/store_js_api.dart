part of 'store_plugin.dart';

// ==================== JS API 实现 ====================

/// 获取所有商品列表（UseCase 版本）
/// 支持分页参数: offset, count
/// 支持 get_http_image 参数：是否将图片路径转换为 HTTP URL
Future<String> _jsGetProducts(Map<String, dynamic> params) async {
  try {
    // 提取图片转换参数
    final getHttpImage = params['get_http_image'] == true;
    params.remove('get_http_image');

    final result = await StorePlugin.instance.useCase.getProducts(params);

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message ?? 'Unknown error',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    var products = result.dataOrNull ?? [];

    // 处理图片路径转换（使用简化方法）
    if (getHttpImage) {
      products = await LocalHttpServer.convertImagesWithAutoConfig(
        items: products,
        pluginId: StorePlugin.instance.id,
        imageKey: 'image',
        storageManager: StorePlugin.instance.storage,
      );
    }

    return jsonEncode({
      'success': true,
      'data': products,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    debugPrint('[StorePlugin] ✗ 获取商品列表失败: $e');
    return jsonEncode({
      'success': false,
      'error': '获取商品列表失败: $e',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

/// 获取商品详情（UseCase 版本）
/// 支持 get_http_image 参数：是否将图片路径转换为 HTTP URL
Future<String> _jsGetProduct(Map<String, dynamic> params) async {
  try {
    // 提取图片转换参数
    final getHttpImage = params['get_http_image'] == true;
    params.remove('get_http_image');

    // 支持 productId 或 id 参数
    final productId =
        params['productId'] as String? ?? params['id'] as String?;
    if (productId == null || productId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: productId 或 id'});
    }

    final result = await StorePlugin.instance.useCase.getProductById({'id': productId});

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    var product = result.dataOrNull;
    if (product == null) {
      return jsonEncode({'error': '商品不存在'});
    }

    // 处理图片路径转换（使用简化方法）
    if (getHttpImage) {
      final convertedList = await LocalHttpServer.convertImagesWithAutoConfig(
        items: [product],
        pluginId: StorePlugin.instance.id,
        imageKey: 'image',
        storageManager: StorePlugin.instance.storage,
      );
      product = convertedList.isNotEmpty ? convertedList.first : product;
    }

    return jsonEncode(product);
  } catch (e) {
    return jsonEncode({'error': '获取商品失败: $e'});
  }
}

/// 创建商品（UseCase 版本）
Future<String> _jsCreateProduct(Map<String, dynamic> params) async {
  try {
    final result = await StorePlugin.instance.useCase.createProduct(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull ?? {});
  } catch (e) {
    return jsonEncode({'error': '创建商品失败: $e'});
  }
}

/// 更新商品（UseCase 版本）
Future<String> _jsUpdateProduct(Map<String, dynamic> params) async {
  try {
    final result = await StorePlugin.instance.useCase.updateProduct(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull ?? {});
  } catch (e) {
    return jsonEncode({'error': '更新商品失败: $e'});
  }
}

/// 删除商品（归档，UseCase 版本）
Future<String> _jsDeleteProduct(Map<String, dynamic> params) async {
  try {
    final String? productId = params['productId'] ?? params['id'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': '缺少必需参数: productId 或 id',
      });
    }

    final result = await StorePlugin.instance.useCase.deleteProduct({'id': productId});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode({'success': true, 'productId': productId});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '删除商品失败: $e'});
  }
}

/// 兑换商品（UseCase 版本）
Future<String> _jsRedeem(Map<String, dynamic> params) async {
  try {
    final String? productId = params['productId'] ?? params['id'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: productId 或 id'});
    }

    final result = await StorePlugin.instance.useCase.exchangeProduct({'productId': productId});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode({
      'success': true,
      'message': '兑换成功',
      'currentPoints': StorePlugin.instance.controller.currentPoints,
    });
  } catch (e) {
    return jsonEncode({'success': false, 'error': '兑换失败: $e'});
  }
}

/// 获取当前积分（UseCase 版本）
Future<String> _jsGetPoints(Map<String, dynamic> params) async {
  try {
    // UseCase 中没有单独的获取积分方法，使用 getPointsInfo
    final result = await StorePlugin.instance.useCase.getPointsInfo(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    final pointsInfo = result.dataOrNull;
    return jsonEncode(
      pointsInfo != null
          ? pointsInfo['currentPoints']
          : StorePlugin.instance.controller.currentPoints,
    );
  } catch (e) {
    return jsonEncode(StorePlugin.instance.controller.currentPoints);
  }
}

/// 添加积分（UseCase 版本）
Future<String> _jsAddPoints(Map<String, dynamic> params) async {
  try {
    final int? points = params['points'] ?? params['value'];
    if (points == null) {
      return jsonEncode({'error': '缺少必需参数: points 或 value'});
    }

    final String? reason = params['reason'];
    if (reason == null || reason.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: reason'});
    }

    final result = await StorePlugin.instance.useCase.addPoints({
      'value': points,
      'reason': reason,
    });

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    final pointsInfo = result.dataOrNull;
    return jsonEncode({
      'success': true,
      'currentPoints':
          pointsInfo != null
              ? pointsInfo['currentPoints']
              : StorePlugin.instance.controller.currentPoints,
      'message': '积分已${points > 0 ? "增加" : "减少"}: $points',
    });
  } catch (e) {
    return jsonEncode({'error': '添加积分失败: $e'});
  }
}

/// 获取兑换历史（用户物品，UseCase 版本）
/// 支持分页参数: offset, count
Future<String> _jsGetRedeemHistory(Map<String, dynamic> params) async {
  try {
    final result = await StorePlugin.instance.useCase.getUserItems(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull ?? []);
  } catch (e) {
    return jsonEncode({'error': '获取兑换历史失败: $e'});
  }
}

/// 获取积分历史（UseCase 版本）
/// 支持分页参数: offset, count
Future<String> _jsGetPointsHistory(Map<String, dynamic> params) async {
  try {
    final result = await StorePlugin.instance.useCase.searchPointsLogs(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull ?? []);
  } catch (e) {
    return jsonEncode({'error': '获取积分历史失败: $e'});
  }
}

/// 获取用户物品（UseCase 版本）
/// 支持分页参数: offset, count
Future<String> _jsGetUserItems(Map<String, dynamic> params) async {
  try {
    final result = await StorePlugin.instance.useCase.getUserItems(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull ?? []);
  } catch (e) {
    return jsonEncode({'error': '获取用户物品失败: $e'});
  }
}

/// 使用物品（UseCase 版本）
Future<String> _jsUseItem(Map<String, dynamic> params) async {
  try {
    final String? itemId = params['itemId'] ?? params['id'];
    if (itemId == null || itemId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: itemId 或 id'});
    }

    final result = await StorePlugin.instance.useCase.useItem({'itemId': itemId});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode({'success': true, 'message': '使用成功'});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '使用物品失败: $e'});
  }
}

/// 归档商品（UseCase 版本）
Future<String> _jsArchiveProduct(Map<String, dynamic> params) async {
  try {
    final String? productId = params['productId'] ?? params['id'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': '缺少必需参数: productId 或 id',
      });
    }

    final result = await StorePlugin.instance.useCase.archiveProduct({'id': productId});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode({'success': true, 'productId': productId});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '归档商品失败: $e'});
  }
}

/// 恢复归档商品（UseCase 版本）
Future<String> _jsRestoreProduct(Map<String, dynamic> params) async {
  try {
    final String? productId = params['productId'] ?? params['id'];
    if (productId == null || productId.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': '缺少必需参数: productId 或 id',
      });
    }

    final result = await StorePlugin.instance.useCase.restoreProduct({'id': productId});

    if (result.isFailure) {
      return jsonEncode({
        'success': false,
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode({'success': true, 'productId': productId});
  } catch (e) {
    return jsonEncode({'success': false, 'error': '恢复商品失败: $e'});
  }
}

/// 获取归档商品列表（UseCase 版本）
/// 支持分页参数: offset, count
Future<String> _jsGetArchivedProducts(Map<String, dynamic> params) async {
  try {
    final result = await StorePlugin.instance.useCase.getArchivedProducts(params);

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull ?? []);
  } catch (e) {
    return jsonEncode({'error': '获取归档商品失败: $e'});
  }
}

// ==================== 查找方法（UseCase 版本） ====================

/// 通用商品查找（使用 UseCase 搜索功能）
Future<String> _jsFindProductBy(Map<String, dynamic> params) async {
  try {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    // 根据字段类型选择搜索方法
    if (field.toLowerCase() == 'name') {
      final result = await StorePlugin.instance.useCase.searchProducts({
        'nameKeyword': value.toString(),
        'includeArchived': false,
        if (!findAll) 'offset': 0,
        if (!findAll) 'count': 1,
      });

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      final products = result.dataOrNull as List? ?? [];
      if (products.isEmpty) {
        return jsonEncode(findAll ? [] : null);
      }

      return jsonEncode(findAll ? products : products.first);
    } else if (field.toLowerCase() == 'id') {
      // ID 精确查找
      final result = await StorePlugin.instance.useCase.getProductById({'id': value.toString()});

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      final product = result.dataOrNull;
      return jsonEncode(
        findAll ? (product != null ? [product] : []) : product,
      );
    }

    return jsonEncode(findAll ? [] : null);
  } catch (e) {
    return jsonEncode({'error': '查找商品失败: $e'});
  }
}

/// 根据ID查找商品（UseCase 版本）
Future<String> _jsFindProductById(Map<String, dynamic> params) async {
  try {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final result = await StorePlugin.instance.useCase.getProductById({'id': id});

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode(null);
  }
}

/// 根据名称查找商品（UseCase 版本）
Future<String> _jsFindProductByName(Map<String, dynamic> params) async {
  try {
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    // 模糊搜索和精确搜索都使用 nameKeyword，UseCase 内部处理模糊匹配
    final result = await StorePlugin.instance.useCase.searchProducts({
      'nameKeyword': name,
      'includeArchived': false,
      if (!findAll) 'offset': 0,
      if (!findAll) 'count': 1,
    });

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    final products = result.dataOrNull as List? ?? [];
    if (products.isEmpty) {
      return jsonEncode(findAll ? [] : null);
    }

    // 如果不是查找全部且需要精确匹配，检查第一个结果是否精确匹配
    if (!findAll && !fuzzy) {
      final firstProduct = products.first;
      if (firstProduct['name'] != name) {
        return jsonEncode(null);
      }
    }

    return jsonEncode(findAll ? products : products.first);
  } catch (e) {
    return jsonEncode({'error': '查找商品失败: $e'});
  }
}

/// 通用用户物品查找（使用 UseCase 搜索功能）
Future<String> _jsFindUserItemBy(Map<String, dynamic> params) async {
  try {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    if (field.toLowerCase() == 'productid') {
      final result = await StorePlugin.instance.useCase.searchUserItems({
        'productId': value.toString(),
        'includeExpired': true,
        if (!findAll) 'offset': 0,
        if (!findAll) 'count': 1,
      });

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      final items = result.dataOrNull as List? ?? [];
      if (items.isEmpty) {
        return jsonEncode(findAll ? [] : null);
      }

      return jsonEncode(findAll ? items : items.first);
    } else if (field.toLowerCase() == 'id') {
      // ID 精确查找
      final result = await StorePlugin.instance.useCase.getUserItemById({'id': value.toString()});

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      final item = result.dataOrNull;
      return jsonEncode(findAll ? (item != null ? [item] : []) : item);
    }

    return jsonEncode(findAll ? [] : null);
  } catch (e) {
    return jsonEncode({'error': '查找用户物品失败: $e'});
  }
}

/// 根据ID查找用户物品（UseCase 版本）
Future<String> _jsFindUserItemById(Map<String, dynamic> params) async {
  try {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final result = await StorePlugin.instance.useCase.getUserItemById({'id': id});

    if (result.isFailure) {
      return jsonEncode({
        'error': result.errorOrNull?.message ?? 'Unknown error',
      });
    }

    return jsonEncode(result.dataOrNull);
  } catch (e) {
    return jsonEncode(null);
  }
}
