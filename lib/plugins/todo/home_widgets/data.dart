/// 待办插件主页小组件数据模型
library;

/// 任务数据简略信息
class TaskSummaryData {
  final String id;
  final String title;
  final int priority;
  final int status;

  const TaskSummaryData({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
  });

  /// 从 Map 创建
  factory TaskSummaryData.fromJson(Map<String, dynamic> json) {
    return TaskSummaryData(
      id: json['id'] as String,
      title: json['title'] as String,
      priority: json['priority'] as int,
      status: json['status'] as int,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'status': status,
    };
  }
}
