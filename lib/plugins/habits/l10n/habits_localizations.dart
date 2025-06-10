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
  String get pleaseEnterTitle => 'please Enter Title';
  String get sortByName => 'Sort by Name';
  String get sortByCompletions => 'Sort by Completions';
  String get sortByDuration => 'Sort by Duration';
  String get completions => 'Completions';
  String get totalDuration => 'Total Duration';
  String get edit => 'Edit';
  String get close => 'Close';
  String get records => 'records';
  String get recentRecords => 'recent Records';
  String get deleteSkill => 'Delete Skill';
  String get deleteSkillConfirmation =>
      'Are you sure you want to delete this skill?';
  String get totalCompletions => 'Total Completions';
  String get statisticsChartsPlaceholder =>
      'Statistics charts will be displayed here';
  String get history => 'History';
  String get editRecord => 'Edit Record';
  String get editRecordMessage => 'Edit completion record details';
  String get deleteRecord => 'Delete Record';
  String get deleteRecordMessage =>
      'Are you sure you want to delete this record?';
  String get recordUpdated => 'Record updated';
  String get recordDeleted => 'Record deleted';

  static HabitsLocalizations of(BuildContext context) {
    return const HabitsLocalizations();
  }
}
