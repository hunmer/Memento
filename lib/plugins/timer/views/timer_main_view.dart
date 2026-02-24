import 'package:get/get.dart';
import 'dart:async';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/plugins/timer/views/add_timer_task_dialog.dart';
import 'package:Memento/plugins/timer/views/timer_task_details_page.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/swipe_action/index.dart';
import 'package:Memento/plugins/timer/timer_plugin.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:collection/collection.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/common/timer_card_widget.dart';

class TimerMainView extends StatefulWidget {
  const TimerMainView({super.key});
  @override
  State<TimerMainView> createState() => _TimerMainViewState();
}

class _TimerMainViewState extends State<TimerMainView> {
  List<TimerTask> _tasks = [];
  late TimerPlugin _plugin;
  Map<String, List<TimerTask>> _groupedTasks = {};
  List<TimerTask> _searchResults = [];
  String _currentQuery = '';
  String _selectedGroup = '全部'; // 当前选中的分组

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager().getPlugin('timer') as TimerPlugin;
    _updateTasksAndGroups();
    _loadConfig();

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateRouteContext(_selectedGroup);
      }
    });
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前分组
  void _updateRouteContext(String group) {
    RouteHistoryManager.updateCurrentContext(
      pageId: "/timer_main",
      title: '计时器 - $group',
      params: {'group': group},
    );
  }

  void _updateTasksAndGroups() {
    _tasks = _plugin.getTasks();
    _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
  }

  /// 执行搜索
  void _searchTasks(String query) {
    setState(() {
      _currentQuery = query;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults =
            _tasks.where((task) {
              final nameMatch = task.name.toLowerCase().contains(
                query.toLowerCase(),
              );
              final groupMatch = task.group.toLowerCase().contains(
                query.toLowerCase(),
              );
              return nameMatch || groupMatch;
            }).toList();
      }
    });
  }

  /// 获取所有分组(用于过滤栏)
  List<String> get _groups {
    final g = _groupedTasks.keys.toList()..sort();
    return ['全部', ...g];
  }

  /// 选择分组
  void _selectGroup(String group) {
    setState(() {
      _selectedGroup = group;
    });
    // 更新路由上下文
    _updateRouteContext(group);
  }

  /// 根据选中的分组过滤任务
  List<TimerTask> get _filteredByGroup {
    if (_selectedGroup == '全部') {
      return _tasks;
    } else {
      return _groupedTasks[_selectedGroup] ?? [];
    }
  }

  Future<void> _loadConfig() async {
    try {
      // final config = await _plugin.storage.read('configs/${_plugin.id}.json');
    } catch (e) {
      // 如果配置不存在，使用默认值
    }
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
      title: Text(_plugin.getPluginName(context)!),
      largeTitle: '计时器',
      enableLargeTitle: true,
      // ========== 搜索相关配置 ==========
      enableSearchBar: true,
      searchPlaceholder: 'timer_searchPlaceholder'.tr,
      onSearchChanged: _searchTasks,
      searchBody: _buildSearchResults(),
      // ========== 过滤栏配置 ==========
      enableFilterBar: true,
      filterBarChild: _buildFilterBar(),

      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final newTask = await NavigationHelper.openContainer<TimerTask>(
              context,
              (context) => AddTimerTaskDialog(
                groups: _plugin.timerController.getGroups(),
              ),
            );
            if (newTask != null) {
              await _plugin.addTask(newTask);
              setState(() {
                _tasks = _plugin.getTasks();
                _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
              });
            }
          },
        ),
      ],
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredByGroup.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final task = _filteredByGroup[index];
          // 根据计时器数量决定是否使用网格布局
          final useGridLayout = task.timerItems.length >= 3;

          return SwipeActionWrapper(
            key: ValueKey(task.id),
            trailingActions: [
              SwipeActionPresets.edit(
                onTap: () => _editTask(task),
              ),
              SwipeActionOption(
                label: '重置',
                icon: Icons.replay,
                backgroundColor: Colors.orange,
                textColor: Colors.white,
                onTap: () => _resetTask(task),
              ),
              SwipeActionPresets.delete(
                onTap: () => _deleteTask(task),
                showConfirm: false,
              ),
            ],
            child: TimerCardWidget(
              task: task,
              onTap: _showTaskDetails,
              onEdit: _editTask,
              onReset: _resetTask,
              onDelete: _deleteTask,
              showGroup: true,  // 显示分组名称
              useGridLayout: useGridLayout,  // 根据计时器数量决定布局
            ),
          );
        },
      ),
    );
  }

  void _showTaskDetails(TimerTask task) async {
    await NavigationHelper.push(
      context,
      TimerTaskDetailsPage(taskId: task.id),
    );
    setState(() {
      _updateTasksAndGroups();
    });
  }

  void _editTask(TimerTask task) async {
    final editedTask = await showDialog<TimerTask>(
      context: context,
      builder:
          (context) => AddTimerTaskDialog(
            groups: _plugin.timerController.getGroups(),
            initialTask: task,
          ),
    );

    if (editedTask != null) {
      await _plugin.updateTask(editedTask);
      await _plugin.saveTasks();
      setState(() {
        _updateTasksAndGroups();
      });
    }
  }

  void _resetTask(TimerTask task) {
    task.reset();
    setState(() {});
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    if (_currentQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '搜索计时器任务',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '输入任务名称或分组名称',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的任务',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前查询：$_currentQuery',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final task = _searchResults[index];
        // 根据计时器数量决定是否使用网格布局
        final useGridLayout = task.timerItems.length >= 3;

        return SwipeActionWrapper(
          key: ValueKey(task.id),
          trailingActions: [
            SwipeActionPresets.edit(
              onTap: () => _editTask(task),
            ),
            SwipeActionOption(
              label: '重置',
              icon: Icons.replay,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              onTap: () => _resetTask(task),
            ),
            SwipeActionPresets.delete(
              onTap: () => _deleteTask(task),
              showConfirm: false,
            ),
          ],
          child: TimerCardWidget(
            task: task,
            onTap: _showTaskDetails,
            onEdit: _editTask,
            onReset: _resetTask,
            onDelete: _deleteTask,
            showGroup: true,  // 显示分组名称
            useGridLayout: useGridLayout,  // 根据计时器数量决定布局
          ),
        );
      },
    );
  }

  void _deleteTask(TimerTask task) async {
    await _plugin.removeTask(task.id);
    setState(() {
      _updateTasksAndGroups();
    });
  }
}
