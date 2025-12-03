/// 插件动作事件参数
/// 用于传递插件动作执行的数据
import 'event_manager.dart';

/// 插件动作事件参数类
class PluginActionEventArgs extends EventArgs {
  /// 插件ID
  final String pluginId;

  /// 动作名称
  final String actionName;

  /// 动作数据
  final Map<String, dynamic>? data;

  PluginActionEventArgs({
    required this.pluginId,
    required this.actionName,
    this.data,
    String eventName = 'plugin_action',
  }) : super(eventName);
}
