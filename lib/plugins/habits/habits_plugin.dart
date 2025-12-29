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

  /// 注册数据选择器
  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'habits.habit',
      pluginId: id,
      name: '选择习惯',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'habit',
          title: '选择习惯',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            final habits = _habitController.getHabits();
            final List<SelectableItem> items = [];

            for (final habit in habits) {
              // 获取累计时长和完成次数作为副标题
              final duration = await _recordController.getTotalDuration(habit.id);
              final count = await _recordController.getCompletionCount(habit.id);

              items.add(SelectableItem(
                id: habit.id,
                title: habit.title,
                subtitle: '$duration 分钟 · $count 次完成',
                icon: habit.icon != null
                    ? IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons')
                    : Icons.auto_awesome,
                rawData: habit,
              ));
            }

            return items;
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery) ||
              (item.rawData as Habit).group?.toLowerCase().contains(lowerQuery) == true ||
              (item.rawData as Habit).tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
            ).toList();
          },
        ),
      ],
    ));
  }

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
  /// 支持分页参数: offset, count
  Future<String> _jsGetHabits(Map<String, dynamic> params) async {
    final result = await _useCase.getHabits(params);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 根据ID获取习惯
  Future<String> _jsGetHabitById(Map<String, dynamic> params) async {
    // 将 habitId 转换为 id 格式（UseCase 期望的参数名）
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('habitId')) {
      useCaseParams['id'] = params['habitId'];
    }

    final result = await _useCase.getHabitById(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull ?? {'error': 'Habit not found'});
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 创建习惯
  Future<String> _jsCreateHabit(Map<String, dynamic> params) async {
    final result = await _useCase.createHabit(params);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 更新习惯
  Future<String> _jsUpdateHabit(Map<String, dynamic> params) async {
    // 将 habitId 转换为 id 格式（UseCase 期望的参数名）
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('habitId')) {
      useCaseParams['id'] = params['habitId'];
    }

    final result = await _useCase.updateHabit(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 删除习惯
  Future<String> _jsDeleteHabit(Map<String, dynamic> params) async {
    // 将 habitId 转换为 id 格式（UseCase 期望的参数名）
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('habitId')) {
      useCaseParams['id'] = params['habitId'];
    }

    final result = await _useCase.deleteHabit(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode({'success': true});
    } else {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }
  }

  /// 获取所有技能
  /// 支持分页参数: offset, count
  Future<String> _jsGetSkills(Map<String, dynamic> params) async {
    final result = await _useCase.getSkills(params);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 根据ID获取技能
  Future<String> _jsGetSkillById(Map<String, dynamic> params) async {
    // 将 skillId 转换为 id 格式（UseCase 期望的参数名）
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('skillId')) {
      useCaseParams['id'] = params['skillId'];
    }

    final result = await _useCase.getSkillById(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull ?? {'error': 'Skill not found'});
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 创建技能
  Future<String> _jsCreateSkill(Map<String, dynamic> params) async {
    final result = await _useCase.createSkill(params);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 更新技能
  Future<String> _jsUpdateSkill(Map<String, dynamic> params) async {
    // 将 skillId 转换为 id 格式（UseCase 期望的参数名）
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('skillId')) {
      useCaseParams['id'] = params['skillId'];
    }

    final result = await _useCase.updateSkill(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 删除技能
  Future<String> _jsDeleteSkill(Map<String, dynamic> params) async {
    // 将 skillId 转换为 id 格式（UseCase 期望的参数名）
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('skillId')) {
      useCaseParams['id'] = params['skillId'];
    }

    final result = await _useCase.deleteSkill(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode({'success': true});
    } else {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }
  }

  /// 打卡（创建完成记录）
  Future<String> _jsCheckIn(Map<String, dynamic> params) async {
    // 转换参数格式
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('habitId')) {
      useCaseParams['parentId'] = params['habitId'];
    }
    if (params.containsKey('durationSeconds')) {
      useCaseParams['durationSeconds'] = params['durationSeconds'];
    } else if (params.containsKey('durationMinutes')) {
      // 如果传入的是分钟，转换为秒
      useCaseParams['durationSeconds'] = (params['durationMinutes'] as int) * 60;
    }
    if (!useCaseParams.containsKey('date')) {
      useCaseParams['date'] = DateTime.now().toIso8601String();
    }

    final result = await _useCase.createCompletionRecord(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 获取完成记录
  /// 支持分页参数: offset, count
  Future<String> _jsGetCompletionRecords(Map<String, dynamic> params) async {
    // 转换参数格式
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('habitId')) {
      useCaseParams['parentId'] = params['habitId'];
    }

    final result = await _useCase.getCompletionRecords(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode(result.dataOrNull);
    } else {
      return jsonEncode({'error': result.errorOrNull?.message});
    }
  }

  /// 删除完成记录
  Future<String> _jsDeleteCompletionRecord(Map<String, dynamic> params) async {
    // 转换参数格式
    final useCaseParams = Map<String, dynamic>.from(params);
    if (params.containsKey('recordId')) {
      useCaseParams['id'] = params['recordId'];
    }

    final result = await _useCase.deleteCompletionRecord(useCaseParams);

    if (result.isSuccess) {
      return jsonEncode({'success': true});
    } else {
      return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
    }
  }

  /// 获取统计信息
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    // 获取总时长
    final durationParams = {'habitId': habitId};
    final durationResult = await _useCase.getHabitTotalDuration(durationParams);

    // 获取完成次数
    final countParams = {'habitId': habitId};
    final countResult = await _useCase.getHabitCompletionCount(countParams);

    if (durationResult.isSuccess && countResult.isSuccess) {
      return jsonEncode({
        'habitId': habitId,
        'totalDurationMinutes': durationResult.dataOrNull,
        'completionCount': countResult.dataOrNull,
      });
    } else {
      return jsonEncode({
        'error': durationResult.errorOrNull?.message ?? countResult.errorOrNull?.message,
      });
    }
  }

  /// 获取今日需要打卡的习惯
  /// 支持分页参数: offset, count
  Future<String> _jsGetTodayHabits(Map<String, dynamic> params) async {
    // 首先获取所有习惯
    final allHabitsResult = await _useCase.getHabits({});

    if (allHabitsResult.isFailure) {
      return jsonEncode({'error': allHabitsResult.errorOrNull?.message});
    }

    final allHabits = allHabitsResult.dataOrNull as List;
    final today = DateTime.now().weekday % 7; // 转换为 0-6 (周日-周六)

    // 过滤出今日需要打卡的习惯
    final todayHabits = allHabits.where((habitJson) {
      final intervalDays = habitJson['intervalDays'] as int? ?? 0;
      final reminderDays = List<int>.from(habitJson['reminderDays'] ?? []);

      // 如果是每日习惯（intervalDays == 0）或包含今日的提醒日期
      return intervalDays == 0 || reminderDays.contains(today);
    }).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        todayHabits,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(todayHabits);
  }

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

  /// 启动计时器
  Future<String> _jsStartTimer(Map<String, dynamic> params) async {
    // 必需参数
    final String? habitId = params['habitId'];
    if (habitId == null) {
      return jsonEncode({'error': '缺少必需参数: habitId'});
    }

    // 确保习惯数据已加载完成
    final habits = await _habitController.loadHabits();
    try {
      final habit = habits.firstWhere((h) => h.id == habitId);

      // 启动计时器（使用空回调，因为 JS API 不需要实时更新）
      _timerController.startTimer(
        habit,
        (elapsedSeconds) {}, // 空回调
      );

      return jsonEncode({
        'habitId': habitId,
        'status': 'started',
        'durationMinutes': habit.durationMinutes,
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
