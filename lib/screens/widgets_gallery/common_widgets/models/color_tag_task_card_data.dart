/// 彩色标签任务列表卡片数据模型
/// 用于显示带彩色标签的任务列表
class ColorTagTaskCardData {
  /// 任务总数
  final int taskCount;

  /// 标签文本
  final String label;

  /// 任务项列表
  final List<ColorTagTaskItem> tasks;

  /// 更多任务数量（默认为0）
  final int moreCount;

  const ColorTagTaskCardData({
    required this.taskCount,
    required this.label,
    required this.tasks,
    this.moreCount = 0,
  });

  /// 从 JSON 创建
  factory ColorTagTaskCardData.fromJson(Map<String, dynamic> json) {
    return ColorTagTaskCardData(
      taskCount: json['taskCount'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => ColorTagTaskItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      moreCount: json['moreCount'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'taskCount': taskCount,
      'label': label,
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'moreCount': moreCount,
    };
  }
}

/// 彩色标签任务项数据模型
class ColorTagTaskItem {
  /// 任务标题
  final String title;

  /// 标签颜色（ARGB 格式，如 0xFF3B82F6）
  final int color;

  /// 标签文本（显示在右侧）
  final String tag;

  const ColorTagTaskItem({
    required this.title,
    required this.color,
    required this.tag,
  });

  /// 从 JSON 创建
  factory ColorTagTaskItem.fromJson(Map<String, dynamic> json) {
    return ColorTagTaskItem(
      title: json['title'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF000000,
      tag: json['tag'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'color': color,
      'tag': tag,
    };
  }
}
