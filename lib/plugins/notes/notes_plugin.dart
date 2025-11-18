import 'dart:convert';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'controllers/notes_controller.dart';
import 'screens/notes_screen.dart';
import 'l10n/notes_localizations.dart';
import 'controls/prompt_controller.dart';

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
  late NotesPromptController _promptController;
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

    // 初始化 Prompt 控制器
    _promptController = NotesPromptController(this);
    _promptController.initialize();

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
    _promptController.unregisterPromptMethods();
    _promptController.dispose();
    await super.uninstall();
  }

  @override
  String getPluginStoragePath() {
    return storage.getPluginStoragePath(id);
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 测试API（同步）
      'testSync': _jsTestSync,

      // 笔记相关
      'getNotes': _jsGetNotes,
      'getNote': _jsGetNote,
      'createNote': _jsCreateNote,
      'updateNote': _jsUpdateNote,
      'deleteNote': _jsDeleteNote,
      'searchNotes': _jsSearchNotes,

      // 文件夹相关
      'getFolders': _jsGetFolders,
      'getFolder': _jsGetFolder,
      'createFolder': _jsCreateFolder,
      'renameFolder': _jsRenameFolder,
      'deleteFolder': _jsDeleteFolder,
      'getFolderNotes': _jsGetFolderNotes,
      'moveNote': _jsMoveNote,
    };
  }

  // ==================== JS API 实现 ====================

  /// 同步测试 API
  String _jsTestSync() {
    return jsonEncode({
      'status': 'ok',
      'message': '笔记插件 JS API 测试成功！',
      'timestamp': DateTime.now().toIso8601String(),
      'plugin': id,
    });
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

    return jsonEncode(notesJson);
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
    final String? folderId = params['folderId'];
    final List<String>? tags = params['tags'];

    // 如果没有指定文件夹，使用根文件夹
    final targetFolderId = folderId ?? 'root';

    // 创建笔记
    var note = await controller.createNote(title, content, targetFolderId);

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
    final List<String>? tags = params['tags'];

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
  Future<bool> _jsDeleteNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return false;
    }

    // 提取必需参数并验证
    final String? noteId = params['noteId'];
    if (noteId == null || noteId.isEmpty) {
      return false;
    }

    await controller.deleteNote(noteId);
    return true;
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
    final List<String>? tags = params['tags'];
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

    return jsonEncode(notes.map((n) => n.toJson()).toList());
  }

  /// 获取所有文件夹
  Future<String> _jsGetFolders(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final folders = controller.getAllFolders();
    return jsonEncode(folders.map((f) => f.toJson()).toList());
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
    final String? parentId = params['parentId'];

    final folder = await controller.createFolder(name, parentId);
    return jsonEncode(folder.toJson());
  }

  /// 重命名文件夹
  Future<bool> _jsRenameFolder(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return false;
    }

    // 提取必需参数并验证
    final String? folderId = params['folderId'];
    if (folderId == null || folderId.isEmpty) {
      return false;
    }

    final String? newName = params['newName'];
    if (newName == null || newName.isEmpty) {
      return false;
    }

    await controller.renameFolder(folderId, newName);
    return true;
  }

  /// 删除文件夹（递归删除子文件夹和笔记）
  Future<bool> _jsDeleteFolder(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return false;
    }

    // 提取必需参数并验证
    final String? folderId = params['folderId'];
    if (folderId == null || folderId.isEmpty) {
      return false;
    }

    await controller.deleteFolder(folderId);
    return true;
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
    return jsonEncode(notes.map((n) => n.toJson()).toList());
  }

  /// 移动笔记到其他文件夹
  Future<bool> _jsMoveNote(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return false;
    }

    // 提取必需参数并验证
    final String? noteId = params['noteId'];
    if (noteId == null || noteId.isEmpty) {
      return false;
    }

    final String? targetFolderId = params['targetFolderId'];
    if (targetFolderId == null || targetFolderId.isEmpty) {
      return false;
    }

    await controller.moveNote(noteId, targetFolderId);
    return true;
  }
}
