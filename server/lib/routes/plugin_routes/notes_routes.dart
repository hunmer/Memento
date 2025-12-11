import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../services/plugin_data_service.dart';

/// Notes 插件 HTTP 路由
class NotesRoutes {
  final PluginDataService _dataService;
  final _uuid = const Uuid();

  NotesRoutes(this._dataService);

  Router get router {
    final router = Router();

    // ==================== 笔记 API ====================
    // GET /notes - 获取笔记列表
    router.get('/notes', _getNotes);

    // GET /notes/<id> - 获取单个笔记
    router.get('/notes/<id>', _getNote);

    // POST /notes - 创建笔记
    router.post('/notes', _createNote);

    // PUT /notes/<id> - 更新笔记
    router.put('/notes/<id>', _updateNote);

    // DELETE /notes/<id> - 删除笔记
    router.delete('/notes/<id>', _deleteNote);

    // POST /notes/<id>/move - 移动笔记
    router.post('/notes/<id>/move', _moveNote);

    // GET /search - 搜索笔记
    router.get('/search', _searchNotes);

    // ==================== 文件夹 API ====================
    // GET /folders - 获取文件夹列表
    router.get('/folders', _getFolders);

    // GET /folders/<id> - 获取单个文件夹
    router.get('/folders/<id>', _getFolder);

    // POST /folders - 创建文件夹
    router.post('/folders', _createFolder);

    // PUT /folders/<id> - 更新文件夹
    router.put('/folders/<id>', _updateFolder);

    // DELETE /folders/<id> - 删除文件夹
    router.delete('/folders/<id>', _deleteFolder);

    // GET /folders/<id>/notes - 获取文件夹的笔记
    router.get('/folders/<id>/notes', _getFolderNotes);

    return router;
  }

