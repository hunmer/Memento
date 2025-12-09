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
///   displayDaysCount: 7, // 可选，初始显示7天，默认7
///   showCalendarButton: true, // 可选，默认显示日历按钮
///   allowFutureDates: false, // 可选，是否允许加载未来日期，默认false
///   height: 70, // 可选，默认70
///   itemWidth: 54, // 可选，默认54
/// )
/// ```
///
/// 特性：
/// - 向左滚动自动加载过去的日期
/// - 向右滚动可加载未来的日期（如果 allowFutureDates 为 true）
/// - 滚动时保持视图稳定，体验流畅
class CalendarStripDatePicker extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 日期变更回调
  final ValueChanged<DateTime> onDateChanged;

  /// 初始显示的天数，默认7天（滚动时会动态加载更多）
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

  /// 是否允许加载未来日期，默认false
  final bool allowFutureDates;

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
    this.allowFutureDates = false,
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
  late List<DateTime> _dates;
  late int _initialSelectedIndex;
  bool _isLoadingMore = false;

  /// 每次加载更多日期的数量
  static const int _loadMoreCount = 7;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 初始化日期列表
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

  /// 初始化日期列表
  void _initializeDates() {
    _dates = [];
    final now = DateTime.now();
    final selectedDate = widget.selectedDate;

    // 计算初始日期范围（以选中日期为中心）
    final halfCount = widget.displayDaysCount ~/ 2;
    final startDate = selectedDate.subtract(Duration(days: halfCount));

    // 生成初始日期列表
    for (int i = 0; i < widget.displayDaysCount; i++) {
      final date = startDate.add(Duration(days: i));
      // 如果不允许未来日期且日期在今天之后，则跳过
      if (!widget.allowFutureDates && date.isAfter(DateTime(now.year, now.month, now.day))) {
        continue;
      }
      _dates.add(date);
    }

    // 查找选中日期的索引
    _initialSelectedIndex = _dates.indexWhere((d) =>
      d.year == selectedDate.year &&
      d.month == selectedDate.month &&
      d.day == selectedDate.day
    );

    // 如果找不到选中日期，添加到列表中
    if (_initialSelectedIndex == -1) {
      _dates.add(selectedDate);
      _dates.sort((a, b) => a.compareTo(b));
      _initialSelectedIndex = _dates.indexWhere((d) =>
        d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day
      );
    }
  }

  /// 更新选中日期
  void _updateSelectedDate() {
    final selectedDate = widget.selectedDate;
    final selectedIndex = _dates.indexWhere((d) =>
      d.year == selectedDate.year &&
      d.month == selectedDate.month &&
      d.day == selectedDate.day
    );

    if (selectedIndex == -1) {
      // 如果选中日期不在列表中，重新初始化
      _initializeDates();
    }

    _scrollToSelectedDate();
  }

  /// 滚动监听
  void _onScroll() {
    if (_isLoadingMore || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final itemSize = widget.itemWidth + widget.itemSpacing;

    // 向左滚动到接近开始位置时，加载过去的日期
    if (currentScroll < itemSize * 2) {
      _loadMorePastDates();
    }
    // 向右滚动到接近结束位置时，加载未来的日期
    else if (currentScroll > maxScroll - itemSize * 2) {
      _loadMoreFutureDates();
    }
  }

  /// 加载过去的日期
  void _loadMorePastDates() {
    if (_isLoadingMore || _dates.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 保存当前滚动位置
    final currentOffset = _scrollController.offset;
    final itemSize = widget.itemWidth + widget.itemSpacing;

    // 在列表开头添加过去的日期
    final firstDate = _dates.first;
    final newDates = <DateTime>[];
    for (int i = _loadMoreCount; i > 0; i--) {
      newDates.add(firstDate.subtract(Duration(days: i)));
    }

    setState(() {
      _dates.insertAll(0, newDates);
      _isLoadingMore = false;
    });

    // 调整滚动位置以保持视图稳定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final newOffset = currentOffset + (newDates.length * itemSize);
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  /// 加载未来的日期
  void _loadMoreFutureDates() {
    if (_isLoadingMore || _dates.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = _dates.last;

    // 在列表末尾添加未来的日期
    final newDates = <DateTime>[];
    for (int i = 1; i <= _loadMoreCount; i++) {
      final newDate = lastDate.add(Duration(days: i));
      // 如果不允许未来日期且日期在今天之后，则停止添加
      if (!widget.allowFutureDates && newDate.isAfter(today)) {
        break;
      }
      newDates.add(newDate);
    }

    if (newDates.isNotEmpty) {
      setState(() {
        _dates.addAll(newDates);
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// 滚动到选中日期位置
  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients || _dates.isEmpty) return;

    final selectedDate = widget.selectedDate;
    final selectedIndex = _dates.indexWhere((d) =>
      d.year == selectedDate.year &&
      d.month == selectedDate.month &&
      d.day == selectedDate.day
    );

    if (selectedIndex == -1) return;

    final itemSize = widget.itemWidth + widget.itemSpacing;
    final targetOffset = selectedIndex * itemSize;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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