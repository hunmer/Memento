import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'database_plugin.dart';

/// 数据库插件的主页小组件注册
class DatabaseHomeWidgets {
  /// 注册所有数据库插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'database_icon',
      pluginId: 'database',
      name: 'database_widgetName'.tr,
      description: 'database_widgetDescription'.tr,
      icon: Icons.storage,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.storage,
        color: Colors.deepPurple,
        name: 'database_name'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'database_overview',
      pluginId: 'database',
      name: 'database_overviewName'.tr,
      description: 'database_overviewDescription'.tr,
      icon: Icons.storage_outlined,
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
      final plugin = PluginManager.instance.getPlugin('database') as DatabasePlugin?;
      if (plugin == null) return [];

      // 同步获取数据库计数（使用 Future.wait 的同步版本）
      int databaseCount = 0;
      plugin.service.getDatabaseCount().then((count) {
        databaseCount = count;
      });
      return [
        StatItemData(
          id: 'total_databases',
          label: 'database_totalDatabases'.tr,
          value: '$databaseCount',
          highlight: databaseCount > 0,
          color: Colors.deepPurple,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const [
            'database_added',
            'database_updated',
            'database_deleted',
            'database_record_added',
            'database_record_updated',
            'database_record_deleted',
          ],
          onEvent: () => setState(() {}),
          child: _buildOverviewContent(context, config),
        );
      },
    );
  }

  /// 构建概览小组件内容（获取最新数据）
  static Widget _buildOverviewContent(BuildContext context, Map<String, dynamic> config) {
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
        pluginId: 'database',
        pluginName: 'database_name'.tr,
        pluginIcon: Icons.storage,
        pluginDefaultColor: Colors.deepPurple,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }
}
