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
        body: Column(
          children: [
            _buildCalendarListView(calendarController, selectedDate),
            _buildEntryList(
              context,
              calendarController,
              tagController,
              selectedDate,
              l10n,
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(
          context,
          calendarController,
          tagController,
          selectedDate,
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算动态高度，考虑屏幕大小和可用空间
        final availableHeight = constraints.maxHeight;
        final calendarHeight = (availableHeight * 0.6).clamp(280.0, 400.0);

        return SizedBox(
          height: calendarHeight,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: EnhancedCalendarWidget(
              dayData: _getCalendarDayData(),
              focusedMonth: _focusedDay,
              selectedDate: selectedDate,
              onDaySelected: (selectedDay) {
                calendarController.selectDate(selectedDay);
                setState(() => _focusedDay = selectedDay);
              },
              onDayLongPressed: (pressedDay) {
                // 长按可以选择日期并打开编辑器
                calendarController.selectDate(pressedDay);
                setState(() => _focusedDay = pressedDay);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                              value: calendarController,
                            ),
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
              calendarFormat: CalendarFormat.month,
              enableNavigation: true,
              enableTodayButton: true,
              enableDateSelection: true,
              locale: 'zh_CN',
            ),
          ),
        );
      },
    );
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
