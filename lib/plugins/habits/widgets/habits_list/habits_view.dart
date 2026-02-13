import 'package:get/get.dart';

import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/habits/widgets/habit_form.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habit_card.dart';
import 'package:Memento/plugins/habits/controllers/timer_controller.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Memento/plugins/habits/widgets/habit_action_sheet.dart';
import 'package:Memento/plugins/habits/screens/habit_monthly_list_screen.dart';

/// 搜索结果Widget
class HabitSearchResultsWidget extends StatelessWidget {
  final List<Habit> habits;
  final HabitController controller;
  final Function(Habit)? onHabitTap;
  final Function(Habit)? onHabitLongPress;

  const HabitSearchResultsWidget({
    super.key,
    required this.habits,
    required this.controller,
    this.onHabitTap,
    this.onHabitLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    final skillController = habitsPlugin?.getSkillController();

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final skill =
            habit.skillId != null
                ? skillController?.getSkillById(habit.skillId!)
                : null;

        return HabitCard(
          key: ValueKey('${habit.id}_search'),
          habit: habit,
          skill: skill,
          controller: controller,
          onTap: () => onHabitTap?.call(habit),
          onLongPress: () => onHabitLongPress?.call(habit),
        );
      },
    );
  }
}

class CombinedHabitsView extends StatefulWidget {
  final HabitController controller;
  final String? habitId;

  const CombinedHabitsView({
    super.key,
    required this.controller,
    this.habitId,
  });

  @override
  State<CombinedHabitsView> createState() => _CombinedHabitsViewState();
}

