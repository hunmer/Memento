import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/calendar/utils/calendar_notification_utils.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/form_fields/index.dart';

class EventEditPage extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime initialDate;
  final Function(CalendarEvent) onSave;

  const EventEditPage({
    super.key,
    this.event,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  late final GlobalKey<FormBuilderWrapperState> _formKey;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormBuilderWrapperState>();
    final event = widget.event;
    _startTime = TimeOfDay.fromDateTime(event?.startTime ?? widget.initialDate);
    if (event != null && event.endTime != null) {
      _endTime = TimeOfDay.fromDateTime(event.endTime!);
    }

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前事件编辑状态
  void _updateRouteContext() {
    final isEditing = widget.event != null;
    final initialEvent = widget.event;
    final title = initialEvent?.title ?? '未命名事件';
    final dateStr = initialEvent != null
        ? '${initialEvent.startTime.year}-${initialEvent.startTime.month.toString().padLeft(2, '0')}-${initialEvent.startTime.day.toString().padLeft(2, '0')}'
        : '${widget.initialDate.year}-${widget.initialDate.month.toString().padLeft(2, '0')}-${widget.initialDate.day.toString().padLeft(2, '0')}';

    RouteHistoryManager.updateCurrentContext(
      pageId: isEditing ? '/calendar_event_edit' : '/calendar_event_new',
      title: isEditing ? '编辑事件 - $title' : '新建事件',
      params: {
        'mode': isEditing ? '编辑' : '新建',
        'eventTitle': title,
        'startDate': dateStr,
        if (isEditing) 'eventId': widget.event!.id,
      },
    );
  }

  /// 组合日期和时间
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// 保存事件
  Future<void> _saveEvent(Map<String, dynamic> values) async {
    final title = values['title'] as String?;
    if (title == null || title.isEmpty) {
      toastService.showToast('calendar_enterEventTitle'.tr);
      return;
    }

    final description = values['description'] as String? ?? '';
    final iconColorData = values['iconColor'] as Map<String, dynamic>?;
    final selectedIcon = iconColorData?['icon'] as IconData? ?? Icons.event;
    final selectedColor = iconColorData?['color'] as Color? ?? Colors.blue;

    // 日期范围处理
    final dateRange = values['dateRange'] as Map<String, dynamic>?;
    final startDate = dateRange?['startDate'] as DateTime? ?? widget.initialDate;
    final endDate = dateRange?['endDate'] as DateTime?;

    // 使用状态变量中的时间
    final startDateTime = _combineDateAndTime(startDate, _startTime);
    DateTime endDateTime;

    if (endDate != null) {
      TimeOfDay effectiveEndTime = _endTime ?? _startTime;
      endDateTime = _combineDateAndTime(endDate, effectiveEndTime);
    } else {
      endDateTime = startDateTime.add(const Duration(hours: 1));
    }

    if (endDateTime.isBefore(startDateTime)) {
      toastService.showToast('calendar_endTimeCannotBeEarlier'.tr);
      return;
    }

    // 提醒设置处理
    final reminderMinutes = values['reminder'] as int?;

    final event = CalendarEvent(
      id: widget.event?.id ?? const Uuid().v4(),
      title: title,
      description: description,
      startTime: startDateTime,
      endTime: endDateTime,
      icon: selectedIcon,
      color: selectedColor,
      reminderMinutes: reminderMinutes,
      source: 'default',
    );

    // 设置提醒
    if (reminderMinutes != null) {
      final reminderTime = startDateTime.subtract(
        Duration(minutes: reminderMinutes),
      );
      if (reminderTime.isAfter(DateTime.now())) {
        await CalendarNotificationUtils.scheduleEventNotification(
          id: int.parse(event.id),
          title: event.title,
          body: event.description,
          scheduledDateTime: reminderTime,
          payload: event.id,
        );
      }
    }

    widget.onSave(event);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: Text(event == null ? '新建事件' : '编辑事件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _formKey.currentState?.submitForm();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilderWrapper(
          key: _formKey,
          config: FormConfig(
            showSubmitButton: false,
            showResetButton: false,
            fieldSpacing: 16,
            fields: [
              // 图标和颜色选择器
              FormFieldConfig(
                name: 'iconColor',
                type: FormFieldType.circleIconPicker,
                initialValue: event != null
                    ? {
                        'icon': event.icon,
                        'color': event.color,
                      }
                    : {
                        'icon': Icons.event,
                        'color': Colors.blue,
                      },
              ),

              // 事件标题
              FormFieldConfig(
                name: 'title',
                type: FormFieldType.text,
                labelText: 'calendar_eventTitle'.tr,
                hintText: '请输入事件标题',
                initialValue: event?.title ?? '',
                required: true,
                validationMessage: 'calendar_enterEventTitle'.tr,
              ),

              // 事件描述
              FormFieldConfig(
                name: 'description',
                type: FormFieldType.textArea,
                labelText: 'calendar_eventDescription'.tr,
                hintText: '请输入事件描述',
                initialValue: event?.description ?? '',
                extra: {
                  'minLines': 3,
                  'maxLines': 5,
                },
              ),

              // 日期范围选择器
              FormFieldConfig(
                name: 'dateRange',
                type: FormFieldType.dateRange,
                initialValue: event?.endTime != null
                    ? {
                        'startDate': event!.startTime,
                        'endDate': event.endTime,
                      }
                    : {
                        'startDate': event?.startTime ?? widget.initialDate,
                        'endDate': null,
                      },
                extra: {
                  'rangeLabelText': 'calendar_dateRange'.tr,
                  'firstDate': DateTime(2000),
                  'lastDate': DateTime(2100),
                },
              ),

              // 提醒设置
              FormFieldConfig(
                name: 'reminder',
                type: FormFieldType.select,
                labelText: 'calendar_reminderSettings'.tr,
                initialValue: event?.reminderMinutes,
                items: const [
                  DropdownMenuItem(value: null, child: Text('不提醒')),
                  DropdownMenuItem(value: 5, child: Text('提前5分钟')),
                  DropdownMenuItem(value: 15, child: Text('提前15分钟')),
                  DropdownMenuItem(value: 30, child: Text('提前30分钟')),
                  DropdownMenuItem(value: 60, child: Text('提前1小时')),
                  DropdownMenuItem(value: 120, child: Text('提前2小时')),
                  DropdownMenuItem(value: 1440, child: Text('提前1天')),
                  DropdownMenuItem(value: 2880, child: Text('提前2天')),
                ],
              ),
            ],
            onSubmit: _saveEvent,
          ),
          // 使用 contentBuilder 来添加时间选择器（并排显示）
          contentBuilder: (context, fields) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标和颜色
                fields[0],
                // 标题
                fields[1],
                // 描述
                fields[2],
                // 日期范围
                fields[3],
                // 提醒设置
                fields[4],
                // 时间选择器（并排显示）
                Row(
                  children: [
                    Expanded(
                      child: TimePickerField(
                        label: 'calendar_startTime'.tr,
                        time: _startTime,
                        onTimeChanged: (time) {
                          setState(() {
                            _startTime = time;
                            // 如果结束时间未设置，默认设置为开始时间后1小时
                            _endTime ??= TimeOfDay(
                              hour: (time.hour + 1) % 24,
                              minute: time.minute,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TimePickerField(
                        label: 'calendar_endTime'.tr,
                        time: _endTime ?? const TimeOfDay(hour: 0, minute: 0),
                        onTimeChanged: (time) {
                          setState(() {
                            _endTime = time;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
