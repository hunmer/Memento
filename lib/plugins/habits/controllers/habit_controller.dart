import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/event_args.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/sample_data.dart';

typedef TimerModeListener = void Function(String habitId, bool isCountdown);

/// 习惯缓存更新事件参数（携带数据，性能优化）
class HabitCacheUpdatedEventArgs extends EventArgs {
  /// 所有习惯列表
  final List<Habit> habits;

  /// 习惯数量
  final int count;

  /// 缓存日期
  final DateTime cacheDate;

  HabitCacheUpdatedEventArgs({
    required this.habits,
    required this.cacheDate,
  }) : count = habits.length,
       super('habits_cache_updated');
}

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
    _initialize();
  }

  Future<void> _initialize() async {
    // 先确保技能数据加载完成
    await skillController.loadSkills();
    // 再加载习惯数据
    await loadHabits();
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
    // 使用示例数据创建默认习惯
    final sampleData = HabitsSampleData.getSampleData();
    final habitMaps = sampleData['habits'] as List<Map<String, dynamic>>;
    final defaultHabits = habitMaps.map((m) => Habit.fromMap(m)).toList();

    _habits = defaultHabits;
    await storage.writeJson(
      _habitsKey,
      defaultHabits.map((h) => h.toMap()).toList(),
    );
    print('Created default habits: ${defaultHabits.length} items');

    // 同时创建示例完成记录
    await _createDefaultRecords();
  }

  /// 创建默认完成记录
  Future<void> _createDefaultRecords() async {
    final sampleData = HabitsSampleData.getSampleData();
    final recordsMap = sampleData['records'] as Map<String, dynamic>;

    for (final entry in recordsMap.entries) {
      final habitId = entry.key;
      final recordList = entry.value as List;

      if (recordList.isNotEmpty) {
        await storage.writeJson('habits/records/$habitId.json', recordList);
      }
    }

    print('Created default completion records for ${recordsMap.length} habits');
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

    // 广播习惯数据变更事件，同步小组件
    EventManager.instance.broadcast('habit_data_changed', Value({'habit': habit}));

    // 广播缓存更新事件（携带数据，性能优化）
    EventManager.instance.broadcast(
      'habits_cache_updated',
      HabitCacheUpdatedEventArgs(
        habits: List.from(habits),
        cacheDate: DateTime.now(),
      ),
    );

    // 同步到小组件
    await _syncWidget();
  }

  Future<void> deleteHabit(String id) async {
    final habits = getHabits();
    habits.removeWhere((h) => h.id == id);
    await storage.writeJson(_habitsKey, habits.map((h) => h.toMap()).toList());

    // 广播习惯数据变更事件，同步小组件
    EventManager.instance.broadcast('habit_data_changed', Value({'habitId': id}));

    // 广播缓存更新事件（携带数据，性能优化）
    EventManager.instance.broadcast(
      'habits_cache_updated',
      HabitCacheUpdatedEventArgs(
        habits: List.from(habits),
        cacheDate: DateTime.now(),
      ),
    );

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

  /// 更新习惯的总累计时长（仅在记录变更时调用，避免重复计算）
  Future<void> updateTotalDuration(String habitId, int totalMinutes) async {
    final habits = getHabits();
    final index = habits.indexWhere((h) => h.id == habitId);

    if (index >= 0) {
      final oldHabit = habits[index];
      // 创建新的习惯对象，更新总时长
      final updatedHabit = Habit(
        id: oldHabit.id,
        title: oldHabit.title,
        notes: oldHabit.notes,
        group: oldHabit.group,
        icon: oldHabit.icon,
        image: oldHabit.image,
        reminderDays: oldHabit.reminderDays,
        intervalDays: oldHabit.intervalDays,
        durationMinutes: oldHabit.durationMinutes,
        tags: oldHabit.tags,
        skillId: oldHabit.skillId,
        totalDurationMinutes: totalMinutes,
      );

      habits[index] = updatedHabit;
      await storage.writeJson(_habitsKey, habits.map((h) => h.toMap()).toList());

      // 广播习惯数据变更事件
      EventManager.instance.broadcast('habit_data_changed', Value({'habit': updatedHabit}));

      // 广播缓存更新事件（携带数据，性能优化）
      EventManager.instance.broadcast(
        'habits_cache_updated',
        HabitCacheUpdatedEventArgs(
          habits: List.from(habits),
          cacheDate: DateTime.now(),
        ),
      );
    }
  }
}
