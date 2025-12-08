import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'contact_plugin.dart';
import 'l10n/contact_localizations.dart';

/// 联系人插件的主页小组件注册
class ContactHomeWidgets {
  /// 注册所有联系人插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'contact_icon',
      pluginId: 'contact',
      name: '联系人',
      description: '快速打开联系人管理',
      icon: Icons.contacts,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.contacts,
        color: Colors.deepPurple,
        name: '联系人',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'contact_overview',
      pluginId: 'contact',
      name: '联系人概览',
      description: '显示联系人总数和最近联系统计',
      icon: Icons.people,
      color: Colors.deepPurple,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  /// 返回联系人插件支持的所有统计项类型定义
  /// 实际数据值由 _buildOverviewWidget 在 FutureBuilder 中异步获取并更新
  static List<StatItemData> _getAvailableStats() {
    return [
      StatItemData(
        id: 'total_contacts',
        label: '联系人总数',
        value: '0', // 占位符，实际值由 _buildOverviewWidget 异步获取
        highlight: false,
      ),
      StatItemData(
        id: 'recent_contacts',
        label: '最近联系',
        value: '0', // 占位符，实际值由 _buildOverviewWidget 异步获取
        highlight: false,
        color: Colors.green,
      ),
    ];
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
    try {
      final l10n = ContactLocalizations.of(context);

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

      // 异步加载实际的统计数据
      return FutureBuilder<List<StatItemData>>(
        future: _loadContactStats(),
        builder: (context, snapshot) {
          final availableItems = snapshot.data ?? _getAvailableStats();

          // 使用通用小组件
          return GenericPluginWidget(
            pluginName: l10n.name,
            pluginIcon: Icons.contacts,
            pluginDefaultColor: Colors.deepPurple,
            availableItems: availableItems,
            config: widgetConfig,
          );
        },
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 异步加载联系人统计数据
  static Future<List<StatItemData>> _loadContactStats() async {
    try {
      final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
      if (plugin == null) return _getAvailableStats();

      final controller = plugin.controller;
      final contacts = await controller.getAllContacts();
      final recentCount = await controller.getRecentlyContactedCount();

      return [
        StatItemData(
          id: 'total_contacts',
          label: '联系人总数',
          value: '${contacts.length}',
          highlight: false,
        ),
        StatItemData(
          id: 'recent_contacts',
          label: '最近联系',
          value: '$recentCount',
          highlight: recentCount > 0,
          color: Colors.green,
        ),
      ];
    } catch (e) {
      return _getAvailableStats();
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
