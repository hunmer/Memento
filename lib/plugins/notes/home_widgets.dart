import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
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
      name: 'notes_widgetName'.tr,
      description: 'notes_widgetDescription'.tr,
      icon: Icons.note_alt_outlined,
      color: _notesColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.note_alt_outlined,
        color: _notesColor,
        name: 'notes_widgetName'.tr,
      ),
    ));

    // 2x2 详细卡片 - 显示统计信息
    registry.register(HomeWidget(
      id: 'notes_overview',
      pluginId: 'notes',
      name: 'notes_overviewName'.tr,
      description: 'notes_overviewDescription'.tr,
      icon: Icons.notes,
      color: _notesColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => _buildOverviewWidget(context, config),
      availableStatsProvider: _getAvailableStats,
    ));

    // 文件夹选择器小组件 - 快速访问指定文件夹
    registry.register(HomeWidget(
      id: 'notes_folder_selector',
      pluginId: 'notes',
      name: 'notes_folderQuickAccess'.tr,
      description: 'notes_folderQuickAccessDesc'.tr,
      icon: Icons.folder_open,
      color: _notesColor,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'notes.folder',
      dataRenderer: _renderFolderData,
      navigationHandler: _navigateToFolder,

      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('notes_folder_selector')!,
          config: config,
        );
      },
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
        pluginId: 'notes',
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
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 选择器小组件相关方法 =====

  /// 渲染文件夹数据
  static Widget _renderFolderData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);
    final folderData = result.data as Map<String, dynamic>;

    final name = folderData['name'] as String? ?? '未命名文件夹';
    final notesCount = folderData['notesCount'] as int? ?? 0;
    final folderPath = folderData['folderPath'] as String? ?? '';
    final iconCodePoint = folderData['icon'] as int?;
    final colorValue = folderData['color'] as int?;

    final folderIcon = iconCodePoint != null
        ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
        : Icons.folder;
    final folderColor = colorValue != null
        ? Color(colorValue)
        : _notesColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和路径
              Row(
                children: [
                  Icon(
                    folderIcon,
                    size: 24,
                    color: folderColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folderPath,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Spacer(),
              // 文件夹名称
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 笔记数量
              Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'notes_notesCount'.trParams({'count': '$notesCount'}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'notes_clickToView'.tr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到选中的文件夹
  static void _navigateToFolder(
    BuildContext context,
    SelectorResult result,
  ) {
    final folderData = result.data as Map<String, dynamic>;
    final folderId = folderData['id'] as String;

    NavigationHelper.pushNamed(
      context,
      '/notes',
      arguments: {'folderId': folderId},
    );
  }
}
