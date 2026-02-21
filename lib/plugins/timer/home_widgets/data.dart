/// 计时器插件主页小组件数据模型
library;

/// 统计项数据（从核心库导入）
// StatItemData 从 HomeWidget 相关核心库中定义，此处无需重复定义

/// 计时器小组件配置数据
class TimerWidgetData {
  final String id;
  final String name;
  final int icon;
  final int color;

  const TimerWidgetData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}
