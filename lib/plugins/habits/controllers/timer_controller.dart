import 'dart:async';
import 'package:Memento/plugins/habits/models/habit.dart';

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

  void dispose() {
    _timers.values.forEach((state) => state.dispose());
    _timers.clear();
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
    });
  }

  void stop() {
    isRunning = false;
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
