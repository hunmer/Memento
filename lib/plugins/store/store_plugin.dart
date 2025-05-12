
import 'package:Memento/plugins/store/controllers/store_controller.dart';
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
    await pluginManager.registerPlugin(this);
  }

  StoreController? _controller;

  @override
  Future<void> initialize() async {
    _controller = StoreController(this);
    await _controller!.loadFromStorage();
  }

  @override
  Widget buildMainView(BuildContext context) {
    _controller ??= StoreController();
    return StoreView(
      controller: _controller!,
      onDataChanged: (products, points) async {
        // 当数据变化时保存到本地
        await _controller!.saveToStorage();
      },
    );
  }
}
