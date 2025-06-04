class Goal {
  final String id;
  final String name;
  final String icon;
  final int? iconColor;
  final String unitType;
  final String group;
  final String? imagePath;
  final double targetValue;
  final double currentValue;
  final DateSettings dateSettings;
  final String? reminderTime;
  final bool isLoopReset;
  final DateTime createdAt;

  bool get isCompleted => currentValue >= targetValue;

  Goal({
    required this.id,
    required this.name,
    required this.icon,
    this.iconColor,
    required this.unitType,
    required this.targetValue,
    required this.currentValue,
    required this.dateSettings,
    this.reminderTime,
    required this.isLoopReset,
    required this.createdAt,
    this.group = '默认',
    this.imagePath,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      iconColor: json['iconColor'],
      unitType: json['unitType'],
      targetValue: json['targetValue'],
      currentValue: json['currentValue'],
      dateSettings: DateSettings.fromJson(json['dateSettings']),
      reminderTime: json['reminderTime'],
      isLoopReset: json['isLoopReset'],
      createdAt: DateTime.parse(json['createdAt']),
      group: json['group'] ?? '默认',
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'iconColor': iconColor,
      'unitType': unitType,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'dateSettings': dateSettings.toJson(),
      'reminderTime': reminderTime,
      'isLoopReset': isLoopReset,
      'createdAt': createdAt.toIso8601String(),
      'group': group,
      'imagePath': imagePath,
    };
  }

  Goal copyWith({
    String? id,
    String? name,
    String? icon,
    int? iconColor,
    String? unitType,
    double? targetValue,
    double? currentValue,
    DateSettings? dateSettings,
    String? reminderTime,
    bool? isLoopReset,
    DateTime? createdAt,
    String? group,
    String? imagePath,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      unitType: unitType ?? this.unitType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      dateSettings: dateSettings ?? this.dateSettings,
      reminderTime: reminderTime ?? this.reminderTime,
      isLoopReset: isLoopReset ?? this.isLoopReset,
      createdAt: createdAt ?? this.createdAt,
      group: group ?? this.group,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class DateSettings {
  final String type; // daily/weekly/monthly/custom
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? selectedDays; // For weekly
  final int? monthDay; // For monthly

  DateSettings({
    required this.type,
    this.startDate,
    this.endDate,
    this.selectedDays,
    this.monthDay,
  });

  factory DateSettings.fromJson(Map<String, dynamic> json) {
    return DateSettings(
      type: json['type'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      selectedDays:
          json['selectedDays'] != null
              ? List<String>.from(json['selectedDays'])
              : null,
      monthDay: json['monthDay'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'selectedDays': selectedDays,
      'monthDay': monthDay,
    };
  }
}
