/// Notes 插件 - Repository 接口定义
///
/// 定义笔记和文件夹的数据访问抽象接口
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 笔记 DTO
class NoteDto {
  final String id;
  final String title;
  final String content;
  final String? folderId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final Map<String, dynamic>? metadata;

  const NoteDto({
    required this.id,
    required this.title,
    this.content = '',
    this.folderId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.metadata,
  });

  factory NoteDto.fromJson(Map<String, dynamic> json) {
    return NoteDto(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      folderId: json['folderId'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folderId': folderId,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'metadata': metadata,
    };
  }

  NoteDto copyWith({
    String? id,
    String? title,
    String? content,
    String? folderId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    Map<String, dynamic>? metadata,
  }) {
    return NoteDto(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 文件夹 DTO
class FolderDto {
  final String id;
  final String name;
  final String? parentId;
  final int? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderDto({
    required this.id,
    required this.name,
    this.parentId,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderDto.fromJson(Map<String, dynamic> json) {
    return FolderDto(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      icon: json['icon'] as int?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FolderDto copyWith({
    String? id,
    String? name,
    String? parentId,
    int? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderDto(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============ Query Objects ============

/// 笔记查询参数
class NoteQuery {
  final String? folderId;
  final String? keyword;
  final List<String>? tags;
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const NoteQuery({
    this.folderId,
    this.keyword,
    this.tags,
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = true,
    this.pagination,
  });
}

/// 文件夹查询参数
class FolderQuery {
  final String? parentId;
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const FolderQuery({
    this.parentId,
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = true,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Notes Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class INotesRepository {
  // ============ 笔记操作 ============

  /// 获取所有笔记
  Future<Result<List<NoteDto>>> getNotes({
    String? folderId,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取笔记
  Future<Result<NoteDto?>> getNoteById(String id);

  /// 创建笔记
  Future<Result<NoteDto>> createNote(NoteDto note);

  /// 更新笔记
  Future<Result<NoteDto>> updateNote(String id, NoteDto note);

  /// 删除笔记
  Future<Result<bool>> deleteNote(String id);

  /// 移动笔记到其他文件夹
  Future<Result<NoteDto>> moveNote(String id, String? targetFolderId);

  /// 搜索笔记
  Future<Result<List<NoteDto>>> searchNotes(NoteQuery query);

  // ============ 文件夹操作 ============

  /// 获取所有文件夹
  Future<Result<List<FolderDto>>> getFolders({
    String? parentId,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取文件夹
  Future<Result<FolderDto?>> getFolderById(String id);

  /// 创建文件夹
  Future<Result<FolderDto>> createFolder(FolderDto folder);

  /// 更新文件夹
  Future<Result<FolderDto>> updateFolder(String id, FolderDto folder);

  /// 删除文件夹（递归删除子文件夹）
  Future<Result<bool>> deleteFolder(String id);

  /// 获取文件夹的笔记
  Future<Result<List<NoteDto>>> getFolderNotes(
    String folderId, {
    PaginationParams? pagination,
  });
}
