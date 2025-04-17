import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'notes_plugin.dart';

/// Notes插件的入口点
class NotesPluginEntry {
  /// 获取插件实例
  static BasePlugin getPlugin() {
    return NotesPlugin();
  }
}