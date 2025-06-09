import 'package:flutter/material.dart';

class HabitsLocalizations {
  const HabitsLocalizations();

  String get habits => 'Habits';
  String get skills => 'Skills';
  String get habit => 'Habit';
  String get skill => 'Skill';
  String get title => 'Title';
  String get notes => 'Notes';
  String get group => 'Group';
  String get duration => 'Duration';
  String get minutes => 'minutes';
  String get reminderDays => 'Reminder Days';
  String get intervalDays => 'Repeat every (days)';
  String get maxDuration => 'Max Duration';
  String get completionRecords => 'Completion Records';
  String get statistics => 'Statistics';
  String get createHabit => 'Create Habit';
  String get createSkill => 'Create Skill';
  String get editHabit => 'Edit Habit';
  String get editSkill => 'Edit Skill';
  String get delete => 'Delete';
  String get startTimer => 'Start Timer';
  String get save => 'Save';
  String get cancel => 'Cancel';

  static HabitsLocalizations of(BuildContext context) {
    return const HabitsLocalizations();
  }
}
