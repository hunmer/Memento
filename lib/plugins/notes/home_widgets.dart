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
import 'package:Memento/widgets/event_listener_container.dart';
import 'notes_plugin.dart';

const Color _notesColor = Color.fromARGB(255, 61, 204, 185);

/// 笔记插件的主页小组件注册
class NotesHomeWidgets {
  /// 注册所有笔记插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'notes_icon',
        pluginId: 'notes',
        name: 'notes_widgetName'.tr,
        description: 'notes_widgetDescription'.tr,
        icon: Icons.note_alt_outlined,
        color: _notesColor,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.note_alt_outlined,
              color: _notesColor,
              name: 'notes_widgetName'.tr,
            ),
      ),
    );

    // 1x1 文件夹快捷创建组件 - 选择文件夹后快速新建笔记
    registry.register(
      HomeWidget(
        id: 'notes_folder_quick_create',
        pluginId: 'notes',
        name: 'notes_quickCreate'.tr,
        description: 'notes_quickCreateDesc'.tr,
        icon: Icons.add_circle_outline,
        color: _notesColor,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        selectorId: 'notes.folder',
        dataRenderer: _renderQuickCreateData,
        navigationHandler: _navigateToQuickCreate,
        dataSelector: _extractFolderData,
        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('notes_folder_quick_create')!,
            config: config,
          );
        },
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
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
      ),
    );

    // 文件夹选择器小组件 - 快速访问指定文件夹
    registry.register(
      HomeWidget(
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
        dataSelector: _extractFolderData,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('notes_folder_selector')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 从选择器数据数组中提取文件夹数据
  static Map<String, dynamic> _extractFolderData(List<dynamic> dataArray) {
    Map<String, dynamic> itemData = {};
    final rawData = dataArray[0];

    if (rawData is Map<String, dynamic>) {
      itemData = rawData;
    } else if (rawData is dynamic && rawData.toJson != null) {
      final jsonResult = rawData.toJson();
      if (jsonResult is Map<String, dynamic>) {
        itemData = jsonResult;
      }
    }

    final result = <String, dynamic>{};
    result['id'] = itemData['id'] as String?;
    result['name'] = itemData['name'] as String?;
    result['folderPath'] = itemData['folderPath'] as String?;
    result['icon'] = itemData['icon'] as int?;
    result['color'] = itemData['color'] as int?;
    result['notesCount'] = itemData['notesCount'] as int?;
    return result;
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
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
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

  /// 渲染文件夹数据 - 使用列表样式展示笔记
  static Widget _renderFolderData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final folderData = result.data as Map<String, dynamic>;
    final folderId = folderData['id'] as String?;

    if (folderId == null) {
      return _buildErrorWidget(context, 'notes_folderNotFound'.tr);
    }

    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['note_added', 'note_updated', 'note_deleted'],
          onEvent: () => setState(() {}),
          child: _buildFolderWidget(context, folderId, folderData, config),
        );
      },
    );
  }

  /// 构建文件夹小组件内容（获取最新数据）
  static Widget _buildFolderWidget(
    BuildContext context,
    String folderId,
    Map<String, dynamic> folderData,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);
    final name = folderData['name'] as String? ?? '未命名文件夹';
    final folderPath = folderData['folderPath'] as String? ?? '';
    final iconCodePoint = folderData['icon'] as int?;
    final colorValue = folderData['color'] as int?;

    final folderIcon =
        iconCodePoint != null
            ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
            : Icons.folder;
    final folderColor = colorValue != null ? Color(colorValue) : _notesColor;

    // 获取小组件尺寸
    final widgetSize = config['widgetSize'] as HomeWidgetSize?;
    final isMediumSize = widgetSize == HomeWidgetSize.medium;

    // 从 PluginManager 获取最新的笔记数据
    List<Map<String, dynamic>> notes = [];
    int notesCount = 0;
    try {
      final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (plugin != null) {
        final notesController = plugin.controller;
        final allNotes = notesController.getFolderNotes(folderId);
        notesCount = allNotes.length;
        // 取最近的 3-5 条笔记
        notes =
            allNotes
                .take(isMediumSize ? 3 : 5)
                .map(
                  (note) => {
                    'title': note.title,
                    'updatedAt': note.updatedAt.toIso8601String(),
                  },
                )
                .toList();
      }
    } catch (e) {
      debugPrint('[NotesHomeWidgets] 获取笔记列表失败: $e');
    }

    // 格式化时间
    String formatNoteTime(String isoTime) {
      try {
        final date = DateTime.parse(isoTime);
        final now = DateTime.now();
        final diff = now.difference(date);

        if (diff.inMinutes < 1) return '刚刚';
        if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
        if (diff.inDays < 1) return '${diff.inHours}小时前';
        if (diff.inDays < 7) return '${diff.inDays}天前';
        return '${date.month}/${date.day}';
      } catch (e) {
        return '';
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部文件夹信息
              Row(
                children: [
                  Icon(folderIcon, size: 20, color: folderColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folderPath.isNotEmpty ? folderPath : name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 笔记数量徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: folderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$notesCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: folderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 笔记列表（使用滚动容器防止溢出）
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notes.isNotEmpty) ...[
                        ...notes.map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    note['title'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatNoteTime(note['updatedAt'] as String),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (notesCount > notes.length)
                          Text(
                            'notes_andMore'.trParams({
                              'count': '${notesCount - notes.length}',
                            }),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'empty_folder'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 1x1 快捷创建小组件 =====

  /// 渲染快捷创建小组件数据
  static Widget _renderQuickCreateData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);
    final folderData = result.data as Map<String, dynamic>;

    final name = folderData['name'] as String? ?? '未命名文件夹';
    final folderPath = folderData['folderPath'] as String? ?? '';
    final iconCodePoint = folderData['icon'] as int?;
    final colorValue = folderData['color'] as int?;

    final folderIcon =
        iconCodePoint != null
            ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
            : Icons.folder;
    final folderColor = colorValue != null ? Color(colorValue) : _notesColor;

    final displayName = folderPath.isNotEmpty ? folderPath : name;

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标在中间，标题在下边，图标右上角带加号 badge
              Stack(
                alignment: Alignment.topRight,
                clipBehavior: Clip.none,
                children: [
                  Icon(folderIcon, size: 40, color: folderColor),
                  // 图标右上角加号 badge
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: folderColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primaryContainer,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到快捷创建笔记
  static void _navigateToQuickCreate(
    BuildContext context,
    SelectorResult result,
  ) {
    // 从 result.data 获取 folderId
    final folderData = result.data as Map<String, dynamic>?;
    final folderId = folderData?['id'] as String? ?? 'root';

    // 通过路由跳转到笔记编辑页面
    NavigationHelper.pushNamed(
      context,
      '/notes/create',
      arguments: {'folderId': folderId},
    );
  }

  /// 导航到选中的文件夹
  static void _navigateToFolder(BuildContext context, SelectorResult result) {
    // 从 result.data 获取 folderId
    final folderData = result.data as Map<String, dynamic>?;
    final folderId = folderData?['id'] as String?;

    if (folderId == null || folderId.isEmpty) {
      debugPrint('[NotesHomeWidgets] 文件夹ID为空');
      return;
    }

    // 尝试从控制器获取最新数据
    try {
      final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      final folder = plugin?.controller.getFolder(folderId);
      final actualFolderId = folder?.id ?? folderId;

      NavigationHelper.pushNamed(
        context,
        '/notes',
        arguments: {'folderId': actualFolderId},
      );
    } catch (e) {
      debugPrint('[NotesHomeWidgets] 获取文件夹失败: $e');
      // 回退到使用原始 folderId
      NavigationHelper.pushNamed(
        context,
        '/notes',
        arguments: {'folderId': folderId},
      );
    }
  }
}
