import 'package:flutter/material.dart';
import '../../main.dart';

class PluginOrderManager {
  // 存储插件的顺序
  List<String> pluginOrder = [];

  // 加载插件顺序
  Future<void> loadPluginOrder() async {
    try {
      final orderConfig = await globalConfigManager.getPluginConfig(
        'plugin_order',
      );
      if (orderConfig != null && orderConfig['order'] != null) {
        final List<dynamic> order = orderConfig['order'] as List<dynamic>;
        pluginOrder = order.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error loading plugin order: $e');
    }
  }

  // 保存插件顺序
  Future<void> savePluginOrder() async {
    try {
      await globalConfigManager.savePluginConfig('plugin_order', {
        'order': pluginOrder,
      });
    } catch (e) {
      debugPrint('Error saving plugin order: $e');
    }
  }

  // 更新插件顺序
  void updatePluginOrder(int oldIndex, int newIndex) {
    final List<String> currentOrder = List.from(pluginOrder);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = currentOrder[oldIndex];
    currentOrder.removeAt(oldIndex);
    currentOrder.insert(newIndex, item);
    pluginOrder = currentOrder;
  }
}