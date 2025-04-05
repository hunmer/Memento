enum Priority {
  importantUrgent,
  importantNotUrgent,
  notImportantUrgent,
  notImportantNotUrgent,
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
