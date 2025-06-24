import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_home.dart';

class HabitsMainView extends StatefulWidget {
  const HabitsMainView({super.key});

  @override
  State<HabitsMainView> createState() => _HabitsMainViewState();
}

class _HabitsMainViewState extends State<HabitsMainView> {
  late HabitsPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = HabitsPlugin.instance;
  }

  @override
  Widget build(BuildContext context) {
    return HabitsHome(
      habitController: _plugin._habitController,
      skillController: _plugin._skillController,
      recordController: _plugin._recordController,
    );
  }
}

class HabitsPlugin extends PluginBase {
  late final HabitController _habitController;
  late final SkillController _skillController;
  late final CompletionRecordController _recordController;
  late final TimerController _timerController;
  static HabitsPlugin? _instance;
  static HabitsPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (_instance == null) {
        throw StateError('HabitsPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  final String author = 'Memento Team';
  @override
  String get description => '';
  @override
  String get id => 'habits';
  @override
  String get name => '习惯管理';

  @override
  Widget buildMainView(BuildContext context) {
    return HabitsMainView();
  }

  @override
  Future<void> initialize() async {
    _timerController = TimerController();
    _habitController = HabitController(
      storage,
      timerController: _timerController,
    );
    _skillController = SkillController(storage);
    _recordController = CompletionRecordController(
      storage,
      habitController: _habitController,
      skillControlle: _skillController,
    );
  }

  TimerController get timerController => _timerController;

  getHabitController() => _habitController;
  getSkillController() => _skillController;
  getRecordController() => _recordController;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  Future<void> onDispose() async {
    // Clean up resources if needed
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final habitCount = _habitController.getHabits().length;
    final skillCount = _skillController.getSkills().length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部图标和标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 统计信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$habitCount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('习惯', style: theme.textTheme.bodyMedium),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$skillCount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('技能', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
