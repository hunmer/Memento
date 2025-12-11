/// Notes 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Notes Repository 实现
class ServerNotesRepository implements INotesRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'notes';

  ServerNotesRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有笔记
  Future<List<NoteDto>> _readAllNotes() async {
    final notesData = await dataService.readPluginData(
      userId,
      _pluginId,
      'notes.json',
    );
    if (notesData == null) return [];

    final notes = notesData['notes'] as List<dynamic>? ?? [];
    return notes.map((n) => NoteDto.fromJson(n as Map<String, dynamic>)).toList();
  }

  /// 保存所有笔记
  Future<void> _saveAllNotes(List<NoteDto> notes) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'notes.json',
      {'notes': notes.map((n) => n.toJson()).toList()},
    );
  }

  /// 读取所有文件夹
  Future<List<FolderDto>> _readAllFolders() async {
    final foldersData = await dataService.readPluginData(
      userId,
      _pluginId,
      'folders.json',
    );
    if (foldersData == null) return [];

    final folders = foldersData['folders'] as List<dynamic>? ?? [];
    return folders.map((f) => FolderDto.fromJson(f as Map<String, dynamic>)).toList();
  }

  /// 保存所有文件夹
  Future<void> _saveAllFolders(List<FolderDto> folders) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'folders.json',
      {'folders': folders.map((f) => f.toJson()).toList()},
    );
  }

  // ============ 笔记操作 ============

  @override
  Future<Result<List<NoteDto>>> getNotes({
    String? folderId,
    PaginationParams? pagination,
  }) async {
    try {
      var notes = await _readAllNotes();

      // 按文件夹过滤
      if (folderId != null) {
        notes = notes.where((n) => n.folderId == folderId).toList();
      }

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          notes,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(notes);
    } catch (e) {
      return Result.failure('获取笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto?>> getNoteById(String id) async {
    try {
      final notes = await _readAllNotes();
      final note = notes.where((n) => n.id == id).firstOrNull;
      return Result.success(note);
    } catch (e) {
      return Result.failure('获取笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto>> createNote(NoteDto note) async {
    try {
      final notes = await _readAllNotes();
      notes.add(note);
      await _saveAllNotes(notes);
      return Result.success(note);
    } catch (e) {
      return Result.failure('创建笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto>> updateNote(String id, NoteDto note) async {
    try {
      final notes = await _readAllNotes();
      final index = notes.indexWhere((n) => n.id == id);

      if (index == -1) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      notes[index] = note;
      await _saveAllNotes(notes);
      return Result.success(note);
    } catch (e) {
      return Result.failure('更新笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteNote(String id) async {
    try {
      final notes = await _readAllNotes();
      final initialLength = notes.length;
      notes.removeWhere((n) => n.id == id);

      if (notes.length == initialLength) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      await _saveAllNotes(notes);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto>> moveNote(String id, String? targetFolderId) async {
    try {
      final notes = await _readAllNotes();
      final index = notes.indexWhere((n) => n.id == id);

      if (index == -1) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      final updated = notes[index].copyWith(
        folderId: targetFolderId,
        updatedAt: DateTime.now(),
      );
      notes[index] = updated;
      await _saveAllNotes(notes);
      return Result.success(updated);
    } catch (e) {
      return Result.failure('移动笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NoteDto>>> searchNotes(NoteQuery query) async {
    try {
      var notes = await _readAllNotes();

      // 按文件夹过滤
      if (query.folderId != null) {
        notes = notes.where((n) => n.folderId == query.folderId).toList();
      }

      // 按关键词过滤
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lowerKeyword = query.keyword!.toLowerCase();
        notes = notes.where((n) {
          final title = n.title.toLowerCase();
          final content = n.content.toLowerCase();
          return title.contains(lowerKeyword) || content.contains(lowerKeyword);
        }).toList();
      }

      // 按标签过滤
      if (query.tags != null && query.tags!.isNotEmpty) {
        notes = notes.where((n) {
          return query.tags!.any((tag) => n.tags.contains(tag));
        }).toList();
      }

      // 通用字段查找
      if (query.field != null && query.value != null) {
        notes = notes.where((note) {
          final json = note.toJson();
          final fieldValue = json[query.field]?.toString() ?? '';
          if (query.fuzzy) {
            return fieldValue.toLowerCase().contains(query.value!.toLowerCase());
          }
          return fieldValue == query.value;
        }).toList();
      }

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          notes,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(notes);
    } catch (e) {
      return Result.failure('搜索笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 文件夹操作 ============

  @override
  Future<Result<List<FolderDto>>> getFolders({
    String? parentId,
    PaginationParams? pagination,
  }) async {
    try {
      var folders = await _readAllFolders();

      // 按父文件夹过滤
      if (parentId != null) {
        folders = folders.where((f) => f.parentId == parentId).toList();
      }

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          folders,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(folders);
    } catch (e) {
      return Result.failure('获取文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FolderDto?>> getFolderById(String id) async {
    try {
      final folders = await _readAllFolders();
      final folder = folders.where((f) => f.id == id).firstOrNull;
      return Result.success(folder);
    } catch (e) {
      return Result.failure('获取文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FolderDto>> createFolder(FolderDto folder) async {
    try {
      final folders = await _readAllFolders();
      folders.add(folder);
      await _saveAllFolders(folders);
      return Result.success(folder);
    } catch (e) {
      return Result.failure('创建文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FolderDto>> updateFolder(String id, FolderDto folder) async {
    try {
      final folders = await _readAllFolders();
      final index = folders.indexWhere((f) => f.id == id);

      if (index == -1) {
        return Result.failure('文件夹不存在', code: ErrorCodes.notFound);
      }

      folders[index] = folder;
      await _saveAllFolders(folders);
      return Result.success(folder);
    } catch (e) {
      return Result.failure('更新文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteFolder(String id) async {
    try {
      final folders = await _readAllFolders();
      final initialLength = folders.length;

      // 递归收集要删除的文件夹 ID
      void collectChildIds(String folderId, Set<String> idsToDelete) {
        idsToDelete.add(folderId);
        final children = folders.where((f) => f.parentId == folderId);
        for (final child in children) {
          collectChildIds(child.id, idsToDelete);
        }
      }

      final idsToDelete = <String>{};
      collectChildIds(id, idsToDelete);

      folders.removeWhere((f) => idsToDelete.contains(f.id));

      if (folders.length == initialLength) {
        return Result.failure('文件夹不存在', code: ErrorCodes.notFound);
      }

      await _saveAllFolders(folders);

      // 将被删除文件夹下的笔记移到根目录
      final notes = await _readAllNotes();
      var updated = false;
      final updatedNotes = notes.map((note) {
        if (idsToDelete.contains(note.folderId)) {
          updated = true;
          return note.copyWith(folderId: null);
        }
        return note;
      }).toList();

      if (updated) {
        await _saveAllNotes(updatedNotes);
      }

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NoteDto>>> getFolderNotes(
    String folderId, {
    PaginationParams? pagination,
  }) async {
    return getNotes(folderId: folderId, pagination: pagination);
  }
}
