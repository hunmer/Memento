import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:flutter/material.dart';
import '../timer_plugin.dart';
import '../models/timer_task.dart';
import 'timer_task_card.dart';
import 'add_timer_task_dialog.dart';
import 'timer_task_details_page.dart';
import 'package:collection/collection.dart';
import 'package:Memento/l10n/app_localizations.dart';

class TimerMainView extends StatefulWidget {
  const TimerMainView({super.key});
  @override
  State<TimerMainView> createState() => _TimerMainViewState();
}

class _TimerMainViewState extends State<TimerMainView> {
  List<TimerTask> _tasks = [];
  late TimerPlugin _plugin;
  Map<String, List<TimerTask>> _groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager().getPlugin('timer') as TimerPlugin;
    _updateTasksAndGroups();
    _loadConfig();
  }

  void _updateTasksAndGroups() {
    _tasks = _plugin.getTasks();
    _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
  }

  Future<void> _loadConfig() async {
    try {
      // final config = await _plugin.storage.read('configs/${_plugin.id}.json');
    } catch (e) {
      // 如果配置不存在，使用默认值
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedTasks.keys.toList();

    return DefaultTabController(
      length: groups.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => PluginManager.toHomeScreen(context),
          ),
          title: Text(_plugin.getPluginName(context)!),
          bottom: TabBar(
            isScrollable: true,
            tabs: groups.map((group) => Tab(text: group)).toList(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddTaskDialog,
            ),
          ],
        ),
        body: TabBarView(
          children:
              groups.map((group) {
                final tasksInGroup = _groupedTasks[group]!;
                return MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  crossAxisCount: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 8,
                  itemCount: tasksInGroup.length,
                  itemBuilder: (context, index) {
                    final task = tasksInGroup[index];
                    return TimerTaskCard(
                      task: task,
                      onTap: _showTaskDetails,
                      onEdit: _editTask,
                      onReset: _resetTask,
                      onDelete: _deleteTask,
                    );
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  void _showAddTaskDialog() async {
    final groups = _plugin.timerController.getGroups();
    final newTask = await showDialog<TimerTask>(
      context: context,
      builder: (context) => AddTimerTaskDialog(groups: groups),
    );

    if (newTask != null) {
      await _plugin.addTask(newTask);
      setState(() {
        _tasks = _plugin.getTasks();
        _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
      });
    }
  }

  void _showTaskDetails(TimerTask task) async {
    // 导航到任务详情页面
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TimerTaskDetailsPage(
              task: task,
              onReset: () {
                task.reset();
                setState(() {});
              },
              onResume: () {
                task.toggle();
                setState(() {});
              },
            ),
      ),
    );
    // 返回后刷新状态
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

  void _deleteTask(TimerTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(TimerLocalizations.of(context)!.deleteTimer),
            content: Text(
              '${TimerLocalizations.of(context)!.deleteTimerConfirmation} "${task.name}"',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _plugin.removeTask(task.id);
      setState(() {
        _updateTasksAndGroups();
      });
    }
  }
}
