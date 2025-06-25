import 'package:flutter/material.dart';

import 'calendar_localizations.dart';

class CalendarLocalizationsZh extends CalendarLocalizations {
  CalendarLocalizationsZh(super.locale);

  @override
  String get noCompletedEvents => '暂无活动';

  @override
  String get pluginName => '日历';

  @override
  String get calendar => '日历';

  @override
  String get eventCount => '总活动数';

  @override
  String get weekEvents => '7天内活动';

  @override
  String get expiredEvents => '过期活动';

  @override
  String get allEvents => '所有活动';

  @override
  String get completedEvents => '已完成活动';

  @override
  String get backToToday => '回到今天';

  @override
  String get addEvent => '添加活动';

  @override
  String get editEvent => '编辑活动';

  @override
  String get deleteEvent => '删除活动';

  @override
  String get completeEvent => '完成活动';

  @override
  String get eventTitle => '活动标题';

  @override
  String get eventDescription => '描述';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirmDeleteEvent => '确定要删除此活动吗？';

  @override
  String get noEvents => '没有活动';

  @override
  String get dayView => '日视图';

  @override
  String get weekView => '周视图';

  @override
  String get workWeekView => '工作周视图';

  @override
  String get monthView => '月视图';

  @override
  String get timelineDayView => '时间线日视图';

  @override
  String get timelineWeekView => '时间线周视图';

  @override
  String get timelineWorkWeekView => '时间线工作周视图';

  @override
  String get scheduleView => '日程视图';

  @override
  // TODO: implement reminderSettings
  String get reminderSettings => throw UnimplementedError();

  @override
  // TODO: implement selectDateRangeFirst
  String get selectDateRangeFirst => throw UnimplementedError();

  @override
  // TODO: implement selectReminderTime
  String get selectReminderTime => throw UnimplementedError();

  @override
  // TODO: implement enterEventTitle
  String get enterEventTitle => throw UnimplementedError();

  @override
  // TODO: implement endTimeCannotBeEarlier
  String get endTimeCannotBeEarlier => throw UnimplementedError();
}
