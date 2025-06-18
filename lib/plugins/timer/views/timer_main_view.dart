import 'package:Memento/core/plugin_manager.dart';
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
  int _tasksPerRow = 2;
  Map<String, List<TimerTask>> _groupedTasks = {};
  Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _updateTasksAndGroups();
    _loadConfig();
  }

  void _updateTasksAndGroups() {
    _tasks = widget.plugin.getTasks();
    _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
    _expandedGroups = widget.plugin.expandedGroups;
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
              icon: const Icon(Icons.folder),
              onPressed: () => widget.plugin.showGroupManagementDialog(context),
            ),
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
                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: tasksInGroup.length,
                  itemBuilder: (context, taskIndex) {
                    final task = tasksInGroup[taskIndex];
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
    final newTask = await showDialog<TimerTask>(
      context: context,
      builder: (context) => AddTimerTaskDialog(groups: widget.plugin.groups),
    );

    if (newTask != null) {
      await widget.plugin.addTask(newTask);
      setState(() {
        _tasks = widget.plugin.getTasks();
        _groupedTasks = groupBy(_tasks, (TimerTask task) => task.group);
        _expandedGroups = widget.plugin.expandedGroups;
      });
    }
  }

  void _showTaskDetails(TimerTask task) async {
    // 导航到任务详情页面
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TimerTaskDetailsPage(task: task)),
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
            groups: widget.plugin.groups,
            initialTask: task,
          ),
    );

    if (editedTask != null) {
      // 保持原有的 ID，创建一个完整的任务对象
      final updatedTask = TimerTask(
        id: task.id,
        name: editedTask.name,
        color: editedTask.color,
        icon: editedTask.icon,
        timerItems: editedTask.timerItems,
        createdAt: editedTask.createdAt,
        isRunning: editedTask.isRunning,
        group: editedTask.group,
      );
      await widget.plugin.updateTask(updatedTask);
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
