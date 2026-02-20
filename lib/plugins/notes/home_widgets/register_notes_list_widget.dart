/// 笔记插件 - 笔记列表组件注册
///
/// 注册笔记列表小组件，支持文件夹、标签、日期过滤
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:intl/intl.dart';
import '../notes_plugin.dart';
import '../models/note.dart';
import '../models/folder.dart';
import 'utils.dart' show notesColor;
import 'providers.dart';

/// 注册笔记列表小组件
void registerNotesListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'notes_list_widget',
      pluginId: 'notes',
      name: 'notes_listWidgetName'.tr,
      description: 'notes_listWidgetDescription'.tr,
      icon: Icons.view_list,
      color: notesColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'notes.list.config',

      // 导航处理器：点击小组件时跳转到笔记插件
      navigationHandler: _navigateToNotesPlugin,

      // 公共组件提供者
      commonWidgetsProvider: provideNotesListWidgets,

      // 使用专用的 StatefulWidget 持有事件携带的缓存数据（性能优化）
      builder: (context, config) {
        return _NotesListStatefulWidget(config: config);
      },
    ),
  );
}

/// 导航到笔记插件
void _navigateToNotesPlugin(BuildContext context, SelectorResult result) {
  final plugin = PluginManager.instance.getPlugin('notes');
  if (plugin == null) return;

  // 记录插件打开历史
  PluginManager.instance.recordPluginOpen(plugin);

  // 跳转到笔记插件
  NavigationHelper.openContainerWithHero(
    context,
    (_) => plugin.buildMainView(context),
    heroTag: 'notes_list_widget',
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// 笔记列表小组件 StatefulWidget
///
/// 使用事件携带的数据模式，避免重复的缓存访问操作
class _NotesListStatefulWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const _NotesListStatefulWidget({required this.config});

  @override
  State<_NotesListStatefulWidget> createState() =>
      _NotesListStatefulWidgetState();
}

class _NotesListStatefulWidgetState extends State<_NotesListStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    // 解析选择器配置
    final selectorConfig =
        widget.config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig == null) {
      return HomeWidget.buildErrorWidget(context, '配置错误：缺少 selectorWidgetConfig');
    }

    final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
    final commonWidgetProps = selectorConfig['commonWidgetProps'] as Map<String, dynamic>?;

    if (commonWidgetId == null) {
      return HomeWidget.buildErrorWidget(context, '配置错误：缺少 commonWidgetId');
    }

    // 查找对应的 CommonWidgetId 枚举
    final widgetIdEnum = CommonWidgetId.values.asNameMap()[commonWidgetId];
    if (widgetIdEnum == null) {
      return HomeWidget.buildErrorWidget(context, '未知的公共小组件类型: $commonWidgetId');
    }

    // 获取元数据以确定默认尺寸
    final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);
    final size = widget.config['widgetSize'] as HomeWidgetSize? ?? metadata.defaultSize;

    return EventListenerContainer(
      events: const [
        'note_added',
        'note_updated',
        'note_deleted',
      ],
      onEvent: () => setState(() {}),
      child: _buildWidgetContent(
        context,
        widgetIdEnum,
        size,
        selectorConfig,
        commonWidgetProps,
      ),
    );
  }

  /// 构建小组件内容（使用实时数据）
  Widget _buildWidgetContent(
    BuildContext context,
    CommonWidgetId widgetIdEnum,
    HomeWidgetSize size,
    Map<String, dynamic> selectorConfig,
    Map<String, dynamic>? commonWidgetProps,
  ) {
    try {
      final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (plugin == null) {
        return HomeWidget.buildErrorWidget(context, '未找到笔记插件');
      }

      // 获取实时数据
      final data = _getNotesDataSync(
        plugin,
        selectorConfig,
      );

      if (data == null) {
        return HomeWidget.buildErrorWidget(context, '数据获取失败');
      }

      return CommonWidgetBuilder.build(
        context,
        widgetIdEnum,
        data,
        size,
        inline: true,
      );
    } catch (e) {
      debugPrint('[NotesListWidget] 构建小组件内容失败: $e');
      return HomeWidget.buildErrorWidget(context, e.toString());
    }
  }

  /// 同步获取笔记数据
  Map<String, dynamic>? _getNotesDataSync(
    NotesPlugin plugin,
    Map<String, dynamic> selectorConfig,
  ) {
    try {
      final controller = plugin.controller;

      // 解析过滤器参数
      final folderId = selectorConfig['data']?['folderId'] as String?;
      final tags = selectorConfig['data']?['tags'] as List<dynamic>?;
      final startDateStr = selectorConfig['data']?['startDate'] as String?;
      final endDateStr = selectorConfig['data']?['endDate'] as String?;

      // 解析日期范围
      DateTime? startDate;
      DateTime? endDate;
      if (startDateStr != null) {
        try {
          startDate = DateTime.parse(startDateStr);
        } catch (e) {
          debugPrint('[NotesListWidget] 解析 startDate 失败: $e');
        }
      }
      if (endDateStr != null) {
        try {
          endDate = DateTime.parse(endDateStr);
        } catch (e) {
          debugPrint('[NotesListWidget] 解析 endDate 失败: $e');
        }
      }

      // 获取过滤后的笔记列表
      List<Note> filteredNotes = [];

      if (folderId != null) {
        // 按文件夹过滤
        final folderNotes = controller.getFolderNotes(folderId);

        // 进一步按标签和日期过滤
        filteredNotes = folderNotes.where((note) {
          // 标签过滤
          if (tags != null && tags.isNotEmpty) {
            final hasMatchingTag = tags.any((tag) => note.tags.contains(tag as String));
            if (!hasMatchingTag) return false;
          }

          // 日期过滤
          if (startDate != null && note.createdAt.isBefore(startDate)) {
            return false;
          }
          if (endDate != null) {
            final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
            if (note.createdAt.isAfter(endOfDay)) {
              return false;
            }
          }

          return true;
        }).toList();

        // 按更新时间降序排序
        filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        // 如果没有指定文件夹，使用搜索功能
        filteredNotes = controller.searchNotes(
          query: '',
          tags: tags?.map((e) => e as String).toList(),
          startDate: startDate,
          endDate: endDate,
        );
        // 按更新时间降序排序
        filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      final now = DateTime.now();
      final notesCount = filteredNotes.length;

      // 获取文件夹信息（如果指定了）
      Folder? folder;
      String folderName = 'notes_allNotes'.tr;
      if (folderId != null) {
        folder = controller.getFolder(folderId);
        folderName = folder?.name ?? 'notes_unknownFolder'.tr;
      }

      // 获取标签颜色映射
      final tagColors = <String, Color>{};
      for (final note in filteredNotes) {
        for (final tag in note.tags) {
          if (!tagColors.containsKey(tag)) {
            tagColors[tag] = _getColorFromTag(tag);
          }
        }
      }

      // 最多显示 5 条笔记
      final displayNotes = filteredNotes.take(5).toList();
      final moreCount = notesCount > displayNotes.length ? notesCount - displayNotes.length : 0;

      // 根据 commonWidgetId 返回对应的数据
      final commonWidgetId = selectorConfig['commonWidgetId'] as String?;
      switch (commonWidgetId) {
        case 'taskListCard':
          return {
            'icon': Icons.notes.codePoint.toString(),
            'iconBackgroundColor': notesColor.value,
            'count': notesCount,
            'countLabel': 'notes_notesCount'.tr,
            'items': displayNotes.map((note) => note.title).toList(),
            'moreCount': moreCount,
          };

        case 'newsUpdateCard':
          return displayNotes.isNotEmpty
              ? {
                  'icon': 'bolt',
                  'title': displayNotes.first.title,
                  'timestamp': _formatTimeAgo(displayNotes.first.updatedAt, now),
                  'currentIndex': 0,
                  'totalItems': displayNotes.length.clamp(1, 4),
                }
              : {
                  'icon': 'bolt',
                  'title': 'notes_noNotes'.tr,
                  'timestamp': DateFormat('yyyy-MM-dd').format(now),
                  'currentIndex': 0,
                  'totalItems': 1,
                };

        case 'colorTagTaskCard':
          return {
            'taskCount': notesCount,
            'label': folderName,
            'tasks': displayNotes.map((note) {
              final primaryTag = note.tags.isNotEmpty ? note.tags.first : '';
              final tagColor = primaryTag.isNotEmpty ? tagColors[primaryTag] : notesColor;
              return {
                'title': note.title,
                'color': tagColor?.value ?? notesColor.value,
                'tag': primaryTag.isNotEmpty ? primaryTag : 'notes_untagged'.tr,
              };
            }).toList(),
            'moreCount': moreCount,
          };

        case 'inboxMessageCard':
          return {
            'messages': displayNotes.map((note) {
              final primaryTag = note.tags.isNotEmpty ? note.tags.first : '';
              final tagColor = primaryTag.isNotEmpty ? tagColors[primaryTag] : notesColor;
              return {
                'name': note.title,
                'avatarUrl': '',
                'preview': _getPreviewText(note.content),
                'timeAgo': _formatTimeAgo(note.updatedAt, now),
                'iconCodePoint': Icons.note_outlined.codePoint,
                'iconBackgroundColor': tagColor?.value ?? notesColor.value,
              };
            }).toList(),
            'totalCount': notesCount,
            'remainingCount': moreCount,
            'title': folderName,
            'primaryColor': notesColor.value,
          };

        case 'folderNotesCard':
          return {
            'folderName': folderName,
            'folderPath': folderName,
            'iconCodePoint': folder?.icon.codePoint ?? Icons.folder.codePoint,
            'colorValue': folder?.color.value ?? notesColor.value,
            'notesCount': notesCount,
            'notes': displayNotes
                .map((note) => {
                      'title': note.title,
                      'updatedAt': note.updatedAt.toIso8601String(),
                    })
                .toList(),
          };

        default:
          return {
            'count': notesCount,
            'items': displayNotes.map((note) => note.title).toList(),
          };
      }
    } catch (e) {
      debugPrint('[NotesListWidget] 获取笔记数据失败: $e');
      return null;
    }
  }

  /// 从标签获取颜色
  Color _getColorFromTag(String tag) {
    final hashCode = tag.hashCode;
    final hue = (hashCode % 360).abs();
    return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();
  }

  /// 获取预览文本（前50个字符）
  String _getPreviewText(String content) {
    String cleanText = content
        .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'\1')
        .replaceAll(RegExp(r'`([^`]+)`'), r'\1')
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
        .trim();

    if (cleanText.length > 50) {
      cleanText = cleanText.substring(0, 50);
      final lastSpace = cleanText.lastIndexOf(' ');
      if (lastSpace > 30) {
        cleanText = cleanText.substring(0, lastSpace);
      }
      cleanText += '...';
    }
    return cleanText.isEmpty ? 'notes_emptyPreview'.tr : cleanText;
  }

  /// 格式化相对时间
  String _formatTimeAgo(DateTime dateTime, DateTime now) {
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'justNow'.tr;
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'minutesAgo'.trParams({'count': '$minutes'});
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'hoursAgo'.trParams({'count': '$hours'});
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'daysAgo'.trParams({'count': '$days'});
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }
}
