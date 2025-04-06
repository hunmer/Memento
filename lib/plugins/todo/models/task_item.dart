enum Priority {
  importantUrgent,
  importantNotUrgent,
  notImportantUrgent,
  notImportantNotUrgent;

  static Priority fromString(String value) {
    return Priority.values.firstWhere(
      (e) => e.toString() == 'Priority.$value',
      orElse: () => Priority.notImportantNotUrgent,
    );
  }
}

class TaskItem {
  final String id;
  String title;
  List<String> subTaskIds;
  DateTime createdAt;
  List<String> tags;
  String group;
  DateTime? startDate;
  DateTime? dueDate;
  Map<String, dynamic> customFields;
  String? subtitle;
  String? notes;
  Priority priority;
  DateTime? completedAt;

  TaskItem({
    required this.id,
    required this.title,
    this.subTaskIds = const [],
    required this.createdAt,
    this.tags = const [],
    this.group = '',
    this.startDate,
    this.dueDate,
    this.customFields = const {},
    this.subtitle,
    this.notes,
    this.priority = Priority.notImportantNotUrgent,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;

  void toggleComplete() {
    if (isCompleted) {
      completedAt = null;
    } else {
      completedAt = DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subTaskIds': subTaskIds,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'group': group,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'customFields': customFields,
      'subtitle': subtitle,
      'notes': notes,
      'priority': priority.toString().split('.').last,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subTaskIds: (json['subTaskIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      group: json['group'] as String,
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'] as String)
              : null,
      dueDate:
          json['dueDate'] != null
              ? DateTime.parse(json['dueDate'] as String)
              : null,
      customFields: (json['customFields'] as Map<String, dynamic>?) ?? {},
      subtitle: json['subtitle'] as String?,
      notes: json['notes'] as String?,
      priority: Priority.fromString(json['priority'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
    );
  }

  TaskItem copyWith({
    String? id,
    String? title,
    List<String>? subTaskIds,
    DateTime? createdAt,
    List<String>? tags,
    String? group,
    DateTime? startDate,
    DateTime? dueDate,
    Map<String, dynamic>? customFields,
    String? subtitle,
    String? notes,
    Priority? priority,
    DateTime? completedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subTaskIds: subTaskIds ?? this.subTaskIds,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      group: group ?? this.group,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      customFields: customFields ?? this.customFields,
      subtitle: subtitle ?? this.subtitle,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
