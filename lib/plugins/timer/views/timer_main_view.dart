import 'dart:async';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/timer/l10n/timer_localizations.dart';
import 'package:flutter/material.dart';
import '../timer_plugin.dart';
import '../models/timer_task.dart';
import '../models/timer_item.dart';
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
        backgroundColor: const Color(0xFFF5F6F8), // Light background
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
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasksInGroup.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final task = tasksInGroup[index];
                    return _TimerTaskCard(
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
            title: Text(TimerLocalizations.of(context).deleteTimer),
            content: Text(
              '${TimerLocalizations.of(context).deleteTimerConfirmation} "${task.name}"',
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

class _TimerTaskCard extends StatefulWidget {
  final TimerTask task;
  final Function(TimerTask) onTap;
  final Function(TimerTask) onEdit;
  final Function(TimerTask) onReset;
  final Function(TimerTask) onDelete;

  const _TimerTaskCard({
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onReset,
    required this.onDelete,
  });

  @override
  State<_TimerTaskCard> createState() => _TimerTaskCardState();
}

class _TimerTaskCardState extends State<_TimerTaskCard> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final bool useGridLayout = task.timerItems.length >= 3;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onTap(task),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: task.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(task.icon, color: task.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.group, // Using group as subtitle/description
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(task),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: useGridLayout 
                  ? _buildGridLayout(task)
                  : _buildListLayout(task),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(TimerTask task) {
    if (task.isRunning) {
      // Active state with timer
       final activeTimer = task.activeTimer;
       String timerText = "Running";
       if (activeTimer != null) {
          timerText = activeTimer.formattedRemainingTime;
       }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
             task.pause();
             setState(() {});
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 const Icon(Icons.pause, size: 18, color: Color(0xFF1E293B)),
                 const SizedBox(width: 6),
                 Text(
                    timerText,
                    style: const TextStyle(
                       fontFamily: 'Monospace',
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                       color: Color(0xFF1E293B),
                    ),
                 ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Start button
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (task.isCompleted) {
              widget.onReset(task);
            } else {
              task.start();
            }
            setState(() {});
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: task.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                   task.isCompleted ? Icons.replay : Icons.play_arrow, 
                   size: 18, 
                   color: Colors.white // Assuming dark text on primary as per HTML, but usually white on primary
                ),
                const SizedBox(width: 4),
                Text(
                  task.isCompleted ? 'Reset' : 'Start',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildGridLayout(TimerTask task) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: task.timerItems.map((item) => _buildGridItem(item)).toList(),
    );
  }

  Widget _buildGridItem(TimerItem item) {
    final progress = item.duration.inSeconds > 0 
        ? item.completedDuration.inSeconds / item.duration.inSeconds 
        : 0.0;
    // Determine color based on type or order? 
    // HTML uses specific colors. We'll use type mapping or random/hash.
    Color itemColor;
    switch(item.type) {
      case TimerType.pomodoro: itemColor = Colors.red; break;
      case TimerType.countUp: itemColor = Colors.blue; break;
      case TimerType.countDown: itemColor = Colors.green; break;
    }
    if (item.name.toLowerCase().contains('break')) {
       itemColor = Colors.blue;
       if (item.duration.inMinutes > 10) itemColor = Colors.green; // Long break
    } else {
       itemColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      // No background in grid items in HTML, just layout
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    color: Colors.grey[200],
                    strokeWidth: 8,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : 0.001, // Show at least a dot? No.
                    color: itemColor,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.type == TimerType.pomodoro)
                       Text(
                          '${item.currentCycle}/${item.cycles}',
                          style: TextStyle(fontSize: 10, color: itemColor.withValues(alpha: 0.7)),
                       ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.duration.inMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: itemColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.type == TimerType.pomodoro 
                 ? (item.isWorkPhase == true ? 'Work' : 'Rest') 
                 : (item.name.contains('Break') ? 'Relax' : 'Work'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: itemColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout(TimerTask task) {
    return Column(
      children: task.timerItems.map((item) => _buildListItem(item, task.color)).toList(),
    );
  }

  Widget _buildListItem(TimerItem item, Color taskColor) {
    final progress = item.duration.inSeconds > 0 
        ? item.completedDuration.inSeconds / item.duration.inSeconds 
        : 0.0;
        
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (item.type == TimerType.pomodoro)
                 Text(
                    '${item.currentCycle}/${item.cycles} cycles',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                 ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
             children: [
                Container(
                   height: 8,
                   decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                   ),
                ),
                FractionallySizedBox(
                   widthFactor: progress.clamp(0.0, 1.0),
                   child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                         color: taskColor,
                         borderRadius: BorderRadius.circular(4),
                      ),
                   ),
                ),
             ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.formattedRemainingTime, // Or total duration? HTML shows total duration e.g. "50 min"
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
