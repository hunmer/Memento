import 'package:Memento/plugins/todo/l10n/todo_localizations_en.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract class TodoLocalizations {
  TodoLocalizations(String locale) : localeName = locale;

  final String localeName;

  String get name;
  String get todoPluginDescription;
  String get totalTasks;
  String get weeklyTasks;
  String get taskDetailsTitle;
  String get deleteTaskTitle;
  String get deleteTaskMessage;
  String get description;
  String get notes;
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
  String get createTask;
  String get saveTask;
  String get title;
  String get startDate;
  String get notSet;
  String get clear;
  String get add;
  String get totalTasksCount; // 总任务数
  String get weeklyTasksCount; // 七日任务数
  String get completedOn; // 完成于
  String get searchIn;
  String get createdAt; // 创建于
  String get noCompletedTasks; // 暂无已完成任务
  String get delete; // 删除
  String get cancel; // 取消
  String get close; // 关闭
  String get edit; // 编辑
  String get deleteTask; // 删除任务
  String get confirmDeleteThisTask; // 确定要删除这个任务吗？
  String get configureTodoListWidget; // 配置待办列表小组件
  String get configureQuadrantWidget; // 配置四象限小组件

  // 时间范围选项
  String get today; // 今日
  String get thisWeek; // 本周
  String get thisMonth; // 本月
  String get all; // 所有

  // Tab 标签
  String get todoTab; // 待办
  String get historyTab; // 历史

  // 搜索相关
  String get searchTasksHint; // 搜索任务标题、备注、标签...
  String get searchTitle; // 标题
  String get searchDescription; // 备注
  String get searchTag; // 标签
  String get searchSubtask; // 子任务
  String get searchInputHint; // 输入关键词开始搜索
  String get searchSupportHint; // 支持搜索：标题、备注、标签、子任务
  String get noMatchingTasks; // 未找到匹配的任务
  String get tryOtherKeywords; // 尝试使用其他关键词

  // 历史记录相关
  String get historyTitle; // 历史记录
  String get clearHistoryTitle; // 清空历史记录
  String get clearHistoryMessage; // 确定要清空所有历史记录吗？此操作不可撤销。
  String get clearHistoryAction; // 清空

  // 其他
  String get todoTasks; // 待办事项
  String get widgetTitle; // 小组件标题
  String get timeRange; // 时间范围
  String get noTodoTasks; // 暂无待办任务
  String get confirmConfiguration; // 确认配置
  String get leaveEmptyForDefaultTitle; // 留空则使用默认标题
  String get loading; // 加载中
  String get done; // 完成

  static const LocalizationsDelegate<TodoLocalizations> delegate =
      _TodoLocalizationsDelegate();

  static TodoLocalizations of(BuildContext context) {
    final localizations = Localizations.of<TodoLocalizations>(
      context,
      TodoLocalizations,
    );
    if (localizations == null) {
      throw FlutterError('No TodoLocalizations found in context');
    }
    return localizations;
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
