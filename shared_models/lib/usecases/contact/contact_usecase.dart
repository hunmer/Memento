/// Contact 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/contact/contact_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Contact 插件 UseCase - 封装所有业务逻辑
class ContactUseCase {
  final IContactRepository repository;
  final Uuid _uuid = const Uuid();

  ContactUseCase(this.repository);

  // ============ 联系人 CRUD 操作 ============

  /// 获取联系人列表
  Future<Result<dynamic>> getContacts(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getContacts(pagination: pagination);

      return result.map((contacts) {
        final jsonList = contacts.map((c) => c.toJson()).toList();

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
      return Result.failure('获取联系人列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取联系人
  Future<Result<Map<String, dynamic>?>> getContactById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getContactById(id);
      return result.map((contact) => contact?.toJson());
    } catch (e) {
      return Result.failure('获取联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建联系人
  Future<Result<Map<String, dynamic>>> createContact(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final phoneValidation = ParamValidator.requireString(params, 'phone');
    if (!phoneValidation.isValid) {
      return Result.failure(
        phoneValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final contact = ContactDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        avatar: params['avatar'] as String?,
        iconCodePoint: params['icon'] as int? ?? 0xe7f0,
        iconColorValue: params['iconColor'] as int? ?? 4280391411,
        phone: params['phone'] as String,
        organization: params['organization'] as String?,
        email: params['email'] as String?,
        website: params['website'] as String?,
        address: params['address'] as String?,
        notes: params['notes'] as String?,
        gender: params['gender'] as String?,
        tags: (params['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        customFields: params['customFields'] != null
            ? Map<String, String>.from(params['customFields'] as Map)
            : const {},
        customActivityEvents: (params['customActivityEvents'] as List<dynamic>?)
                ?.map((e) => InteractionRecordDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        createdTime: now,
        lastContactTime: now,
      );

      final result = await repository.createContact(contact);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('创建联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新联系人
  Future<Result<Map<String, dynamic>>> updateContact(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getContactById(id);
      if (existingResult.isFailure) {
        return Result.failure('联系人不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('联系人不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String?,
        avatar: params['avatar'] as String?,
        iconCodePoint: params['icon'] as int?,
        iconColorValue: params['iconColor'] as int?,
        phone: params['phone'] as String?,
        organization: params['organization'] as String?,
        email: params['email'] as String?,
        website: params['website'] as String?,
        address: params['address'] as String?,
        notes: params['notes'] as String?,
        gender: params['gender'] as String?,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                existing.tags
            : existing.tags,
        customFields: params.containsKey('customFields')
            ? Map<String, String>.from(params['customFields'] as Map)
            : existing.customFields,
        customActivityEvents: params.containsKey('customActivityEvents')
            ? (params['customActivityEvents'] as List<dynamic>?)
                    ?.map((e) => InteractionRecordDto.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                existing.customActivityEvents
            : existing.customActivityEvents,
        lastContactTime: params.containsKey('lastContactTime')
            ? DateTime.parse(params['lastContactTime'] as String)
            : existing.lastContactTime,
      );

      final result = await repository.updateContact(id, updated);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('更新联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除联系人
  Future<Result<bool>> deleteContact(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 先删除所有相关的交互记录
      await repository.deleteInteractionRecordsByContactId(id);

      return repository.deleteContact(id);
    } catch (e) {
      return Result.failure('删除联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索联系人
  Future<Result<dynamic>> searchContacts(Map<String, dynamic> params) async {
    try {
      final query = ContactQuery(
        nameKeyword: params['nameKeyword'] as String?,
        tags: params['tags'] != null
            ? List<String>.from(params['tags'] as List)
            : null,
        startDate: params['startDate'] != null
            ? DateTime.parse(params['startDate'] as String)
            : null,
        endDate: params['endDate'] != null
            ? DateTime.parse(params['endDate'] as String)
            : null,
        uncontactedDays: params['uncontactedDays'] as int?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchContacts(query);
      return result.map((contacts) {
        final jsonList = contacts.map((c) => c.toJson()).toList();

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
      return Result.failure('搜索联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 交互记录 CRUD 操作 ============

  /// 获取交互记录列表
  Future<Result<dynamic>> getInteractionRecords(
    Map<String, dynamic> params,
  ) async {
    final contactId = params['contactId'] as String?;
    if (contactId == null || contactId.isEmpty) {
      return Result.failure(
        '缺少必需参数: contactId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final pagination = _extractPagination(params);
      final result =
          await repository.getInteractionRecords(contactId, pagination: pagination);

      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

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
      return Result.failure('获取交互记录列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取交互记录
  Future<Result<Map<String, dynamic>?>> getInteractionRecordById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getInteractionRecordById(id);
      return result.map((record) => record?.toJson());
    } catch (e) {
      return Result.failure('获取交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 创建交互记录
  Future<Result<Map<String, dynamic>>> createInteractionRecord(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final contactIdValidation =
        ParamValidator.requireString(params, 'contactId');
    if (!contactIdValidation.isValid) {
      return Result.failure(
        contactIdValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final notesValidation = ParamValidator.requireString(params, 'notes');
    if (!notesValidation.isValid) {
      return Result.failure(
        notesValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final record = InteractionRecordDto(
        id: params['id'] as String? ?? _uuid.v4(),
        contactId: params['contactId'] as String,
        date: params['date'] != null
            ? DateTime.parse(params['date'] as String)
            : DateTime.now(),
        notes: params['notes'] as String,
        participants: (params['participants'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

      final result = await repository.createInteractionRecord(record);
      return result.map((r) => r.toJson());
    } catch (e) {
      return Result.failure('创建交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 更新交互记录
  Future<Result<Map<String, dynamic>>> updateInteractionRecord(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getInteractionRecordById(id);
      if (existingResult.isFailure) {
        return Result.failure('交互记录不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('交互记录不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        contactId: params['contactId'] as String?,
        date: params['date'] != null
            ? DateTime.parse(params['date'] as String)
            : existing.date,
        notes: params['notes'] as String?,
        participants: params.containsKey('participants')
            ? (params['participants'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                existing.participants
            : existing.participants,
      );

      final result = await repository.updateInteractionRecord(id, updated);
      return result.map((r) => r.toJson());
    } catch (e) {
      return Result.failure('更新交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 删除交互记录
  Future<Result<bool>> deleteInteractionRecord(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteInteractionRecord(id);
    } catch (e) {
      return Result.failure('删除交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 根据联系人 ID 删除所有交互记录
  Future<Result<bool>> deleteInteractionRecordsByContactId(
    Map<String, dynamic> params,
  ) async {
    final contactId = params['contactId'] as String?;
    if (contactId == null || contactId.isEmpty) {
      return Result.failure(
        '缺少必需参数: contactId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.deleteInteractionRecordsByContactId(contactId);
    } catch (e) {
      return Result.failure('删除交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 搜索交互记录
  Future<Result<dynamic>> searchInteractionRecords(
    Map<String, dynamic> params,
  ) async {
    final contactId = params['contactId'] as String?;
    if (contactId == null || contactId.isEmpty) {
      return Result.failure(
        '缺少必需参数: contactId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final query = InteractionRecordQuery(
        contactId: contactId,
        startDate: params['startDate'] != null
            ? DateTime.parse(params['startDate'] as String)
            : null,
        endDate: params['endDate'] != null
            ? DateTime.parse(params['endDate'] as String)
            : null,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchInteractionRecords(query);
      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

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
      return Result.failure('搜索交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 筛选与排序配置 ============

  /// 获取筛选配置
  Future<Result<Map<String, dynamic>>> getFilterConfig(
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await repository.getFilterConfig();
      return result.map((config) => config.toJson());
    } catch (e) {
      return Result.failure('获取筛选配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 保存筛选配置
  Future<Result<Map<String, dynamic>>> saveFilterConfig(
    Map<String, dynamic> params,
  ) async {
    try {
      final config = FilterConfigDto(
        nameKeyword: params['nameKeyword'] as String?,
        startDate: params['startDate'] != null
            ? DateTime.parse(params['startDate'] as String)
            : null,
        endDate: params['endDate'] != null
            ? DateTime.parse(params['endDate'] as String)
            : null,
        uncontactedDays: params['uncontactedDays'] as int?,
        selectedTags: (params['selectedTags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

      final result = await repository.saveFilterConfig(config);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('保存筛选配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 获取排序配置
  Future<Result<Map<String, dynamic>>> getSortConfig(
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await repository.getSortConfig();
      return result.map((config) => config.toJson());
    } catch (e) {
      return Result.failure('获取排序配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 保存排序配置
  Future<Result<Map<String, dynamic>>> saveSortConfig(
    Map<String, dynamic> params,
  ) async {
    try {
      final type = params['type'] as int?;
      final isReverse = params['isReverse'] as bool? ?? false;

      final config = SortConfigDto(
        type: type != null ? SortType.values[type] : SortType.name,
        isReverse: isReverse,
      );

      final result = await repository.saveSortConfig(config);
      return result.map((c) => c.toJson());
    } catch (e) {
      return Result.failure('保存排序配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 标签管理 ============

  /// 获取所有标签
  Future<Result<List<String>>> getAllTags(Map<String, dynamic> params) async {
    try {
      return repository.getAllTags();
    } catch (e) {
      return Result.failure('获取标签列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取最近联系的联系人数量
  Future<Result<int>> getRecentlyContactedCount(
    Map<String, dynamic> params,
  ) async {
    try {
      return repository.getRecentlyContactedCount();
    } catch (e) {
      return Result.failure('获取最近联系人数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 获取联系人的交互记录数量
  Future<Result<int>> getContactInteractionCount(
    Map<String, dynamic> params,
  ) async {
    final contactId = params['contactId'] as String?;
    if (contactId == null || contactId.isEmpty) {
      return Result.failure(
        '缺少必需参数: contactId',
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      return repository.getContactInteractionCount(contactId);
    } catch (e) {
      return Result.failure('获取交互记录数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  /// 获取总联系人数
  Future<Result<int>> getTotalContactCount(
    Map<String, dynamic> params,
  ) async {
    try {
      return repository.getTotalContactCount();
    } catch (e) {
      return Result.failure('获取总联系人数失败: $e',
          code: ErrorCodes.serverError);
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
