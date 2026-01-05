import 'dart:convert';
import 'package:get/get.dart';
import 'package:Memento/plugins/store/widgets/store_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/screens/store_settings_screen.dart';
import 'package:Memento/plugins/store/events/point_award_event.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';

// UseCase 架构相关导入
import 'package:shared_models/usecases/store/store_usecase.dart';
import 'package:Memento/plugins/store/repositories/client_store_repository.dart';

// HTTP 服务器导入
import 'package:Memento/plugins/webview/services/local_http_server.dart';

part 'store_js_api.dart';
part 'store_data_selectors.dart';

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

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 商品管理
      'getProducts': _jsGetProducts,
      'getProduct': _jsGetProduct,
      'createProduct': _jsCreateProduct,
      'updateProduct': _jsUpdateProduct,
      'deleteProduct': _jsDeleteProduct,
      'archiveProduct': _jsArchiveProduct,
      'restoreProduct': _jsRestoreProduct,
      'getArchivedProducts': _jsGetArchivedProducts,

      // 商品查找
      'findProductBy': _jsFindProductBy,
      'findProductById': _jsFindProductById,
      'findProductByName': _jsFindProductByName,

      // 用户物品管理
      'getUserItems': _jsGetUserItems,
      'useItem': _jsUseItem,
      'findUserItemBy': _jsFindUserItemBy,
      'findUserItemById': _jsFindUserItemById,

      // 积分管理
      'getPoints': _jsGetPoints,
      'addPoints': _jsAddPoints,
      'getPointsHistory': _jsGetPointsHistory,

      // 兑换
      'redeem': _jsRedeem,
      'getRedeemHistory': _jsGetRedeemHistory,
    };
  }

  /// 默认积分配置
  static const Map<String, dynamic> defaultPointSettings = {
    'point_awards': {
      'activity_added': 3, // 添加活动奖励
      'checkin_completed': 10, // 签到完成奖励
      'task_completed': 20, // 完成任务奖励
      'note_added': 10, // 添加笔记奖励
      'goods_added': 5, // 添加物品奖励
      'chat_message_sent': 1, // 发送消息奖励
      'onRecordAdded': 2, // 添加记录奖励
      'diary_entry_created': 5, // 添加日记奖励
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
}
