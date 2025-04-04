import 'package:flutter/material.dart';
import '../checkin_plugin.dart';

class CheckinItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  String group;
  final Map<DateTime, bool> checkInRecords;

  CheckinItem({
    String? id,
    required this.name,
    required this.icon,
    Color? color,
    String? group,
    Map<DateTime, bool>? checkInRecords,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       color = color ?? Colors.blue,
       group = group ?? '默认分组',
       checkInRecords = checkInRecords ?? {};

  // 检查今天是否已打卡
  bool isCheckedToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return checkInRecords[todayDate] ?? false;
  }

  // 打卡
  Future<void> checkIn() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    checkInRecords[todayDate] = true;
    await CheckinPlugin.shared.triggerSave();
  }

  // 取消打卡
  Future<void> cancelCheckIn() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    checkInRecords[todayDate] = false;
    await CheckinPlugin.shared.triggerSave();
  }

  // 获取指定月份的打卡记录
  Map<DateTime, bool> getMonthlyRecords(int year, int month) {
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
      if (checkInRecords[date] ?? false) {
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
        (key, value) => MapEntry(key.toIso8601String(), value),
      ),
    };
  }

  // 从Map创建对象
  factory CheckinItem.fromJson(Map<String, dynamic> json) {
    // 使用预定义的MaterialIcons中的图标
    final iconData = IconData(
      json['icon'] as int,
      fontFamily: 'MaterialIcons',
      fontPackage: null,
      matchTextDirection: false,
    );

    return CheckinItem(
      id: json['id'],
      name: json['name'],
      icon: iconData,
      color: Color(json['color']),
      group: json['group'] ?? '默认分组',
      checkInRecords: (json['checkInRecords'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(DateTime.parse(key), value as bool),
      ),
    );
  }
}
