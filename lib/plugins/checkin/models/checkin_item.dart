import 'package:flutter/material.dart';
import '../checkin_plugin.dart';

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
    Map<String, List<CheckinRecord>>? checkInRecords,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
    final dateStr = _dateToString(record.checkinTime);
    if (!checkInRecords.containsKey(dateStr)) {
      checkInRecords[dateStr] = [];
    }
    checkInRecords[dateStr]!.add(record);
    checkInRecords[dateStr]!.sort((a, b) => b.checkinTime.compareTo(a.checkinTime));
    await CheckinPlugin.shared.triggerSave();
  }

  // 取消打卡
  Future<void> cancelCheckinRecord(DateTime recordTime, {int? recordIndex}) async {
    final dateStr = _dateToString(recordTime);
    if (checkInRecords.containsKey(dateStr)) {
      if (recordIndex != null && recordIndex >= 0 && recordIndex < checkInRecords[dateStr]!.length) {
        // 如果提供了索引，只删除指定索引的记录
        checkInRecords[dateStr]!.removeAt(recordIndex);
      } else {
        // 如果没有提供索引，找到第一个匹配的记录删除
        final index = checkInRecords[dateStr]!.indexWhere(
          (record) => record.checkinTime.isAtSameMomentAs(recordTime)
        );
        if (index >= 0) {
          checkInRecords[dateStr]!.removeAt(index);
        }
      }
      
      // 如果该日期下没有记录了，移除该日期
      if (checkInRecords[dateStr]!.isEmpty) {
        checkInRecords.remove(dateStr);
      }
    }
    await CheckinPlugin.shared.triggerSave();
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
    checkInRecords.clear();
    await CheckinPlugin.shared.triggerSave();
  }

  // 将对象转换为可序列化的Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'group': group,
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
