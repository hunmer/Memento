/// 笔记插件主页小组件数据提供者
///
/// 为各种公共组件提供笔记数据

library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../notes_plugin.dart';
import '../models/note.dart';
import '../models/folder.dart';
import 'utils.dart' show notesColor;

/// 笔记列表小组件提供者
///
/// 支持过滤器：文件夹、标签、日期范围
Future<Map<String, Map<String, dynamic>>> provideNotesListWidgets(
  Map<String, dynamic> config,
) async {
  final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
  if (plugin == null) return {};

  final controller = plugin.controller;

  // 解析过滤器参数
  final folderId = config['folderId'] as String?;
  final tags = config['tags'] as List<dynamic>?;
  final startDateStr = config['startDate'] as String?;
  final endDateStr = config['endDate'] as String?;

  // 解析日期范围
  DateTime? startDate;
  DateTime? endDate;
  if (startDateStr != null) {
    try {
      startDate = DateTime.parse(startDateStr);
    } catch (e) {
      debugPrint('[NotesListWidgets] 解析 startDate 失败: $e');
    }
  }
  if (endDateStr != null) {
    try {
      endDate = DateTime.parse(endDateStr);
    } catch (e) {
      debugPrint('[NotesListWidgets] 解析 endDate 失败: $e');
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

  // 构建 TaskListCard 数据
  final taskListCardData = {
    'icon': Icons.notes.codePoint.toString(),
    'iconBackgroundColor': notesColor.value,
    'count': notesCount,
    'countLabel': 'notes_notesCount'.tr,
    'items': displayNotes.map((note) => note.title).toList(),
    'moreCount': moreCount,
  };

  // 构建 NewsUpdateCard 数据
  final newsUpdateCardData = displayNotes.isNotEmpty
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

  // 构建 ColorTagTaskCard 数据
  final colorTagTaskCardData = {
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

  // 构建 InboxMessageCard 数据
  final inboxMessageCardData = {
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

  // 构建 folderNotesCard 数据
  final folderNotesCardData = {
    'folderName': folder?.name ?? 'notes_allNotes'.tr,
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

  return {
    'taskListCard': taskListCardData,
    'newsUpdateCard': newsUpdateCardData,
    'colorTagTaskCard': colorTagTaskCardData,
    'inboxMessageCard': inboxMessageCardData,
    if (folderNotesCardData != null) 'folderNotesCard': folderNotesCardData,
  };
}

/// 从标签获取颜色
Color _getColorFromTag(String tag) {
  // 使用标签的哈希值生成一致的颜色
  final hashCode = tag.hashCode;
  final hue = (hashCode % 360).abs();
  return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();
}

/// 获取预览文本（前50个字符）
String _getPreviewText(String content) {
  // 移除 Markdown 符号
  String cleanText = content
      .replaceAll(RegExp(r'^#+\s+', multiLine: true), '') // 标题
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1') // 粗体
      .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1') // 斜体
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'\1') // 链接
      .replaceAll(RegExp(r'`([^`]+)`'), r'\1') // 代码
      .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '') // 列表
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
