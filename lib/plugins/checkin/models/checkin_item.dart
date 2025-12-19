import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:shared_models/shared_models.dart';

enum CheckinCardStyle {
  weekly,
  small,
  calendar,
}

class CheckinItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  String group;
  String description;
  List<bool> frequency;
  // 提醒设置
  ReminderSettings? reminderSettings;
  // 卡片显示风格
  CheckinCardStyle cardStyle;
  // 打卡记录，包含时间范围和备注，key为yyyy-MM-dd格式的日期字符串
  final Map<String, List<CheckinRecord>> checkInRecords;

  CheckinItem({
    String? id,
    required this.name,
    required this.icon,
    Color? color,
    String? group,
    String? description,
    List<bool>? frequency,
    this.reminderSettings,
    this.cardStyle = CheckinCardStyle.weekly,
    Map<String, List<CheckinRecord>>? checkInRecords,
  }) : id = id ?? const Uuid().v4(),
       color = color ?? Colors.blue,
       group = group ?? '默认分组',
       description = description ?? '',
       frequency = frequency ?? List.filled(7, true),
       checkInRecords = checkInRecords ?? {};

  // 将DateTime转换为yyyy-MM-dd格式的字符串
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 将yyyy-MM-dd格式的字符串转换为DateTime
  DateTime _stringToDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // 检查今天是否已打卡
  bool isCheckedToday() {
    final today = DateTime.now();
    final todayStr = _dateToString(today);
    return checkInRecords.containsKey(todayStr) && checkInRecords[todayStr]!.isNotEmpty;
  }

  // 获取最后一次打卡日期
  DateTime? get lastCheckinDate {
    if (checkInRecords.isEmpty) return null;
    final lastDateStr = checkInRecords.keys
        .reduce((a, b) => _stringToDate(a).isAfter(_stringToDate(b)) ? a : b);
    return _stringToDate(lastDateStr);
  }

  // 获取今天的打卡记录列表
  List<CheckinRecord> getTodayRecords() {
    final today = DateTime.now();
    final todayStr = _dateToString(today);
    return checkInRecords[todayStr]?.toList() ?? [];
  }

  // 获取指定日期的打卡记录列表
  List<CheckinRecord> getDateRecords(DateTime date) {
    final dateStr = _dateToString(date);
    final records = checkInRecords[dateStr]?.toList() ?? [];
    return records..sort((a, b) => b.checkinTime.compareTo(a.checkinTime));
  }

  // 添加打卡记录
  Future<void> addCheckinRecord(CheckinRecord record) async {
    try {
      // 通过 UseCase 保存到数据库
      final result = await CheckinPlugin.instance.checkinUseCase.addCheckinRecord({
        'itemId': id,
        'startTime': record.startTime.toIso8601String(),
        'endTime': record.endTime.toIso8601String(),
        'checkinTime': record.checkinTime.toIso8601String(),
        'note': record.note,
      });

      if (result.isSuccess) {
        // 保存成功后，重新加载数据以确保本地和数据库一致
        await CheckinPlugin.shared.triggerSave();
      } else {
        final error = result.errorOrNull;
        final message = error != null ? error.message : '添加打卡记录失败';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('添加打卡记录失败: $e');
    }
  }

  // 取消打卡
  Future<void> cancelCheckinRecord(DateTime recordTime, {int? recordIndex}) async {
    final dateStr = _dateToString(recordTime);
    int? indexToDelete = recordIndex;

    // 如果没有提供索引，找到第一个匹配的记录
    if (indexToDelete == null && checkInRecords.containsKey(dateStr)) {
      indexToDelete = checkInRecords[dateStr]!.indexWhere(
        (record) => record.checkinTime.isAtSameMomentAs(recordTime)
      );
    }

    if (indexToDelete != null && indexToDelete >= 0) {
      try {
        // 通过 UseCase 删除记录
        final result = await CheckinPlugin.instance.checkinUseCase.deleteCheckinRecord({
          'itemId': id,
          'date': dateStr,
          'recordIndex': indexToDelete,
        });

        if (result.isSuccess) {
          // 删除成功后，重新加载数据
          await CheckinPlugin.shared.triggerSave();
        } else {
          final error = result.errorOrNull;
          final message = error != null ? error.message : '删除打卡记录失败';
          throw Exception(message);
        }
      } catch (e) {
        throw Exception('删除打卡记录失败: $e');
      }
    }
  }

  // 获取指定月份的打卡记录
  Map<DateTime, List<CheckinRecord>> getMonthlyRecords(int year, int month) {
    final result = <DateTime, List<CheckinRecord>>{};
    checkInRecords.forEach((dateStr, records) {
      final date = _stringToDate(dateStr);
      if (date.year == year && date.month == month) {
        result[date] = records;
      }
    });
    return result;
  }

  // 获取连续打卡天数
  int getConsecutiveDays() {
    int consecutiveDays = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 365; i++) {
      final date = todayDate.subtract(Duration(days: i));
      final dateStr = _dateToString(date);
      
      if (checkInRecords.containsKey(dateStr) && checkInRecords[dateStr]!.isNotEmpty) {
        consecutiveDays++;
      } else {
        break;
      }
    }

    return consecutiveDays;
  }

  // 重置所有打卡记录
  Future<void> resetRecords() async {
    try {
      // 通过 UseCase 更新项目，清空所有打卡记录
      final updatedCheckInRecords = <String, List<CheckinRecordDto>>{};

      // 转换为 DTO 格式（空地图）
      final result = await CheckinPlugin.instance.checkinUseCase.updateItem({
        'id': id,
        'checkInRecords': updatedCheckInRecords,
      });

      if (result.isSuccess) {
        // 更新成功后，重新加载数据
        await CheckinPlugin.shared.triggerSave();
      } else {
        final error = result.errorOrNull;
        final message = error != null ? error.message : '重置打卡记录失败';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('重置打卡记录失败: $e');
    }
  }

  // 将对象转换为可序列化的Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      // ignore: deprecated_member_use
      'color': color.value,
      'group': group,
      'cardStyle': cardStyle.index,
      'reminderSettings': reminderSettings?.toJson(),
      'checkInRecords': checkInRecords.map(
        (key, value) => MapEntry(key, value.map((record) => record.toJson()).toList()),
      ),
    };
  }

  // 预定义常用Material图标常量
  static const Map<int, IconData> materialIcons = {
    0xe3a9: Icons.check, // check图标
    0xe5ca: Icons.arrow_back, // arrow_back图标
    0xe5cd: Icons.arrow_forward, // arrow_forward图标
    0xe7fd: Icons.person, // person图标
    0xe0be: Icons.home, // home图标
  };

  // 从Map创建对象
  factory CheckinItem.fromJson(Map<String, dynamic> json) {
    // 尝试从预定义的MaterialIcons常量中查找图标
    IconData icon;
    final iconCodePoint = json['icon'] as int;
    if (materialIcons.containsKey(iconCodePoint)) {
      icon = materialIcons[iconCodePoint]!;
    } else {
      // 如果不在预定义列表中，直接创建IconData
      icon = IconData(
        iconCodePoint,
        fontFamily: 'MaterialIcons',
      );
    }

    return CheckinItem(
      id: json['id'],
      name: json['name'],
      icon: icon,
      color: Color(json['color']),
      group: json['group'] ?? '默认分组',
      cardStyle: json['cardStyle'] != null
          ? CheckinCardStyle.values[json['cardStyle'] as int]
          : CheckinCardStyle.weekly,
      reminderSettings: json['reminderSettings'] != null
          ? ReminderSettings.fromJson(json['reminderSettings'])
          : null,
      checkInRecords: (json['checkInRecords'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((recordJson) => CheckinRecord.fromJson(recordJson as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }
}

// 提醒设置类
class ReminderSettings {
  final ReminderType type;
  final List<int> weekdays; // 用于周提醒，0-6 表示周日到周六
  final int? dayOfMonth; // 用于月提醒，1-31
  final DateTime? specificDate; // 用于特定日期提醒
  final TimeOfDay timeOfDay; // 提醒时间

  ReminderSettings({
    required this.type,
    this.weekdays = const [],
    this.dayOfMonth,
    this.specificDate,
    required this.timeOfDay,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'weekdays': weekdays,
      'dayOfMonth': dayOfMonth,
      'specificDate': specificDate?.toIso8601String(),
      'timeOfDay': {
        'hour': timeOfDay.hour,
        'minute': timeOfDay.minute,
      },
    };
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      type: ReminderType.values[json['type'] as int],
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
      dayOfMonth: json['dayOfMonth'] as int?,
      specificDate: json['specificDate'] != null
          ? DateTime.parse(json['specificDate'] as String)
          : null,
      timeOfDay: TimeOfDay(
        hour: (json['timeOfDay'] as Map<String, dynamic>)['hour'] as int,
        minute: (json['timeOfDay'] as Map<String, dynamic>)['minute'] as int,
      ),
    );
  }
}

// 提醒类型枚举
enum ReminderType {
  weekly, // 每周特定日期提醒
  monthly, // 每月特定日期提醒
  specific, // 特定日期提醒
}

// 打卡记录类
class CheckinRecord {
  final DateTime startTime;
  final DateTime endTime;
  final DateTime checkinTime;
  final String? note;

  CheckinRecord({
    required this.startTime,
    required this.endTime,
    required this.checkinTime,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'checkinTime': checkinTime.toIso8601String(),
      'note': note,
    };
  }

  factory CheckinRecord.fromJson(Map<String, dynamic> json) {
    return CheckinRecord(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      checkinTime: DateTime.parse(json['checkinTime'] as String),
      note: json['note'] as String?,
    );
  }
}
