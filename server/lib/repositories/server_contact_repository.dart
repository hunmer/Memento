/// Contact 插件 - 服务端 Repository 实现

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class ServerContactRepository implements IContactRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'contact';

  ServerContactRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<ContactDto>> _readAllContacts() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'contacts.json',
    );
    if (data == null) return [];

    final contacts = data['contacts'] as List<dynamic>? ?? [];
    return contacts
        .map((e) => ContactDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllContacts(List<ContactDto> contacts) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'contacts.json',
      {'contacts': contacts.map((c) => c.toJson()).toList()},
    );
  }

  Future<List<InteractionRecordDto>> _readAllInteractionRecords() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'interactions.json',
    );
    if (data == null) return [];

    final records = data['records'] as List<dynamic>? ?? [];
    return records
        .map((e) => InteractionRecordDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAllInteractionRecords(
    List<InteractionRecordDto> records,
  ) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'interactions.json',
      {'records': records.map((r) => r.toJson()).toList()},
    );
  }

  Future<FilterConfigDto> _readFilterConfig() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'filter_config.json',
    );
    if (data == null) return const FilterConfigDto();

    return FilterConfigDto.fromJson(data);
  }

  Future<void> _saveFilterConfig(FilterConfigDto config) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'filter_config.json',
      config.toJson(),
    );
  }

  Future<SortConfigDto> _readSortConfig() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'sort_config.json',
    );
    if (data == null) return const SortConfigDto();

    return SortConfigDto.fromJson(data);
  }

  Future<void> _saveSortConfig(SortConfigDto config) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'sort_config.json',
      config.toJson(),
    );
  }

  // ============ 联系人操作实现 ============

  @override
  Future<Result<List<ContactDto>>> getContacts(
      {PaginationParams? pagination}) async {
    try {
      var contacts = await _readAllContacts();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          contacts,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(contacts);
    } catch (e) {
      return Result.failure('获取联系人列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ContactDto?>> getContactById(String id) async {
    try {
      final contacts = await _readAllContacts();
      final contact = contacts.where((c) => c.id == id).firstOrNull;
      return Result.success(contact);
    } catch (e) {
      return Result.failure('获取联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ContactDto>> createContact(ContactDto contact) async {
    try {
      final contacts = await _readAllContacts();
      contacts.add(contact);
      await _saveAllContacts(contacts);
      return Result.success(contact);
    } catch (e) {
      return Result.failure('创建联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ContactDto>> updateContact(
      String id, ContactDto contact) async {
    try {
      final contacts = await _readAllContacts();
      final index = contacts.indexWhere((c) => c.id == id);

      if (index == -1) {
        return Result.failure('联系人不存在', code: ErrorCodes.notFound);
      }

      contacts[index] = contact;
      await _saveAllContacts(contacts);
      return Result.success(contact);
    } catch (e) {
      return Result.failure('更新联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteContact(String id) async {
    try {
      final contacts = await _readAllContacts();
      final initialLength = contacts.length;
      contacts.removeWhere((c) => c.id == id);

      if (contacts.length == initialLength) {
        return Result.failure('联系人不存在', code: ErrorCodes.notFound);
      }

      await _saveAllContacts(contacts);

      // 同时删除所有相关的交互记录
      await deleteInteractionRecordsByContactId(id);

      return Result.success(true);
    } catch (e) {
      return Result.failure('删除联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ContactDto>>> searchContacts(ContactQuery query) async {
    try {
      var contacts = await _readAllContacts();

      // 姓名关键词筛选
      if (query.nameKeyword != null) {
        final keyword = query.nameKeyword!.toLowerCase();
        contacts = contacts.where((contact) {
          return contact.name.toLowerCase().contains(keyword) ||
              contact.notes?.toLowerCase().contains(keyword) == true ||
              contact.phone.contains(query.nameKeyword!) ||
              contact.organization?.toLowerCase().contains(keyword) == true ||
              contact.email?.toLowerCase().contains(keyword) == true ||
              contact.address?.toLowerCase().contains(keyword) == true ||
              contact.tags.any((tag) => tag.toLowerCase().contains(keyword));
        }).toList();
      }

      // 标签筛选
      if (query.tags != null && query.tags!.isNotEmpty) {
        contacts = contacts.where((contact) {
          return query.tags!.any((tag) => contact.tags.contains(tag));
        }).toList();
      }

      // 创建日期范围筛选
      if (query.startDate != null) {
        contacts = contacts.where((contact) {
          return contact.createdTime.isAfter(query.startDate!) ||
              contact.createdTime.isAtSameMomentAs(query.startDate!);
        }).toList();
      }

      if (query.endDate != null) {
        contacts = contacts.where((contact) {
          return contact.createdTime.isBefore(
            query.endDate!.add(const Duration(days: 1)),
          );
        }).toList();
      }

      // 未联系天数筛选
      if (query.uncontactedDays != null) {
        contacts = contacts.where((contact) {
          final daysSinceLastContact =
              DateTime.now().difference(contact.lastContactTime).inDays;
          return daysSinceLastContact >= query.uncontactedDays!;
        }).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          contacts,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(contacts);
    } catch (e) {
      return Result.failure('搜索联系人失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 交互记录操作实现 ============

  @override
  Future<Result<List<InteractionRecordDto>>> getInteractionRecords(
    String contactId, {
    PaginationParams? pagination,
  }) async {
    try {
      var records = await _readAllInteractionRecords();
      records = records.where((r) => r.contactId == contactId).toList();

      // 按日期倒序排列
      records.sort((a, b) => b.date.compareTo(a.date));

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          records,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(records);
    } catch (e) {
      return Result.failure('获取交互记录列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<InteractionRecordDto?>> getInteractionRecordById(
      String id) async {
    try {
      final records = await _readAllInteractionRecords();
      final record = records.where((r) => r.id == id).firstOrNull;
      return Result.success(record);
    } catch (e) {
      return Result.failure('获取交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<InteractionRecordDto>> createInteractionRecord(
      InteractionRecordDto record) async {
    try {
      final records = await _readAllInteractionRecords();
      records.add(record);
      await _saveAllInteractionRecords(records);

      // 同时更新联系人的最后联系时间
      final contacts = await _readAllContacts();
      final index = contacts.indexWhere((c) => c.id == record.contactId);
      if (index != -1) {
        final updatedContact = contacts[index].copyWith(
          lastContactTime: record.date,
        );
        contacts[index] = updatedContact;
        await _saveAllContacts(contacts);
      }

      return Result.success(record);
    } catch (e) {
      return Result.failure('创建交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<InteractionRecordDto>> updateInteractionRecord(
      String id, InteractionRecordDto record) async {
    try {
      final records = await _readAllInteractionRecords();
      final index = records.indexWhere((r) => r.id == id);

      if (index == -1) {
        return Result.failure('交互记录不存在', code: ErrorCodes.notFound);
      }

      records[index] = record;
      await _saveAllInteractionRecords(records);
      return Result.success(record);
    } catch (e) {
      return Result.failure('更新交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteInteractionRecord(String id) async {
    try {
      final records = await _readAllInteractionRecords();
      final initialLength = records.length;
      records.removeWhere((r) => r.id == id);

      if (records.length == initialLength) {
        return Result.failure('交互记录不存在', code: ErrorCodes.notFound);
      }

      await _saveAllInteractionRecords(records);
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
      final records = await _readAllInteractionRecords();
      final initialLength = records.length;
      records.removeWhere((r) => r.contactId == contactId);

      await _saveAllInteractionRecords(records);
      return Result.success(initialLength != records.length);
    } catch (e) {
      return Result.failure('删除交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<InteractionRecordDto>>> searchInteractionRecords(
      InteractionRecordQuery query) async {
    try {
      var records = await _readAllInteractionRecords();
      records = records.where((r) => r.contactId == query.contactId).toList();

      // 日期范围筛选
      if (query.startDate != null) {
        records = records.where((record) {
          return record.date.isAfter(query.startDate!) ||
              record.date.isAtSameMomentAs(query.startDate!);
        }).toList();
      }

      if (query.endDate != null) {
        records = records.where((record) {
          return record.date.isBefore(
            query.endDate!.add(const Duration(days: 1)),
          );
        }).toList();
      }

      // 按日期倒序排列
      records.sort((a, b) => b.date.compareTo(a.date));

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          records,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(records);
    } catch (e) {
      return Result.failure('搜索交互记录失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 筛选与排序配置实现 ============

  @override
  Future<Result<FilterConfigDto>> getFilterConfig() async {
    try {
      final config = await _readFilterConfig();
      return Result.success(config);
    } catch (e) {
      return Result.failure('获取筛选配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<FilterConfigDto>> saveFilterConfig(
      FilterConfigDto config) async {
    try {
      await _saveFilterConfig(config);
      return Result.success(config);
    } catch (e) {
      return Result.failure('保存筛选配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SortConfigDto>> getSortConfig() async {
    try {
      final config = await _readSortConfig();
      return Result.success(config);
    } catch (e) {
      return Result.failure('获取排序配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<SortConfigDto>> saveSortConfig(SortConfigDto config) async {
    try {
      await _saveSortConfig(config);
      return Result.success(config);
    } catch (e) {
      return Result.failure('保存排序配置失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 标签管理实现 ============

  @override
  Future<Result<List<String>>> getAllTags() async {
    try {
      final contacts = await _readAllContacts();
      final Set<String> tags = {};

      for (final contact in contacts) {
        tags.addAll(contact.tags);
      }

      return Result.success(tags.toList()..sort());
    } catch (e) {
      return Result.failure('获取标签列表失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作实现 ============

  @override
  Future<Result<int>> getRecentlyContactedCount() async {
    try {
      final contacts = await _readAllContacts();
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final count = contacts.where((contact) {
        return contact.lastContactTime.isAfter(thirtyDaysAgo) ||
            contact.lastContactTime.isAtSameMomentAs(thirtyDaysAgo);
      }).length;

      return Result.success(count);
    } catch (e) {
      return Result.failure('获取最近联系人数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getContactInteractionCount(String contactId) async {
    try {
      final records = await _readAllInteractionRecords();
      final count = records.where((r) => r.contactId == contactId).length;
      return Result.success(count);
    } catch (e) {
      return Result.failure('获取交互记录数量失败: $e',
          code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<int>> getTotalContactCount() async {
    try {
      final contacts = await _readAllContacts();
      return Result.success(contacts.length);
    } catch (e) {
      return Result.failure('获取总联系人数失败: $e',
          code: ErrorCodes.serverError);
    }
  }
}
