import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 日历条日期选择器组件
///
/// 显示一个可滚动的日期条，支持滑动浏览、动态加载更多日期和日历选择
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
///   showCalendarButton: true, // 可选，默认显示日历按钮
///   allowFutureDates: false, // 可选，是否允许加载未来日期，默认false
///   height: 70, // 可选，默认70
///   itemWidth: 54, // 可选，默认54
///   useShortWeekDay: false, // 可选，使用短周名（一、二...），默认false
/// )
/// ```
///
/// 特性：
/// - 默认展示当前月份的所有日期
/// - 向左滚动自动加载过去的月份
/// - 向右滚动可加载未来的月份（如果 allowFutureDates 为 true）
/// - 滚动时保持视图稳定，体验流畅
/// - 支持国际化（中英文周名）
class CalendarStripDatePicker extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 日期变更回调
  final ValueChanged<DateTime> onDateChanged;

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

  /// 是否允许加载未来日期，默认false
  final bool allowFutureDates;

  /// 是否使用短周名（一、二、三...），默认false使用长周名（周一、周二...）
  final bool useShortWeekDay;

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

  /// 自定义周名获取函数
  final String Function(int weekday, bool isShort)? weekDayNameBuilder;

  const CalendarStripDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.showCalendarButton = true,
    this.height = 70,
    this.itemWidth = 54,
    this.itemSpacing = 12,
    this.listPadding = const EdgeInsets.only(left: 16, right: 8),
    this.calendarButtonPadding = const EdgeInsets.only(right: 16),
    this.allowFutureDates = false,
    this.useShortWeekDay = false,
    this.weekDayTextStyle,
    this.dateTextStyle,
    this.selectedColor,
    this.unselectedColor,
    this.todayBorderColor,
    this.selectedShadow,
    this.weekDayNameBuilder,
  });

  @override
  State<CalendarStripDatePicker> createState() =>
      _CalendarStripDatePickerState();
}

class _CalendarStripDatePickerState extends State<CalendarStripDatePicker> {
  late ScrollController _scrollController;
  late List<DateTime> _dates;
  bool _isLoadingMore = false;

  /// 已加载的月份范围
  late int _earliestMonth; // 格式：年*12+月
  late int _latestMonth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 初始化日期列表（当前月份）
    _initializeDates();

