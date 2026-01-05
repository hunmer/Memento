import 'package:get/get.dart';
import 'dart:convert';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_bottom_bar.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/plugins/habits/repositories/client_habits_repository.dart';
import 'package:shared_models/usecases/habits/habits_usecase.dart';

part 'habits_js_api.dart';
part 'habits_data_selectors.dart';

/// 习惯追踪插件主视图
class HabitsMainView extends StatefulWidget {
  /// 可选的习惯ID，用于从小组件跳转时自动显示习惯详情
  final String? habitId;

  const HabitsMainView({super.key, this.habitId});

  @override
  State<HabitsMainView> createState() => _HabitsMainViewState();
}

class _HabitsMainViewState extends State<HabitsMainView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: HabitsBottomBar(plugin: HabitsPlugin.instance, habitId: widget.habitId),
    );
  }
}

class HabitsPlugin extends PluginBase with JSBridgePlugin {
  late final HabitController _habitController;
  late final SkillController _skillController;
  late final CompletionRecordController _recordController;
  late final TimerController _timerController;
  late final ClientHabitsRepository _repository;
  late final HabitsUseCase _useCase;
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

      // 打卡和记录
      'checkIn': _jsCheckIn,
      'getCompletionRecords': _jsGetCompletionRecords,
      'deleteCompletionRecord': _jsDeleteCompletionRecord,

      // 统计
      'getStats': _jsGetStats,
      'getTodayHabits': _jsGetTodayHabits,

      // 计时器
      'startTimer': _jsStartTimer,
      'stopTimer': _jsStopTimer,
      'getTimerStatus': _jsGetTimerStatus,
    };
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
    return 'habits_name'.tr;
  }

  @override
  Future<void> initialize() async {
    _timerController = TimerController();
    _skillController = SkillController(storage);
    _habitController = HabitController(
      storage,
      timerController: _timerController,
      skillController: _skillController,
    );
    _recordController = CompletionRecordController(
      storage,
      habitController: _habitController,
      skillControlle: _skillController,
    );

    // 创建 Repository 和 UseCase 实例
    _repository = ClientHabitsRepository(
      habitController: _habitController,
      skillController: _skillController,
      recordController: _recordController,
    );
    _useCase = HabitsUseCase(_repository);

    // 迁移：为已有习惯初始化总累计时长
    await _migrateTotalDuration();

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
  }

  /// 一次性迁移：为已有习惯初始化总累计时长字段
  Future<void> _migrateTotalDuration() async {
    const migrationKey = 'habits/migrations/total_duration_initialized';
    final migrated = await storage.readJson(migrationKey, false);

    if (migrated == true) {
      return; // 已经迁移过，跳过
    }

    try {
      final habits = _habitController.getHabits();
      for (final habit in habits) {
        // 计算每个习惯的总累计时长
        final records = await _recordController.getHabitCompletionRecords(habit.id);
        final totalMinutes = records.fold<int>(
          0,
          (sum, record) => sum + record.duration.inMinutes,
        );

        // 更新习惯的总累计时长
        if (totalMinutes > 0) {
          await _habitController.updateTotalDuration(habit.id, totalMinutes);
        }
      }

      // 标记迁移完成
      await storage.writeJson(migrationKey, true);
    } catch (e) {
      print('Error migrating total duration: $e');
    }
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
    // 监听计时器事件，同步小组件数据
    EventManager.instance.subscribe('habit_timer_started', _onTimerEvent);
    EventManager.instance.subscribe('habit_timer_stopped', _onTimerEvent);
    // 监听完成记录保存事件，同步周视图小组件
    EventManager.instance.subscribe('habit_completion_record_saved', _onCompletionRecordSaved);
    // 监听习惯数据变更事件，同步习惯分组列表小组件
    EventManager.instance.subscribe('habit_data_changed', _onHabitDataChanged);
    // 监听技能数据变更事件，同步习惯分组列表小组件
    EventManager.instance.subscribe('skill_data_changed', _onSkillDataChanged);
  }

  /// 处理计时器事件，同步小组件
  void _onTimerEvent(EventArgs args) {
    // 异步执行同步操作，避免阻塞事件处理
    Future.microtask(() async {
      try {
        await PluginWidgetSyncHelper.instance.syncHabitTimerWidget();
      } catch (e) {
        debugPrint('同步习惯计时器小组件失败: $e');
      }
    });
  }

  /// 处理完成记录保存事件，同步周视图小组件
  void _onCompletionRecordSaved(EventArgs args) {
    // 异步执行同步操作，避免阻塞事件处理
    Future.microtask(() async {
      try {
        await PluginWidgetSyncHelper.instance.syncHabitsWeeklyWidget();
        debugPrint('已同步习惯周视图小组件');
      } catch (e) {
        debugPrint('同步习惯周视图小组件失败: $e');
      }
    });
  }

  /// 处理习惯数据变更事件，同步习惯分组列表小组件
  void _onHabitDataChanged(EventArgs args) {
    // 异步执行同步操作，避免阻塞事件处理
    Future.microtask(() async {
      try {
        await PluginWidgetSyncHelper.instance.syncHabitGroupListWidget();
        debugPrint('已同步习惯分组列表小组件');
      } catch (e) {
        debugPrint('同步习惯分组列表小组件失败: $e');
      }
    });
  }

  /// 处理技能数据变更事件，同步习惯分组列表小组件
  void _onSkillDataChanged(EventArgs args) {
    // 异步执行同步操作，避免阻塞事件处理
    Future.microtask(() async {
      try {
        await PluginWidgetSyncHelper.instance.syncHabitGroupListWidget();
        debugPrint('已同步习惯分组列表小组件');
      } catch (e) {
        debugPrint('同步习惯分组列表小组件失败: $e');
      }
    });
  }

  Future<void> onDispose() async {
    // 取消事件订阅
    EventManager.instance.unsubscribe('habit_timer_started', _onTimerEvent);
    EventManager.instance.unsubscribe('habit_timer_stopped', _onTimerEvent);
    EventManager.instance.unsubscribe('habit_completion_record_saved', _onCompletionRecordSaved);
    EventManager.instance.unsubscribe('habit_data_changed', _onHabitDataChanged);
    EventManager.instance.unsubscribe('skill_data_changed', _onSkillDataChanged);
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
                'habits_name'.tr,
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
                    'habits_habits'.tr,
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
                    'habits_skills'.tr,
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
}
