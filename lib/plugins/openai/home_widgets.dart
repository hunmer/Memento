import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/widgets/generic_plugin_widget.dart';
import '../../screens/home_screen/models/plugin_widget_config.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';
import '../../core/plugin_manager.dart';
import 'openai_plugin.dart';
import 'l10n/openai_localizations.dart';

/// OpenAI插件的主页小组件注册
class OpenAIHomeWidgets {
  /// 注册所有OpenAI插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'openai_icon',
      pluginId: 'openai',
      name: 'AI助手',
      description: '快速打开AI助手',
      icon: Icons.smart_toy,
      color: Colors.deepOrange,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.smart_toy,
        color: Colors.deepOrange,
        name: 'AI助手',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'openai_overview',
      pluginId: 'openai',
      name: 'AI助手概览',
      description: '显示智能体统计信息',
      icon: Icons.psychology,
      color: Colors.deepOrange,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats() {
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
          label: 'AI助手数',
          value: '$agentsCount',
          highlight: agentsCount > 0,
          color: Colors.deepOrange,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = OpenAILocalizations.of(context);

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
      final availableItems = _getAvailableStats();

      // 使用通用小组件
      return GenericPluginWidget(
        pluginName: l10n.name,
        pluginIcon: Icons.smart_toy,
        pluginDefaultColor: Colors.deepOrange,
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
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
