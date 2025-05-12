
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/widgets/store_view.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';

/// 物品兑换插件
class StorePlugin extends BasePlugin {
  @override
  String get id => 'store_plugin';

  @override
  String get name => '物品兑换';

  @override
  String get version => '1.0.0';

  @override
  String get description => '提供物品兑换和管理功能';

  @override
  String get author => '系统团队';

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件到应用
  }

  @override
  Future<void> initialize() async {
    // 初始化测试数据
    final controller = StoreController();
    
    // 添加示例商品
    controller.addProduct(Product(
      id: '1',
      name: '精美笔记本',
      description: '高品质纸质笔记本',
      image: 'https://example.com/notebook.jpg',
      stock: 10,
      price: 500,
      exchangeStart: DateTime.now().subtract(const Duration(days: 1)),
      exchangeEnd: DateTime.now().add(const Duration(days: 30)),
      useDuration: 90,
    ));

    controller.addProduct(Product(
      id: '2',
      name: '马克杯',
      description: '公司定制马克杯',
      image: 'https://example.com/mug.jpg',
      stock: 5,
      price: 800,
      exchangeStart: DateTime.now().subtract(const Duration(days: 1)),
      exchangeEnd: DateTime.now().add(const Duration(days: 15)),
      useDuration: 180,
    ));

    // 添加初始积分
    controller.addPoints(2000, '初始积分');
  }

  @override
  Widget buildMainView(BuildContext context) {
    return StoreView(
      controller: StoreController(),
    );
  }
}
