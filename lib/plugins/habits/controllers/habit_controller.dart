import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

typedef TimerModeListener = void Function(String habitId, bool isCountdown);

class HabitController {
  final List<TimerModeListener> _timerModeListeners = [];
  final StorageManager storage;
  final TimerController timerController;
  final SkillController skillController;
  static const _habitsKey = 'habits/habits';
  static const String _initializedKey = 'habits/habits_initialized';
  List<Habit> _habits = [];

  HabitController(
    this.storage, {
    required this.timerController,
    required this.skillController,
  }) {
    loadHabits();
  }

  Future<List<Habit>> loadHabits() async {
    try {
      final data = await storage.readJson(_habitsKey, []);

      List<Map<String, dynamic>> habitMaps = [];
      if (data is List) {
        habitMaps = List<Map<String, dynamic>>.from(
          data.whereType<Map>().where((m) => m.isNotEmpty),
        );
      } else if (data is Map) {
        // 如果数据是Map格式，可能存储结构有问题
        if (data.containsKey('habits')) {
          final habitsData = data['habits'];
          if (habitsData is List) {
            habitMaps = List<Map<String, dynamic>>.from(
              habitsData.whereType<Map>().where((m) => m.isNotEmpty),
            );
          }
        }
      }

      _habits =
          habitMaps
              .map((e) => Habit.fromMap(e))
              .where((h) => h != null)
              .toList();

      // 如果没有习惯数据且未初始化过，创建默认习惯
      if (_habits.isEmpty) {
        final isInitialized = await storage.readJson(_initializedKey, false);
        if (isInitialized == false) {
          await _createDefaultHabits();
          await storage.writeJson(_initializedKey, true);
        }
      }

      return _habits;
    } catch (e) {
      print('Error loading habits: $e');
      return _habits = [];
    }
  }

  Future<void> _createDefaultHabits() async {
    // 获取已创建的技能
    final skills = skillController.getSkills();

    // 找到对应的技能ID
    Skill? getSkillByTitle(String title) {
      try {
        return skills.firstWhere((s) => s.title == title);
      } catch (e) {
        return null;
      }
    }

    final defaultHabits = [
      Habit(
        id: HabitsUtils.generateId(),
        title: '晨跑',
        notes: '每天早上跑步30分钟，保持身体健康',
        group: '运动',
        icon: '58352',
        reminderDays: [1, 2, 3, 4, 5, 6],
        durationMinutes: 30,
        tags: ['运动', '晨练'],
        skillId: getSkillByTitle('健康生活')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '阅读',
        notes: '每天阅读30分钟，提升知识储备',
        group: '学习',
        icon: '59544',
        reminderDays: [1, 2, 3, 4, 5, 6, 7],
        durationMinutes: 30,
        tags: ['阅读', '学习'],
        skillId: getSkillByTitle('学习提升')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '冥想',
        notes: '每天冥想10分钟，提升专注力和内心平静',
        group: '健康',
        icon: '59569',
        reminderDays: [1, 2, 3, 4, 5, 6, 7],
        durationMinutes: 10,
        tags: ['冥想', '正念'],
        skillId: getSkillByTitle('健康生活')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '写作',
        notes: '每天写作，记录思考和感悟',
        group: '创作',
        icon: '57975',
        reminderDays: [1, 2, 3, 4, 5, 6, 7],
        durationMinutes: 20,
        tags: ['写作', '创作'],
        skillId: getSkillByTitle('创意艺术')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '英语学习',
        notes: '学习英语，提升语言能力',
        group: '学习',
        icon: '58834',
        reminderDays: [1, 2, 3, 4, 5],
        durationMinutes: 25,
        tags: ['英语', '语言'],
        skillId: getSkillByTitle('学习提升')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '时间回顾',
        notes: '每天晚上回顾当天的工作和生活',
        group: '效率',
        icon: '58845',
        reminderDays: [1, 2, 3, 4, 5, 6, 7],
        durationMinutes: 15,
        tags: ['复盘', '总结'],
        skillId: getSkillByTitle('工作效率')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '健身',
        notes: '进行力量训练或身体锻炼',
        group: '运动',
        icon: '59642',
        reminderDays: [1, 2, 3, 4, 5, 6],
        durationMinutes: 45,
        tags: ['健身', '力量训练'],
        skillId: getSkillByTitle('健康生活')?.id,
      ),
      Habit(
        id: HabitsUtils.generateId(),
        title: '学习新技能',
        notes: '每天学习一样新东西',
        group: '学习',
        icon: '58373',
        reminderDays: [1, 2, 3, 4, 5],
        durationMinutes: 30,
        tags: ['技能', '成长'],
        skillId: getSkillByTitle('学习提升')?.id,
      ),
    ];

    _habits = defaultHabits;
    await storage.writeJson(
      _habitsKey,
      defaultHabits.map((h) => h.toMap()).toList(),
    );
    print('Created default habits: ${defaultHabits.length} items');
  }

  List<Habit> getHabits() => _habits;

  Future<void> saveHabit(Habit habit) async {
    final habits = getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);

    if (index >= 0) {
      habits[index] = habit;
    } else {
      habits.add(habit);
    }

    await storage.writeJson(_habitsKey, habits.map((h) => h.toMap()).toList());

    // 同步到小组件
    await _syncWidget();
  }

  Future<void> deleteHabit(String id) async {
    final habits = getHabits();
    habits.removeWhere((h) => h.id == id);
    await storage.writeJson(_habitsKey, habits.map((h) => h.toMap()).toList());

    // 同步到小组件
    await _syncWidget();
  }

  void addTimerModeListener(TimerModeListener listener) {
    _timerModeListeners.add(listener);
  }

  void removeTimerModeListener(TimerModeListener listener) {
    _timerModeListeners.remove(listener);
  }

  void notifyTimerModeChanged(String habitId, bool isCountdown) {
    for (final listener in _timerModeListeners) {
      listener(habitId, isCountdown);
    }
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncHabits();
  }
}
