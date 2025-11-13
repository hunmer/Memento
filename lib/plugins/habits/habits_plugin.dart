import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
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

class HabitsPlugin extends PluginBase with JSBridgePlugin {
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

  @override
  String get id => 'habits';

  @override
  IconData get icon => Icons.auto_awesome;

  @override
  Color get color => Colors.amber;

  @override
  Widget buildMainView(BuildContext context) {
    return HabitsMainView();
  }

  @override
  String? getPluginName(context) {
    return HabitsLocalizations.of(context).name;
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

    // 注册 JS API（最后一步）
    await registerJSAPI();
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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                HabitsLocalizations.of(context).name,
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
                  Text(
                    HabitsLocalizations.of(context).habits,
                    style: theme.textTheme.bodyMedium,
                  ),
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
                  Text(
                    HabitsLocalizations.of(context).skills,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 习惯相关
      'getHabits': _jsGetHabits,
      'getHabitById': _jsGetHabitById,
      'createHabit': _jsCreateHabit,
      'updateHabit': _jsUpdateHabit,
      'deleteHabit': _jsDeleteHabit,

      // 技能相关
      'getSkills': _jsGetSkills,
      'getSkillById': _jsGetSkillById,
      'createSkill': _jsCreateSkill,
      'updateSkill': _jsUpdateSkill,
      'deleteSkill': _jsDeleteSkill,

      // 打卡相关
      'checkIn': _jsCheckIn,
      'getCompletionRecords': _jsGetCompletionRecords,
      'deleteCompletionRecord': _jsDeleteCompletionRecord,

      // 统计相关
      'getStats': _jsGetStats,
      'getTodayHabits': _jsGetTodayHabits,

      // 计时器相关
      'startTimer': _jsStartTimer,
      'stopTimer': _jsStopTimer,
      'getTimerStatus': _jsGetTimerStatus,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有习惯
  Future<String> _jsGetHabits() async {
    final habits = _habitController.getHabits();
    return jsonEncode(habits.map((h) => h.toMap()).toList());
  }

  /// 根据ID获取习惯
  Future<String> _jsGetHabitById(String habitId) async {
    final habits = _habitController.getHabits();
    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found: $habitId'),
    );
    return jsonEncode(habit.toMap());
  }

  /// 创建习惯
  Future<String> _jsCreateHabit(
    String title,
    int durationMinutes,
    String? skillId, {
    String? notes,
    String? group,
    String? icon,
    String? image,
    List<int>? reminderDays,
    int? intervalDays,
    List<String>? tags,
  }) async {
    // 生成新的习惯ID
    final habitId = DateTime.now().millisecondsSinceEpoch.toString();

    final habit = Habit(
      id: habitId,
      title: title,
      durationMinutes: durationMinutes,
      skillId: skillId,
      notes: notes,
      group: group,
      icon: icon,
      image: image,
      reminderDays: reminderDays ?? [],
      intervalDays: intervalDays ?? 0,
      tags: tags ?? [],
    );

    await _habitController.saveHabit(habit);
    return jsonEncode(habit.toMap());
  }

  /// 更新习惯
  Future<String> _jsUpdateHabit(String habitId, Map<String, dynamic> updates) async {
    final habits = _habitController.getHabits();
    final existingHabit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found: $habitId'),
    );

    // 合并现有数据和更新数据
    final habitMap = existingHabit.toMap();
    habitMap.addAll(updates);

    final updatedHabit = Habit.fromMap(habitMap);
    await _habitController.saveHabit(updatedHabit);
    return jsonEncode(updatedHabit.toMap());
  }

  /// 删除习惯
  Future<bool> _jsDeleteHabit(String habitId) async {
    await _habitController.deleteHabit(habitId);
    // 同时删除该习惯的所有完成记录
    await _recordController.clearAllCompletionRecords(habitId);
    return true;
  }

  /// 获取所有技能
  Future<String> _jsGetSkills() async {
    final skills = _skillController.getSkills();
    return jsonEncode(skills.map((s) => s.toMap()).toList());
  }

  /// 根据ID获取技能
  Future<String> _jsGetSkillById(String skillId) async {
    final skill = _skillController.getSkillById(skillId);
    return jsonEncode(skill.toMap());
  }

  /// 创建技能
  Future<String> _jsCreateSkill(
    String title, {
    String? description,
    String? notes,
    String? group,
    String? icon,
    String? image,
    int? targetMinutes,
    int? maxDurationMinutes,
  }) async {
    final skillId = DateTime.now().millisecondsSinceEpoch.toString();

    final skill = Skill(
      id: skillId,
      title: title,
      description: description,
      notes: notes,
      group: group,
      icon: icon,
      image: image,
      targetMinutes: targetMinutes ?? 0,
      maxDurationMinutes: maxDurationMinutes ?? 0,
    );

    await _skillController.saveSkill(skill);
    return jsonEncode(skill.toMap());
  }