    // 延迟滚动到选中日期位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(CalendarStripDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果选中日期变化，更新列表并滚动
    if (widget.selectedDate != oldWidget.selectedDate) {
      _updateSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化日期列表（默认展示当前月份）
  void _initializeDates() {
    _dates = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 使用当前月份作为初始月份
    final currentMonth = DateTime(now.year, now.month, 1);
    _earliestMonth = currentMonth.year * 12 + currentMonth.month;
    _latestMonth = _earliestMonth;

    // 生成当前月份的所有日期
    _addMonthDates(currentMonth, today);

    // 如果选中日期不在当前月份，扩展日期范围
    final selectedDate = widget.selectedDate;
    final selectedMonth = selectedDate.year * 12 + selectedDate.month;

    if (selectedMonth < _earliestMonth) {
      // 选中日期在更早的月份，加载从选中月份到当前月份的所有日期
      var month = DateTime(selectedDate.year, selectedDate.month, 1);
      while (month.year * 12 + month.month < _earliestMonth) {
        _addMonthDatesToFront(month, today);
        _earliestMonth = month.year * 12 + month.month;
        month = DateTime(month.year, month.month + 1, 1);
      }
    } else if (selectedMonth > _latestMonth && widget.allowFutureDates) {
      // 选中日期在更晚的月份（且允许未来日期）
      var month = DateTime(now.year, now.month + 1, 1);
      while (month.year * 12 + month.month <= selectedMonth) {
        _addMonthDates(month, today);
        _latestMonth = month.year * 12 + month.month;
        month = DateTime(month.year, month.month + 1, 1);
      }
    }
  }

  /// 添加指定月份的所有日期到列表末尾
  void _addMonthDates(DateTime month, DateTime today) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      // 如果不允许未来日期且日期在今天之后，则跳过
      if (!widget.allowFutureDates && date.isAfter(today)) {
        continue;
      }
      _dates.add(date);
    }
  }

  /// 添加指定月份的所有日期到列表开头
  void _addMonthDatesToFront(DateTime month, DateTime today) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final newDates = <DateTime>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      newDates.add(date);
    }

    _dates.insertAll(0, newDates);
  }

  /// 更新选中日期
  void _updateSelectedDate() {
    final selectedDate = widget.selectedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 检查选中日期是否在当前列表中
    final selectedIndex = _dates.indexWhere(
      (d) =>
          d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day,
    );

    if (selectedIndex == -1) {
      // 选中日期不在列表中，需要扩展
      final selectedMonth = selectedDate.year * 12 + selectedDate.month;

      if (selectedMonth < _earliestMonth) {
        // 需要向前加载
        _loadMonthsToDate(selectedDate, today);
      } else if (selectedMonth > _latestMonth && widget.allowFutureDates) {
        // 需要向后加载
        _loadFutureMonthsToDate(selectedDate, today);
      }

      setState(() {});
    }

    _scrollToSelectedDate();
  }

  /// 加载月份直到包含指定日期（向前）
  void _loadMonthsToDate(DateTime targetDate, DateTime today) {
    final targetMonth = targetDate.year * 12 + targetDate.month;

    while (_earliestMonth > targetMonth) {
      final prevMonth = _earliestMonth - 1;
      final year = prevMonth ~/ 12;
      final month = prevMonth % 12;
      final actualMonth = month == 0 ? 12 : month;
      final actualYear = month == 0 ? year - 1 : year;

      final monthDate = DateTime(actualYear, actualMonth, 1);
      _addMonthDatesToFront(monthDate, today);
      _earliestMonth = actualYear * 12 + actualMonth;
    }
  }

  /// 加载月份直到包含指定日期（向后）
  void _loadFutureMonthsToDate(DateTime targetDate, DateTime today) {
    final targetMonth = targetDate.year * 12 + targetDate.month;

    while (_latestMonth < targetMonth) {
      final nextMonth = _latestMonth + 1;
      final year = nextMonth ~/ 12;
      final month = nextMonth % 12;
      final actualMonth = month == 0 ? 12 : month;
      final actualYear = month == 0 ? year - 1 : year;

      final monthDate = DateTime(actualYear, actualMonth, 1);
      _addMonthDates(monthDate, today);
      _latestMonth = actualYear * 12 + actualMonth;
    }
  }

  /// 滚动监听
  void _onScroll() {
    if (_isLoadingMore || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final itemSize = widget.itemWidth + widget.itemSpacing;

    // 向左滚动到接近开始位置时，加载过去的月份
    if (currentScroll < itemSize * 3) {
      _loadMorePastDates();
    }
    // 向右滚动到接近结束位置时，加载未来的月份
    else if (currentScroll > maxScroll - itemSize * 3) {
      _loadMoreFutureDates();
    }
  }

  /// 加载过去的日期（一个月）
  void _loadMorePastDates() {
    if (_isLoadingMore || _dates.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 保存当前滚动位置
    final currentOffset = _scrollController.offset;
    final itemSize = widget.itemWidth + widget.itemSpacing;

    // 计算上一个月
    final prevMonth = _earliestMonth - 1;
    final year = prevMonth ~/ 12;
    final month = prevMonth % 12;
    final actualMonth = month == 0 ? 12 : month;
    final actualYear = month == 0 ? year - 1 : year;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthDate = DateTime(actualYear, actualMonth, 1);

    final previousLength = _dates.length;
    _addMonthDatesToFront(monthDate, today);
    final addedCount = _dates.length - previousLength;

    _earliestMonth = actualYear * 12 + actualMonth;

    setState(() {
      _isLoadingMore = false;
    });

    // 调整滚动位置以保持视图稳定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final newOffset = currentOffset + (addedCount * itemSize);
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  /// 加载未来的日期（一个月）
  void _loadMoreFutureDates() {
    if (_isLoadingMore || _dates.isEmpty || !widget.allowFutureDates) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 计算下一个月
    final nextMonth = _latestMonth + 1;
    final year = nextMonth ~/ 12;
    final month = nextMonth % 12;
    final actualMonth = month == 0 ? 12 : month;
    final actualYear = month == 0 ? year - 1 : year;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthDate = DateTime(actualYear, actualMonth, 1);

    _addMonthDates(monthDate, today);
    _latestMonth = actualYear * 12 + actualMonth;

    setState(() {
      _isLoadingMore = false;
    });
  }

  /// 滚动到选中日期位置
  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients || _dates.isEmpty) return;

    final selectedDate = widget.selectedDate;
    final selectedIndex = _dates.indexWhere(
      (d) =>
          d.year == selectedDate.year &&
          d.month == selectedDate.month &&
          d.day == selectedDate.day,
    );

    if (selectedIndex == -1) return;

    final itemSize = widget.itemWidth + widget.itemSpacing;
    final viewportWidth = _scrollController.position.viewportDimension;
    // 将选中项居中显示
    final targetOffset =
        (selectedIndex * itemSize) - (viewportWidth / 2) + (widget.itemWidth / 2);

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 判断是否为今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 判断是否为选中日期
  bool _isSelected(DateTime date) {
    return date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;
  }

  /// 获取周名称（支持国际化）
  String _getWeekDayName(int weekday) {
    // 如果提供了自定义构建器，使用它
    if (widget.weekDayNameBuilder != null) {
      return widget.weekDayNameBuilder!(weekday, widget.useShortWeekDay);
    }

    // 使用 GetX 国际化
    if (widget.useShortWeekDay) {
      const keys = [
        'widget_calendarStrip_mon',
        'widget_calendarStrip_tue',
        'widget_calendarStrip_wed',
        'widget_calendarStrip_thu',
        'widget_calendarStrip_fri',
        'widget_calendarStrip_sat',
        'widget_calendarStrip_sun',
      ];
      return keys[weekday - 1].tr;
    } else {
      const keys = [
        'widget_calendarStrip_monday',
        'widget_calendarStrip_tuesday',
        'widget_calendarStrip_wednesday',
        'widget_calendarStrip_thursday',
        'widget_calendarStrip_friday',
        'widget_calendarStrip_saturday',
        'widget_calendarStrip_sunday',
      ];
      return keys[weekday - 1].tr;
    }
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
              ? (widget.selectedShadow ??
                  [
                    BoxShadow(
                      color: (widget.selectedColor ?? theme.primaryColor)
                          .withOpacity(0.3),
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
              style: widget.weekDayTextStyle ??
                  TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: widget.dateTextStyle ??
                  TextStyle(
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
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: widget.allowFutureDates ? DateTime(2100) : now,
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
                itemCount: _dates.length,
                padding: widget.listPadding,
                itemBuilder: (context, index) {
                  final date = _dates[index];
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
