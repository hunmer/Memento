import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:flutter/material.dart';
import '../timer_plugin.dart';
import '../models/timer_task.dart';
import 'timer_task_card.dart';
import 'add_timer_task_dialog.dart';
import 'timer_task_details_page.dart';
import 'package:collection/collection.dart';

class TimerMainView extends StatefulWidget {
  final TimerPlugin plugin;

  const TimerMainView({super.key, required this.plugin});

  @override
  State<TimerMainView> createState() => TimerMainViewState();
}

class TimerMainViewState extends State<TimerMainView> {
  List<TimerTask> _tasks = [];
  Map<String, List<TimerTask>> _groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _updateTasksAndGroups();
    _loadConfig();
  }

  void _updateTasksAndGroups() {
    _tasks = widget.plugin.getTasks();
    _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
  }

  Future<void> _loadConfig() async {
    try {
      final config = await widget.plugin.storage.read(
        'configs/${widget.plugin.id}.json',
      );
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
          title: Text(widget.plugin.name),
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
    final groups = await widget.plugin.timerController.getGroups();
    final newTask = await showDialog<TimerTask>(
      context: context,
      builder: (context) => AddTimerTaskDialog(groups: groups),
    );

    if (newTask != null) {
      await widget.plugin.addTask(newTask);
      setState(() {
        _tasks = widget.plugin.getTasks();
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
            groups: widget.plugin.timerController.getGroups(),
            initialTask: task,
          ),
    );

    if (editedTask != null) {
      await widget.plugin.updateTask(editedTask);
      await widget.plugin.saveTasks();
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
            title: const Text('删除计时器'),
            content: Text('确定要删除"${task.name}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await widget.plugin.removeTask(task.id);
      setState(() {
        _updateTasksAndGroups();
      });
    }
  }
}
