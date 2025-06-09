import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_home.dart';

class HabitsPlugin extends PluginBase {
  late final HabitController _habitController;
  late final SkillController _skillController;
  late final CompletionRecordController _recordController;

  @override
  final String version = '1.0.0';
  @override
  final String author = 'Memento Team';
  @override
  String get description => '';
  @override
  String get id => 'habbits';
  @override
  String get name => '习惯管理';

  @override
  Widget buildMainView(BuildContext context) {
    return HabitsHome(
      habitController: _habitController,
      skillController: _skillController,
      recordController: _recordController,
    );
  }

  @override
  Future<void> initialize() async {
    _habitController = HabitController(storage);
    _skillController = SkillController(storage);
    _recordController = CompletionRecordController(storage);
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  @override
  Future<void> onDispose() async {
    // Clean up resources if needed
  }
}