  // ==================== 辅助方法 ====================

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  Response _successResponse(dynamic data) {
    return Response.ok(
      jsonEncode({
        'success': true,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _paginatedResponse(
    List<dynamic> data, {
    int offset = 0,
    int count = 100,
  }) {
    final paginated = _dataService.paginate(data, offset: offset, count: count);
    return Response.ok(
      jsonEncode({
        'success': true,
        ...paginated,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 读取所有笔记
  Future<List<Map<String, dynamic>>> _readAllNotes(String userId) async {
    final notesData = await _dataService.readPluginData(
      userId,
      'notes',
      'notes.json',
    );
    if (notesData == null) return [];

    // notes.json 结构: { "notes": [...] }
    final notes = notesData['notes'] as List<dynamic>? ?? [];
    return notes.cast<Map<String, dynamic>>();
  }

  /// 保存所有笔记
  Future<void> _saveAllNotes(String userId, List<Map<String, dynamic>> notes) async {
    await _dataService.writePluginData(
      userId,
      'notes',
      'notes.json',
      {'notes': notes},
    );
  }

  /// 读取所有文件夹
  Future<List<Map<String, dynamic>>> _readAllFolders(String userId) async {
    final foldersData = await _dataService.readPluginData(
      userId,
      'notes',
      'folders.json',
    );
    if (foldersData == null) return [];

    // folders.json 结构: { "folders": [...] }
    final folders = foldersData['folders'] as List<dynamic>? ?? [];
    return folders.cast<Map<String, dynamic>>();
  }

  /// 保存所有文件夹
  Future<void> _saveAllFolders(String userId, List<Map<String, dynamic>> folders) async {
    await _dataService.writePluginData(
      userId,
      'notes',
      'folders.json',
      {'folders': folders},
    );
  }

  // ==================== 笔记处理方法 ====================

  /// 获取笔记列表
  Future<Response> _getNotes(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final folderId = request.url.queryParameters['folderId'];
      var notes = await _readAllNotes(userId);

      // 按文件夹过滤
      if (folderId != null) {
        notes = notes.where((n) => n['folderId'] == folderId).toList();
      }

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(notes, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(notes);
    } catch (e) {
      return _errorResponse(500, '获取笔记失败: $e');
    }
  }

  /// 获取单个笔记
  Future<Response> _getNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final notes = await _readAllNotes(userId);
      final note = notes.firstWhere(
        (n) => n['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (note.isEmpty) {
        return _errorResponse(404, '笔记不存在');
      }

      return _successResponse(note);
    } catch (e) {
      return _errorResponse(500, '获取笔记失败: $e');
    }
  }

  /// 创建笔记
  Future<Response> _createNote(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final title = data['title'] as String?;
      if (title == null || title.isEmpty) {
        return _errorResponse(400, '缺少必需参数: title');
      }

      final noteId = data['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final note = {
        'id': noteId,
        'title': title,
        'content': data['content'] ?? '',
        'folderId': data['folderId'],
        'tags': data['tags'] ?? <String>[],
        'createdAt': now,
        'updatedAt': now,
        'isPinned': data['isPinned'] ?? false,
        'metadata': data['metadata'],
      };

      final notes = await _readAllNotes(userId);
      notes.add(note);
      await _saveAllNotes(userId, notes);

      return _successResponse(note);
    } catch (e) {
      return _errorResponse(500, '创建笔记失败: $e');
    }
  }

  /// 更新笔记
  Future<Response> _updateNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final notes = await _readAllNotes(userId);
      final index = notes.indexWhere((n) => n['id'] == id);

      if (index == -1) {
        return _errorResponse(404, '笔记不存在');
      }

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;

      // 合并更新
      final note = Map<String, dynamic>.from(notes[index]);
      if (updates.containsKey('title')) note['title'] = updates['title'];
      if (updates.containsKey('content')) note['content'] = updates['content'];
      if (updates.containsKey('folderId')) note['folderId'] = updates['folderId'];
      if (updates.containsKey('tags')) note['tags'] = updates['tags'];
      if (updates.containsKey('isPinned')) note['isPinned'] = updates['isPinned'];
      if (updates.containsKey('metadata')) note['metadata'] = updates['metadata'];
      note['updatedAt'] = DateTime.now().toIso8601String();

      notes[index] = note;
      await _saveAllNotes(userId, notes);

      return _successResponse(note);
    } catch (e) {
      return _errorResponse(500, '更新笔记失败: $e');
    }
  }

  /// 删除笔记
  Future<Response> _deleteNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final notes = await _readAllNotes(userId);
      final initialLength = notes.length;

      notes.removeWhere((n) => n['id'] == id);

      if (notes.length == initialLength) {
        return _errorResponse(404, '笔记不存在');
      }

      await _saveAllNotes(userId, notes);

      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除笔记失败: $e');
    }
  }

  /// 移动笔记到其他文件夹
  Future<Response> _moveNote(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final targetFolderId = data['targetFolderId'] as String?;

      final notes = await _readAllNotes(userId);
      final index = notes.indexWhere((n) => n['id'] == id);

      if (index == -1) {
        return _errorResponse(404, '笔记不存在');
      }

      notes[index]['folderId'] = targetFolderId;
      notes[index]['updatedAt'] = DateTime.now().toIso8601String();

      await _saveAllNotes(userId, notes);

      return _successResponse(notes[index]);
    } catch (e) {
      return _errorResponse(500, '移动笔记失败: $e');
    }
  }

  /// 搜索笔记
  Future<Response> _searchNotes(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final keyword = request.url.queryParameters['keyword'];
    final tags = request.url.queryParameters['tags']?.split(',');

    try {
      var notes = await _readAllNotes(userId);

      // 按关键词过滤
      if (keyword != null && keyword.isNotEmpty) {
        final lowerKeyword = keyword.toLowerCase();
        notes = notes.where((n) {
          final title = (n['title'] as String? ?? '').toLowerCase();
          final content = (n['content'] as String? ?? '').toLowerCase();
          return title.contains(lowerKeyword) || content.contains(lowerKeyword);
        }).toList();
      }

      // 按标签过滤
      if (tags != null && tags.isNotEmpty) {
        notes = notes.where((n) {
          final noteTags = (n['tags'] as List<dynamic>?)?.cast<String>() ?? [];
          return tags.any((tag) => noteTags.contains(tag));
        }).toList();
      }

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(notes, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(notes);
    } catch (e) {
      return _errorResponse(500, '搜索笔记失败: $e');
    }
  }

  // ==================== 文件夹处理方法 ====================

  /// 获取文件夹列表
  Future<Response> _getFolders(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final folders = await _readAllFolders(userId);

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(folders, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(folders);
    } catch (e) {
      return _errorResponse(500, '获取文件夹失败: $e');
    }
  }

  /// 获取单个文件夹
  Future<Response> _getFolder(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final folders = await _readAllFolders(userId);
      final folder = folders.firstWhere(
        (f) => f['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (folder.isEmpty) {
        return _errorResponse(404, '文件夹不存在');
      }

      return _successResponse(folder);
    } catch (e) {
      return _errorResponse(500, '获取文件夹失败: $e');
    }
  }

  /// 创建文件夹
  Future<Response> _createFolder(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null || name.isEmpty) {
        return _errorResponse(400, '缺少必需参数: name');
      }

      final folderId = data['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final folder = {
        'id': folderId,
        'name': name,
        'parentId': data['parentId'],
        'icon': data['icon'],
        'color': data['color'],
        'createdAt': now,
        'updatedAt': now,
      };

      final folders = await _readAllFolders(userId);
      folders.add(folder);
      await _saveAllFolders(userId, folders);

      return _successResponse(folder);
    } catch (e) {
      return _errorResponse(500, '创建文件夹失败: $e');
    }
  }

