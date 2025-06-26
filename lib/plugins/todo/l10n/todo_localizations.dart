import 'package:Memento/plugins/todo/l10n/todo_localizations_en.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class TodoLocalizations {
  TodoLocalizations(String locale) : localeName = locale;

  final String localeName;

  String get todoPluginName;
  String get todoPluginDescription;
  String get totalTasks;
  String get weeklyTasks;
  String get taskDetailsTitle;
  String get deleteTaskTitle;
  String get deleteTaskMessage;
  String get description;
  String get tags;
  String get timer;
  String get duration;
  String get start;
  String get pause;
  String get complete;
  String get dates;
  String get created;
  String get dueDate;
  String get subtasks;
  String get reminders;
  String get pleaseEnterTitle;
  String get selectDates;
  String get priority;
  String get low;
  String get medium;
  String get high;
  String get addTag;
  String get addReminder;
  String get filterTasksTitle;
  String get showCompleted;
  String get showIncomplete;
  String get selectTagsTitle;
  String get ok;
  String get sortByDueDate;
  String get sortByPriority;
  String get customSort;
  String get completedTasksHistoryTitle;
  String get completedTaskDetailsTitle;
  String get newTask;
  String get editTask;
  String get title;
  String get startDate;
  String get notSet;
  String get clear;
  String get add;

  static const LocalizationsDelegate<TodoLocalizations> delegate =
      _TodoLocalizationsDelegate();

  static TodoLocalizations? of(BuildContext context) {
    return Localizations.of<TodoLocalizations>(context, TodoLocalizations);
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('zh')];
}

class _TodoLocalizationsDelegate
    extends LocalizationsDelegate<TodoLocalizations> {
  const _TodoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<TodoLocalizations> load(Locale locale) {
    return SynchronousFuture<TodoLocalizations>(
      lookupTodoLocalizations(locale),
    );
  }

  @override
  bool shouldReload(_TodoLocalizationsDelegate old) => false;
}

TodoLocalizations lookupTodoLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return TodoLocalizationsEn(locale.languageCode);
    case 'zh':
      return TodoLocalizationsZh(locale.languageCode);
  }

  throw FlutterError(
    'TodoLocalizations.delegate failed to load unsupported locale "$locale". '
    'This is likely an issue with the localizations setup.',
  );
}
