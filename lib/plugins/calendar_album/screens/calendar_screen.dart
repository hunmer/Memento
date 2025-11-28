import 'dart:io' show Platform;
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;
import 'package:Memento/widgets/enhanced_calendar/index.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../widgets/entry_list.dart';
import 'entry_editor_screen.dart';
import 'entry_detail_screen.dart';
import '../utils/date_utils.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DateTime _focusedDay = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _isVerticalView = true; // 默认显示垂直视图

  /// 获取日历日期数据
  Map<DateTime, CalendarDayData> _getCalendarDayData() {
    final calendarController = Provider.of<CalendarController>(
      context,
      listen: false,
    );
    final selectedDate = calendarController.selectedDate;
    final Map<DateTime, CalendarDayData> dayData = {};

    // 获取当月所有条目
    final currentMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);

    // 为有日记的日期创建数据
    calendarController.entries.forEach((date, entries) {
      if (date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(nextMonth)) {
        // 获取当天日记的第一张图片作为背景
        String? backgroundImage;

        // 优先获取第一张图片作为背景
        for (var entry in entries) {
          // 首先检查直接的图片URLs
          if (entry.imageUrls.isNotEmpty) {
            backgroundImage = entry.imageUrls.first;
            break;
          }

          // 然后检查Markdown中提取的图片
          final markdownImages = entry.extractImagesFromMarkdown();
          if (markdownImages.isNotEmpty) {
            backgroundImage = markdownImages.first;
            break;
          }
        }

        dayData[date] = CalendarDayData(
          date: date,
          backgroundImage: backgroundImage,
          count: entries.length,
          isSelected: isSameDay(date, selectedDate),
          isToday: isSameDay(date, DateTime.now()),
          isCurrentMonth: date.month == _focusedDay.month,
        );
      }
    });

    return dayData;
  }

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      // 只在首次初始化时跳转到当前日期
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Provider.of<CalendarController>(
            context,
            listen: false,
          ).selectDate(DateTime.now());
          setState(() => _isInitialized = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = CalendarAlbumLocalizations.of(context);
    final calendarController = Provider.of<CalendarController>(context);
    final tagController = Provider.of<TagController>(context);
    final selectedDate = calendarController.selectedDate;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: calendarController),
        ChangeNotifierProvider.value(value: tagController),
      ],
      child: Scaffold(
        appBar: _buildAppBar(context, l10n),
        body: _buildCalendarListView(calendarController, selectedDate),
        floatingActionButton: _buildFloatingActionButton(
          context,
          calendarController,
          tagController,
          selectedDate,
        ),
        persistentFooterButtons: [
          _buildFooterButton(context, calendarController, selectedDate, l10n),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, dynamic l10n) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading:
          (Platform.isAndroid || Platform.isIOS)
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
      title: Text(
        CalendarAlbumLocalizations.of(context).calendarDiary,
        style: const TextStyle(fontSize: 18),
      ),
      actions: [
        // 视图切换按钮
        IconButton(
          icon: Icon(
            _isVerticalView ? Icons.view_week : Icons.calendar_view_month,
          ),
          onPressed: () {
            setState(() {
              _isVerticalView = !_isVerticalView;
            });
          },
          tooltip: _isVerticalView ? '切换到水平视图' : '切换到垂直视图',
        ),
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              Provider.of<CalendarController>(
                context,
                listen: false,
              ).selectDate(DateTime.now());
            });
          },
          tooltip: '回到当前月份',
        ),
      ],
    );
  }

  Widget _buildCalendarListView(
    CalendarController calendarController,
    DateTime selectedDate,
  ) {
    if (_isVerticalView) {
      return _VerticalCalendarView(
        calendarController: calendarController,
        selectedDate: selectedDate,
        focusedDay: _focusedDay,
        onDateSelected: (selectedDay) {
          calendarController.selectDate(selectedDay);
          setState(() => _focusedDay = selectedDay);
        },
        onDateLongPressed: (pressedDay) {
          // 长按可以选择日期并打开编辑器
          calendarController.selectDate(pressedDay);
          setState(() => _focusedDay = pressedDay);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: calendarController),
                      ChangeNotifierProvider.value(
                        value: Provider.of<TagController>(
                          context,
                          listen: false,
                        ),
                      ),
                    ],
                    child: EntryEditorScreen(
                      initialDate: pressedDay,
                      isEditing: false,
                    ),
                  ),
            ),
          );
        },
        onHeaderTapped: (focusedMonth) {
          _showDatePicker(context, calendarController);
        },
      );
    } else {
      return _MultiMonthCalendarView(
        calendarController: calendarController,
        selectedDate: selectedDate,
        focusedDay: _focusedDay,
        onDateSelected: (selectedDay) {
          calendarController.selectDate(selectedDay);
          setState(() => _focusedDay = selectedDay);
        },
        onDateLongPressed: (pressedDay) {
          // 长按可以选择日期并打开编辑器
          calendarController.selectDate(pressedDay);
          setState(() => _focusedDay = pressedDay);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: calendarController),
                      ChangeNotifierProvider.value(
                        value: Provider.of<TagController>(
                          context,
                          listen: false,
                        ),
                      ),
                    ],
                    child: EntryEditorScreen(
                      initialDate: pressedDay,
                      isEditing: false,
                    ),
                  ),
            ),
          );
        },
        onHeaderTapped: (focusedMonth) {
          _showDatePicker(context, calendarController);
        },
      );
    }
  }

  Widget _buildEntryList(
    BuildContext context,
    CalendarController calendarController,
    TagController tagController,
    DateTime selectedDate,
    dynamic l10n,
  ) {
    return Expanded(
      child: EntryList(
        entries: calendarController.getEntriesForDate(selectedDate),
        onTap: (entry) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: calendarController),
                      ChangeNotifierProvider.value(value: tagController),
                    ],
                    child: EntryDetailScreen(entry: entry),
                  ),
            ),
          );
          if (mounted) setState(() {});
        },
        onEdit: (entry) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: calendarController),
                      ChangeNotifierProvider.value(value: tagController),
                    ],
                    child: EntryEditorScreen(entry: entry, isEditing: true),
                  ),
            ),
          );
          if (mounted) {
            calendarController.selectDate(selectedDate);
            setState(() {});
          }
        },
        onDelete:
            (entry) => showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(l10n.get('delete')),
                    content: Text('${l10n.get('delete')} "${entry.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.get('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          calendarController.deleteEntry(entry);
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: Text(l10n.get('delete')),
                      ),
                    ],
                  ),
            ),
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context,
    CalendarController calendarController,
    DateTime selectedDate,
    dynamic l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showEntryDrawer(context, calendarController, selectedDate, l10n);
        },
        icon: const Icon(Icons.menu),
        label: Text(
          '查看当日日记 (${calendarController.getEntriesForDate(selectedDate).length})',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showEntryDrawer(
    BuildContext context,
    CalendarController calendarController,
    DateTime selectedDate,
    dynamic l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ' ${DateFormat('yyyy年MM月dd日').format(selectedDate)} 的日记',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Consumer<TagController>(
                          builder: (context, tagController, child) {
                            return _buildDrawerEntryList(
                              context,
                              calendarController,
                              tagController,
                              selectedDate,
                              l10n,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDrawerEntryList(
    BuildContext context,
    CalendarController calendarController,
    TagController tagController,
    DateTime selectedDate,
    dynamic l10n,
  ) {
    return EntryList(
      entries: calendarController.getEntriesForDate(selectedDate),
      onTap: (entry) async {
        Navigator.pop(context); // 关闭抽屉
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryDetailScreen(entry: entry),
                ),
          ),
        );
        if (mounted) setState(() {});
      },
      onEdit: (entry) async {
        Navigator.pop(context); // 关闭抽屉
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryEditorScreen(entry: entry, isEditing: true),
                ),
          ),
        );
        if (mounted) {
          calendarController.selectDate(selectedDate);
          setState(() {});
        }
      },
      onDelete:
          (entry) => showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(l10n.get('delete')),
                  content: Text('${l10n.get('delete')} "${entry.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.get('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        calendarController.deleteEntry(entry);
                        Navigator.pop(context); // 关闭对话框
                        Navigator.pop(context); // 关闭抽屉并刷新
                        setState(() {});
                      },
                      child: Text(l10n.get('delete')),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    CalendarController calendarController,
    TagController tagController,
    DateTime selectedDate,
  ) {
    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryEditorScreen(
                    initialDate: selectedDate,
                    isEditing: false,
                  ),
                ),
          ),
        );
        if (mounted) {
          calendarController.selectDate(selectedDate);
          setState(() {});
        }
      },
      child: const Icon(Icons.add),
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    CalendarController calendarController,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: '选择年月',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (selectedDate != null) {
      setState(() {
        _focusedDay = DateTime(selectedDate.year, selectedDate.month);
      });
      Provider.of<CalendarController>(
        context,
        listen: false,
      ).selectDate(DateTime(selectedDate.year, selectedDate.month));
    }
  }
}

