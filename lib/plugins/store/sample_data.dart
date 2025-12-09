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
    // 学习用品类
    Product(
      id: '1705123456789',
      name: '免作业卡',
      description: '可免除一次作业任务',
      image: 'assets/store/homework_card.png',
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
      image: 'assets/store/focus_potion.png',
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
      image: 'assets/store/knowledge_pill.png',
      stock: 15,
      price: 120,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 7,
    ),
    Product(
      id: '1705123456792',
      name: '记忆面包',
      description: '吃完后对刚才看过的内容过目不忘',
      image: 'assets/store/memory_bread.png',
      stock: 8,
      price: 100,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456793',
      name: '考试必过符',
      description: '在考试中如有神助，难题迎刃而解',
      image: 'assets/store/exam_charm.png',
      stock: 5,
      price: 200,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 3,
    ),

    // 生活便利类
    Product(
      id: '1705123456794',
      name: '时间延长券',
      description: '一天额外增加2小时可自由支配时间',
      image: 'assets/store/time_voucher.png',
      stock: 3,
      price: 300,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456795',
      name: '体力恢复包',
      description: '瞬间消除疲劳感，焕发活力',
      image: 'assets/store/energy_pack.png',
      stock: 25,
      price: 60,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456796',
      name: '幸运硬币',
      description: '一天的好运气围绕着你',
      image: 'assets/store/lucky_coin.png',
      stock: 12,
      price: 150,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456797',
      name: '天气预报伞',
      description: '拥有它，你带的伞永远用不上',
      image: 'assets/store/weather_umbrella.png',
      stock: 10,
      price: 90,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 30,
    ),
    Product(
      id: '1705123456798',
      name: '万能充电器',
      description: '任何电子设备都能充的电',
      image: 'assets/store/charger.png',
      stock: 6,
      price: 180,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 90,
    ),

    // 健康养生类
    Product(
      id: '1705123456799',
      name: '睡眠质量提升器',
      description: '让你拥有婴儿般甜美的睡眠',
      image: 'assets/store/sleep_device.png',
      stock: 15,
      price: 110,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 30,
    ),
    Product(
      id: '1705123456800',
      name: '健身达人药剂',
      description: '一次使用，健身效果提升三倍',
      image: 'assets/store/fitness_potion.png',
      stock: 8,
      price: 160,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 7,
    ),
    Product(
      id: '1705123456801',
      name: '健康体检套餐',
      description: '全面检查身体隐患，预防疾病',
      image: 'assets/store/health_check.png',
      stock: 4,
      price: 250,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),

    // 娱乐休闲类
    Product(
      id: '1705123456802',
      name: '快乐源泉饮料',
      description: '喝完心情瞬间好起来',
      image: 'assets/store/happy_drink.png',
      stock: 30,
      price: 40,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456803',
      name: '灵感爆发器',
      description: '创作时灵感如泉涌，作品质量大幅提升',
      image: 'assets/store/inspiration_device.png',
      stock: 10,
      price: 130,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 1,
    ),
    Product(
      id: '1705123456804',
      name: '人际关系润滑剂',
      description: '改善你的人际关系，让沟通更顺畅',
      image: 'assets/store/relationship_drug.png',
      stock: 7,
      price: 170,
      exchangeStart: now,
      exchangeEnd: oneYearFromNow,
      useDuration: 14,
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
      productId: products[0].id, // 免作业卡
      remaining: 0,
      expireDate: yesterday,
      purchaseDate: fiveDaysAgo,
      purchasePrice: 50,
      productSnapshot: products[0].toJson(),
    ),

    // 即将过期的物品
    UserItem(
      id: '1705130000002',
      productId: products[6].id, // 体力恢复包
      remaining: 1,
      expireDate: now.add(const Duration(days: 2)),
      purchaseDate: now.subtract(const Duration(days: 5)),
      purchasePrice: 60,
      productSnapshot: products[6].toJson(),
    ),

    // 正常使用中的物品
    UserItem(
      id: '1705130000003',
      productId: products[13].id, // 快乐源泉饮料
      remaining: 1,
      expireDate: now.add(const Duration(days: 30)),
      purchaseDate: threeDaysAgo,
      purchasePrice: 40,
      productSnapshot: products[13].toJson(),
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
      productId: products[13].id,
      useDate: now.subtract(const Duration(days: 2)),
      productSnapshot: products[13].toJson(),
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
      'archived_products': {
        'products': [],
      },
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
