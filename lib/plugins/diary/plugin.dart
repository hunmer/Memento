import '../base_plugin.dart';
import 'diary_plugin.dart';

/// 创建插件实例的工厂函数
BasePlugin createPlugin() {
  return DiaryPlugin.instance;
}
