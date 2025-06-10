import 'dart:async';
import 'package:Memento/plugins/habits/models/habit.dart';

class TimerController {
  final Map<String, TimerState> _timers = {};

  bool isHabitTiming(String habitId) => _timers.containsKey(habitId);

  void startTimer(Habit habit) {
    stopTimer(habit.id);
    _timers[habit.id] = TimerState(
      habit: habit,
      isRunning: true,
      elapsedSeconds: 0,
    )..startTimer();
  }

  void stopTimer(String habitId) {
    _timers[habitId]?.dispose();
    _timers.remove(habitId);
  }

  void toggleTimer(String habitId, bool isRunning) {
    final state = _timers[habitId];
    if (state != null) {
      if (isRunning) {
        state.startTimer();
      } else {
        state.stopTimer();
      }
    }
  }

  Map<String, dynamic> getTimerData(String habitId) {
    final state = _timers[habitId];
    if (state == null) {
      throw StateError('No timer running for habit $habitId');
    }
    return {
      'isRunning': state.isRunning,
      'isCountdown': state.isCountdown,
      'elapsedSeconds': state.elapsedSeconds,
    };
  }

  void dispose() {
    _timers.values.forEach((state) => state.dispose());
    _timers.clear();
  }
}

class TimerState {
  final Habit habit;
  bool isRunning;
  bool isCountdown;
  int elapsedSeconds;
  Timer? _timer;

  TimerState({
    required this.habit,
    this.isRunning = false,
    this.isCountdown = true,
    this.elapsedSeconds = 0,
  });

  void startTimer() {
    isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
    });
  }

  void stopTimer() {
    isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopTimer();
  }
}
