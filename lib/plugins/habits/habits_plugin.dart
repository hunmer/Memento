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
import 'package:Memento/plugins/habits/widgets/habits_bottom_bar.dart';

/// 习惯追踪插件主视图
class HabitsMainView extends StatelessWidget {
  const HabitsMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return HabitsBottomBar(plugin: HabitsPlugin.instance);
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
    return const HabitsMainView();
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有习惯
  /// 支持分页参数: offset, count
  Future<String> _jsGetHabits(Map<String, dynamic> params) async {
    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
    final habitsJson = habits.map((h) => h.toMap()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        habitsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(habitsJson);
  }

  /// 根据ID获取习惯
  Future<String> _jsGetHabitById(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
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
    final String? habitId = params['id']; // 支持自定义ID，方便调试
    String? skillId = params['skillId'];
    final String? notes = params['notes'];
    final String? group = params['group'];
    final String? icon = params['icon'];
    final String? image = params['image'];
    final List<int>? reminderDays =
        params['reminderDays'] != null
            ? List<int>.from(params['reminderDays'])
            : null;
    final int? intervalDays = params['intervalDays'];
    final List<String>? tags =
        params['tags'] != null ? List<String>.from(params['tags']) : null;

    // 如果提供了skillId，检查技能是否存在，不存在则自动创建
    if (skillId != null && skillId.isNotEmpty) {
      try {
        _skillController.getSkillById(skillId);
        // 技能存在，不做任何操作
      } catch (e) {
        // 技能不存在，自动创建一个新技能
        final newSkill = Skill(
          id: skillId,
          title: skillId, // 使用skillId作为标题
          description: '自动创建的技能，关联习惯：$title',
          targetMinutes: 0,
          maxDurationMinutes: 0,
        );
        await _skillController.saveSkill(newSkill);
      }
    }

    // 如果没有提供自定义ID，则生成新的习惯ID
    final finalHabitId =
        habitId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final habit = Habit(
      id: finalHabitId,
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

    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
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
  /// 支持分页参数: offset, count
  Future<String> _jsGetSkills(Map<String, dynamic> params) async {
    // 确保技能数据已加载完成
    final skills = await _skillController.loadSkills();
    final skillsJson = skills.map((s) => s.toMap()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        skillsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(skillsJson);
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
      return jsonEncode(skill!.toMap());
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
    final String? skillId = params['id']; // 支持自定义ID，方便调试
    final String? description = params['description'];
    final String? notes = params['notes'];
    final String? group = params['group'];
    final String? icon = params['icon'];
    final String? image = params['image'];
    final int? targetMinutes = params['targetMinutes'];
    final int? maxDurationMinutes = params['maxDurationMinutes'];

    // 如果没有提供自定义ID，则生成新的技能ID
    final finalSkillId =
        skillId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final skill = Skill(
      id: finalSkillId,
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
      final skillMap = existingSkill!.toMap();
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

      // 先检查技能是否存在
      try {
        _skillController.getSkillById(skillId);
      } catch (e) {
        return jsonEncode({
          'success': false,
          'error': 'Skill not found: $skillId',
        });
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

    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
    try {
      final habit = habits.firstWhere((h) => h.id == habitId);

      final recordId = DateTime.now().millisecondsSinceEpoch.toString();
      final duration =
          durationSeconds != null
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
      return jsonEncode({'error': 'Habit not found: $habitId. Details: $e'});
    }
  }

  /// 获取完成记录
  /// 支持分页参数: offset, count
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
    final List<CompletionRecord> resultRecords =
        limit != null && limit < records.length
            ? records.sublist(records.length - limit)
            : records;

    final recordsJson = resultRecords.map((r) => r.toMap()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        recordsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(recordsJson);
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
  /// 支持分页参数: offset, count
  Future<String> _jsGetTodayHabits(Map<String, dynamic> params) async {
    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
    final today = DateTime.now().weekday % 7; // 转换为 0-6 (周日-周六)

    final todayHabits =
        habits.where((habit) {
          // 如果是每日习惯（intervalDays == 0）或包含今日的提醒日期
          return habit.intervalDays == 0 || habit.reminderDays.contains(today);
        }).toList();

    final todayHabitsJson = todayHabits.map((h) => h.toMap()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        todayHabitsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(todayHabitsJson);
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

    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
    try {
      final habit = habits.firstWhere((h) => h.id == habitId);

      final initialDuration =
          initialSeconds != null
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

    return jsonEncode({'habitId': habitId, 'status': 'stopped'});
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
      return jsonEncode({'habitId': habitId, 'isRunning': false});
    }

    return jsonEncode({
      'habitId': habitId,
      'isRunning': isRunning,
      'elapsedSeconds': timerData['elapsedSeconds'] ?? 0,
      'isCountdown': timerData['isCountdown'] ?? true,
    });
  }
}
