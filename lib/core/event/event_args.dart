import 'event_manager.dart';

/// 用于传递单个值的事件参数
class Value<T> extends EventArgs {
  final T value;
  
  Value(this.value, [String eventName = '']) : super(eventName);
}

/// 用于传递两个值的事件参数
class Values<T1, T2> extends EventArgs {
  final T1 value1;
  final T2 value2;
  
  Values(this.value1, this.value2, [String eventName = '']) : super(eventName);
}

/// 自定义事件参数示例 - 可以根据需要创建更多自定义事件参数类
class UpdateEvent extends EventArgs {
  final String version;
  final bool forceUpdate;
  final String? changelog;
  
  UpdateEvent({
    required this.version,
    this.forceUpdate = false,
    this.changelog,
    String eventName = '',
  }) : super(eventName);
}