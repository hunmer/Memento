import 'dart:async';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/services/foreground_timer_service.dart';
import 'package:Memento/plugins/habits/models/habit.dart';

class HabitTimerEventArgs extends EventArgs {
  final String habitId;
  final int elapsedSeconds;
  final bool isCountdown;
  final bool isRunning;

  HabitTimerEventArgs({
    required this.habitId,
    required this.elapsedSeconds,
    required this.isCountdown,
    required this.isRunning,
  });
}

typedef TimerUpdateCallback = void Function(int elapsedSeconds);

class TimerController {
  static TimerController? _instance;

  factory TimerController() {
    return _instance ??= TimerController._internal();
  }

  TimerController._internal() {
    _timers = {};
  }

  Map<String, TimerState> _timers = {};

  bool isHabitTiming(String habitId) => _timers.containsKey(habitId);

  void startTimer(
    Habit habit,
    TimerUpdateCallback onUpdate, {
    Duration? initialDuration,
  }) {
    stopTimer(habit.id);
    _timers[habit.id] = TimerState(
      habit: habit,
      onUpdate: onUpdate,
      initialDuration: initialDuration,
    )..start();
  }

  void stopTimer(String habitId) {
    _timers[habitId]?.dispose();
    _timers.remove(habitId);
  }

  void pauseTimer(String habitId) {
    final state = _timers[habitId];
    if (state != null) {
      state.stop();
    }
  }

  void toggleTimer(String habitId, bool isRunning) {
    final state = _timers[habitId];
    if (state != null) {
      if (isRunning) {
        state.start();
      } else {
        state.stop();
      }
    }
  }

  void setCountdownMode(String habitId, bool isCountdown) {
    final state = _timers[habitId];
    if (state != null) {
      state.isCountdown = isCountdown;
    }
  }

  Map<String, dynamic>? getTimerData(String habitId) {
    final state = _timers[habitId];
    if (state == null) return null;
    return {
      'isRunning': state.isRunning,
      'notes': state.notes,
      'isCountdown': state.isCountdown,
      'elapsedSeconds': state.elapsedSeconds,
    };
  }

  void clearTimerData(String habitId) {
    _timers[habitId]?.dispose();
    _timers.remove(habitId);
    // 确保停止前台通知服务
    ForegroundTimerService.stopService(id: habitId);
  }

  void updateTimerData(String habitId, Map<String, dynamic> data) {
    final state = _timers[habitId];
    if (state != null) {
      state.notes = data['notes'] ?? state.notes;
      state.isRunning = data['isRunning'] ?? state.isRunning;
      state.isCountdown = data['isCountdown'] ?? state.isCountdown;
      state.elapsedSeconds = data['elapsedSeconds'] ?? state.elapsedSeconds;
    }
  }

  Map<String, bool> getActiveTimers() {
    return _timers.map((key, value) => MapEntry(key, value.isRunning));
  }
}

class TimerState {
  final Habit habit;
  final TimerUpdateCallback onUpdate;
  bool isRunning = false;
  bool isCountdown = true;
  int elapsedSeconds = 0;
  String? notes = '';
  Timer? _timer;
  final Duration? initialDuration;
  bool _isDisposed = false;

  TimerState({
    required this.habit,
    required this.onUpdate,
    this.initialDuration,
  }) {
    final initialDuration = this.initialDuration;
    if (initialDuration != null) {
      elapsedSeconds = initialDuration.inSeconds;
    }
  }

  void start() {
    if (isRunning) return;
    isRunning = true;
    _isDisposed = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      elapsedSeconds++;
      onUpdate(elapsedSeconds);
      // 更新前台通知
      _updateForegroundNotification();
    });

    // 启动前台通知服务
    ForegroundTimerService.startService(
      id: habit.id,
      name: habit.title,
      elapsedSeconds: elapsedSeconds,
      totalSeconds: isCountdown ? habit.durationMinutes * 60 : null,
      isCountdown: isCountdown,
    );

    EventManager.instance.broadcast(
      'habit_timer_started',
      HabitTimerEventArgs(
        habitId: habit.id,
        elapsedSeconds: elapsedSeconds,
        isCountdown: isCountdown,
        isRunning: true,
      ),
    );
  }

  void stop() {
    isRunning = false;
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;

    // 停止前台通知服务
    ForegroundTimerService.stopService(id: habit.id);

    EventManager.instance.broadcast(
      'habit_timer_stopped',
      HabitTimerEventArgs(
        habitId: habit.id,
        elapsedSeconds: elapsedSeconds,
        isCountdown: isCountdown,
        isRunning: false,
      ),
    );
  }

  void dispose() {
    stop();
  }

  /// 更新前台通知
  void _updateForegroundNotification() {
    ForegroundTimerService.updateService(
      id: habit.id,
      name: habit.title,
      elapsedSeconds: elapsedSeconds,
      totalSeconds: isCountdown ? habit.durationMinutes * 60 : null,
      isCompleted: false,
    );
  }
}
