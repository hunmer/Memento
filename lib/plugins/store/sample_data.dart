/// 商店插件示例数据
/// 当 JSON 文件不存在时，使用此文件中的数据作为默认值
library;

import 'models/product.dart';
import 'models/user_item.dart';
import 'models/points_log.dart';
import 'models/used_item.dart';

/// 获取默认商店商品数据
List<Product> getDefaultProducts() {
  final now = DateTime.now();
  final oneYearFromNow = DateTime(now.year + 1, now.month, now.day);

  return [
    Product(
      id: '1705123456789',
      name: '免作业卡',
      description: '可免除一次作业任务',
      stock: 10,
      price: 50,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 30,
    ),
    Product(
      id: '1705123456790',
      name: '专注力提升剂',
      description: '提高30分钟专注力，学习效率倍增',
      stock: 20,
      price: 80,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456791',
      name: '知识胶囊',
      description: '快速掌握一个知识点的精华内容',
      stock: 15,
      price: 120,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 7,
    ),
  ];
}

/// 获取默认用户物品数据
List<UserItem> getDefaultUserItems() {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  final threeDaysAgo = now.subtract(const Duration(days: 3));
  final fiveDaysAgo = now.subtract(const Duration(days: 5));

  // 获取示例商品数据
  final products = getDefaultProducts();

  return [
    // 已过期但仍保留的物品（用于演示）
    UserItem(
      id: '1705130000001',
      productId: products[0].id,
      remaining: 0,
      expireDate: yesterday,
      purchaseDate: fiveDaysAgo,
      purchasePrice: 50,
      productSnapshot: products[0].toJson(),
    ),

    // 即将过期的物品
    UserItem(
      id: '1705130000002',
      productId: products[1].id,
      remaining: 1,
      expireDate: now.add(const Duration(days: 2)),
      purchaseDate: now.subtract(const Duration(days: 5)),
      purchasePrice: 80,
      productSnapshot: products[1].toJson(),
    ),

    // 正常使用中的物品
    UserItem(
      id: '1705130000003',
      productId: products[2].id,
      remaining: 1,
      expireDate: now.add(const Duration(days: 30)),
      purchaseDate: threeDaysAgo,
      purchasePrice: 120,
      productSnapshot: products[2].toJson(),
    ),
  ];
}

/// 获取示例积分记录
List<PointsLog> getDefaultPointsLogs() {
  final now = DateTime.now();

  return [
    PointsLog(
      id: '1705140000001',
      type: '获得',
      value: 10,
      reason: '完成签到奖励',
      timestamp: now.subtract(const Duration(hours: 2)),
    ),
    PointsLog(
      id: '1705140000002',
      type: '获得',
      value: 3,
      reason: '添加活动记录',
      timestamp: now.subtract(const Duration(hours: 3)),
    ),
    PointsLog(
      id: '1705140000003',
      type: '获得',
      value: 20,
      reason: '完成任务奖励',
      timestamp: now.subtract(const Duration(hours: 5)),
    ),
    PointsLog(
      id: '1705140000004',
      type: '消耗',
      value: 50,
      reason: '兑换商品: 免作业卡',
      timestamp: now.subtract(const Duration(days: 1)),
    ),
    PointsLog(
      id: '1705140000005',
      type: '获得',
      value: 5,
      reason: '添加日记奖励',
      timestamp: now.subtract(const Duration(days: 1, hours: 6)),
    ),
    PointsLog(
      id: '1705140000006',
      type: '获得',
      value: 10,
      reason: '添加笔记奖励',
      timestamp: now.subtract(const Duration(days: 2)),
    ),
    PointsLog(
      id: '1705140000007',
      type: '获得',
      value: 1,
      reason: '发送消息奖励',
      timestamp: now.subtract(const Duration(days: 2, hours: 3)),
    ),
    PointsLog(
      id: '1705140000008',
      type: '获得',
      value: 10,
      reason: '添加账单奖励',
      timestamp: now.subtract(const Duration(days: 3)),
    ),
    PointsLog(
      id: '1705140000009',
      type: '获得',
      value: 5,
      reason: '添加物品奖励',
      timestamp: now.subtract(const Duration(days: 4)),
    ),
  ];
}

/// 获取示例已使用物品记录
List<UsedItem> getDefaultUsedItems() {
  final now = DateTime.now();
  final products = getDefaultProducts();

  return [
    UsedItem(
      id: '1705150000001',
      productId: products[0].id,
      useDate: now.subtract(const Duration(days: 1)),
      productSnapshot: products[0].toJson(),
    ),
    UsedItem(
      id: '1705150000002',
      productId: products[1].id,
      useDate: now.subtract(const Duration(days: 2)),
      productSnapshot: products[1].toJson(),
    ),
  ];
}

/// 获取默认积分余额
int getDefaultPointsBalance() {
  return 47; // 根据积分记录计算得出
}

/// 初始化默认数据的完整结构
class StoreDefaultData {
  /// 获取包含所有默认数据的Map
  static Map<String, dynamic> getAllData() {
    return {
      'products': {
        'products': getDefaultProducts().map((p) => p.toJson()).toList(),
      },
      'archived_products': {'products': []},
      'points': {
        'value': getDefaultPointsBalance(),
        'logs': getDefaultPointsLogs().map((log) => log.toJson()).toList(),
      },
      'user_items': {
        'items': getDefaultUserItems().map((item) => item.toJson()).toList(),
      },
      'used_items': {
        'items': getDefaultUsedItems().map((item) => item.toJson()).toList(),
      },
    };
  }
}