/// 多月份并排日历视图
class _MultiMonthCalendarView extends StatefulWidget {
  final CalendarController calendarController;
  final DateTime selectedDate;
  final DateTime focusedDay;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onDateLongPressed;
  final Function(DateTime) onHeaderTapped;

  const _MultiMonthCalendarView({
    required this.calendarController,
    required this.selectedDate,
    required this.focusedDay,
    required this.onDateSelected,
    required this.onDateLongPressed,
    required this.onHeaderTapped,
  });

  @override
  State<_MultiMonthCalendarView> createState() =>
      _MultiMonthCalendarViewState();
}

class _MultiMonthCalendarViewState extends State<_MultiMonthCalendarView>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late ScrollController _horizontalController;
  final List<DateTime> _months = [];
  final int _maxCalendarCount = 12;
  final Map<String, Map<DateTime, CalendarDayData>> _cachedDayData = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMonths();
    _pageController = PageController(initialPage: 1); // 从中间月份开始
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  /// 初始化月份列表（以当前月份为中心）
  void _initializeMonths() {
    _months.clear();
    final now = DateTime.now();

    // 添加当前月份及相邻月份（最多4个）
    for (int i = -1; i <= 2 && _months.length < _maxCalendarCount; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      _months.add(month);
    }
  }

  /// 加载更多月份（向前或向后）
  void _loadMoreMonths(bool isBefore) {
    final shouldRemove = _months.length >= _maxCalendarCount;
    DateTime? removedMonth;
    DateTime? addedMonth;
    bool hasChanges = false;

    // 移除不再需要的月份，保持最多显示12个
    if (shouldRemove) {
      if (isBefore) {
        removedMonth = _months.last;
        _months.removeLast(); // 移除最后一个
        hasChanges = true;
      } else {
        removedMonth = _months.first;
        _months.removeAt(0); // 移除第一个
        hasChanges = true;
      }
    }

    if (isBefore) {
      final firstMonth = _months.first;
      addedMonth = DateTime(firstMonth.year, firstMonth.month - 1);
      _months.insert(0, addedMonth);
      hasChanges = true;
    } else {
      final lastMonth = _months.last;
      addedMonth = DateTime(lastMonth.year, lastMonth.month + 1);
      _months.add(addedMonth);
      hasChanges = true;
    }

    // 只在有实际变化时更新状态
    if (hasChanges && mounted) {
      setState(() {});
    }

    // 清理不再需要的缓存数据
    if (removedMonth != null) {
      _cachedDayData.remove(_getMonthKey(removedMonth));
    }

    // 预加载新月份的数据
    if (addedMonth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCalendarDayData(addedMonth!); // 触发数据缓存
      });
    }
  }

  /// 生成月份的唯一key
  String _getMonthKey(DateTime month) {
    return '${month.year}_${month.month}';
  }

  /// 获取指定月份的日历数据（带缓存）- 水平视图
  Map<DateTime, CalendarDayData> _getCalendarDayData(DateTime month) {
    final monthKey = _getMonthKey(month);

    // 检查缓存
    if (_cachedDayData.containsKey(monthKey)) {
      final cachedData = _cachedDayData[monthKey]!;
      // 更新选中状态和今天状态（这些是动态的）
      cachedData.forEach((date, dayData) {
        cachedData[date] = dayData.copyWith(
          isSelected: isSameDay(date, widget.selectedDate),
          isToday: isSameDay(date, DateTime.now()),
        );
      });
      return cachedData;
    }

    // 计算新的日历数据
    final Map<DateTime, CalendarDayData> dayData = {};
    final currentMonth = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    // 获取当月所有条目
    widget.calendarController.entries.forEach((date, entries) {
      if (date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(nextMonth)) {
        // 获取当天日记的第一张图片作为背景
        String? backgroundImage;

        for (var entry in entries) {
          if (entry.imageUrls.isNotEmpty) {
            backgroundImage = entry.imageUrls.first;
            break;
          }

          final markdownImages = entry.extractImagesFromMarkdown();
          if (markdownImages.isNotEmpty) {
            backgroundImage = markdownImages.first;
            break;
          }
        }

        dayData[date] = CalendarDayData(
          date: date,
          backgroundImage: backgroundImage,
          count: entries.length,
          isSelected: isSameDay(date, widget.selectedDate),
          isToday: isSameDay(date, DateTime.now()),
          isCurrentMonth: date.year == month.year && date.month == month.month,
        );
      }
    });

    // 缓存数据
    _cachedDayData[monthKey] = Map.from(dayData);
    return dayData;
  }

  /// 构建单个日历月份
  Widget _buildMonthCalendar(DateTime month) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份标题
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('yyyy年MM月').format(month),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  onSelected: (value) {
                    if (value == 'select_month') {
                      widget.onHeaderTapped(month);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'select_month',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today),
                              SizedBox(width: 8),
                              Text('跳转到此月'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
          // 日历内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: EnhancedCalendarWidget(
                dayData: _getCalendarDayData(month),
                focusedMonth: month,
                selectedDate: widget.selectedDate,
                onDaySelected: widget.onDateSelected,
                onDayLongPressed: widget.onDateLongPressed,
                onHeaderTapped: widget.onHeaderTapped,
                enableNavigation: false, // 禁用内置导航，使用外部控制
                locale: 'zh_CN',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          // 当滚动到左侧边界附近时，加载更多月份
          if (metrics.pixels <= 100 && _months.first.month > 1) {
            _loadMoreMonths(true);
            // 调整滚动位置，避免跳跃
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_horizontalController.hasClients) {
                _horizontalController.jumpTo(350);
              }
            });
          }
          // 当滚动到右侧边界附近时，加载更多月份
          else if (metrics.pixels >= metrics.maxScrollExtent - 100) {
            _loadMoreMonths(false);
          }
        }
        return false;
      },
      child: Column(
        children: [
          // 顶部导航栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    if (_horizontalController.hasClients) {
                      _horizontalController.animateTo(
                        _horizontalController.offset - 350,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  tooltip: '上个月',
                ),
                Text(
                  '日历视图',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    if (_horizontalController.hasClients) {
                      _horizontalController.animateTo(
                        _horizontalController.offset + 350,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  tooltip: '下个月',
                ),
              ],
            ),
          ),
          // 横向滚动的日历列表
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // 限制最多显示12个日历
                  ..._months.take(_maxCalendarCount).map((month) {
                    return KeyedSubtree(
                      key: ValueKey('horizontal_${_getMonthKey(month)}'),
                      child: SizedBox(
                        width: 350, // 固定每个日历的宽度
                        child: _buildMonthCalendar(month),
                      ),
                    );
                  }).toList(),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 垂直日历视图（默认视图）
class _VerticalCalendarView extends StatefulWidget {
  final CalendarController calendarController;
  final DateTime selectedDate;
  final DateTime focusedDay;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onDateLongPressed;
  final Function(DateTime) onHeaderTapped;

  const _VerticalCalendarView({
    required this.calendarController,
    required this.selectedDate,
    required this.focusedDay,
    required this.onDateSelected,
    required this.onDateLongPressed,
    required this.onHeaderTapped,
  });

  @override
  State<_VerticalCalendarView> createState() => _VerticalCalendarViewState();
}

class _VerticalCalendarViewState extends State<_VerticalCalendarView>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _verticalController;
  final List<DateTime> _months = [];
  final int _maxCalendarCount = 12;
  final Map<String, Map<DateTime, CalendarDayData>> _cachedDayData = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMonths();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  /// 初始化月份列表（以当前月份为中心）
  void _initializeMonths() {
    _months.clear();
    final now = DateTime.now();

    // 添加当前月份及相邻月份（最多4个）
    for (int i = -1; i <= 2 && _months.length < _maxCalendarCount; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      _months.add(month);
    }
  }

  /// 加载更多月份（向下）
  void _loadMoreMonths() {
    final shouldRemove = _months.length >= _maxCalendarCount;
    DateTime? removedMonth;
    DateTime? addedMonth;
    bool hasChanges = false;

    // 移除不再需要的月份，保持最多显示12个
    if (shouldRemove) {
      removedMonth = _months.first;
      _months.removeAt(0); // 移除第一个月份
      hasChanges = true;
    }

    final lastMonth = _months.last;
    addedMonth = DateTime(lastMonth.year, lastMonth.month + 1);
    _months.add(addedMonth);
    hasChanges = true;

    // 只在有实际变化时更新状态
    if (hasChanges && mounted) {
      setState(() {});
    }

    // 清理不再需要的缓存数据
    if (removedMonth != null) {
      _cachedDayData.remove(_getMonthKey(removedMonth));
    }

    // 预加载新月份的数据
    if (addedMonth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCalendarDayData(addedMonth!); // 触发数据缓存
      });
    }
  }

  /// 加载更多月份（向上）
  void _loadMoreMonthsBefore() {
    final shouldRemove = _months.length >= _maxCalendarCount;
    DateTime? removedMonth;
    DateTime? addedMonth;
    bool hasChanges = false;

    // 移除不再需要的月份，保持最多显示12个
    if (shouldRemove) {
      removedMonth = _months.last;
      _months.removeLast(); // 移除最后一个月份
      hasChanges = true;
    }

    final firstMonth = _months.first;
    addedMonth = DateTime(firstMonth.year, firstMonth.month - 1);
    _months.insert(0, addedMonth);
    hasChanges = true;

    // 只在有实际变化时更新状态
    if (hasChanges && mounted) {
      setState(() {});
    }

    // 清理不再需要的缓存数据
    if (removedMonth != null) {
      _cachedDayData.remove(_getMonthKey(removedMonth));
    }

    // 预加载新月份的数据
    if (addedMonth != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCalendarDayData(addedMonth!); // 触发数据缓存
      });
    }
  }

  /// 生成月份的唯一key
  String _getMonthKey(DateTime month) {
    return '${month.year}_${month.month}';
  }

  /// 获取指定月份的日历数据（带缓存）- 垂直视图
  Map<DateTime, CalendarDayData> _getCalendarDayData(DateTime month) {
    final monthKey = _getMonthKey(month);

    // 检查缓存
    if (_cachedDayData.containsKey(monthKey)) {
      final cachedData = _cachedDayData[monthKey]!;
      // 更新选中状态和今天状态（这些是动态的）
      cachedData.forEach((date, dayData) {
        cachedData[date] = dayData.copyWith(
          isSelected: isSameDay(date, widget.selectedDate),
          isToday: isSameDay(date, DateTime.now()),
        );
      });
      return cachedData;
    }

    // 计算新的日历数据
    final Map<DateTime, CalendarDayData> dayData = {};
    final currentMonth = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    // 获取当月所有条目
    widget.calendarController.entries.forEach((date, entries) {
      if (date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(nextMonth)) {
        // 获取当天日记的第一张图片作为背景
        String? backgroundImage;

        for (var entry in entries) {
          if (entry.imageUrls.isNotEmpty) {
            backgroundImage = entry.imageUrls.first;
            break;
          }

          final markdownImages = entry.extractImagesFromMarkdown();
          if (markdownImages.isNotEmpty) {
            backgroundImage = markdownImages.first;
            break;
          }
        }

        dayData[date] = CalendarDayData(
          date: date,
          backgroundImage: backgroundImage,
          count: entries.length,
          isSelected: isSameDay(date, widget.selectedDate),
          isToday: isSameDay(date, DateTime.now()),
          isCurrentMonth: date.year == month.year && date.month == month.month,
        );
      }
    });

    // 缓存数据
    _cachedDayData[monthKey] = Map.from(dayData);
    return dayData;
  }

  /// 构建单个日历月份
  Widget _buildMonthCalendar(DateTime month) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 日历内容
          Padding(
            padding: const EdgeInsets.all(8),
            child: EnhancedCalendarWidget(
              dayData: _getCalendarDayData(month),
              focusedMonth: month,
              selectedDate: widget.selectedDate,
              onDaySelected: widget.onDateSelected,
              onDayLongPressed: widget.onDateLongPressed,
              onHeaderTapped: widget.onHeaderTapped,
              enableNavigation: false, // 禁用内置导航，使用外部控制
              locale: 'zh_CN',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          // 当滚动到底部时，加载更多月份
          if (metrics.pixels >= metrics.maxScrollExtent - 100) {
            _loadMoreMonths();
          }
          // 当滚动到顶部时，加载前面的月份
          else if (metrics.pixels <= 100 && _months.first.month > 1) {
            _loadMoreMonthsBefore();
            // 调整滚动位置，避免跳跃
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_verticalController.hasClients) {
                final currentScrollPosition = _verticalController.offset;
                _verticalController.jumpTo(currentScrollPosition + 400);
              }
            });
          }
        }
        return false;
      },
      child: Column(
        children: [
          // 顶部标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    if (_verticalController.hasClients) {
                      _verticalController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  tooltip: '回到顶部',
                ),
                Text(
                  '垂直日历视图',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_months.length}/${_maxCalendarCount} 个月',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // 垂直滚动的日历列表
          Expanded(
            child: ListView(
              controller: _verticalController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                // 显示所有月份
                ..._months.take(_maxCalendarCount).map((month) {
                  return KeyedSubtree(
                    key: ValueKey('vertical_${_getMonthKey(month)}'),
                    child: _buildMonthCalendar(month),
                  );
                }).toList(),
                const SizedBox(height: 100), // 底部留白
              ],
            ),
          ),
        ],
      ),
    );
  }
}
