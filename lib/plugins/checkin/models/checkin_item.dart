import 'package:flutter/material.dart';
import '../checkin_plugin.dart';

class CheckinItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  String group;
  // 打卡记录，包含时间范围和备注
  final Map<DateTime, CheckinRecord> checkInRecords;

  CheckinItem({
    String? id,
    required this.name,
    required this.icon,
    Color? color,
    String? group,
    Map<DateTime, CheckinRecord>? checkInRecords,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       color = color ?? Colors.blue,
       group = group ?? '默认分组',
       checkInRecords = checkInRecords ?? {};

  // 检查今天是否已打卡
  bool isCheckedToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return checkInRecords.containsKey(todayDate);
  }

  // 获取今天的打卡记录列表
  List<CheckinRecord> getTodayRecords() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final records = <CheckinRecord>[];
    checkInRecords.forEach((date, record) {
      if (date.year == todayDate.year &&
          date.month == todayDate.month &&
          date.day == todayDate.day) {
        records.add(record);
      }
    });
    return records..sort((a, b) => b.checkinTime.compareTo(a.checkinTime));
  }

  // 添加打卡记录
  Future<void> addCheckinRecord(CheckinRecord record) async {
    final checkinTime = record.checkinTime;
    final recordDate = DateTime(
      checkinTime.year,
      checkinTime.month,
      checkinTime.day,
      checkinTime.hour,
      checkinTime.minute,
      checkinTime.second,
    );
    checkInRecords[recordDate] = record;
    await CheckinPlugin.shared.triggerSave();
  }

  // 取消打卡
  Future<void> cancelCheckinRecord(DateTime recordTime) async {
    checkInRecords.remove(recordTime);
    await CheckinPlugin.shared.triggerSave();
  }

  // 获取指定月份的打卡记录
  Map<DateTime, CheckinRecord> getMonthlyRecords(int year, int month) {
    return checkInRecords.entries
        .where((entry) => entry.key.year == year && entry.key.month == month)
        .fold({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
  }

  // 获取连续打卡天数
  int getConsecutiveDays() {
    int consecutiveDays = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 365; i++) {
      final date = todayDate.subtract(Duration(days: i));
      final dateRecords =
          checkInRecords.entries
              .where(
                (entry) =>
                    entry.key.year == date.year &&
                    entry.key.month == date.month &&
                    entry.key.day == date.day,
              )
              .toList();

      if (dateRecords.isNotEmpty) {
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
      'checkInRecords': checkInRecords.map(
        (key, value) => MapEntry(key.toIso8601String(), value.toJson()),
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
    // 使用预定义的MaterialIcons常量
    final icon = materialIcons[json['icon'] as int] ?? Icons.help_outline;

    return CheckinItem(
      id: json['id'],
      name: json['name'],
      icon: icon,
      color: Color(json['color']),
      group: json['group'] ?? '默认分组',
      checkInRecords: (json['checkInRecords'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          DateTime.parse(key),
          CheckinRecord.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
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
