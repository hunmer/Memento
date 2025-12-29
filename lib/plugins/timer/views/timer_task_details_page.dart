import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/timer/timer_plugin.dart';

class TimerTaskDetailsPage extends StatefulWidget {
  final String taskId;

  const TimerTaskDetailsPage({
    super.key,
    required this.taskId,
  });

  @override
  State<TimerTaskDetailsPage> createState() => _TimerTaskDetailsPageState();
}

class _TimerTaskDetailsPageState extends State<TimerTaskDetailsPage> {
  late TimerPlugin _plugin;
  late TimerTask _currentTask;
  late int _currentTimerIndex;
  late bool _isRunning;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin;
    _loadTask();
    _subscribeToEvents();
    _updateRouteContext();
  }

  void _loadTask() {
    final tasks = _plugin.getTasks();
    final task = tasks.firstWhereOrNull((t) => t.id == widget.taskId);
    if (task != null) {
      _currentTask = task;
      _currentTimerIndex = _currentTask.getCurrentIndex();
      if (_currentTimerIndex == -1) _currentTimerIndex = 0;
      _isRunning = _currentTask.isRunning;
    }
  }

  void _subscribeToEvents() {
    EventManager.instance.subscribe('timer_task_changed', onTimerTaskChanged);
    EventManager.instance.subscribe('timer_item_progress', onTimerItemProgress);
    EventManager.instance.subscribe('timer_item_changed', onTimerItemChanged);
  }

  void onTimerItemProgress(EventArgs args) {
    if (args is TimerItemEventArgs &&
        _currentTask.timerItems.any((item) => item.id == args.timer.id)) {
      if (mounted) setState(() {});
    }
  }

  void onTimerTaskChanged(EventArgs args) {
    if (args is TimerTaskEventArgs && args.task.id == _currentTask.id) {
      if (mounted) {
        setState(() {
          _currentTask = args.task;
          _isRunning = _currentTask.isRunning;
        });
        _updateRouteContext();
      }
    }
  }

  void onTimerItemChanged(EventArgs args) {
    if (args is TimerItemEventArgs &&
        _currentTask.timerItems.any((item) => item.id == args.timer.id)) {
      if (mounted) {
        setState(() {
          _currentTimerIndex = _currentTask.timerItems
              .indexWhere((item) => item.id == args.timer.id);
        });
        _updateRouteContext();
      }
    }
  }

  void _updateRouteContext() {
    final currentTimer = _currentTask.timerItems[_currentTimerIndex];
    RouteHistoryManager.updateCurrentContext(
      pageId: "/timer_details",
      title: '计时器详情 - ${_currentTask.name}',
      params: {
        'taskId': _currentTask.id,
        'taskName': _currentTask.name,
        'currentTimerName': currentTimer.name,
        'isRunning': _isRunning.toString(),
      },
    );
  }

  @override
  void dispose() {
    EventManager.instance.unsubscribe('timer_task_changed', onTimerTaskChanged);
    EventManager.instance.unsubscribe('timer_item_progress', onTimerItemProgress);
    EventManager.instance.unsubscribe('timer_item_changed', onTimerItemChanged);
    super.dispose();
  }

  void _handlePlayPause() {
    if (_isRunning) {
      _currentTask.pause();
    } else {
      _currentTask.start();
    }
    // 立即更新本地状态
    setState(() {
      _isRunning = _currentTask.isRunning;
    });
    _plugin.updateTask(_currentTask);
  }

  void _handleReset() {
    _currentTask.reset();
    _plugin.updateTask(_currentTask);
  }

  String _formatRemainingTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds ${'timer_remainingTime'.tr}";
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTask.timerItems.isEmpty) {
      return Scaffold(
        body: Center(child: Text('timer_taskEmpty'.tr)),
      );
    }

    final currentTimer = _currentTask.timerItems[_currentTimerIndex];
    final progress = (currentTimer.completedDuration.inSeconds /
            currentTimer.duration.inSeconds)
        .clamp(0.0, 1.0);
    final remainingTime = currentTimer.duration - currentTimer.completedDuration;
    final theme = Theme.of(context);
    final primaryColor = Color(0xFF607AFB);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _handleReset,
            tooltip: 'timer_reset'.tr,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentTask.name,
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTimer.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.textTheme.titleLarge?.color?.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildCircularProgress(progress, remainingTime, primaryColor),
                  const SizedBox(height: 48),
                  _buildProgressDots(primaryColor),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: _buildControlButton(primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress(
      double progress, Duration remainingTime, Color primaryColor) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            strokeCap: StrokeCap.round,
            color: primaryColor,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.displayLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRemainingTime(remainingTime),
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots(Color primaryColor) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          List.generate(_currentTask.timerItems.length, (index) {
        bool isActive = index == _currentTimerIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentTimerIndex
                ? primaryColor
                : theme.colorScheme.onSurface.withOpacity(0.2),
            border: isActive
                ? Border.all(color: primaryColor, width: 2)
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildControlButton(Color primaryColor) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: _handlePlayPause,
      icon: Icon(
        _isRunning ? Icons.pause : Icons.play_arrow,
        size: 36,
      ),
      label: Text(
        _isRunning ? 'timer_pause'.tr : 'timer_play'.tr,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.colorScheme.primary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(192, 64),
      ),
    );
  }
}
