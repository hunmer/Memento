part of 'package:Memento/plugins/notes/notes_plugin.dart';

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

  /// 获取笔记列表
  Future<String> _jsGetNotes(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    // 提取可选参数
    final String? folderId = params['folderId'];

    final result = await _useCase.getNotes({
      'folderId': folderId,
      'offset': params['offset'],
      'count': params['count'],
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode({
      'success': true,
      'data': result.dataOrNull ?? [],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
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

    final result = await _useCase.getNoteById({'id': noteId});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    if (result.dataOrNull == null) {
      return jsonEncode({'error': '笔记不存在'});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.createNote({
      'id': customId,
      'title': title,
      'content': content,
      'folderId': targetFolderId,
      'tags': tags ?? [],
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.updateNote({
      'id': noteId,
      'title': title,
      'content': content,
      'tags': tags,
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.deleteNote({'id': noteId});

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true, 'noteId': noteId});
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

    final result = await _useCase.searchNotes({
      'keyword': keyword,
      'tags': tags?.join(','),
      'offset': params['offset'],
      'count': params['count'],
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
  }

  /// 获取所有文件夹
  Future<String> _jsGetFolders(Map<String, dynamic> params) async {
    if (!_isInitialized) {
      return jsonEncode({'error': '插件未初始化'});
    }

    final result = await _useCase.getFolders({
      'parentId': params['parentId'],
      'offset': params['offset'],
      'count': params['count'],
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.getFolderById({'id': folderId});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    if (result.dataOrNull == null) {
      return jsonEncode({'error': '文件夹不存在'});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.createFolder({
      'id': customId,
      'name': name,
      'parentId': parentId,
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.updateFolder({
      'id': folderId,
      'name': newName,
    });

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true, 'folderId': folderId, 'newName': newName});
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

    final result = await _useCase.deleteFolder({'id': folderId});

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true, 'folderId': folderId});
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

    final result = await _useCase.getFolderNotes({
      'id': folderId,
      'offset': params['offset'],
      'count': params['count'],
    });

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    final result = await _useCase.moveNote({
      'id': noteId,
      'targetFolderId': targetFolderId,
    });

    if (result.isFailure) {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }

    return jsonEncode({'success': true, 'noteId': noteId, 'targetFolderId': targetFolderId});
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
    final result = await _useCase.getNotes({});
    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final allNotes = result.dataOrNull as List<dynamic>;
    final matchedNotes = <dynamic>[];

    for (final noteJson in allNotes) {
      final noteMap = noteJson as Map<String, dynamic>;

      // 检查字段是否匹配
      if (noteMap.containsKey(field) && noteMap[field] == value) {
        matchedNotes.add(noteJson);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      return jsonEncode(matchedNotes);
    } else {
      if (matchedNotes.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedNotes.first);
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

    final result = await _useCase.getNoteById({'id': id});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    // 获取所有笔记
    final result = await _useCase.getNotes({});
    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final allNotes = result.dataOrNull as List<dynamic>;
    final matchedNotes = <dynamic>[];

    for (final noteJson in allNotes) {
      final noteMap = noteJson as Map<String, dynamic>;
      final noteTitle = noteMap['title'] as String;

      bool matches = false;
      if (fuzzy) {
        matches = noteTitle.contains(title);
      } else {
        matches = noteTitle == title;
      }

      if (matches) {
        matchedNotes.add(noteJson);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedNotes);
    } else {
      if (matchedNotes.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedNotes.first);
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

    // 获取所有文件夹
    final result = await _useCase.getFolders({});
    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final allFolders = result.dataOrNull as List<dynamic>;
    final matchedFolders = <dynamic>[];

    for (final folderJson in allFolders) {
      final folderMap = folderJson as Map<String, dynamic>;

      // 检查字段是否匹配
      if (folderMap.containsKey(field) && folderMap[field] == value) {
        matchedFolders.add(folderJson);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedFolders);
    } else {
      if (matchedFolders.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedFolders.first);
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

    final result = await _useCase.getFolderById({'id': id});

    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    return jsonEncode(result.dataOrNull);
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

    // 获取所有文件夹
    final result = await _useCase.getFolders({});
    if (result.isFailure) {
      return jsonEncode({'error': result.errorOrNull?.message});
    }

    final allFolders = result.dataOrNull as List<dynamic>;
    final matchedFolders = <dynamic>[];

    for (final folderJson in allFolders) {
      final folderMap = folderJson as Map<String, dynamic>;
      final folderName = folderMap['name'] as String;

      bool matches = false;
      if (fuzzy) {
        matches = folderName.contains(name);
      } else {
        matches = folderName == name;
      }

      if (matches) {
        matchedFolders.add(folderJson);
        if (!findAll) break;
      }
    }

    if (findAll) {
      return jsonEncode(matchedFolders);
    } else {
      if (matchedFolders.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedFolders.first);
    }
  }
