/// Contact 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 联系人 DTO
class ContactDto {
  final String id;
  final String name;
  final String? avatar;
  final int iconCodePoint;
  final int iconColorValue;
  final String phone;
  final String? organization;
  final String? email;
  final String? website;
  final String? address;
  final String? notes;
  final String? gender;
  final List<String> tags;
  final Map<String, String> customFields;
  final List<InteractionRecordDto> customActivityEvents;
  final DateTime createdTime;
  final DateTime lastContactTime;

  const ContactDto({
    required this.id,
    required this.name,
    this.avatar,
    required this.iconCodePoint,
    required this.iconColorValue,
    required this.phone,
    this.organization,
    this.email,
    this.website,
    this.address,
    this.notes,
    this.gender,
    this.tags = const [],
    this.customFields = const {},
    this.customActivityEvents = const [],
    required this.createdTime,
    required this.lastContactTime,
  });

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    return ContactDto(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      iconCodePoint: json['icon'] as int,
      iconColorValue: json['iconColor'] as int,
      phone: json['phone'] as String,
      organization: json['organization'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      gender: json['gender'] as String?,
      tags: List<String>.from(json['tags'] as List),
      customFields: Map<String, String>.from(json['customFields'] as Map),
      customActivityEvents:
          (json['customActivityEvents'] as List<dynamic>? ?? [])
              .map((e) => InteractionRecordDto.fromJson(e as Map<String, dynamic>))
              .toList(),
      createdTime: DateTime.parse(json['createdTime'] as String),
      lastContactTime: DateTime.parse(json['lastContactTime'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'icon': iconCodePoint,
      'iconColor': iconColorValue,
      'phone': phone,
      'organization': organization,
      'email': email,
      'website': website,
      'address': address,
      'notes': notes,
      'gender': gender,
      'tags': tags,
      'customFields': customFields,
      'customActivityEvents':
          customActivityEvents.map((e) => e.toJson()).toList(),
      'createdTime': createdTime.toIso8601String(),
      'lastContactTime': lastContactTime.toIso8601String(),
    };
  }

  ContactDto copyWith({
    String? id,
    String? name,
    String? avatar,
    int? iconCodePoint,
    int? iconColorValue,
    String? phone,
    String? organization,
    String? email,
    String? website,
    String? address,
    String? notes,
    String? gender,
    List<String>? tags,
    Map<String, String>? customFields,
    List<InteractionRecordDto>? customActivityEvents,
    DateTime? lastContactTime,
  }) {
    return ContactDto(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconColorValue: iconColorValue ?? this.iconColorValue,
      phone: phone ?? this.phone,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      tags: tags ?? List.from(this.tags),
      customFields: customFields ?? Map.from(this.customFields),
      customActivityEvents:
          customActivityEvents ?? List.from(this.customActivityEvents),
      createdTime: createdTime,
      lastContactTime: lastContactTime ?? this.lastContactTime,
    );
  }
}

/// 交互记录 DTO
class InteractionRecordDto {
  final String id;
  final String contactId;
  final DateTime date;
  final String notes;
  final List<String> participants;

  const InteractionRecordDto({
    required this.id,
    required this.contactId,
    required this.date,
    required this.notes,
    this.participants = const [],
  });

  factory InteractionRecordDto.fromJson(Map<String, dynamic> json) {
    return InteractionRecordDto(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      participants: List<String>.from(json['participants'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'date': date.toIso8601String(),
      'notes': notes,
      'participants': participants,
    };
  }

  InteractionRecordDto copyWith({
    String? id,
    String? contactId,
    DateTime? date,
    String? notes,
    List<String>? participants,
  }) {
    return InteractionRecordDto(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      participants: participants ?? List<String>.from(this.participants),
    );
  }
}

/// 筛选配置 DTO
class FilterConfigDto {
  final String? nameKeyword;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? uncontactedDays;
  final List<String> selectedTags;

  const FilterConfigDto({
    this.nameKeyword,
    this.startDate,
    this.endDate,
    this.uncontactedDays,
    this.selectedTags = const [],
  });

  factory FilterConfigDto.fromJson(Map<String, dynamic> json) {
    return FilterConfigDto(
      nameKeyword: json['nameKeyword'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String? ?? '')
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String? ?? '')
          : null,
      uncontactedDays: json['uncontactedDays'] as int?,
      selectedTags: List<String>.from(json['selectedTags'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nameKeyword': nameKeyword,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'uncontactedDays': uncontactedDays,
      'selectedTags': selectedTags,
    };
  }
}

enum SortType { name, createdTime, lastContactTime, contactCount }

/// 排序配置 DTO
class SortConfigDto {
  final SortType type;
  final bool isReverse;

  const SortConfigDto({this.type = SortType.name, this.isReverse = false});

  factory SortConfigDto.fromJson(Map<String, dynamic> json) {
    return SortConfigDto(
      type: json['type'] != null
          ? SortType.values[json['type'] as int]
          : SortType.name,
      isReverse: json['isReverse'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type.index, 'isReverse': isReverse};
  }
}

// ============ Query Objects ============

/// 联系人查询参数对象
class ContactQuery {
  final String? nameKeyword;
  final List<String>? tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? uncontactedDays;
  final PaginationParams? pagination;

  const ContactQuery({
    this.nameKeyword,
    this.tags,
    this.startDate,
    this.endDate,
    this.uncontactedDays,
    this.pagination,
  });
}

/// 交互记录查询参数对象
class InteractionRecordQuery {
  final String contactId;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaginationParams? pagination;

  const InteractionRecordQuery({
    required this.contactId,
    this.startDate,
    this.endDate,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Contact 插件 Repository 接口
abstract class IContactRepository {
  // ============ 联系人操作 ============

  /// 获取所有联系人
  Future<Result<List<ContactDto>>> getContacts({PaginationParams? pagination});

  /// 根据 ID 获取联系人
  Future<Result<ContactDto?>> getContactById(String id);

  /// 创建联系人
  Future<Result<ContactDto>> createContact(ContactDto contact);

  /// 更新联系人
  Future<Result<ContactDto>> updateContact(String id, ContactDto contact);

  /// 删除联系人
  Future<Result<bool>> deleteContact(String id);

  /// 搜索联系人
  Future<Result<List<ContactDto>>> searchContacts(ContactQuery query);

  // ============ 交互记录操作 ============

  /// 获取指定联系人的交互记录
  Future<Result<List<InteractionRecordDto>>> getInteractionRecords(
    String contactId, {
    PaginationParams? pagination,
  });

  /// 根据 ID 获取交互记录
  Future<Result<InteractionRecordDto?>> getInteractionRecordById(String id);

  /// 创建交互记录
  Future<Result<InteractionRecordDto>> createInteractionRecord(
    InteractionRecordDto record,
  );

  /// 更新交互记录
  Future<Result<InteractionRecordDto>> updateInteractionRecord(
    String id,
    InteractionRecordDto record,
  );

  /// 删除交互记录
  Future<Result<bool>> deleteInteractionRecord(String id);

  /// 根据联系人 ID 删除所有交互记录
  Future<Result<bool>> deleteInteractionRecordsByContactId(String contactId);

  /// 搜索交互记录
  Future<Result<List<InteractionRecordDto>>> searchInteractionRecords(
    InteractionRecordQuery query,
  );

  // ============ 筛选与排序配置 ============

  /// 获取筛选配置
  Future<Result<FilterConfigDto>> getFilterConfig();

  /// 保存筛选配置
  Future<Result<FilterConfigDto>> saveFilterConfig(FilterConfigDto config);

  /// 获取排序配置
  Future<Result<SortConfigDto>> getSortConfig();

  /// 保存排序配置
  Future<Result<SortConfigDto>> saveSortConfig(SortConfigDto config);

  // ============ 标签管理 ============

  /// 获取所有标签
  Future<Result<List<String>>> getAllTags();

  // ============ 统计操作 ============

  /// 获取最近联系的联系人数量
  Future<Result<int>> getRecentlyContactedCount();

  /// 获取联系人的交互记录数量
  Future<Result<int>> getContactInteractionCount(String contactId);

  /// 获取总联系人数
  Future<Result<int>> getTotalContactCount();
}
