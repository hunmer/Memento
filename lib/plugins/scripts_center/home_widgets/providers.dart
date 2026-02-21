/// 脚本中心主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import '../scripts_center_plugin.dart';
import '../models/script_info.dart';

/// 从选择器数据数组中提取小组件需要的数据
Map<String, dynamic> extractScriptData(List<dynamic> dataArray) {
  // dataArray 是选择器返回的选中项数组（单选模式只有一个元素）
  if (dataArray.isEmpty) {
    debugPrint('[ScriptSelector] dataArray 为空');
    return {};
  }

  final rawData = dataArray[0];
  debugPrint('[ScriptSelector] rawData 类型: ${rawData.runtimeType}');

  // 处理 Map 类型的数据
  if (rawData is Map<String, dynamic>) {
    return rawData;
  }

  // 如果是 SelectableItem，从 rawData 字段提取
  if (rawData is Map && rawData.containsKey('rawData')) {
    final rawDataMap = rawData['rawData'];
    if (rawDataMap is Map<String, dynamic>) {
      return rawDataMap;
    }
  }

  debugPrint('[ScriptSelector] 无法提取数据: $rawData');
  return {};
}

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('scripts_center') as ScriptsCenterPlugin?;
    if (plugin == null) return [];

    final manager = plugin.scriptManager;
    final scripts = manager.scripts;
    final enabledCount = scripts.where((s) => s.enabled).length;
    final triggerCount = scripts.fold<int>(0, (sum, s) => sum + s.triggers.length);

    return [
      StatItemData(
        id: 'total_scripts',
        label: 'scripts_center_all'.tr,
        value: '${scripts.length}',
        highlight: scripts.isNotEmpty,
        color: Colors.deepPurple,
      ),
      StatItemData(
        id: 'enabled_scripts',
        label: 'scripts_center_enableScript'.tr,
        value: '$enabledCount',
        highlight: enabledCount > 0,
        color: Colors.green,
      ),
      StatItemData(
        id: 'total_triggers',
        label: 'scripts_center_addTrigger'.tr,
        value: '$triggerCount',
        highlight: triggerCount > 0,
        color: Colors.orange,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 从 scriptManager 加载最新脚本数据
Future<ScriptInfo?> loadLatestScript(String scriptId) async {
  try {
    final plugin = PluginManager.instance.getPlugin('scripts_center') as ScriptsCenterPlugin?;
    if (plugin == null || scriptId.isEmpty) return null;

    // 加载所有脚本并查找
    final scripts = await plugin.scriptManager.loadAllScripts();
    return scripts.firstWhere(
      (s) => s.id == scriptId,
      orElse: () => plugin.scriptManager.getScriptById(scriptId)!,
    );
  } catch (e) {
    debugPrint('加载脚本数据失败: $e');
    return null;
  }
}
