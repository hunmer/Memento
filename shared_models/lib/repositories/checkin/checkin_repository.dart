/// Checkin 插件 - Repository 接口定义
///
/// 定义打卡项目的数据访问抽象接口
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 打卡记录 DTO
class CheckinRecordDto {
  final DateTime startTime;
  final DateTime endTime;
  final DateTime checkinTime;
  final String? note;

  const CheckinRecordDto({
    required this.startTime,
    required this.endTime,
    required this.checkinTime,
    this.note,
  });

  factory CheckinRecordDto.fromJson(Map<String, dynamic> json) {
    return CheckinRecordDto(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      checkinTime: DateTime.parse(json['checkinTime'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'checkinTime': checkinTime.toIso8601String(),
      'note': note,
    };
  }

  CheckinRecordDto copyWith({
    DateTime? startTime,
    DateTime? endTime,
    DateTime? checkinTime,
    String? note,
  }) {
    return CheckinRecordDto(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      checkinTime: checkinTime ?? this.checkinTime,
      note: note ?? this.note,
    );
  }
}

/// 提醒设置 DTO
class ReminderSettingsDto {
  final int type; // 0=weekly, 1=monthly, 2=specific
  final List<int> weekdays; // 0-6 (周日到周六)
  final int? dayOfMonth; // 1-31
  final DateTime? specificDate;
  final int hour; // 0-23
  final int minute; // 0-59

  const ReminderSettingsDto({
    required this.type,
    this.weekdays = const [],
    this.dayOfMonth,
    this.specificDate,
    required this.hour,
    required this.minute,
  });

  factory ReminderSettingsDto.fromJson(Map<String, dynamic> json) {
    return ReminderSettingsDto(
      type: json['type'] as int,
      weekdays: (json['weekdays'] as List<dynamic>?)?.cast<int>() ?? [],
      dayOfMonth: json['dayOfMonth'] as int?,
      specificDate: json['specificDate'] != null
          ? DateTime.parse(json['specificDate'] as String)
          : null,
      hour: (json['timeOfDay'] as Map<String, dynamic>)['hour'] as int,
      minute: (json['timeOfDay'] as Map<String, dynamic>)['minute'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'weekdays': weekdays,
      'dayOfMonth': dayOfMonth,
      'specificDate': specificDate?.toIso8601String(),
      'timeOfDay': <String, dynamic>{
        'hour': hour,
        'minute': minute,
      },
    };
  }

  ReminderSettingsDto copyWith({
    int? type,
    List<int>? weekdays,
    int? dayOfMonth,
    DateTime? specificDate,
    int? hour,
    int? minute,
  }) {
    return ReminderSettingsDto(
      type: type ?? this.type,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      specificDate: specificDate ?? this.specificDate,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

/// 打卡项目 DTO
class CheckinItemDto {
  final String id;
  final String name;
  final int icon; // IconData.codePoint
  final int color; // Color.value
  final String group;
  final String description;
  final int cardStyle; // 0=weekly, 1=small, 2=calendar
  final ReminderSettingsDto? reminderSettings;
  final Map<String, List<CheckinRecordDto>> checkInRecords; // key: yyyy-MM-dd

  const CheckinItemDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.group = '默认分组',
    this.description = '',
    this.cardStyle = 0,
    this.reminderSettings,
    this.checkInRecords = const {},
  });

  factory CheckinItemDto.fromJson(Map<String, dynamic> json) {
    return CheckinItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as int,
      color: json['color'] as int,
      group: json['group'] as String? ?? '默认分组',
      description: json['description'] as String? ?? '',
      cardStyle: json['cardStyle'] as int? ?? 0,
      reminderSettings: json['reminderSettings'] != null
          ? ReminderSettingsDto.fromJson(
              json['reminderSettings'] as Map<String, dynamic>)
          : null,
      checkInRecords:
          (json['checkInRecords'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((r) => CheckinRecordDto.fromJson(r as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'group': group,
      'description': description,
      'cardStyle': cardStyle,
      'reminderSettings': reminderSettings?.toJson(),
      'checkInRecords': checkInRecords.map<String, dynamic>(
        (key, value) => MapEntry(key, value.map((r) => r.toJson()).toList()),
      ),
    };
  }

  CheckinItemDto copyWith({
    String? id,
    String? name,
    int? icon,
    int? color,
    String? group,
    String? description,
    int? cardStyle,
    ReminderSettingsDto? reminderSettings,
    Map<String, List<CheckinRecordDto>>? checkInRecords,
  }) {
    return CheckinItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      group: group ?? this.group,
      description: description ?? this.description,
      cardStyle: cardStyle ?? this.cardStyle,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      checkInRecords: checkInRecords ?? this.checkInRecords,
    );
  }
}

/// 统计信息 DTO
class CheckinStatsDto {
  final int totalCheckins; // 总打卡数
  final int todayCheckins; // 今日打卡数
  final int totalItems; // 打卡项目总数
  final int todayCompletedItems; // 今日已完成项目数
  final double completionRate; // 完成率 0.0-1.0
  final Map<String, int> groupStats; // 按分组统计项目数

  const CheckinStatsDto({
    required this.totalCheckins,
    required this.todayCheckins,
    required this.totalItems,
    required this.todayCompletedItems,
    required this.completionRate,
    required this.groupStats,
  });

  factory CheckinStatsDto.fromJson(Map<String, dynamic> json) {
    return CheckinStatsDto(
      totalCheckins: json['totalCheckins'] as int,
      todayCheckins: json['todayCheckins'] as int,
      totalItems: json['totalItems'] as int,
      todayCompletedItems: json['todayCompletedItems'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      groupStats: (json['groupStats'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'totalCheckins': totalCheckins,
      'todayCheckins': todayCheckins,
      'totalItems': totalItems,
      'todayCompletedItems': todayCompletedItems,
      'completionRate': completionRate,
      'groupStats': groupStats,
    };
  }
}

// ============ Repository Interface ============

/// Checkin Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class ICheckinRepository {
  // ============ 打卡项目操作 ============

  /// 获取所有打卡项目
  Future<Result<List<CheckinItemDto>>> getItems({
    PaginationParams? pagination,
  });

  /// 根据 ID 获取打卡项目
  Future<Result<CheckinItemDto?>> getItemById(String id);

  /// 创建打卡项目
  Future<Result<CheckinItemDto>> createItem(CheckinItemDto item);

  /// 更新打卡项目
  Future<Result<CheckinItemDto>> updateItem(String id, CheckinItemDto item);

  /// 删除打卡项目
  Future<Result<bool>> deleteItem(String id);

  // ============ 打卡记录操作 ============

  /// 添加打卡记录
  Future<Result<CheckinItemDto>> addCheckinRecord(
    String itemId,
    CheckinRecordDto record,
  );

  /// 删除打卡记录（按日期+索引）
  Future<Result<CheckinItemDto>> deleteCheckinRecord(
    String itemId,
    String date, // yyyy-MM-dd
    int recordIndex,
  );

  // ============ 统计信息 ============

  /// 获取统计信息
  Future<Result<CheckinStatsDto>> getStats();
}
