/// Contact 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 ContactController 来实现 IContactRepository 接口

import 'package:shared_models/repositories/contact/contact_repository.dart' as shared_models;
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/interaction_record_model.dart';
import '../models/filter_sort_config.dart';
import '../controllers/contact_controller.dart';

/// 客户端 Contact Repository 实现
class ClientContactRepository implements IContactRepository {
  final ContactController controller;

  ClientContactRepository({required this.controller});

  // ============ 联系人操作 ============

  @override
  Future<Result<List<ContactDto>>> getContacts({
    PaginationParams? pagination,
  }) async {
    try {
      final contacts = await controller.getAllContacts();
      final dtos = contacts.map(_contactToDto).toList();

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
      return Result.failure('获取联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ContactDto?>> getContactById(String id) async {
    try {
      final contact = await controller.getContact(id);
      if (contact == null) {
        return Result.success(null);
      }
      return Result.success(_contactToDto(contact));
    } catch (e) {
      return Result.failure('获取联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ContactDto>> createContact(ContactDto dto) async {
    try {
      final contact = _dtoToContact(dto);
      final result = await controller.addContact(contact);
      return Result.success(_contactToDto(result));
    } catch (e) {
      return Result.failure('创建联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ContactDto>> updateContact(String id, ContactDto dto) async {
    try {
      final contact = _dtoToContact(dto);
      final result = await controller.updateContact(contact);
      return Result.success(_contactToDto(result));
    } catch (e) {
      return Result.failure('更新联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteContact(String id) async {
    try {
      await controller.deleteContact(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ContactDto>>> searchContacts(ContactQuery query) async {
    try {
      // 获取所有联系人
      final contacts = await controller.getAllContacts();
      final matches = <Contact>[];

      // 应用筛选条件
      for (final contact in contacts) {
        bool isMatch = true;

        // 姓名关键词筛选
        if (query.nameKeyword != null &&
            query.nameKeyword!.isNotEmpty) {
          isMatch = contact.name.toLowerCase().contains(
            query.nameKeyword!.toLowerCase(),
          );
        }

        // 标签筛选
        if (isMatch && query.tags != null && query.tags!.isNotEmpty) {
          isMatch = query.tags!.any((tag) => contact.tags.contains(tag));
        }

        // 创建日期范围筛选
        if (isMatch && query.startDate != null) {
          isMatch = contact.createdTime.isAfter(query.startDate!) ||
              contact.createdTime.isAtSameMomentAs(query.startDate!);
        }
        if (isMatch && query.endDate != null) {
          final endDate = query.endDate!.add(const Duration(days: 1));
          isMatch = contact.createdTime.isBefore(endDate);
        }

        // 未联系天数筛选
        if (isMatch && query.uncontactedDays != null) {
          final daysSinceLastContact =
              DateTime.now().difference(contact.lastContactTime).inDays;
          isMatch = daysSinceLastContact >= query.uncontactedDays!;
        }

        if (isMatch) {
          matches.add(contact);
        }
      }

      final dtos = matches.map(_contactToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 交互记录操作 ============

  @override
  Future<Result<List<InteractionRecordDto>>> getInteractionRecords(
    String contactId, {
    PaginationParams? pagination,
  }) async {
    try {
      final records = await controller.getInteractionsByContactId(contactId);
      final dtos = records.map(_interactionToDto).toList();

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
      return Result.failure('获取交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<InteractionRecordDto?>> getInteractionRecordById(
      String id) async {
    try {
      final interactions = await controller.getAllInteractions();
      final interaction = interactions.where((i) => i.id == id).firstOrNull;
      if (interaction == null) {
        return Result.success(null);
      }
      return Result.success(_interactionToDto(interaction));
    } catch (e) {
      return Result.failure('获取交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<InteractionRecordDto>> createInteractionRecord(
    InteractionRecordDto dto,
  ) async {
    try {
      final record = _dtoToInteraction(dto);
      final result = await controller.addInteraction(record);
      return Result.success(_interactionToDto(result));
    } catch (e) {
      return Result.failure('创建交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<InteractionRecordDto>> updateInteractionRecord(
    String id,
    InteractionRecordDto dto,
  ) async {
    try {
      // 先获取现有记录
      final interactions = await controller.getAllInteractions();
      final existing = interactions.where((i) => i.id == id).firstOrNull;
      if (existing == null) {
        return Result.failure('交互记录不存在', code: ErrorCodes.notFound);
      }

      // 更新记录
      final updated = existing.copyWith(
        contactId: dto.contactId,
        date: dto.date,
        notes: dto.notes,
        participants: dto.participants,
      );

      // 保存更新
      final allInteractions = await controller.getAllInteractions();
      final index = allInteractions.indexWhere((i) => i.id == id);
      if (index != -1) {
        allInteractions[index] = updated;
        await controller.saveAllInteractions(allInteractions);
      }

      return Result.success(_interactionToDto(updated));
    } catch (e) {
      return Result.failure('更新交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteInteractionRecord(String id) async {
    try {
      await controller.deleteInteraction(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteInteractionRecordsByContactId(
      String contactId) async {
    try {
      await controller.deleteInteractionsByContactId(contactId);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<InteractionRecordDto>>> searchInteractionRecords(
    InteractionRecordQuery query,
  ) async {
    try {
      final records = await controller.getInteractionsByContactId(query.contactId);
      final matches = <InteractionRecord>[];

      // 应用筛选条件
      for (final record in records) {
        bool isMatch = true;

        // 日期范围筛选
        if (isMatch && query.startDate != null) {
          isMatch = record.date.isAfter(query.startDate!) ||
              record.date.isAtSameMomentAs(query.startDate!);
        }
        if (isMatch && query.endDate != null) {
          final endDate = query.endDate!.add(const Duration(days: 1));
          isMatch = record.date.isBefore(endDate);
        }

        if (isMatch) {
          matches.add(record);
        }
      }

      final dtos = matches.map(_interactionToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 筛选与排序配置 ============

  @override
  Future<Result<FilterConfigDto>> getFilterConfig() async {
    try {
      final config = await controller.getFilterConfig();
      return Result.success(_filterConfigToDto(config));
    } catch (e) {
      return Result.failure('获取筛选配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FilterConfigDto>> saveFilterConfig(
      FilterConfigDto config) async {
    try {
      final filterConfig = _dtoToFilterConfig(config);
      await controller.saveFilterConfig(filterConfig);
      return Result.success(config);
    } catch (e) {
      return Result.failure('保存筛选配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SortConfigDto>> getSortConfig() async {
    try {
      final config = await controller.getSortConfig();
      return Result.success(_sortConfigToDto(config));
    } catch (e) {
      return Result.failure('获取排序配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SortConfigDto>> saveSortConfig(SortConfigDto config) async {
    try {
      final sortConfig = _dtoToSortConfig(config);
      await controller.saveSortConfig(sortConfig);
      return Result.success(config);
    } catch (e) {
      return Result.failure('保存排序配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 标签管理 ============

  @override
  Future<Result<List<String>>> getAllTags() async {
    try {
      final tags = await controller.getAllTags();
      return Result.success(tags);
    } catch (e) {
      return Result.failure('获取标签列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<int>> getRecentlyContactedCount() async {
    try {
      final count = await controller.getRecentlyContactedCount();
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取最近联系人数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getContactInteractionCount(String contactId) async {
    try {
      final count = await controller.getContactInteractionsCount(contactId);
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取交互记录数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getTotalContactCount() async {
    try {
      final contacts = await controller.getAllContacts();
      return Result.success(contacts.length);
    } catch (e) {
      return Result.failure('获取总联系人数失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  ContactDto _contactToDto(Contact contact) {
    return ContactDto(
      id: contact.id,
      name: contact.name,
      avatar: contact.avatar,
      iconCodePoint: contact.icon.codePoint,
      iconColorValue: contact.iconColor.value,
      phone: contact.phone,
      organization: contact.organization,
      email: contact.email,
      website: contact.website,
      address: contact.address,
      notes: contact.notes,
      gender: contact.gender?.name,
      tags: List<String>.from(contact.tags),
      customFields: Map<String, String>.from(contact.customFields),
      customActivityEvents: [], // CustomActivityEvent 与 InteractionRecordDto 不兼容，暂不转换
      createdTime: contact.createdTime,
      lastContactTime: contact.lastContactTime,
    );
  }

  Contact _dtoToContact(ContactDto dto) {
    return Contact(
      id: dto.id,
      name: dto.name,
      avatar: dto.avatar,
      icon: IconData(dto.iconCodePoint, fontFamily: 'MaterialIcons'),
      iconColor: Color(dto.iconColorValue),
      phone: dto.phone,
      organization: dto.organization,
      email: dto.email,
      website: dto.website,
      address: dto.address,
      notes: dto.notes,
      gender: dto.gender != null
          ? ContactGender.values.firstWhere(
              (e) => e.name == dto.gender,
              orElse: () => ContactGender.other,
            )
          : null,
      tags: List<String>.from(dto.tags),
      customFields: Map<String, String>.from(dto.customFields),
      customActivityEvents: [], // InteractionRecordDto 与 CustomActivityEvent 不兼容，暂不转换
      createdTime: dto.createdTime,
      lastContactTime: dto.lastContactTime,
    );
  }

  InteractionRecordDto _interactionToDto(InteractionRecord record) {
    return InteractionRecordDto(
      id: record.id,
      contactId: record.contactId,
      date: record.date,
      notes: record.notes,
      participants: List<String>.from(record.participants),
    );
  }

  InteractionRecord _dtoToInteraction(InteractionRecordDto dto) {
    return InteractionRecord(
      id: dto.id,
      contactId: dto.contactId,
      date: dto.date,
      notes: dto.notes,
      participants: List<String>.from(dto.participants),
    );
  }

  FilterConfigDto _filterConfigToDto(FilterConfig config) {
    return FilterConfigDto(
      nameKeyword: config.nameKeyword,
      startDate: config.startDate,
      endDate: config.endDate,
      uncontactedDays: config.uncontactedDays,
      selectedTags: List<String>.from(config.selectedTags),
    );
  }

  FilterConfig _dtoToFilterConfig(FilterConfigDto dto) {
    return FilterConfig(
      nameKeyword: dto.nameKeyword,
      startDate: dto.startDate,
      endDate: dto.endDate,
      uncontactedDays: dto.uncontactedDays,
      selectedTags: List<String>.from(dto.selectedTags),
    );
  }

  SortConfigDto _sortConfigToDto(SortConfig config) {
    // 需要将本地 SortType 转换为共享的 SortType
    final typeMap = {
      SortType.name: shared_models.SortType.name,
      SortType.createdTime: shared_models.SortType.createdTime,
      SortType.lastContactTime: shared_models.SortType.lastContactTime,
      SortType.contactCount: shared_models.SortType.contactCount,
    };

    return SortConfigDto(
      type: typeMap[config.type] ?? shared_models.SortType.name,
      isReverse: config.isReverse,
    );
  }

  SortConfig _dtoToSortConfig(SortConfigDto dto) {
    // 需要将共享的 SortType 转换为本地的 SortType
    final typeMap = {
      shared_models.SortType.name: SortType.name,
      shared_models.SortType.createdTime: SortType.createdTime,
      shared_models.SortType.lastContactTime: SortType.lastContactTime,
      shared_models.SortType.contactCount: SortType.contactCount,
    };

    return SortConfig(
      type: typeMap[dto.type] ?? SortType.name,
      isReverse: dto.isReverse,
    );
  }
}

/// 扩展方法：获取列表中的第一个元素或 null
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
