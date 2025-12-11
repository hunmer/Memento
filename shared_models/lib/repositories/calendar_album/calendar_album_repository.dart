/// Calendar Album 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 日记条目 DTO
class CalendarAlbumEntryDto {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? location;
  final String? mood;
  final String? weather;
  final List<String> imageUrls;
  final List<String> thumbUrls;

  const CalendarAlbumEntryDto({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.location,
    this.mood,
    this.weather,
    this.imageUrls = const [],
    this.thumbUrls = const [],
  });

  /// 从 JSON 构造
  factory CalendarAlbumEntryDto.fromJson(Map<String, dynamic> json) {
    return CalendarAlbumEntryDto(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      location: json['location'] as String?,
      mood: json['mood'] as String?,
      weather: json['weather'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      thumbUrls: (json['thumbUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'location': location,
      'mood': mood,
      'weather': weather,
      'imageUrls': imageUrls,
      'thumbUrls': thumbUrls,
    };
  }

  /// 复制并修改
  CalendarAlbumEntryDto copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? location,
    String? mood,
    String? weather,
    List<String>? imageUrls,
    List<String>? thumbUrls,
  }) {
    return CalendarAlbumEntryDto(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      imageUrls: imageUrls ?? this.imageUrls,
      thumbUrls: thumbUrls ?? this.thumbUrls,
    );
  }
}

/// 标签组 DTO
class CalendarAlbumTagGroupDto {
  final String name;
  final List<String> tags;

  const CalendarAlbumTagGroupDto({
    required this.name,
    required this.tags,
  });

  factory CalendarAlbumTagGroupDto.fromJson(Map<String, dynamic> json) {
    return CalendarAlbumTagGroupDto(
      name: json['name'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tags': tags,
    };
  }

  CalendarAlbumTagGroupDto copyWith({
    String? name,
    List<String>? tags,
  }) {
    return CalendarAlbumTagGroupDto(
      name: name ?? this.name,
      tags: tags ?? this.tags,
    );
  }
}

/// 统计信息 DTO
class CalendarAlbumStatsDto {
  final int todayEntries;
  final int last7DaysEntries;
  final int allEntries;
  final int tagsCount;

  const CalendarAlbumStatsDto({
    required this.todayEntries,
    required this.last7DaysEntries,
    required this.allEntries,
    required this.tagsCount,
  });

  factory CalendarAlbumStatsDto.fromJson(Map<String, dynamic> json) {
    return CalendarAlbumStatsDto(
      todayEntries: json['todayEntries'] as int,
      last7DaysEntries: json['last7DaysEntries'] as int,
      allEntries: json['allEntries'] as int,
      tagsCount: json['tagsCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayEntries': todayEntries,
      'last7DaysEntries': last7DaysEntries,
      'allEntries': allEntries,
      'tagsCount': tagsCount,
    };
  }

  CalendarAlbumStatsDto copyWith({
    int? todayEntries,
    int? last7DaysEntries,
    int? allEntries,
    int? tagsCount,
  }) {
    return CalendarAlbumStatsDto(
      todayEntries: todayEntries ?? this.todayEntries,
      last7DaysEntries: last7DaysEntries ?? this.last7DaysEntries,
      allEntries: allEntries ?? this.allEntries,
      tagsCount: tagsCount ?? this.tagsCount,
    );
  }
}

// ============ Query Objects ============

/// 日记查询参数对象
class CalendarAlbumEntryQuery {
  final DateTime? date;
  final List<String>? tags;
  final String? keyword;
  final String? tagKeyword;
  final PaginationParams? pagination;

  const CalendarAlbumEntryQuery({
    this.date,
    this.tags,
    this.keyword,
    this.tagKeyword,
    this.pagination,
  });
}

/// 标签查询参数对象
class CalendarAlbumTagQuery {
  final String? keyword;
  final PaginationParams? pagination;

  const CalendarAlbumTagQuery({
    this.keyword,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Calendar Album 插件 Repository 接口
abstract class ICalendarAlbumRepository {
  // ============ 日记 CRUD 操作 ============

  /// 获取所有日记
  Future<Result<List<CalendarAlbumEntryDto>>> getEntries(
      {PaginationParams? pagination});

  /// 根据 ID 获取日记
  Future<Result<CalendarAlbumEntryDto?>> getEntryById(String id);

  /// 根据日期获取日记
  Future<Result<List<CalendarAlbumEntryDto>>> getEntriesByDate(
    DateTime date, {
    PaginationParams? pagination,
  });

  /// 根据标签获取日记
  Future<Result<List<CalendarAlbumEntryDto>>> getEntriesByTag(
    String tag, {
    PaginationParams? pagination,
  });

  /// 根据多标签获取日记（AND逻辑）
  Future<Result<List<CalendarAlbumEntryDto>>> getEntriesByTags(
    List<String> tags, {
    PaginationParams? pagination,
  });

  /// 搜索日记
  Future<Result<List<CalendarAlbumEntryDto>>> searchEntries(
    CalendarAlbumEntryQuery query,
  );

  /// 创建日记
  Future<Result<CalendarAlbumEntryDto>> createEntry(
    CalendarAlbumEntryDto entry,
  );

  /// 更新日记
  Future<Result<CalendarAlbumEntryDto>> updateEntry(
    String id,
    CalendarAlbumEntryDto entry,
  );

  /// 删除日记
  Future<Result<bool>> deleteEntry(String id);

  // ============ 标签管理 ============

  /// 获取所有标签组
  Future<Result<List<CalendarAlbumTagGroupDto>>> getTagGroups();

  /// 更新标签组
  Future<Result<List<CalendarAlbumTagGroupDto>>> updateTagGroups(
    List<CalendarAlbumTagGroupDto> tagGroups,
  );

  /// 添加标签
  Future<Result<CalendarAlbumTagGroupDto>> addTag(
    String tag, {
    String? groupName,
  });

  /// 删除标签
  Future<Result<bool>> deleteTag(String tag);

  /// 获取所有标签
  Future<Result<List<String>>> getTags(CalendarAlbumTagQuery query);

  /// 搜索标签
  Future<Result<List<String>>> searchTags(CalendarAlbumTagQuery query);

  // ============ 图片相关 ============

  /// 获取所有图片URL
  Future<Result<List<String>>> getAllImages();

  /// 根据图片URL获取对应的日记
  Future<Result<CalendarAlbumEntryDto?>> getEntryByImageUrl(
    String imageUrl,
  );

  // ============ 统计功能 ============

  /// 获取统计信息
  Future<Result<CalendarAlbumStatsDto>> getStats();
}
