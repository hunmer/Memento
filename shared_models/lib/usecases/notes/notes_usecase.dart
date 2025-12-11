/// Notes 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/notes/notes_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Notes UseCase - 封装所有业务逻辑
class NotesUseCase {
  final INotesRepository repository;
  final Uuid _uuid = const Uuid();

  NotesUseCase(this.repository);

  // ============ 笔记操作 ============

  /// 获取笔记列表
  ///
  /// [params] 可选参数:
  /// - `folderId`: 按文件夹过滤
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getNotes(Map<String, dynamic> params) async {
    try {
      final folderId = params['folderId'] as String?;
      final pagination = _extractPagination(params);
      final result = await repository.getNotes(
        folderId: folderId,
        pagination: pagination,
      );

      return result.map((notes) {
        final jsonList = notes.map((n) => n.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取笔记
  Future<Result<Map<String, dynamic>?>> getNoteById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getNoteById(id);
      return result.map((n) => n?.toJson());
    } catch (e) {
      return Result.failure('获取笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建笔记
  ///
  /// [params] 必需参数:
  /// - `title`: 笔记标题
  /// 可选参数:
  /// - `content`: 笔记内容
  /// - `folderId`: 所属文件夹
  /// - `tags`: 标签列表
  /// - `isPinned`: 是否置顶
  /// - `metadata`: 元数据
  Future<Result<Map<String, dynamic>>> createNote(
      Map<String, dynamic> params) async {
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(titleValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();
      final note = NoteDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        content: params['content'] as String? ?? '',
        folderId: params['folderId'] as String?,
        tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: now,
        updatedAt: now,
        isPinned: params['isPinned'] as bool? ?? false,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.createNote(note);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('创建笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新笔记
  Future<Result<Map<String, dynamic>>> updateNote(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有笔记
      final existingResult = await repository.getNoteById(id);
      if (existingResult.isFailure) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('笔记不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        content: params['content'] as String? ?? existing.content,
        folderId: params.containsKey('folderId')
            ? params['folderId'] as String?
            : existing.folderId,
        tags: params['tags'] != null
            ? (params['tags'] as List<dynamic>).cast<String>()
            : existing.tags,
        isPinned: params['isPinned'] as bool? ?? existing.isPinned,
        metadata:
            params['metadata'] as Map<String, dynamic>? ?? existing.metadata,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateNote(id, updated);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('更新笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除笔记
  Future<Result<bool>> deleteNote(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteNote(id);
    } catch (e) {
      return Result.failure('删除笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 移动笔记到其他文件夹
  Future<Result<Map<String, dynamic>>> moveNote(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final targetFolderId = params['targetFolderId'] as String?;
      final result = await repository.moveNote(id, targetFolderId);
      return result.map((n) => n.toJson());
    } catch (e) {
      return Result.failure('移动笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索笔记
  ///
  /// [params] 可选参数:
  /// - `keyword`: 搜索关键词（标题和内容）
  /// - `tags`: 标签列表（逗号分隔）
  /// - `folderId`: 文件夹过滤
  /// - `offset`: 分页偏移
  /// - `count`: 分页数量
  Future<Result<dynamic>> searchNotes(Map<String, dynamic> params) async {
    try {
      final keyword = params['keyword'] as String?;
      final tagsStr = params['tags'] as String?;
      final tags = tagsStr?.split(',').where((t) => t.isNotEmpty).toList();
      final pagination = _extractPagination(params);

      final query = NoteQuery(
        folderId: params['folderId'] as String?,
        keyword: keyword,
        tags: tags,
        pagination: pagination,
      );

      final result = await repository.searchNotes(query);

      return result.map((notes) {
        final jsonList = notes.map((n) => n.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 文件夹操作 ============

  /// 获取文件夹列表
  Future<Result<dynamic>> getFolders(Map<String, dynamic> params) async {
    try {
      final parentId = params['parentId'] as String?;
      final pagination = _extractPagination(params);
      final result = await repository.getFolders(
        parentId: parentId,
        pagination: pagination,
      );

      return result.map((folders) {
        final jsonList = folders.map((f) => f.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取文件夹
  Future<Result<Map<String, dynamic>?>> getFolderById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getFolderById(id);
      return result.map((f) => f?.toJson());
    } catch (e) {
      return Result.failure('获取文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建文件夹
  ///
  /// [params] 必需参数:
  /// - `name`: 文件夹名称
  /// 可选参数:
  /// - `parentId`: 父文件夹 ID
  /// - `icon`: 图标
  /// - `color`: 颜色
  Future<Result<Map<String, dynamic>>> createFolder(
      Map<String, dynamic> params) async {
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();
      final folder = FolderDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        parentId: params['parentId'] as String?,
        icon: params['icon'] as int?,
        color: params['color'] as String?,
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createFolder(folder);
      return result.map((f) => f.toJson());
    } catch (e) {
      return Result.failure('创建文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新文件夹
  Future<Result<Map<String, dynamic>>> updateFolder(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有文件夹
      final existingResult = await repository.getFolderById(id);
      if (existingResult.isFailure) {
        return Result.failure('文件夹不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('文件夹不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        parentId: params.containsKey('parentId')
            ? params['parentId'] as String?
            : existing.parentId,
        icon: params['icon'] as int? ?? existing.icon,
        color: params['color'] as String? ?? existing.color,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateFolder(id, updated);
      return result.map((f) => f.toJson());
    } catch (e) {
      return Result.failure('更新文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除文件夹
  Future<Result<bool>> deleteFolder(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteFolder(id);
    } catch (e) {
      return Result.failure('删除文件夹失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取文件夹的笔记
  Future<Result<dynamic>> getFolderNotes(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final pagination = _extractPagination(params);
      final result =
          await repository.getFolderNotes(id, pagination: pagination);

      return result.map((notes) {
        final jsonList = notes.map((n) => n.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取文件夹笔记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
