import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:flutter/material.dart';
import '../models/timer_task.dart';
import '../../../../core/event/event_manager.dart';

class TimerTaskDetailsPage extends StatefulWidget {
  final TimerTask task;
  final VoidCallback onReset;
  final VoidCallback onResume;

  const TimerTaskDetailsPage({
    super.key,
    required this.task,
    required this.onReset,
    required this.onResume,
  });

  @override
  State<TimerTaskDetailsPage> createState() => _TimerTaskDetailsPageState();
}

class _TimerTaskDetailsPageState extends State<TimerTaskDetailsPage> {
  late TimerTask _currentTask;
  late int _currentTimerIndex = 0;
  late bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _currentTimerIndex = _currentTask.getCurrentIndex();
    if (_currentTimerIndex == -1) _currentTimerIndex = 0;
    _isRunning = _currentTask.isRunning;
    // 订阅任务变更事件
    EventManager.instance.subscribe('timer_task_changed', onTimerTaskChanged);
    // 订阅计时器进度更新事件
    EventManager.instance.subscribe('timer_item_progress', onTimerItemProgress);
    // 订阅计时器开始事件
    EventManager.instance.subscribe('timer_item_changed', onTimerItemChanged);
  }

  onTimerItemProgress(EventArgs args) {
    if (args is TimerItemEventArgs &&
        _currentTask.timerItems.contains(args.timer)) {
      setState(() {});
    }
  }

  void onTimerTaskChanged(EventArgs args) {
    if (args is TimerTaskEventArgs && args.task.id == _currentTask.id) {
      setState(() {
        _currentTask = args.task;
        _isRunning = _currentTask.isRunning;
      });
    }
  }

  void onTimerItemChanged(EventArgs args) {
    if (args is TimerItemEventArgs &&
        _currentTask.timerItems.contains(args.timer)) {
      setState(() {
        _currentTimerIndex = _currentTask.timerItems.indexOf(args.timer);
      });
    }
  }

  @override
  void dispose() {
    // 取消所有订阅
    EventManager.instance.unsubscribe('timer_task_changed', onTimerTaskChanged);
    EventManager.instance.unsubscribe(
      'timer_item_progress',
      onTimerItemProgress,
    );
    EventManager.instance.unsubscribe('timer_item_changed', onTimerItemChanged);
    super.dispose();
  }

  String _formatRemainingTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds remaining";
  }

  @override
  Widget build(BuildContext context) {
    final currentTimer = _currentTask.timerItems[_currentTimerIndex];
    final progress = (currentTimer.completedDuration.inSeconds /
            currentTimer.duration.inSeconds)
        .clamp(0.0, 1.0);
    final remainingTime = currentTimer.duration - currentTimer.completedDuration;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = Color(0xFF607AFB);

    return Scaffold(
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
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.textTheme.titleLarge?.color?.withOpacity(0.7)),
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
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.restore),
              onPressed: widget.onReset,
              tooltip: 'Reset',
            ),
          )
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
                ? Border.all(
                    color: primaryColor,
                    width: 2,
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildControlButton(Color primaryColor) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: widget.onResume,
      icon: Icon(
        _isRunning ? Icons.pause : Icons.play_arrow,
        size: 36,
      ),
      label: Text(
        _isRunning ? 'Pause' : 'Play',
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
