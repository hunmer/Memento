import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../openai_plugin.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
    if (plugin == null) return [];

    // 从存储中读取智能体列表
    int agentsCount = 0;
    plugin.storage.read('openai/agents.json').then((data) {
      if (data is Map<String, dynamic>) {
        final agentsList = data['agents'] as List? ?? [];
        agentsCount = agentsList.length;
      }
    });

    return [
      StatItemData(
        id: 'total_agents',
        label: 'openai_totalAgents'.tr,
        value: '$agentsCount',
        highlight: agentsCount > 0,
        color: Colors.deepOrange,
      ),
    ];
  } catch (e) {
    return [];
  }
}
