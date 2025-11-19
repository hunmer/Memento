import 'package:flutter/material.dart';
import '../notes_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Notes插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class NotesPromptReplacements {
  final NotesPlugin _plugin;

  NotesPromptReplacements(this._plugin);

  /// 获取笔记数据并格式化为文本
  ///
  /// 参数:
  /// - folder_ids: 文件夹ID列表 (可选)
  /// - note_ids: 笔记ID列表 (可选)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, folders, totalWords }, topTags: [...] }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (content截断至100字为desc)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getNotes(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;

      // 2. 获取笔记数据
      final allNotes = await _getNotesFromParams(params);

      // 3. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          allNotes,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(allNotes, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取笔记数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取笔记数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据参数获取笔记列表
  Future<List<Map<String, dynamic>>> _getNotesFromParams(
    Map<String, dynamic> params,
  ) async {
    try {
      List<String> noteIds = [];

      // 处理 folder_ids 参数
      if (params.containsKey('folder_ids') && params['folder_ids'] is List) {
        final List<String> folderIds = List<String>.from(params['folder_ids']);
        for (final folderId in folderIds) {
          // 通过 jsAPI 获取文件夹下的笔记
          final jsAPI = _plugin.defineJSAPI();
          final getFolderNotesFunc = jsAPI['getFolderNotes'];

          if (getFolderNotesFunc != null) {
            final String jsonResult = await getFolderNotesFunc(folderId);
            final List<dynamic> folderNotes = FieldUtils.fromJsonString(jsonResult);

            for (final note in folderNotes) {
              if (note is Map && note.containsKey('id')) {
                noteIds.add(note['id'] as String);
              }
            }
          }
        }
      }

      // 处理 note_ids 参数
      if (params.containsKey('note_ids') && params['note_ids'] is List) {
        final List<String> specificNoteIds = List<String>.from(params['note_ids']);
        noteIds.addAll(specificNoteIds);
      }

      // 如果没有指定任何ID，返回所有笔记
      if (noteIds.isEmpty) {
        return await _getAllNotes();
      }

      // 去重
      noteIds = noteIds.toSet().toList();

      // 获取笔记详细信息
      final List<Map<String, dynamic>> notesInfo = [];

      for (final noteId in noteIds) {
        try {
          final jsAPI = _plugin.defineJSAPI();
          final getNoteFunc = jsAPI['getNote'];

          if (getNoteFunc != null) {
            final String jsonResult = await getNoteFunc(noteId);
            final Map<String, dynamic> note = FieldUtils.fromJsonString(jsonResult);

            if (!note.containsKey('error')) {
              notesInfo.add(note);
            }
          }
        } catch (e) {
          debugPrint('获取笔记 $noteId 失败: $e');
        }
      }

      return notesInfo;
    } catch (e) {
      debugPrint('获取笔记失败: $e');
      return [];
    }
  }

  /// 获取所有笔记
  Future<List<Map<String, dynamic>>> _getAllNotes() async {
    try {
      final jsAPI = _plugin.defineJSAPI();
      final getNotesFunc = jsAPI['getNotes'];

      if (getNotesFunc == null) {
        debugPrint('getNotes jsAPI 未定义');
        return [];
      }

      // 调用 jsAPI 获取所有笔记
      final String jsonResult = await getNotesFunc();

      // 解析 JSON 结果
      final List<dynamic> notes = FieldUtils.fromJsonString(jsonResult);
      return notes.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('调用 jsAPI 失败: $e');
      return [];
    }
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(
    List<Map<String, dynamic>> notes,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(notes);
      case AnalysisMode.compact:
        return _buildCompact(notes);
      case AnalysisMode.full:
        return _buildFull(notes);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 20,
  ///     "folders": 5,
  ///     "totalWords": 15000
  ///   },
  ///   "topTags": [
  ///     {"tag": "技术", "cnt": 8},
  ///     {"tag": "工作", "cnt": 5}
  ///   ]
  /// }
  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'folders': 0,
        'totalWords': 0,
      });
    }

    // 计算总字数和文件夹数
    int totalWords = 0;
    final Set<String> folderIds = {};
    final Map<String, int> tagCounts = {}; // 标签统计

    for (final note in notes) {
      // 统计字数
      final content = note['content'] as String?;
      if (content != null) {
        totalWords += content.length;
      }

      // 统计文件夹
      final folderId = note['folderId'] as String?;
      if (folderId != null) {
        folderIds.add(folderId);
      }

      // 统计标签
      final tags = note['tags'] as List?;
      if (tags != null) {
        for (final tag in tags) {
          if (tag is String) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }
      }
    }

    // 生成标签排行（按次数降序）
    final topTags = tagCounts.entries.map((entry) {
      return {
        'tag': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    // 只保留前10个标签
    final topTagsLimited = topTags.take(10).toList();

    return FieldUtils.buildSummaryResponse({
      'total': notes.length,
      'folders': folderIds.length,
      'totalWords': totalWords,
      if (topTagsLimited.isNotEmpty) 'topTags': topTagsLimited,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 20 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "Flutter 开发笔记",
  ///       "folder": "技术",
  ///       "created": "2025-01-15T09:00:00",
  ///       "tags": ["Flutter", "移动开发"],
  ///       "desc": "关于 Flutter 的学习笔记..."  // content截断至100字
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<Map<String, dynamic>> notes) {
    if (notes.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0},
        [],
      );
    }

    // 简化记录（截断 content 字段至100字并重命名为 desc）
    final compactRecords = notes.map((note) {
      final record = <String, dynamic>{
        'id': note['id'],
        'title': note['title'],
      };

      // 获取文件夹名称
      final folderId = note['folderId'] as String?;
      if (folderId != null) {
        try {
          final folder = _plugin.controller.getFolder(folderId);
          if (folder != null) {
            record['folder'] = folder.name;
          }
        } catch (e) {
          // 忽略错误
        }
      }

      // 添加创建时间
      if (note['createdAt'] != null) {
        record['created'] = FieldUtils.formatDateTime(
          DateTime.parse(note['createdAt'] as String),
        );
      }

      // 添加标签
      if (note['tags'] != null && (note['tags'] as List).isNotEmpty) {
        record['tags'] = note['tags'];
      }

      // 截断 content 为 desc (最多100字)
      final content = note['content'] as String?;
      if (content != null && content.isNotEmpty) {
        record['desc'] = FieldUtils.truncateText(content, 100);
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': notes.length},
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<Map<String, dynamic>> notes) {
    return FieldUtils.buildFullResponse(notes);
  }

  /// 释放资源
  void dispose() {}
}
