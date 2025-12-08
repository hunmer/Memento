import 'package:Memento/plugins/base_plugin.dart';
import 'notes_plugin.dart';

/// Notes插件的入口点
class NotesPluginEntry {
  /// 获取插件实例
  static BasePlugin getPlugin() {
    return NotesPlugin();
  }
}