  /// 更新文件夹
  Future<Response> _updateFolder(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final folders = await _readAllFolders(userId);
      final index = folders.indexWhere((f) => f['id'] == id);

      if (index == -1) {
        return _errorResponse(404, '文件夹不存在');
      }

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;

      // 合并更新
      final folder = Map<String, dynamic>.from(folders[index]);
      if (updates.containsKey('name')) folder['name'] = updates['name'];
      if (updates.containsKey('parentId')) folder['parentId'] = updates['parentId'];
      if (updates.containsKey('icon')) folder['icon'] = updates['icon'];
      if (updates.containsKey('color')) folder['color'] = updates['color'];
      folder['updatedAt'] = DateTime.now().toIso8601String();

      folders[index] = folder;
      await _saveAllFolders(userId, folders);

      return _successResponse(folder);
    } catch (e) {
      return _errorResponse(500, '更新文件夹失败: $e');
    }
  }

  /// 删除文件夹
  Future<Response> _deleteFolder(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final folders = await _readAllFolders(userId);
      final initialLength = folders.length;

      // 递归删除子文件夹
      void removeRecursive(String folderId) {
        folders.removeWhere((f) => f['id'] == folderId);
        final children = folders.where((f) => f['parentId'] == folderId).toList();
        for (final child in children) {
          removeRecursive(child['id'] as String);
        }
      }

      removeRecursive(id);

      if (folders.length == initialLength) {
        return _errorResponse(404, '文件夹不存在');
      }

      await _saveAllFolders(userId, folders);

      // 将该文件夹下的笔记移到根目录
      final notes = await _readAllNotes(userId);
      var updated = false;
      for (final note in notes) {
        if (note['folderId'] == id) {
          note['folderId'] = null;
          updated = true;
        }
      }
      if (updated) {
        await _saveAllNotes(userId, notes);
      }

      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除文件夹失败: $e');
    }
  }

  /// 获取文件夹的笔记
  Future<Response> _getFolderNotes(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final notes = await _readAllNotes(userId);
      final folderNotes = notes.where((n) => n['folderId'] == id).toList();

      // 处理分页
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(folderNotes, offset: offset ?? 0, count: count ?? 100);
      }

      return _successResponse(folderNotes);
    } catch (e) {
      return _errorResponse(500, '获取文件夹笔记失败: $e');
    }
  }
}
