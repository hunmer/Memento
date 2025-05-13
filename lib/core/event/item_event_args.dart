import 'event_manager.dart';

/// 物品事件参数类
class ItemEventArgs extends EventArgs {
  /// 物品ID
  final String itemId;
  
  /// 物品标题
  final String title;
  
  /// 事件动作类型（如：added, completed等）
  final String action;

  /// 创建一个物品事件参数实例
  ItemEventArgs({
    required String eventName,
    required this.itemId,
    required this.title,
    required this.action,
  }) : super(eventName);
}