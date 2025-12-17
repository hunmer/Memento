import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'scripts_center_plugin.dart';
import 'package:get/get.dart';

/// 脚本中心插件的主页小组件注册
class ScriptsCenterHomeWidgets {
  /// 注册所有脚本中心插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'scripts_center_icon',
      pluginId: 'scripts_center',
      name: 'scripts_center_widgetName'.tr,
      description: 'scripts_center_widgetDescription'.tr,
      icon: Icons.code,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.code,
        color: Colors.deepPurple,
        name: 'scripts_center_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'scripts_center_overview',
      pluginId: 'scripts_center',
      name: 'scripts_center_overviewName'.tr,
      description: 'scripts_center_overviewDescription'.tr,
      icon: Icons.code_outlined,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
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

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: 'scripts_center_name'.tr,
        pluginIcon: Icons.code,
        pluginDefaultColor: Colors.deepPurple,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
