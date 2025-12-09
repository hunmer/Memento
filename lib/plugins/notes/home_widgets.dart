import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'notes_plugin.dart';

const Color _notesColor = Color.fromARGB(255, 61, 204, 185);

/// 笔记插件的主页小组件注册
class NotesHomeWidgets {
  /// 注册所有笔记插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(HomeWidget(
      id: 'notes_icon',
      pluginId: 'notes',
      name: '笔记',
      description: '快速打开笔记',
      icon: Icons.note_alt_outlined,
      color: _notesColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '记录',
      builder: (context, config) => const GenericIconWidget(
        icon: Icons.note_alt_outlined,
        color: _notesColor,
        name: '笔记',
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'notes_overview',
      pluginId: 'notes',
      name: '笔记概览',
      description: '显示总笔记数和近期笔记数',
      icon: Icons.notes,
      color: _notesColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '记录',
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (plugin == null) return [];

      final totalNotes = plugin.getTotalNotesCount();
      final recentNotes = plugin.getRecentNotesCount();

      return [
        StatItemData(
          id: 'total_notes',
          label: '总笔记数',
          value: '$totalNotes',
          highlight: false,
        ),
        StatItemData(
          id: 'recent_notes',
          label: '最近笔记',
          value: '$recentNotes',
          highlight: recentNotes > 0,
          color: _notesColor,
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
        pluginName: 'notes_name'.tr,
        pluginIcon: Icons.notes,
        pluginDefaultColor: _notesColor,
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
