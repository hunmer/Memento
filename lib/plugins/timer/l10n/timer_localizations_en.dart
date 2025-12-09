import 'timer_localizations.dart';

class TimerLocalizationsEn extends {
  TimerLocalizationsEn() : super('en');

  @override
  String get totalTimer => 'Total';

  @override
  String get deleteTimer => 'Delete Timer';

  @override
  String get deleteTimerConfirmation =>
      'Are you sure you want to delete this timer?';

  @override
  String get countUpTimer => 'Count Up';

  @override
  String get countDownTimer => 'Count Down';

  @override
  String get pomodoroTimer => 'Pomodoro';

  @override
  String get enableNotification => 'Enable Notification';

  @override
  String get addTimer => 'Add Timer';

  @override
  String get reset => 'Reset';

  @override
  String get timerName => 'Timer Name';

  @override
  String get timerDescription => 'Timer Description';

  @override
  String get timerType => 'Timer Type';

  @override
  String get repeatCount => 'Repeat Count';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Seconds';

  @override
  String get workDuration => 'Work Duration (minutes)';

  @override
  String get breakDuration => 'Break Duration (minutes)';

  @override
  String get cycleCount => 'Cycle Count';

  @override
  String get taskName => 'Task Name';

  @override
  String get selectGroup => 'Select Group';

  @override
  String get name => 'Timer';

  // New missing strings
  @override
  String get cancelTimer => 'Cancel Timer';

  @override
  String get pauseTimerConfirm => 'Are you sure you want to pause the timer? Recorded time: {time}';

  @override
  String get continueTimer => 'Continue Timer';

  @override
  String get confirmCancel => 'Confirm Cancel';

  @override
  String get completeTimer => 'Complete Timer';

  @override
  String get completeTimerConfirm => 'Are you sure you want to complete the timer?\nRecorded time: {time}{note}';

  @override
  String get timerNotePrefix => 'Note: ';

  @override
  String get continueAdjust => 'Continue Adjust';

  @override
  String get confirmComplete => 'Confirm Complete';
}