class _CombinedHabitsViewState extends State<CombinedHabitsView>
    with WidgetsBindingObserver {
  List<Habit> _habits = [];
  List<Habit> _filteredHabits = []; // 搜索过滤后的习惯列表
  final Map<String, bool> _timingStatus = {};
  int _refreshKey = 0; // 用于强制刷新 HabitCard
  String _selectedGroup = '全部'; // 当前选中的分组

  @override
  void initState() {
    super.initState();
    // 添加生命周期监听
    WidgetsBinding.instance.addObserver(this);
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    widget.controller.addTimerModeListener(_onTimerModeChanged);
    final activeTimers = habitsPlugin!.timerController.getActiveTimers();
    _timingStatus.addAll(activeTimers);
    EventManager.instance.subscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.subscribe('habit_timer_stopped', _onTimerStopped);
    _loadHabits();

    // 设置路由上下文
    _updateRouteContext();

    // 如果有 habitId，在加载完成后显示习惯详情
    if (widget.habitId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHabitDetailById(widget.habitId!);
      });
    }
  }

  @override
  void dispose() {
    // 移除生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    EventManager.instance.unsubscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.unsubscribe('habit_timer_stopped', _onTimerStopped);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 应用从后台恢复时重新加载数据
    if (state == AppLifecycleState.resumed) {
      debugPrint('CombinedHabitsView: 应用恢复，重新加载习惯数据');
      _reloadHabits();
    }
  }

  /// 从存储重新加载习惯数据（用于应用恢复时）
  Future<void> _reloadHabits() async {
    // 等待同步完成
    await Future.delayed(const Duration(milliseconds: 300));
    // 从存储重新加载
    final habits = await widget.controller.loadHabits();
    if (mounted) {
      setState(() {
        _habits = habits;
        _refreshKey++; // 增加 key 强制重建所有 HabitCard
      });
    }
  }

  void _onTimerStarted(EventArgs args) {
    if (args is HabitTimerEventArgs) {
      setState(() {
        _timingStatus[args.habitId] = args.isRunning;
      });
    }
  }

  void _onTimerStopped(EventArgs args) {
    if (args is HabitTimerEventArgs) {
      setState(() {
        _timingStatus[args.habitId] = args.isRunning;
      });
    }
  }

  void _onTimerModeChanged(String habitId, bool isCountdown) {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHabits() async {
    final habits = widget.controller.getHabits();
    if (mounted) {
      setState(() {
        _habits = habits;
        _filteredHabits = habits; // 初始化时显示所有习惯
      });
    }
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前页面状态
  void _updateRouteContext() {
    RouteHistoryManager.updateCurrentContext(
      pageId: '/habits_list',
      title: '习惯列表',
      params: {},
    );
  }

  /// 根据搜索关键词过滤习惯
  void _filterHabits(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredHabits = _habits;
      });
    } else {
      setState(() {
        _filteredHabits =
            _habits
                .where(
                  (habit) =>
                      habit.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      });
    }
  }

  /// 获取所有分组(用于过滤栏)
  List<String> get _groups {
    final g =
        _habits.map((habit) => habit.group ?? '未分组').toSet().toList()..sort();
    return ['全部', ...g];
  }

  /// 选择分组
  void _selectGroup(String group) {
    setState(() {
      _selectedGroup = group;
    });
    // 更新路由上下文
    _updateRouteContext();
  }

  /// 根据 ID 显示习惯详情（用于从小组件跳转）
  Future<void> _showHabitDetailById(String habitId) async {
    // 等待习惯数据加载完成
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final habit = _habits.cast<Habit?>().firstWhere(
      (h) => h?.id == habitId,
      orElse: () => null,
    );

    if (habit != null && mounted) {
      _showHabitForm(context, habit);
    }
  }

  /// 根据选中的分组过滤习惯
  List<Habit> get _filteredByGroup {
    if (_selectedGroup == '全部') {
      return _habits;
    } else {
      return _habits
          .where((habit) => (habit.group ?? '未分组') == _selectedGroup)
          .toList();
    }
  }

  Future<void> _showHabitForm(BuildContext context, [Habit? habit]) async {
    FormBuilderWrapperState? wrapperState;

    await NavigationHelper.push(
      context,
      Scaffold(
        appBar: AppBar(
          title: Text(
            habit == null ? 'habits_createHabit'.tr : 'habits_editHabit'.tr,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => wrapperState?.submitForm(),
            ),
            if (habit != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await widget.controller.deleteHabit(habit.id);
                  Navigator.pop(context);
                  _loadHabits();
                },
              ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: HabitForm(
          initialHabit: habit,
          showSubmitButton: false,
          onSave: (habit) async {
            await widget.controller.saveHabit(habit);
            Navigator.pop(context);
            _loadHabits();
          },
          onStateReady: (state) => wrapperState = state,
        ),
      ),
    );
  }

  /// 点击习惯卡片，进入习惯月份列表视图
  void _onHabitTap(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitMonthlyListScreen(
          habitId: habit.id,
          habitTitle: habit.title,
        ),
      ),
    );
  }

  /// 长按习惯卡片，显示操作抽屉
  void _onHabitLongPress(Habit habit) async {
    await HabitActionSheet.show(
      context: context,
      onEdit: () => _showHabitForm(context, habit),
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('habits_confirmDelete'.tr),
              content: Text('habits_confirmDeleteHabit'.tr),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('habits_cancel'.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('habits_delete'.tr),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          await widget.controller.deleteHabit(habit.id);
          _loadHabits();
        }
      },
    );
  }

  Widget _buildCardView(List<Habit> habits) {
    final habitsPlugin =
        PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
    final skillController = habitsPlugin?.getSkillController();

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final skill =
            habit.skillId != null
                ? skillController?.getSkillById(habit.skillId!)
                : null;

        return HabitCard(
          key: ValueKey('${habit.id}_$_refreshKey'),
          habit: habit,
          skill: skill,
          controller: widget.controller,
          onTap: () => _onHabitTap(habit),
          onLongPress: () => _onHabitLongPress(habit),
        );
      },
    );
  }

  /// 构建分组过滤栏
  Widget _buildFilterBar() {
    final groups = _groups;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group == _selectedGroup;
          return ChoiceChip(
            label: Text(group),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                _selectGroup(group);
              }
            },
            showCheckmark: false,
            labelStyle: TextStyle(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            selectedColor: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('habits_habits'.tr),
      largeTitle: 'habits_habits'.tr,
      enableLargeTitle: true,

      // ========== 搜索相关配置 ==========
      enableSearchBar: true, // 启用搜索栏
      searchPlaceholder: 'habits_searchHabitPlaceholder'.tr, // 搜索栏占位符
      onSearchChanged: (query) {
        // 实时搜索，无需等待用户提交
        _filterHabits(query);
      },
      onSearchSubmitted: (query) {
        // 搜索提交时的回调（可选）
        _filterHabits(query);
      },
      searchBody: HabitSearchResultsWidget(
        habits: _filteredHabits,
        controller: widget.controller,
        onHabitTap: _onHabitTap,
        onHabitLongPress: _onHabitLongPress,
      ), // 搜索结果页面
      // ========== 过滤栏配置 ==========
      enableFilterBar: true,
      filterBarChild: _buildFilterBar(),
      actions: [],
      body: _buildCardView(_filteredByGroup),
    );
  }
}
