import 'dart:convert';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'controllers/notes_controller.dart';
import 'screens/notes_screen.dart';
import 'l10n/notes_localizations.dart';

class NotesPlugin extends BasePlugin with ChangeNotifier, JSBridgePlugin {
  static NotesPlugin? _instance;
  static NotesPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (_instance == null) {
        throw StateError('NotesPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String? getPluginName(context) {
    return NotesLocalizations.of(context).name;
  }

  late NotesController controller;
  bool _isInitialized = false;

  @override
  String get id => 'notes';

  @override
  Color get color => const Color.fromARGB(255, 61, 204, 185);

  @override
  IconData get icon => Icons.note_alt_outlined;

  @override
  Future<void> initialize() async {
    controller = NotesController(storage);
    await controller.initialize();


    _isInitialized = true;

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  // 获取总笔记数
  int getTotalNotesCount() {
    if (!_isInitialized) return 0;
    return controller.searchNotes(query: '').length;
  }

  // 获取最近7天的笔记数
  int getRecentNotesCount() {
    if (!_isInitialized) return 0;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return controller
        .searchNotes(query: '', startDate: sevenDaysAgo, endDate: now)
        .length;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    if (!_isInitialized) return null;

    final theme = Theme.of(context);
    final totalNotes = getTotalNotesCount();
    final recentNotes = getRecentNotesCount();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                NotesLocalizations.of(context).name,

                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 总笔记数和七日笔记数
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 总笔记数
                  Column(
                    children: [
                      Text(
                        NotesLocalizations.of(context).totalNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$totalNotes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // 七日笔记数
                  Column(
                    children: [
                      Text(
                        NotesLocalizations.of(context).recentNotes,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$recentNotes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMainView(BuildContext context) {
    return NotesMainView();
  }

  @override
  Future<void> registerToApp(pluginManager, configManager) async {
    // 注册插件到应用
    await initialize();
  }

  @override
  Future<void> uninstall() async {
    await super.uninstall();
  }

  @override
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {

      // 笔记相关
      'getNotes': _jsGetNotes,
      'getNote': _jsGetNote,
      'createNote': _jsCreateNote,
      'updateNote': _jsUpdateNote,
      'deleteNote': _jsDeleteNote,
      'searchNotes': _jsSearchNotes,

      // 笔记查找辅助方法
      'findNoteBy': _jsFindNoteBy,
      'findNoteById': _jsFindNoteById,
      'findNoteByTitle': _jsFindNoteByTitle,

      // 文件夹相关
      'getFolders': _jsGetFolders,
      'getFolder': _jsGetFolder,
      'createFolder': _jsCreateFolder,
      'renameFolder': _jsRenameFolder,
      'deleteFolder': _jsDeleteFolder,
      'getFolderNotes': _jsGetFolderNotes,
      'moveNote': _jsMoveNote,

      // 文件夹查找辅助方法
      'findFolderBy': _jsFindFolderBy,
      'findFolderById': _jsFindFolderById,
      'findFolderByName': _jsFindFolderByName,
    };
  }

  // ==================== JS API 实现 ====================

  /// 分页辅助方法
  ///
  /// 根据 offset 和 count 参数对列表进行分页
  /// - 如果 offset 和 count 都为 null,返回原格式(列表)
  /// - 如果提供了分页参数,返回包含 items、total、offset、count 的对象
  dynamic _paginate(List<dynamic> items, Map<String, dynamic> params) {
    final int? offset = params['offset'];
    final int? count = params['count'];

    // 无分页参数:返回原格式(列表)
    if (offset == null && count == null) {
      return items;
    }

    // 有分页参数:返回分页对象
    final int actualOffset = offset ?? 0;
    final int actualCount = count ?? items.length;
    final List<dynamic> paginatedItems = items.skip(actualOffset).take(actualCount).toList();

    return {
      'items': paginatedItems,
      'total': items.length,
      'offset': actualOffset,
      'count': paginatedItems.length,
    };
  }

  /// 获取笔记列表
  Future<String> _jsGetNotes(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取可选参数
    final String? folderId = params['folderId'];

    List<dynamic> notesJson;
    if (folderId != null) {
      // 获取指定文件夹的笔记
      final notes = controller.getFolderNotes(folderId);
      notesJson = notes.map((n) => n.toJson()).toList();
    } else {
      // 获取所有笔记
      final allNotes = controller.searchNotes(query: '');
      notesJson = allNotes.map((n) => n.toJson()).toList();
    }

    // 应用分页
    final result = _paginate(notesJson, params);
    return jsonEncode(result);
  }

  /// 获取单个笔记详情
  Future<String> _jsGetNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? noteId = params['noteId'];
    if (noteId == null || noteId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: noteId'});
    }

    // 在所有笔记中查找
    final allNotes = controller.searchNotes(query: '');
    final note = allNotes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => throw Exception('笔记不存在'),
    );

    return jsonEncode(note.toJson());
  }

  /// 创建新笔记
  Future<String> _jsCreateNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final String? content = params['content'];
    if (content == null) {
      return jsonEncode({'error': '缺少必需参数: content'});
    }

    // 提取可选参数
    final String? customId = params['id'];
    final String? folderId = params['folderId'];
    final List<String>? tags = params['tags'] != null
        ? (params['tags'] as List<dynamic>).map((e) => e.toString()).toList()
        : null;

    // 如果没有指定文件夹，使用根文件夹
    final targetFolderId = folderId ?? 'root';

    // 创建笔记
    var note = await controller.createNote(
      title,
      content,
      targetFolderId,
      customId: customId,
    );

    // 如果有标签，更新笔记
    if (tags != null && tags.isNotEmpty) {
      note = note.copyWith(tags: tags, updatedAt: DateTime.now());
      await controller.updateNote(note);
    }

    return jsonEncode(note.toJson());
  }

  /// 更新笔记
  Future<String> _jsUpdateNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? noteId = params['noteId'];
    if (noteId == null || noteId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: noteId'});
    }

    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final String? content = params['content'];
    if (content == null) {
      return jsonEncode({'error': '缺少必需参数: content'});
    }

    // 提取可选参数
    final List<String>? tags = params['tags'] != null
        ? (params['tags'] as List<dynamic>).map((e) => e.toString()).toList()
        : null;

    // 查找笔记
    final allNotes = controller.searchNotes(query: '');
    final note = allNotes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => throw Exception('笔记不存在'),
    );

    // 更新笔记
    final updatedNote = note.copyWith(
      title: title,
      content: content,
      tags: tags,
      updatedAt: DateTime.now(),
    );

    await controller.updateNote(updatedNote);
    return jsonEncode(updatedNote.toJson());
  }

  /// 删除笔记
  Future<String> _jsDeleteNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'success': false, 'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? noteId = params['noteId'];
    if (noteId == null || noteId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: noteId'});
    }

    try {
      await controller.deleteNote(noteId);
      return jsonEncode({'success': true, 'noteId': noteId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除失败: ${e.toString()}'});
    }
  }

  /// 搜索笔记
  Future<String> _jsSearchNotes(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? keyword = params['keyword'];
    if (keyword == null) {
      return jsonEncode({'error': '缺少必需参数: keyword'});
    }

    // 提取可选参数
    final List<String>? tags = params['tags'] != null
        ? (params['tags'] as List<dynamic>).map((e) => e.toString()).toList()
        : null;
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];

    // 解析日期
    DateTime? start;
    DateTime? end;
    if (startDate != null) {
      start = DateTime.tryParse(startDate);
    }
    if (endDate != null) {
      end = DateTime.tryParse(endDate);
    }

    // 搜索笔记
    final notes = controller.searchNotes(
      query: keyword,
      tags: tags,
      startDate: start,
      endDate: end,
    );

    final notesJson = notes.map((n) => n.toJson()).toList();

    // 应用分页
    final result = _paginate(notesJson, params);
    return jsonEncode(result);
  }

  /// 获取所有文件夹
  Future<String> _jsGetFolders(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final folders = controller.getAllFolders();
    final foldersJson = folders.map((f) => f.toJson()).toList();

    // 应用分页
    final result = _paginate(foldersJson, params);
    return jsonEncode(result);
  }

  /// 获取单个文件夹详情
  Future<String> _jsGetFolder(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? folderId = params['folderId'];
    if (folderId == null || folderId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: folderId'});
    }

    final folder = controller.getFolder(folderId);
    if (folder == null) {
      throw Exception('文件夹不存在');
    }

    return jsonEncode(folder.toJson());
  }

  /// 创建文件夹
  Future<String> _jsCreateFolder(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    // 提取可选参数
    final String? customId = params['id'];
    final String? parentId = params['parentId'];

    final folder = await controller.createFolder(
      name,
      parentId,
      customId: customId,
    );
    return jsonEncode(folder.toJson());
  }

  /// 重命名文件夹
  Future<String> _jsRenameFolder(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'success': false, 'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? folderId = params['folderId'];
    if (folderId == null || folderId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: folderId'});
    }

    final String? newName = params['newName'];
    if (newName == null || newName.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: newName'});
    }

    try {
      await controller.renameFolder(folderId, newName);
      return jsonEncode({'success': true, 'folderId': folderId, 'newName': newName});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '重命名失败: ${e.toString()}'});
    }
  }

  /// 删除文件夹（递归删除子文件夹和笔记）
  Future<String> _jsDeleteFolder(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'success': false, 'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? folderId = params['folderId'];
    if (folderId == null || folderId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: folderId'});
    }

    try {
      await controller.deleteFolder(folderId);
      return jsonEncode({'success': true, 'folderId': folderId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '删除失败: ${e.toString()}'});
    }
  }

  /// 获取文件夹中的笔记
  Future<String> _jsGetFolderNotes(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? folderId = params['folderId'];
    if (folderId == null || folderId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: folderId'});
    }

    final notes = controller.getFolderNotes(folderId);
    final notesJson = notes.map((n) => n.toJson()).toList();

    // 应用分页
    final result = _paginate(notesJson, params);
    return jsonEncode(result);
  }

  /// 移动笔记到其他文件夹
  Future<String> _jsMoveNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'success': false, 'error': '插件未初始化'});
    }

    // 提取必需参数并验证
    final String? noteId = params['noteId'];
    if (noteId == null || noteId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: noteId'});
    }

    final String? targetFolderId = params['targetFolderId'];
    if (targetFolderId == null || targetFolderId.isEmpty) {
      return jsonEncode({'success': false, 'error': '缺少必需参数: targetFolderId'});
    }

    try {
      await controller.moveNote(noteId, targetFolderId);
      return jsonEncode({'success': true, 'noteId': noteId, 'targetFolderId': targetFolderId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': '移动失败: ${e.toString()}'});
    }
  }

  // ==================== 笔记查找方法 ====================

  /// 通用笔记查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindNoteBy(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    // 获取所有笔记
    final allNotes = controller.searchNotes(query: '');
    final matchedNotes = [];

    for (final note in allNotes) {
      final noteJson = note.toJson();

      // 检查字段是否匹配
      if (noteJson.containsKey(field) && noteJson[field] == value) {
        matchedNotes.add(note);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      return jsonEncode(matchedNotes.map((n) => n.toJson()).toList());
    } else {
      if (matchedNotes.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedNotes.first.toJson());
    }
  }

  /// 根据ID查找笔记
  /// @param params.id 笔记ID (必需)
  Future<String> _jsFindNoteById(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final allNotes = controller.searchNotes(query: '');
    final note = allNotes.firstWhere(
      (n) => n.id == id,
      orElse: () => null as dynamic,
    );

    if (note == null) {
      return jsonEncode(null);
    }

    return jsonEncode(note.toJson());
  }

  /// 根据标题查找笔记
  /// @param params.title 笔记标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindNoteByTitle(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    final allNotes = controller.searchNotes(query: '');
    final matchedNotes = [];

    for (final note in allNotes) {
      bool matches = false;
      if (fuzzy) {
        matches = note.title.contains(title);
      } else {
        matches = note.title == title;
      }

      if (matches) {
        matchedNotes.add(note);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedNotes.map((n) => n.toJson()).toList());
    } else {
      if (matchedNotes.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedNotes.first.toJson());
    }
  }

  // ==================== 文件夹查找方法 ====================

  /// 通用文件夹查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindFolderBy(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;

    final folders = controller.getAllFolders();
    final matchedFolders = [];

    for (final folder in folders) {
      final folderJson = folder.toJson();

      // 检查字段是否匹配
      if (folderJson.containsKey(field) && folderJson[field] == value) {
        matchedFolders.add(folder);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedFolders.map((f) => f.toJson()).toList());
    } else {
      if (matchedFolders.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedFolders.first.toJson());
    }
  }

  /// 根据ID查找文件夹
  /// @param params.id 文件夹ID (必需)
  Future<String> _jsFindFolderById(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final folder = controller.getFolder(id);

    if (folder == null) {
      return jsonEncode(null);
    }

    return jsonEncode(folder.toJson());
  }

  /// 根据名称查找文件夹
  /// @param params.name 文件夹名称 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindFolderByName(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final String? name = params['name'];
    if (name == null || name.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;

    final folders = controller.getAllFolders();
    final matchedFolders = [];

    for (final folder in folders) {
      bool matches = false;
      if (fuzzy) {
        matches = folder.name.contains(name);
      } else {
        matches = folder.name == name;
      }

      if (matches) {
        matchedFolders.add(folder);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedFolders.map((f) => f.toJson()).toList());
    } else {
      if (matchedFolders.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedFolders.first.toJson());
    }
  }
}
