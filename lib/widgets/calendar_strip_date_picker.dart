import 'package:flutter/material.dart';

/// 日历条日期选择器组件
///
/// 显示一个可选月份的日期条，支持滑动浏览和日历选择
///
/// 使用示例:
/// ```dart
/// CalendarStripDatePicker(
///   selectedDate: _selectedDate,
///   onDateChanged: (date) {
///     setState(() {
///       _selectedDate = date;
///     });
///   },
///   displayDaysCount: 7, // 可选，默认7天
///   showCalendarButton: true, // 可选，默认显示日历按钮
///   height: 70, // 可选，默认70
///   itemWidth: 54, // 可选，默认54
/// )
/// ```
class CalendarStripDatePicker extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 日期变更回调
  final ValueChanged<DateTime> onDateChanged;

  /// 显示的天数，默认7天
  final int displayDaysCount;

  /// 是否显示日历按钮，默认true
  final bool showCalendarButton;

  /// 日期选择器高度，默认70
  final double height;

  /// 每个日期项的宽度，默认54
  final double itemWidth;

  /// 日期项间距，默认12
  final double itemSpacing;

  /// 日期选择器的padding，默认EdgeInsets.only(left: 16, right: 8)
  final EdgeInsets listPadding;

  /// 日历按钮的padding，默认EdgeInsets.only(right: 16)
  final EdgeInsets calendarButtonPadding;

  /// 是否循环滚动，默认false
  final bool loopScrolling;

  /// 周名称文本样式
  final TextStyle? weekDayTextStyle;

  /// 日期数字文本样式
  final TextStyle? dateTextStyle;

  /// 选中项的背景颜色，默认使用主题色
  final Color? selectedColor;

  /// 未选中项的背景颜色，默认使用卡片颜色
  final Color? unselectedColor;

  /// 今天的边框颜色，默认使用主题色
  final Color? todayBorderColor;

  /// 选中项的阴影
  final List<BoxShadow>? selectedShadow;

  const CalendarStripDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.displayDaysCount = 7,
    this.showCalendarButton = true,
    this.height = 70,
    this.itemWidth = 54,
    this.itemSpacing = 12,
    this.listPadding = const EdgeInsets.only(left: 16, right: 8),
    this.calendarButtonPadding = const EdgeInsets.only(right: 16),
    this.loopScrolling = false,
    this.weekDayTextStyle,
    this.dateTextStyle,
    this.selectedColor,
    this.unselectedColor,
    this.todayBorderColor,
    this.selectedShadow,
  });

  @override
  State<CalendarStripDatePicker> createState() => _CalendarStripDatePickerState();
}

class _CalendarStripDatePickerState extends State<CalendarStripDatePicker> {
  late ScrollController _scrollController;
  late DateTime _centerDate;

  @override
  void initState() {
    super.initState();
    _centerDate = widget.selectedDate;
    _scrollController = ScrollController();

    // 延迟滚动到选中日期位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(CalendarStripDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果选中日期变化，更新中心日期并滚动
    if (widget.selectedDate != oldWidget.selectedDate) {
      _centerDate = widget.selectedDate;
      _scrollToSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动到选中日期位置
  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;

    final selectedIndex = widget.displayDaysCount ~/ 2;
    final targetOffset = selectedIndex * (widget.itemWidth + widget.itemSpacing);

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 获取指定索引对应的日期
  DateTime _getDateForIndex(int index) {
    final offsetDays = index - widget.displayDaysCount ~/ 2;
    return _centerDate.add(Duration(days: offsetDays));
  }

  /// 判断是否为今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// 判断是否为选中日期
  bool _isSelected(DateTime date) {
    return date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;
  }

  /// 获取周名称
  String _getWeekDayName(int weekday) {
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekDays[weekday - 1];
  }

  /// 构建日期项
  Widget _buildDateItem(DateTime date) {
    final isSelected = _isSelected(date);
    final isToday = _isToday(date);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => widget.onDateChanged(date),
      child: Container(
        width: widget.itemWidth,
        decoration: BoxDecoration(
          color: isSelected
              ? (widget.selectedColor ?? theme.primaryColor)
              : (widget.unselectedColor ?? theme.cardColor),
          borderRadius: BorderRadius.circular(16),
          border: isToday && !isSelected
              ? Border.all(
                  color: widget.todayBorderColor ?? theme.primaryColor,
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? (widget.selectedShadow ?? [
                  BoxShadow(
                    color: (widget.selectedColor ?? theme.primaryColor).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ])
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getWeekDayName(date.weekday),
              style: widget.weekDayTextStyle ?? TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: widget.dateTextStyle ?? TextStyle(
                fontSize: 18,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示日期选择器
  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).primaryColor,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: widget.height,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.displayDaysCount,
                padding: widget.listPadding,
                itemBuilder: (context, index) {
                  final date = _getDateForIndex(index);
                  return Container(
                    margin: EdgeInsets.only(right: widget.itemSpacing),
                    child: _buildDateItem(date),
                  );
                },
              ),
            ),
          ),
          if (widget.showCalendarButton) ...[
            Padding(
              padding: widget.calendarButtonPadding,
              child: GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  width: widget.itemWidth,
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}