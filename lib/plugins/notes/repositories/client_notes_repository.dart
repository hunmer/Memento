/// Notes 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 NotesController 来实现 INotesRepository 接口

import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/models/folder.dart';

/// 客户端 Notes Repository 实现
class ClientNotesRepository implements INotesRepository {
  final NotesController controller;

  ClientNotesRepository({
    required this.controller,
  });

  // ============ 笔记操作 ============

  @override
  Future<Result<List<NoteDto>>> getNotes({
    String? folderId,
    PaginationParams? pagination,
  }) async {
    try {
      List<Note> notes;
      if (folderId != null) {
        notes = controller.getFolderNotes(folderId);
      } else {
        notes = controller.searchNotes(query: '');
      }

      final dtos = notes.map(_noteToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto?>> getNoteById(String id) async {
    try {
      final allNotes = controller.searchNotes(query: '');
      final note = allNotes.where((n) => n.id == id).firstOrNull;
      if (note == null) {
        return Result.success(null);
      }
      return Result.success(_noteToDto(note));
    } catch (e) {
      return Result.failure('获取笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto>> createNote(NoteDto dto) async {
    try {
      final note = await controller.createNote(
        dto.title,
        dto.content,
        dto.folderId ?? 'root',
        customId: dto.id,
      );

      // 如果有标签，更新笔记
      if (dto.tags.isNotEmpty) {
        final updatedNote = note.copyWith(tags: dto.tags, updatedAt: DateTime.now());
        await controller.updateNote(updatedNote);
      }

      return Result.success(_noteToDto(note));
    } catch (e) {
      return Result.failure('创建笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto>> updateNote(String id, NoteDto dto) async {
    try {
      // 获取现有笔记
      final allNotes = controller.searchNotes(query: '');
      final existing = allNotes.where((n) => n.id == id).firstOrNull;
      if (existing == null) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      // 更新笔记
      final updated = existing.copyWith(
        title: dto.title,
        content: dto.content,
        tags: dto.tags,
        updatedAt: DateTime.now(),
      );

      await controller.updateNote(updated);
      return Result.success(_noteToDto(updated));
    } catch (e) {
      return Result.failure('更新笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteNote(String id) async {
    try {
      await controller.deleteNote(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<NoteDto>> moveNote(String id, String? targetFolderId) async {
    try {
      final targetId = targetFolderId ?? 'root';
      await controller.moveNote(id, targetId);

      // 获取更新后的笔记
      final allNotes = controller.searchNotes(query: '');
      final note = allNotes.where((n) => n.id == id).firstOrNull;
      if (note == null) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      return Result.success(_noteToDto(note));
    } catch (e) {
      return Result.failure('移动笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<NoteDto>>> searchNotes(NoteQuery query) async {
    try {
      final keyword = query.keyword ?? '';
      final tags = query.tags;
      final pagination = query.pagination;

      final notes = controller.searchNotes(
        query: keyword,
        tags: tags,
        startDate: null,
        endDate: null,
      );

      final dtos = notes.map(_noteToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
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
      final folders = controller.getAllFolders();
      final dtos = folders.map(_folderToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FolderDto?>> getFolderById(String id) async {
    try {
      final folder = controller.getFolder(id);
      if (folder == null) {
        return Result.success(null);
      }
      return Result.success(_folderToDto(folder));
    } catch (e) {
      return Result.failure('获取文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FolderDto>> createFolder(FolderDto dto) async {
    try {
      final folder = await controller.createFolder(
        dto.name,
        dto.parentId,
        customId: dto.id,
      );
      return Result.success(_folderToDto(folder));
    } catch (e) {
      return Result.failure('创建文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FolderDto>> updateFolder(String id, FolderDto dto) async {
    try {
      // 获取现有文件夹
      final existing = controller.getFolder(id);
      if (existing == null) {
        return Result.failure('文件夹不存在', code: ErrorCodes.notFound);
      }

      // 重命名文件夹
      await controller.renameFolder(id, dto.name);

      // 返回更新后的文件夹
      final updated = controller.getFolder(id);
      if (updated == null) {
        return Result.failure('文件夹不存在', code: ErrorCodes.notFound);
      }

      return Result.success(_folderToDto(updated));
    } catch (e) {
      return Result.failure('更新文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteFolder(String id) async {
    try {
      await controller.deleteFolder(id);
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
    try {
      final notes = controller.getFolderNotes(folderId);
      final dtos = notes.map(_noteToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取文件夹笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  NoteDto _noteToDto(Note note) {
    return NoteDto(
      id: note.id,
      title: note.title,
      content: note.content,
      folderId: note.folderId,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isPinned: false, // Note 模型没有 isPinned 字段
      metadata: null, // Note 模型没有 metadata 字段
    );
  }

  FolderDto _folderToDto(Folder folder) {
    return FolderDto(
      id: folder.id,
      name: folder.name,
      parentId: folder.parentId,
      icon: folder.icon.codePoint,
      color: '#${folder.color.value.toRadixString(16).padLeft(8, '0')}',
      createdAt: folder.createdAt,
      updatedAt: folder.updatedAt,
    );
  }
}