  /// 更新���能
  Future<String> _jsUpdateSkill(String skillId, Map<String, dynamic> updates) async {
    final existingSkill = _skillController.getSkillById(skillId);

    // 合并现有数据和更新数据
    final skillMap = existingSkill.toMap();
    skillMap.addAll(updates);

    final updatedSkill = Skill.fromMap(skillMap);
    await _skillController.saveSkill(updatedSkill);
    return jsonEncode(updatedSkill.toMap());
  }

  /// 删除技能
  Future<bool> _jsDeleteSkill(String skillId) async {
    await _skillController.deleteSkill(skillId);
    return true;
  }

  /// 打卡（创建完成记录）
  Future<String> _jsCheckIn(
    String habitId, {
    int? durationSeconds,
    String? notes,
  }) async {
    final habits = _habitController.getHabits();
    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found: $habitId'),
    );

    final recordId = DateTime.now().millisecondsSinceEpoch.toString();
    final duration = durationSeconds != null
        ? Duration(seconds: durationSeconds)
        : Duration(minutes: habit.durationMinutes);

    final record = CompletionRecord(
      id: recordId,
      parentId: habitId,
      date: DateTime.now(),
      duration: duration,
      notes: notes ?? '',
    );

    await _recordController.saveCompletionRecord(habitId, record);
    return jsonEncode(record.toMap());
  }

  /// 获取完成记录
  Future<String> _jsGetCompletionRecords(String habitId, [int? limit]) async {
    final records = await _recordController.getHabitCompletionRecords(habitId);

    // 如果指定了 limit，只返回最新的 N 条记录
    final List<CompletionRecord> resultRecords = limit != null && limit < records.length
        ? records.sublist(records.length - limit)
        : records;

    return jsonEncode(resultRecords.map((r) => r.toMap()).toList());
  }

  /// 删除完成记录
  Future<bool> _jsDeleteCompletionRecord(String recordId) async {
    await _recordController.deleteCompletionRecord(recordId);
    return true;
  }

  /// 获取统计信息
  Future<String> _jsGetStats(String habitId) async {
    final totalDuration = await _recordController.getTotalDuration(habitId);
    final completionCount = await _recordController.getCompletionCount(habitId);

    return jsonEncode({
      'habitId': habitId,
      'totalDurationMinutes': totalDuration,
      'completionCount': completionCount,
    });
  }

  /// 获取今日需要打卡的习惯
  Future<String> _jsGetTodayHabits() async {
    final habits = _habitController.getHabits();
    final today = DateTime.now().weekday % 7; // 转换为 0-6 (周日-周六)

    final todayHabits = habits.where((habit) {
      // 如果是每日习惯（intervalDays == 0）或包含今日的提醒日期
      return habit.intervalDays == 0 || habit.reminderDays.contains(today);
    }).toList();

    return jsonEncode(todayHabits.map((h) => h.toMap()).toList());
  }

  /// 启动计时器
  Future<String> _jsStartTimer(String habitId, [int? initialSeconds]) async {
    final habits = _habitController.getHabits();
    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found: $habitId'),
    );

    final initialDuration = initialSeconds != null
        ? Duration(seconds: initialSeconds)
        : Duration(minutes: habit.durationMinutes);

    // 启动计时器（使用空回调，因为 JS API 不需要实时更新）
    _timerController.startTimer(
      habit,
      (elapsedSeconds) {}, // 空回调
      initialDuration: initialDuration,
    );

    return jsonEncode({
      'habitId': habitId,
      'status': 'started',
      'initialSeconds': initialDuration.inSeconds,
    });
  }

  /// 停止计时器
  Future<String> _jsStopTimer(String habitId) async {
    _timerController.stopTimer(habitId);

    return jsonEncode({
      'habitId': habitId,
      'status': 'stopped',
    });
  }

  /// 获取计时器状态
  Future<String> _jsGetTimerStatus(String habitId) async {
    final timerData = _timerController.getTimerData(habitId);
    final isRunning = _timerController.isHabitTiming(habitId);

    if (timerData == null) {
      return jsonEncode({
        'habitId': habitId,
        'isRunning': false,
      });
    }

    return jsonEncode({
      'habitId': habitId,
      'isRunning': isRunning,
      'elapsedSeconds': timerData['elapsedSeconds'] ?? 0,
      'isCountdown': timerData['isCountdown'] ?? true,
    });
  }
}
