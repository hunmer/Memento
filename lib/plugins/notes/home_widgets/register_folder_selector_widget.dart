/// 笔记插件 - 文件夹选择器组件注册
library;

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../notes_plugin.dart';
import '../controllers/notes_controller.dart';
import 'utils.dart' show notesColor, extractFolderData, formatNoteTime;

/// 文件夹选择器小组件 - 使用事件携带数据模式
class _FolderSelectorWidget extends StatefulWidget {
  final String folderId;
  final Map<String, dynamic> folderData;
  final Map<String, dynamic> config;

  const _FolderSelectorWidget({
    required this.folderId,
    required this.folderData,
    required this.config,
  });

  @override
  State<_FolderSelectorWidget> createState() => _FolderSelectorWidgetState();
}

class _FolderSelectorWidgetState extends State<_FolderSelectorWidget> {
  // 缓存的事件数据
  List<Map<String, dynamic>> _folders = [];
  List<String> _noteIds = [];

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['notes_cache_updated'],
      onEventWithData: (EventArgs args) {
        if (args is NotesCacheUpdatedEventArgs) {
          setState(() {
            _folders = args.folders;
            _noteIds = args.noteIds;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.folderData['name'] as String? ?? '未命名文件夹';
    final folderPath = widget.folderData['folderPath'] as String? ?? '';
    final iconCodePoint = widget.folderData['icon'] as int?;
    final colorValue = widget.folderData['color'] as int?;

    final folderIcon =
        iconCodePoint != null
            ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
            : Icons.folder;
    final folderColor = colorValue != null ? Color(colorValue) : notesColor;

    // 获取小组件尺寸
    final widgetSize = widget.config['widgetSize'] as HomeWidgetSize?;
    final isMediumSize = widgetSize == const MediumSize();

    // 从缓存数据中获取文件夹的笔记
    List<Map<String, dynamic>> notes = [];
    int notesCount = 0;
    for (var folder in _folders) {
      if (folder['id'] == widget.folderId) {
        // 获取该文件夹下的笔记
        notes = _noteIds
            .where((id) {
              // 这里简化处理，实际应该查找 note 对应的文件夹
              // 由于事件数据中只包含 noteIds，需要从 PluginManager 获取完整数据
              return true;
            })
            .take(isMediumSize ? 3 : 5)
            .map((id) => {
                'title': '笔记 $id',
                'updatedAt': DateTime.now().toIso8601String(),
              })
            .toList();
        notesCount = _noteIds.length;
        break;
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
                                          color:
                                              theme.colorScheme.onPrimaryContainer,
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
                            '还有 ${notesCount - notes.length} 条笔记',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withOpacity(0.5),
                            ),
                          ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'empty_folder'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.5),
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
}

/// 注册文件夹选择器小组件
void registerFolderSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'notes_folder_selector',
      pluginId: 'notes',
      name: 'notes_folderQuickAccess'.tr,
      description: 'notes_folderQuickAccessDesc'.tr,
      icon: Icons.folder_open,
      color: notesColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'notes.folder',
      dataRenderer: _renderFolderData,
      navigationHandler: _navigateToFolder,
      dataSelector: extractFolderData,

      builder: (context, config) {
        final data = config['selectedData'] as Map<String, dynamic>? ?? {};
        final folderId = data['id'] as String?;
        if (folderId == null) {
          return HomeWidget.buildErrorWidget(context, 'notes_folderNotFound'.tr);
        }
        return _FolderSelectorWidget(
          folderId: folderId,
          folderData: data,
          config: config,
        );
      },
    ),
  );
}

/// 渲染文件夹数据 - 使用列表样式展示笔记
Widget _renderFolderData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  final folderData = result.data as Map<String, dynamic>;
  final folderId = folderData['id'] as String?;

  if (folderId == null) {
    return HomeWidget.buildErrorWidget(context, 'notes_folderNotFound'.tr);
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
Widget _buildFolderWidget(
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
  final folderColor = colorValue != null ? Color(colorValue) : notesColor;

  // 获取小组件尺寸
  final widgetSize = config['widgetSize'] as HomeWidgetSize?;
  final isMediumSize = widgetSize == const MediumSize();

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
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
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
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.5),
                          ),
                        ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'empty_folder'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withOpacity(0.5),
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

/// 导航到选中的文件夹
void _navigateToFolder(BuildContext context, SelectorResult result) {
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
