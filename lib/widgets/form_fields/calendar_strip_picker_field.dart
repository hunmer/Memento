import 'package:flutter/material.dart';
import '../picker/calendar_strip_date_picker.dart';

/// 日历条日期选择器字段组件
///
/// 集成 CalendarStripDatePicker，提供横向滚动日期选择功能
class CalendarStripPickerField extends StatelessWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<DateTime> onDateChanged;

  /// 是否允许加载未来日期
  final bool allowFutureDates;

  /// 是否使用短周名
  final bool useShortWeekDay;

  /// 日期选择器高度
  final double height;

  /// 每个日期项的宽度
  final double itemWidth;

  const CalendarStripPickerField({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.enabled = true,
    this.allowFutureDates = false,
    this.useShortWeekDay = false,
    this.height = 70,
    this.itemWidth = 54,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: CalendarStripDatePicker(
          selectedDate: selectedDate,
          onDateChanged: enabled ? onDateChanged : (date) {},
          allowFutureDates: allowFutureDates,
          useShortWeekDay: useShortWeekDay,
          height: height,
          itemWidth: itemWidth,
        ),
      ),
    );
  }
}
