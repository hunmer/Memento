import 'package:flutter/material.dart';
import 'base_plugin.dart';

/// 插件Widget，用于在Widget树中传递插件实例
class PluginWidget extends InheritedWidget {
  final BasePlugin plugin;

  const PluginWidget({super.key, required this.plugin, required super.child});

  static PluginWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PluginWidget>();
  }

  @override
  bool updateShouldNotify(PluginWidget oldWidget) {
    return plugin != oldWidget.plugin;
  }
}
