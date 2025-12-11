/// Calendar Album 插件 - UseCase 业务逻辑层
library;

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/calendar_album/calendar_album_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Calendar Album 插件 UseCase - 封装所有业务逻辑
class CalendarAlbumUseCase {
  final ICalendarAlbumRepository repository;
  final Uuid _uuid = const Uuid();

  CalendarAlbumUseCase(this.repository);

  // ============ 日记 CRUD 操作 ============

  /// 获取所有日记
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getEntries(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getEntries(pagination: pagination);

      return result.map((entries) {
        final jsonList = entries.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取日记列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取日记
  Future<Result<Map<String, dynamic>?>> getEntryById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getEntryById(id);
      return result.map((entry) => entry?.toJson());
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据日期获取日记
  Future<Result<dynamic>> getEntriesByDate(Map<String, dynamic> params) async {
    final dateStr = params['date'] as String?;
    if (dateStr == null || dateStr.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      final date = DateTime.parse(dateStr);
      final pagination = _extractPagination(params);
      final result = await repository.getEntriesByDate(
        date,
        pagination: pagination,
      );

      return result.map((entries) {
        final jsonList = entries.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('根据日期获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据标签获取日记
  Future<Result<dynamic>> getEntriesByTag(Map<String, dynamic> params) async {
    final tag = params['tag'] as String?;
    if (tag == null || tag.isEmpty) {
      return Result.failure('缺少必需参数: tag', code: ErrorCodes.invalidParams);
    }

    try {
      final pagination = _extractPagination(params);
      final result = await repository.getEntriesByTag(
        tag,
        pagination: pagination,
      );

      return result.map((entries) {
        final jsonList = entries.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('根据标签获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据多标签获取日记
  Future<Result<dynamic>> getEntriesByTags(Map<String, dynamic> params) async {
    final tags = params['tags'] as List<dynamic>?;
    if (tags == null || tags.isEmpty) {
      return Result.failure('缺少必需参数: tags', code: ErrorCodes.invalidParams);
    }

    try {
      final tagList = tags.map((e) => e as String).toList();
      final pagination = _extractPagination(params);
      final result = await repository.getEntriesByTags(
        tagList,
        pagination: pagination,
      );

      return result.map((entries) {
        final jsonList = entries.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('根据多标签获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索日记
  Future<Result<dynamic>> searchEntries(Map<String, dynamic> params) async {
    try {
      final query = CalendarAlbumEntryQuery(
        date: params['date'] != null
            ? DateTime.parse(params['date'] as String)
            : null,
        tags: params['tags'] is List<dynamic>
            ? (params['tags'] as List<dynamic>).map((e) => e as String).toList()
            : null,
        keyword: params['keyword'] as String?,
        tagKeyword: params['tagKeyword'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchEntries(query);
      return result.map((entries) {
        final jsonList = entries.map((e) => e.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建日记
  ///
  /// [params] 必需参数:
  /// - `title`: 标题
  /// - `content`: 内容
  /// - `createdAt`: 创建时间
  Future<Result<Map<String, dynamic>>> createEntry(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final contentValidation = ParamValidator.requireString(params, 'content');
    if (!contentValidation.isValid) {
      return Result.failure(
        contentValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final createdAtStr = params['createdAt'] as String?;
    if (createdAtStr == null || createdAtStr.isEmpty) {
      return Result.failure('缺少必需参数: createdAt',
          code: ErrorCodes.invalidParams);
    }

    try {
      final createdAt = DateTime.parse(createdAtStr);
      final now = DateTime.now();

      final entry = CalendarAlbumEntryDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        content: params['content'] as String,
        createdAt: createdAt,
        updatedAt: now,
        tags: params['tags'] is List<dynamic>
            ? (params['tags'] as List<dynamic>).map((e) => e as String).toList()
            : const [],
        location: params['location'] as String?,
        mood: params['mood'] as String?,
        weather: params['weather'] as String?,
        imageUrls: params['imageUrls'] is List<dynamic>
            ? (params['imageUrls'] as List<dynamic>)
                .map((e) => e as String)
                .toList()
            : const [],
        thumbUrls: params['thumbUrls'] is List<dynamic>
            ? (params['thumbUrls'] as List<dynamic>)
                .map((e) => e as String)
                .toList()
            : const [],
      );

      final result = await repository.createEntry(entry);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('创建日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新日记
  Future<Result<Map<String, dynamic>>> updateEntry(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getEntryById(id);
      if (existingResult.isFailure) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String?,
        content: params['content'] as String?,
        tags: params['tags'] is List<dynamic>
            ? (params['tags'] as List<dynamic>).map((e) => e as String).toList()
            : null,
        location: params['location'] as String?,
        mood: params['mood'] as String?,
        weather: params['weather'] as String?,
        imageUrls: params['imageUrls'] is List<dynamic>
            ? (params['imageUrls'] as List<dynamic>)
                .map((e) => e as String)
                .toList()
            : null,
        thumbUrls: params['thumbUrls'] is List<dynamic>
            ? (params['thumbUrls'] as List<dynamic>)
                .map((e) => e as String)
                .toList()
            : null,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateEntry(id, updated);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除日记
  Future<Result<bool>> deleteEntry(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteEntry(id);
    } catch (e) {
      return Result.failure('删除日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 标签管理 ============

  /// 获取标签组
  Future<Result<dynamic>> getTagGroups(Map<String, dynamic> params) async {
    try {
      final result = await repository.getTagGroups();
      return result.map((groups) => groups.map((g) => g.toJson()).toList());
    } catch (e) {
      return Result.failure('获取标签组失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新标签组
  Future<Result<dynamic>> updateTagGroups(Map<String, dynamic> params) async {
    final tagGroupsJson = params['tagGroups'] as List<dynamic>?;
    if (tagGroupsJson == null || tagGroupsJson.isEmpty) {
      return Result.failure('缺少必需参数: tagGroups',
          code: ErrorCodes.invalidParams);
    }

    try {
      final tagGroups = tagGroupsJson
          .map((e) =>
              CalendarAlbumTagGroupDto.fromJson(e as Map<String, dynamic>))
          .toList();

      final result = await repository.updateTagGroups(tagGroups);
      return result.map((groups) => groups.map((g) => g.toJson()).toList());
    } catch (e) {
      return Result.failure('更新标签组失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 添加标签
  Future<Result<Map<String, dynamic>>> addTag(
      Map<String, dynamic> params) async {
    final tag = params['tag'] as String?;
    if (tag == null || tag.isEmpty) {
      return Result.failure('缺少必需参数: tag', code: ErrorCodes.invalidParams);
    }

    try {
      final groupName = params['groupName'] as String?;
      final result = await repository.addTag(tag, groupName: groupName);
      return result.map((g) => g.toJson());
    } catch (e) {
      return Result.failure('添加标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除标签
  Future<Result<bool>> deleteTag(Map<String, dynamic> params) async {
    final tag = params['tag'] as String?;
    if (tag == null || tag.isEmpty) {
      return Result.failure('缺少必需参数: tag', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteTag(tag);
    } catch (e) {
      return Result.failure('删除标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取标签列表
  Future<Result<dynamic>> getTags(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final query = CalendarAlbumTagQuery(
        keyword: params['keyword'] as String?,
        pagination: pagination,
      );

      final result = await repository.getTags(query);
      return result.map((tags) {
        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            tags,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return tags;
      });
    } catch (e) {
      return Result.failure('获取标签列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索标签
  Future<Result<dynamic>> searchTags(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final query = CalendarAlbumTagQuery(
        keyword: params['keyword'] as String?,
        pagination: pagination,
      );

      final result = await repository.searchTags(query);
      return result.map((tags) {
        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            tags,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return tags;
      });
    } catch (e) {
      return Result.failure('搜索标签失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 图片相关 ============

  /// 获取所有图片
  Future<Result<dynamic>> getAllImages(Map<String, dynamic> params) async {
    try {
      final result = await repository.getAllImages();
      return result.map((images) => images);
    } catch (e) {
      return Result.failure('获取图片列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据图片URL获取日记
  Future<Result<Map<String, dynamic>?>> getEntryByImageUrl(
    Map<String, dynamic> params,
  ) async {
    final imageUrl = params['imageUrl'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Result.failure('缺少必需参数: imageUrl', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getEntryByImageUrl(imageUrl);
      return result.map((entry) => entry?.toJson());
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计功能 ============

  /// 获取统计信息
  Future<Result<Map<String, dynamic>>> getStats(
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await repository.getStats();
      return result.map((stats) => stats.toJson());
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
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
