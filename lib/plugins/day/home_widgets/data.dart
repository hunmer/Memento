/// 纪念日插件主页小组件数据模型
library;

/// 纪念日小组件数据
class MemorialDayWidgetData {
  final String id;
  final String title;
  final DateTime targetDate;
  final String? backgroundImageUrl;
  final int backgroundColor;
  final int daysRemaining;
  final int daysPassed;
  final bool isToday;
  final bool isExpired;

  const MemorialDayWidgetData({
    required this.id,
    required this.title,
    required this.targetDate,
    this.backgroundImageUrl,
    required this.backgroundColor,
    required this.daysRemaining,
    required this.daysPassed,
    required this.isToday,
    required this.isExpired,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate.toIso8601String(),
      'backgroundImageUrl': backgroundImageUrl,
      'backgroundColor': backgroundColor,
      'daysRemaining': daysRemaining,
      'daysPassed': daysPassed,
      'isToday': isToday,
      'isExpired': isExpired,
    };
  }

  factory MemorialDayWidgetData.fromJson(Map<String, dynamic> json) {
    return MemorialDayWidgetData(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      targetDate: DateTime.parse(json['targetDate'] as String? ?? ''),
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      backgroundColor: json['backgroundColor'] as int? ?? 0,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      daysPassed: json['daysPassed'] as int? ?? 0,
      isToday: json['isToday'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
    );
  }
}

/// 日期范围小组件数据
class DateRangeWidgetData {
  final int startDay;
  final int endDay;
  final String dateRangeLabel;
  final List<MemorialDayListItemData> daysList;
  final int totalCount;
  final int todayCount;
  final int upcomingCount;
  final int expiredCount;

  const DateRangeWidgetData({
    required this.startDay,
    required this.endDay,
    required this.dateRangeLabel,
    required this.daysList,
    required this.totalCount,
    required this.todayCount,
    required this.upcomingCount,
    required this.expiredCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDay': startDay,
      'endDay': endDay,
      'dateRangeLabel': dateRangeLabel,
      'daysList': daysList.map((d) => d.toJson()).toList(),
      'totalCount': totalCount,
      'todayCount': todayCount,
      'upcomingCount': upcomingCount,
      'expiredCount': expiredCount,
    };
  }
}

/// 纪念日列表项数据
class MemorialDayListItemData {
  final String id;
  final String title;
  final String date;
  final String statusText;
  final String statusColor;
  final int backgroundColor;
  final int daysRemaining;
  final int daysPassed;
  final bool isToday;
  final bool isExpired;

  const MemorialDayListItemData({
    required this.id,
    required this.title,
    required this.date,
    required this.statusText,
    required this.statusColor,
    required this.backgroundColor,
    required this.daysRemaining,
    required this.daysPassed,
    required this.isToday,
    required this.isExpired,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'statusText': statusText,
      'statusColor': statusColor,
      'backgroundColor': backgroundColor,
      'daysRemaining': daysRemaining,
      'daysPassed': daysPassed,
      'isToday': isToday,
      'isExpired': isExpired,
    };
  }
}
