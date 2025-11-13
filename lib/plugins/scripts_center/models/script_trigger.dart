/// 脚本触发器模型
///
/// 定义脚本如何被EventManager事件触发
class ScriptTrigger {
  /// 事件名称（EventManager中的事件）
  final String event;

  /// 延迟执行时间（毫秒），null表示立即执行
  final int? delay;

  /// 可选的条件判断参数（未来扩展用）
  final Map<String, dynamic>? condition;

  const ScriptTrigger({
    required this.event,
    this.delay,
    this.condition,
  });

  /// 从JSON创建触发器对象
  factory ScriptTrigger.fromJson(Map<String, dynamic> json) {
    return ScriptTrigger(
      event: json['event'] as String,
      delay: json['delay'] as int?,
      condition: json['condition'] as Map<String, dynamic>?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'event': event,
      if (delay != null) 'delay': delay,
      if (condition != null) 'condition': condition,
    };
  }

  @override
  String toString() {
    final delayText = delay != null ? ' (延迟${delay}ms)' : ' (即时)';
    return '$event$delayText';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScriptTrigger &&
        other.event == event &&
        other.delay == delay;
  }

  @override
  int get hashCode => Object.hash(event, delay);
}
