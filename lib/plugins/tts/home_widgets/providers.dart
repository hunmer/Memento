/// TTS 插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../tts_plugin.dart';

/// 获取可用的统计项
List<StatItemData> getTTSAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('tts') as TTSPlugin?;
    if (plugin == null) return [];

    final manager = plugin.managerService;
    int serviceCount = 0;
    int enabledCount = 0;

    // 同步获取服务数量
    manager.getAllServices().then((services) {
      serviceCount = services.length;
      enabledCount = services.where((s) => s.isEnabled).length;
    });

    final queueCount = plugin.queue.length;

    return [
      StatItemData(
        id: 'total_services',
        label: 'tts_servicesList'.tr,
        value: '$serviceCount',
        highlight: serviceCount > 0,
        color: Colors.purple,
      ),
      StatItemData(
        id: 'enabled_services',
        label: 'tts_enabled'.tr,
        value: '$enabledCount',
        highlight: enabledCount > 0,
        color: Colors.green,
      ),
      StatItemData(
        id: 'queue_count',
        label: 'tts_queue'.tr,
        value: '$queueCount',
        highlight: queueCount > 0,
        color: Colors.orange,
      ),
    ];
  } catch (e) {
    return [];
  }
}
