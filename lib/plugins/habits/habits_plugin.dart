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
import 'package:Memento/plugins/habits/controls/prompt_controller.dart';

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

    // 初始化 Prompt Controller
    final promptController = HabitsPromptController(this);
    promptController.initialize();
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
  Future<String> _jsGetHabits(Map<String, dynamic> params) async {
    final habits = _habitController.getHabits();
    return jsonEncode(habits.map((h) => h.toMap()).toList());
  }

  /// 根据ID获取习惯
  Future<String> _jsGetHabitById(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    final habits = _habitController.getHabits();
    try {
      final habit = habits.firstWhere((h) => h.id == habitId);
      return jsonEncode(habit.toMap());
    } catch (e) {
      return jsonEncode({'error': 'Habit not found: $habitId'});
    }
  }

  /// 创建习惯
  Future<String> _jsCreateHabit(Map<String, dynamic> params) async {
    // 必需参数
    final String? title = params['title'];
    final int? durationMinutes = params['durationMinutes'];

    if (title == null) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }
    if (durationMinutes == null) {
      return jsonEncode({'error': '缺少必需参数: durationMinutes'});
    }

    // 可选参数
    final String? skillId = params['skillId'];
    final String? notes = params['notes'];
    final String? group = params['group'];
    final String? icon = params['icon'];
    final String? image = params['image'];
    final List<int>? reminderDays = params['reminderDays'] != null
        ? List<int>.from(params['reminderDays'])
        : null;
    final int? intervalDays = params['intervalDays'];
    final List<String>? tags = params['tags'] != null
        ? List<String>.from(params['tags'])
        : null;

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
  Future<String> _jsUpdateHabit(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    final habits = _habitController.getHabits();
    try {
      final existingHabit = habits.firstWhere((h) => h.id == habitId);

      // 合并现有数据和更新数据
      final habitMap = existingHabit.toMap();
      // 移除 habitId，其他都是可更新的字段
      final updates = Map<String, dynamic>.from(params);
      updates.remove('habitId');
      habitMap.addAll(updates);

      final updatedHabit = Habit.fromMap(habitMap);
      await _habitController.saveHabit(updatedHabit);
      return jsonEncode(updatedHabit.toMap());
    } catch (e) {
      return jsonEncode({'error': 'Habit not found: $habitId'});
    }
  }

  /// 删除习惯
  Future<String> _jsDeleteHabit(Map<String, dynamic> params) async {
    try {
      // 必需参数
      final String? habitId = params['habitId'];
      if (habitId == null) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: habitId'});
      }

      await _habitController.deleteHabit(habitId);
      // 同时删除该习惯的所有完成记录
      await _recordController.clearAllCompletionRecords(habitId);
      return jsonEncode({'success': true, 'habitId': habitId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取所有技能
  Future<String> _jsGetSkills(Map<String, dynamic> params) async {
    final skills = _skillController.getSkills();
    return jsonEncode(skills.map((s) => s.toMap()).toList());
  }

  /// 根据ID获取技能
  Future<String> _jsGetSkillById(Map<String, dynamic> params) async {
    // 必需参数
    final String? skillId = params['skillId'];
    if (skillId == null) {
      return jsonEncode({'error': '缺少必需参数: skillId'});
    }

    try {
      final skill = _skillController.getSkillById(skillId);
      return jsonEncode(skill.toMap());
    } catch (e) {
      return jsonEncode({'error': 'Skill not found: $skillId'});
    }
  }

  /// 创建技能
  Future<String> _jsCreateSkill(Map<String, dynamic> params) async {
    // 必需参数
    final String? title = params['title'];
    if (title == null) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    // 可选参数
    final String? description = params['description'];
    final String? notes = params['notes'];
    final String? group = params['group'];
    final String? icon = params['icon'];
    final String? image = params['image'];
    final int? targetMinutes = params['targetMinutes'];
    final int? maxDurationMinutes = params['maxDurationMinutes'];

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

  /// 更新技能
  Future<String> _jsUpdateSkill(Map<String, dynamic> params) async {
    // 必需参数
    final String? skillId = params['skillId'];
    if (skillId == null) {
      return jsonEncode({'error': '缺少必需参数: skillId'});
    }

    try {
      final existingSkill = _skillController.getSkillById(skillId);

      // 合并现有数据和更新数据
      final skillMap = existingSkill.toMap();
      final updates = Map<String, dynamic>.from(params);
      updates.remove('skillId');
      skillMap.addAll(updates);

      final updatedSkill = Skill.fromMap(skillMap);
      await _skillController.saveSkill(updatedSkill);
      return jsonEncode(updatedSkill.toMap());
    } catch (e) {
      return jsonEncode({'error': 'Skill not found: $skillId'});
    }
  }

  /// 删除技能
  Future<String> _jsDeleteSkill(Map<String, dynamic> params) async {
    try {
      // 必需参数
      final String? skillId = params['skillId'];
      if (skillId == null) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: skillId'});
      }

      await _skillController.deleteSkill(skillId);
      return jsonEncode({'success': true, 'skillId': skillId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 打卡（创建完成记录）
  Future<String> _jsCheckIn(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    // 可选参数
    final int? durationSeconds = params['durationSeconds'];
    final String? notes = params['notes'];

    final habits = _habitController.getHabits();
    try {
      final habit = habits.firstWhere((h) => h.id == habitId);

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
    } catch (e) {
      return jsonEncode({'error': 'Habit not found: $habitId'});
    }
  }

  /// 获取完成记录
  Future<String> _jsGetCompletionRecords(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    // 可选参数
    final int? limit = params['limit'];

    final records = await _recordController.getHabitCompletionRecords(habitId);

    // 如果指定了 limit，只返回最新的 N 条记录
    final List<CompletionRecord> resultRecords = limit != null && limit < records.length
        ? records.sublist(records.length - limit)
        : records;

    return jsonEncode(resultRecords.map((r) => r.toMap()).toList());
  }

  /// 删除完成记录
  Future<String> _jsDeleteCompletionRecord(Map<String, dynamic> params) async {
    try {
      // 必需参数
      final String? recordId = params['recordId'];
      if (recordId == null) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: recordId'});
      }

      await _recordController.deleteCompletionRecord(recordId);
      return jsonEncode({'success': true, 'recordId': recordId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取统计信息
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    final totalDuration = await _recordController.getTotalDuration(habitId);
    final completionCount = await _recordController.getCompletionCount(habitId);

    return jsonEncode({
      'habitId': habitId,
      'totalDurationMinutes': totalDuration,
      'completionCount': completionCount,
    });
  }

  /// 获取今日需要打卡的习惯
  Future<String> _jsGetTodayHabits(Map<String, dynamic> params) async {
    final habits = _habitController.getHabits();
    final today = DateTime.now().weekday % 7; // 转换为 0-6 (周日-周六)

    final todayHabits = habits.where((habit) {
      // 如果是每日习惯（intervalDays == 0）或包含今日的提醒日期
      return habit.intervalDays == 0 || habit.reminderDays.contains(today);
    }).toList();

    return jsonEncode(todayHabits.map((h) => h.toMap()).toList());
  }

  /// 启动计时器
  Future<String> _jsStartTimer(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    // 可选参数
    final int? initialSeconds = params['initialSeconds'];

    final habits = _habitController.getHabits();
    try {
      final habit = habits.firstWhere((h) => h.id == habitId);

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
    } catch (e) {
      return jsonEncode({'error': 'Habit not found: $habitId'});
    }
  }

  /// 停止计时器
  Future<String> _jsStopTimer(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    _timerController.stopTimer(habitId);

    return jsonEncode({
      'habitId': habitId,
      'status': 'stopped',
    });
  }

  /// 获取计时器状态
  Future<String> _jsGetTimerStatus(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

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
