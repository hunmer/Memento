import 'dart:convert';
import 'package:get/get.dart';
import 'package:Memento/plugins/store/widgets/store_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/widgets/point_settings_view.dart';
import 'package:Memento/plugins/store/screens/store_settings_screen.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/events/point_award_event.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';

// UseCase 架构相关导入
import 'package:shared_models/usecases/store/store_usecase.dart';
import 'package:Memento/plugins/store/repositories/client_store_repository.dart';

/// 物品兑换插件 - UseCase 架构
class StorePlugin extends BasePlugin with JSBridgePlugin {
  static StorePlugin? _instance;
  static StorePlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (_instance == null) {
        throw StateError('StorePlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'store';

  @override
  Color get color => Colors.pinkAccent;

  @override
  IconData get icon => Icons.store;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  StoreController? _controller;
  PointAwardEvent? _pointAwardEvent;
  bool _isInitialized = false;

  /// UseCase 实例（UseCase 架构）
  late final StoreUseCase _useCase;

  /// 获取商店控制器（保留向后兼容）
  StoreController get controller {
    assert(
      _isInitialized,
      'StorePlugin must be initialized before accessing controller',
    );
    return _controller!;
  }

  /// 获取 UseCase 实例
  StoreUseCase get useCase => _useCase;

  /// 默认积分配置
  static const Map<String, dynamic> defaultPointSettings = {
    'point_awards': {
      'activity_added': 3, // 添加活动奖励
      'checkin_completed': 10, // 签到完成奖励
      'task_completed': 20, // 完成任务奖励
      'note_added': 10, // 添加笔记奖励
      'goods_added': 5, // 添加物品奖励
      'onMessageSent': 1, // 发送消息奖励
      'onRecordAdded': 2, // 添加记录奖励
      'onDiaryAdded': 5, // 添加日记奖励
      'bill_added': 10, // 添加账单奖励
    },
  };

  /// 获取事件积分配置
  Map<String, int> get pointAwardSettings =>
      (settings['point_awards'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      );

  @override
  Future<void> initialize() async {
    if (!_isInitialized) {
      await loadSettings(defaultPointSettings);
      _controller = StoreController(this);
      await _controller!.loadFromStorage();

      // 初始化 UseCase（通过 ClientRepository 适配 StoreController）
      final repository = ClientStoreRepository(controller: _controller!);
      _useCase = StoreUseCase(repository);

      // 初始化积分奖励事件处理器
      _pointAwardEvent = PointAwardEvent(this);

      _isInitialized = true;

      // 注册数据选择器
      _registerDataSelectors();

      // 注册 JS API（最后一步）
      await registerJSAPI();
    }
  }

  /// 清理资源
  void dispose() {
    // 清理事件订阅
    _pointAwardEvent?.dispose();
    _pointAwardEvent = null;
  }

  @override
  String? getPluginName(context) {
    return 'store_name'.tr;
  }

  @override
  Widget buildMainView(BuildContext context) {
    return StoreBottomBar(plugin: this);
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
                'store_name'.tr,
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
              // 第一行 - 商品数量和物品数量
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 商品数量
                  Column(
                    children: [
                      Text(
                        'store_productQuantity'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getGoodsCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 物品数量
                  Column(
                    children: [
                      Text(
                        'store_itemQuantity'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getItemsCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 第二行 - 我的积分和七天到期
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 我的积分
                  Column(
                    children: [
                      Text(
                        'store_myPoints'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.currentPoints.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  // 七天到期
                  Column(
                    children: [
                      Text(
                        'store_expiringIn7Days'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        controller.getExpiringItemsCount().toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
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

  @override
  Widget buildSettingsView(BuildContext context) {
    return StoreSettingsScreen(plugin: this);
  }

  /// 获取事件显示名称
  String getEventDisplayName(String eventKey) {
    switch (eventKey) {
      case 'activity_added':
        return '添加活动';
      case 'checkin_completed':
        return '完成签到';
      case 'task_completed':
        return '完成任务';
      case 'note_added':
        return '添加笔记';
      case 'goods_added':
        return '添加物品';
      case 'onMessageSent':
        return '发送消息';
      case 'onRecordAdded':
        return '添加记录';
      case 'onDiaryAdded':
        return '添加日记';
      case 'bill_added':
        return '添加账单';
      default:
        return eventKey;
    }
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 商品相关
      'getProducts': _jsGetProducts,
      'getProduct': _jsGetProduct,
      'createProduct': _jsCreateProduct,
      'updateProduct': _jsUpdateProduct,
      'deleteProduct': _jsDeleteProduct,

      // 兑换相关
      'redeem': _jsRedeem,

      // 积分相关
      'getPoints': _jsGetPoints,
      'addPoints': _jsAddPoints,

      // 历史记录
      'getRedeemHistory': _jsGetRedeemHistory,
      'getPointsHistory': _jsGetPointsHistory,

      // 用户物品
      'getUserItems': _jsGetUserItems,
      'useItem': _jsUseItem,

      // 归档管理
      'archiveProduct': _jsArchiveProduct,
      'restoreProduct': _jsRestoreProduct,
      'getArchivedProducts': _jsGetArchivedProducts,

      // 查找方法
      'findProductBy': _jsFindProductBy,
      'findProductById': _jsFindProductById,
      'findProductByName': _jsFindProductByName,
      'findUserItemBy': _jsFindUserItemBy,
      'findUserItemById': _jsFindUserItemById,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有商品列表（UseCase 版本）
  /// 支持分页参数: offset, count
  Future<String> _jsGetProducts(Map<String, dynamic> params) async {
    try {
      final result = await useCase.getProducts(params);

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      return jsonEncode(result.dataOrNull ?? []);
    } catch (e) {
      return jsonEncode({'error': '获取商品列表失败: $e'});
    }
  }

  /// 获取商品详情（UseCase 版本）
  Future<String> _jsGetProduct(Map<String, dynamic> params) async {
    try {
      // 支持 productId 或 id 参数
      final productId =
          params['productId'] as String? ?? params['id'] as String?;
      if (productId == null || productId.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: productId 或 id'});
      }

      final result = await useCase.getProductById({'id': productId});

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      final product = result.dataOrNull;
      if (product == null) {
        return jsonEncode({'error': '商品不存在'});
      }

      return jsonEncode(product);
    } catch (e) {
      return jsonEncode({'error': '获取商品失败: $e'});
    }
  }

  /// 创建商品（UseCase 版本）
  Future<String> _jsCreateProduct(Map<String, dynamic> params) async {
    try {
      final result = await useCase.createProduct(params);

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
      final result = await useCase.updateProduct(params);

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

      final result = await useCase.deleteProduct({'id': productId});

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

      final result = await useCase.exchangeProduct({'productId': productId});

      if (result.isFailure) {
        return jsonEncode({
          'success': false,
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      return jsonEncode({
        'success': true,
        'message': '兑换成功',
        'currentPoints': controller.currentPoints,
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': '兑换失败: $e'});
    }
  }

  /// 获取当前积分（UseCase 版本）
  Future<String> _jsGetPoints(Map<String, dynamic> params) async {
    try {
      // UseCase 中没有单独的获取积分方法，使用 getPointsInfo
      final result = await useCase.getPointsInfo(params);

      if (result.isFailure) {
        return jsonEncode({
          'error': result.errorOrNull?.message ?? 'Unknown error',
        });
      }

      final pointsInfo = result.dataOrNull;
      return jsonEncode(
        pointsInfo != null
            ? pointsInfo['currentPoints']
            : controller.currentPoints,
      );
    } catch (e) {
      return jsonEncode(controller.currentPoints);
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

      final result = await useCase.addPoints({
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
                : controller.currentPoints,
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
      final result = await useCase.getUserItems(params);

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
      final result = await useCase.searchPointsLogs(params);

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
      final result = await useCase.getUserItems(params);

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

      final result = await useCase.useItem({'itemId': itemId});

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

      final result = await useCase.archiveProduct({'id': productId});

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

      final result = await useCase.restoreProduct({'id': productId});

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
      final result = await useCase.getArchivedProducts(params);

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
        final result = await useCase.searchProducts({
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
        final result = await useCase.getProductById({'id': value.toString()});

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

      final result = await useCase.getProductById({'id': id});

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
      final result = await useCase.searchProducts({
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
        final result = await useCase.searchUserItems({
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
        final result = await useCase.getUserItemById({'id': value.toString()});

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

      final result = await useCase.getUserItemById({'id': id});

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

  // ==================== 数据选择器注册 ====================

  /// 注册数据选择器
  void _registerDataSelectors() {
    final selectorService = pluginDataSelectorService;

    // 注册商品选择器
    selectorService.registerSelector(
      SelectorDefinition(
        id: 'store.product',
        pluginId: id,
        name: '选择商品',
        icon: icon,
        color: color,
        searchable: true,
        selectionMode: SelectionMode.single,
        steps: [
          SelectorStep(
            id: 'product',
            title: '选择商品',
            viewType: SelectorViewType.grid,
            isFinalStep: true,
            dataLoader: (_) async {
              return controller.products.map((product) {
                // 构建副标题：价格 + 库存
                final subtitle = '${product.price} 积分 · 库存: ${product.stock}';

                return SelectableItem(
                  id: product.id,
                  title: product.name,
                  subtitle: subtitle,
                  icon: Icons.shopping_bag,
                  rawData: product,
                );
              }).toList();
            },
            searchFilter: (items, query) {
              if (query.isEmpty) return items;
              final lowerQuery = query.toLowerCase();
              return items.where((item) {
                final matchesTitle = item.title.toLowerCase().contains(
                  lowerQuery,
                );
                final product = item.rawData as Product;
                final matchesDescription = product.description
                    .toLowerCase()
                    .contains(lowerQuery);
                return matchesTitle || matchesDescription;
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
