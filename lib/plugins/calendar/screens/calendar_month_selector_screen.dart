import 'dart:io';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import '../controllers/calendar_controller.dart' as app;
import 'package:Memento/widgets/widget_config_editor/widget_config_editor.dart';
import 'package:Memento/widgets/widget_config_editor/models/widget_config.dart';
import 'package:Memento/widgets/widget_config_editor/models/color_config.dart';
import 'package:Memento/widgets/widget_config_editor/models/widget_size.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 日历月视图小组件配置界面
///
/// 功能:
/// - 显示当前月份的日历视图
/// - 每日显示该日的事件数量
/// - 点击日期可查看当日事件列表
/// - 支持主题颜色和透明度配置
/// - 实时预览小组件效果
class CalendarMonthSelectorScreen extends StatefulWidget {
  final int? widgetId;

  const CalendarMonthSelectorScreen({super.key, this.widgetId});

  @override
  State<CalendarMonthSelectorScreen> createState() =>
      _CalendarMonthSelectorScreenState();
}

class _CalendarMonthSelectorScreenState
    extends State<CalendarMonthSelectorScreen> {
  late CalendarPlugin _calendarPlugin;
  late app.CalendarController _controller;
  late WidgetConfig _widgetConfig;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calendarPlugin =
        PluginManager.instance.getPlugin('calendar') as CalendarPlugin;
    _controller = _calendarPlugin.controller;
    _initWidgetConfig();
    _loadSavedConfig();
  }

  /// 初始化小组件配置
  void _initWidgetConfig() {
    _widgetConfig = WidgetConfig(
      colors: [
        ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: const Color(0xFFD35B5B), // 日历插件的主色调（红色）
          currentValue: const Color(0xFFD35B5B),
        ),
        ColorConfig(
          key: 'accent',
          label: '标题色',
          defaultValue: Colors.white,
          currentValue: Colors.white,
        ),
      ],
      opacity: 0.95,
    );
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    if (widget.widgetId == null) return;

    try {
      // 加载颜色配置
      final primaryColorStr = await HomeWidget.getWidgetData<String>(
        'calendar_widget_primary_color_${widget.widgetId}',
      );
      final accentColorStr = await HomeWidget.getWidgetData<String>(
        'calendar_widget_accent_color_${widget.widgetId}',
      );
      final opacityStr = await HomeWidget.getWidgetData<String>(
        'calendar_widget_opacity_${widget.widgetId}',
      );

      setState(() {
        // 解析颜色值
        final colors = List<ColorConfig>.from(_widgetConfig.colors);

        if (primaryColorStr != null) {
          final colorValue = int.tryParse(primaryColorStr);
          if (colorValue != null) {
            final primaryIndex = colors.indexWhere((c) => c.key == 'primary');
            if (primaryIndex != -1) {
              colors[primaryIndex] = colors[primaryIndex].copyWith(
                currentValue: Color(colorValue),
              );
            }
          }
        }

        if (accentColorStr != null) {
          final colorValue = int.tryParse(accentColorStr);
          if (colorValue != null) {
            final accentIndex = colors.indexWhere((c) => c.key == 'accent');
            if (accentIndex != -1) {
              colors[accentIndex] = colors[accentIndex].copyWith(
                currentValue: Color(colorValue),
              );
            }
          }
        }

        final newOpacity =
            opacityStr != null
                ? (double.tryParse(opacityStr) ?? 0.95)
                : _widgetConfig.opacity;

        _widgetConfig = WidgetConfig(colors: colors, opacity: newOpacity);
      });
    } catch (e) {
      debugPrint('加载配置失败: $e');
    }
  }

  /// 构建实时预览组件
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final primaryColor = config.getColor('primary') ?? Colors.red;
    final accentColor = config.getColor('accent') ?? Colors.white;
    final opacity = config.opacity;

    // 获取当前月份
    final now = DateTime.now();
    final monthName = DateFormat('M月', 'zh_CN').format(now);

    // 获取本月1日是星期几 (1=周一, 7=周日)
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday;

    // 获取本月天数
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // 构建日历网格
    final List<Widget> dayWidgets = [];

    // 填充空白（本月1日之前）
    for (int i = 1; i < weekdayOfFirstDay; i++) {
      dayWidgets.add(Container());
    }

    // 填充本月日期
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final isToday = day == now.day;
      final isFuture = day > now.day;

      // 获取当日事件数量
      final events =
          _controller.getAllEvents().where((event) {
            final eventDate = event.startTime;
            return eventDate.year == date.year &&
                eventDate.month == date.month &&
                eventDate.day == date.day;
          }).length;

      dayWidgets.add(
        _buildDayCell(day, events, isToday, isFuture, primaryColor, opacity),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '日历',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.chevron_left, color: accentColor, size: 16),
                  Text(
                    monthName,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: accentColor, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 星期标题
          Row(
            children:
                ['一', '二', '三', '四', '五', '六', '日']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: accentColor.withOpacity(0.6),
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 2),

          // 日历网格
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: dayWidgets,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个日期格子
  Widget _buildDayCell(
    int day,
    int eventCount,
    bool isToday,
    bool isFuture,
    Color primaryColor,
    double opacity,
  ) {
    Color bgColor;
    Color textColor;

    if (isFuture) {
      // 未来日期：淡灰色
      bgColor = Colors.transparent;
      textColor = Colors.grey.shade400;
    } else if (isToday && eventCount > 0) {
      // 今天有事件：深色背景
      bgColor = primaryColor.withOpacity(0.8);
      textColor = Colors.white;
    } else if (isToday) {
      // 今天无事件：浅色背景
      bgColor = primaryColor.withOpacity(0.2);
      textColor = primaryColor;
    } else if (eventCount > 0) {
      // 过去有事件：深色背景
      bgColor = primaryColor.withOpacity(0.6);
      textColor = Colors.white;
    } else {
      // 过去无事件：透明背景
      bgColor = Colors.transparent;
      textColor = Colors.grey.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // 日期数字
          Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontSize: 8,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // 事件数量指示器（右下角小圆点）
          if (eventCount > 0 && !isFuture)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isToday || eventCount > 0 ? Colors.white : primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 保存配置并完成
  Future<void> _saveAndFinish() async {
    if (widget.widgetId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. 获取配置值
      final primaryColor = _widgetConfig.getColor('primary') ?? Colors.red;
      final accentColor = _widgetConfig.getColor('accent') ?? Colors.white;
      final opacity = _widgetConfig.opacity;

      // 2. 保存颜色配置（必须使用 String 类型）
      await HomeWidget.saveWidgetData<String>(
        'calendar_widget_primary_color_${widget.widgetId}',
        primaryColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_widget_accent_color_${widget.widgetId}',
        accentColor.value.toString(),
      );

      await HomeWidget.saveWidgetData<String>(
        'calendar_widget_opacity_${widget.widgetId}',
        opacity.toString(),
      );

      // 3. 同步数据到小组件
      await _syncCalendarMonthData();

      // 4. 更新小组件
      await HomeWidget.updateWidget(
        name: 'CalendarMonthWidgetProvider',
        iOSName: 'CalendarMonthWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.CalendarMonthWidgetProvider',
      );

      if (mounted) {
        ToastService.instance.showToast('配置已保存');
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('保存配置失败: $e');
      if (mounted) {
        ToastService.instance.showToast('保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 同步日历月视图数据
  Future<void> _syncCalendarMonthData() async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      // 获取本月所有事件
      final allEvents = _controller.getAllEvents();
      final monthEvents =
          allEvents.where((event) {
            return event.startTime.isAfter(
                  firstDayOfMonth.subtract(const Duration(seconds: 1)),
                ) &&
                event.startTime.isBefore(
                  lastDayOfMonth.add(const Duration(days: 1)),
                );
          }).toList();

      // 构建每日事件数据
      final Map<int, List<Map<String, dynamic>>> dayEventsMap = {};

      for (var event in monthEvents) {
        final day = event.startTime.day;
        if (!dayEventsMap.containsKey(day)) {
          dayEventsMap[day] = [];
        }
        dayEventsMap[day]!.add({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'startTime': event.startTime.toIso8601String(),
          'endTime': event.endTime?.toIso8601String(),
          'completed': false, // 日历事件没有完成状态，默认false
        });
      }

      // 构建完整的月份数据
      final widgetData = {
        'year': now.year,
        'month': now.month,
        'daysInMonth': lastDayOfMonth.day,
        'firstWeekday': firstDayOfMonth.weekday,
        'today': now.day,
        'dayEvents': dayEventsMap.map((day, events) {
          return MapEntry(day.toString(), events);
        }),
      };

      // 保存到 HomeWidgetPreferences
      await HomeWidget.saveWidgetData<String>(
        'calendar_month_widget_data',
        _encodeWidgetData(widgetData),
      );

      debugPrint('同步日历月视图数据成功: ${monthEvents.length} 个事件');
    } catch (e) {
      debugPrint('同步日历月视图数据失败: $e');
      rethrow;
    }
  }

  /// 编码小组件数据为 JSON 字符串
  String _encodeWidgetData(Map<String, dynamic> data) {
    // 手动构建 JSON 字符串（避免使用 jsonEncode，因为它可能不支持所有类型）
    final buffer = StringBuffer('{');

    buffer.write('"year":${data['year']},');
    buffer.write('"month":${data['month']},');
    buffer.write('"daysInMonth":${data['daysInMonth']},');
    buffer.write('"firstWeekday":${data['firstWeekday']},');
    buffer.write('"today":${data['today']},');

    // 构建 dayEvents
    buffer.write('"dayEvents":{');
    final dayEvents = data['dayEvents'] as Map<String, dynamic>;
    final dayKeys = dayEvents.keys.toList();
    for (var i = 0; i < dayKeys.length; i++) {
      final day = dayKeys[i];
      final events = dayEvents[day] as List<Map<String, dynamic>>;

      buffer.write('"$day":[');
      for (var j = 0; j < events.length; j++) {
        final event = events[j];
        buffer.write('{');
        buffer.write('"id":"${event['id']}",');
        buffer.write('"title":"${_escapeJson(event['title'])}",');
        buffer.write('"description":"${_escapeJson(event['description'])}",');
        buffer.write('"startTime":"${event['startTime']}",');
        buffer.write('"endTime":"${event['endTime'] ?? ''}",');
        buffer.write('"completed":${event['completed']}');
        buffer.write('}');
        if (j < events.length - 1) buffer.write(',');
      }
      buffer.write(']');
      if (i < dayKeys.length - 1) buffer.write(',');
    }
    buffer.write('}');

    buffer.write('}');
    return buffer.toString();
  }

  /// 转义 JSON 字符串中的特殊字符
  String _escapeJson(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SuperCupertinoNavigationWrapper(
      title: Text(
        '配置日历月视图小组件',
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: 'calendar_widgetSelector'.tr,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : WidgetConfigEditor(
                widgetSize: WidgetSize.extraLarge,
                initialConfig: _widgetConfig,
                previewBuilder: _buildPreview,
                onConfigChanged: (newConfig) {
                  setState(() => _widgetConfig = newConfig);
                },
                previewTitle: '小组件预览',
                themeSettingsLabel: '主题设置',
                opacityLabel: '背景透明度',
              ),
          // FAB 覆盖层
          if (!_isLoading)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _saveAndFinish,
                icon: const Icon(Icons.check),
                label: Text('calendar_complete'.tr),
              ),
            ),
        ],
      ),
    );
  }
}
