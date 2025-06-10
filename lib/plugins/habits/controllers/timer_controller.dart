import 'package:Memento/plugins/habits/models/habit.dart';

class TimerController {
  Habit? _currentTimerHabit;
  bool _isRunning = false;
  bool _isCountdown = true;
  int _elapsedSeconds = 0;

  Habit? get currentTimerHabit => _currentTimerHabit;

  bool isHabitTiming(String habitId) {
    return _currentTimerHabit?.id == habitId;
  }

  void startTimer(Habit habit) {
    _currentTimerHabit = habit;
    _isRunning = true;
    _elapsedSeconds = 0;
  }

  void stopTimer() {
    _currentTimerHabit = null;
    _isRunning = false;
  }

  Map<String, dynamic> getTimerData(String habitId) {
    if (!isHabitTiming(habitId)) {
      throw StateError('No timer running for habit $habitId');
    }
    return {
      'isRunning': _isRunning,
      'isCountdown': _isCountdown,
      'elapsedSeconds': _elapsedSeconds,
    };
  }
}
