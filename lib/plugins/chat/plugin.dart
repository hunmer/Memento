import '../base_plugin.dart';
import 'chat_plugin.dart';

/// 创建插件实例的工厂函数
BasePlugin createPlugin() {
  return ChatPlugin.instance;
}