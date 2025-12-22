import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/widgets/quill_viewer/index.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'diary_editor_screen.dart';
import 'package:Memento/plugins/diary/models/diary_entry.dart';
import 'package:Memento/plugins/diary/utils/diary_utils.dart';

class DiaryCalendarScreen extends StatefulWidget {
  final StorageManager storage;
  final DateTime? initialDate;

  const DiaryCalendarScreen({
    super.key,
    required this.storage,
    this.initialDate,
  });

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, DiaryEntry> _diaryEntries = {};
  late CalendarController _calendarController;

  // 搜索相关状态
  String _searchQuery = '';
  List<DiaryEntry> _searchResults = [];

  // GlobalKeys for OpenContainer animation
  final GlobalKey _editButtonKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  // Colors from design
  static const Color _primaryColor = Color(0xFFD8BFD8); // Dusty Rose
  static const Color _primaryTextColor = Color(0xFF4A4A4A); // Soft charcoal
  static const Color _backgroundColor = Color(0xFFFAF8F5); // Light cream

  @override
  void initState() {
    super.initState();

    // 使用 initialDate 或默认为今天
    final initialDay = widget.initialDate ?? DateTime.now();
    _focusedDay = initialDay;
    _selectedDay = DateTime(
      initialDay.year,
      initialDay.month,
      initialDay.day,
    );
    _calendarController = CalendarController();
    _calendarController.displayDate = initialDay;
    _calendarController.selectedDate = _selectedDay;
    _loadDiaryEntries();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryEntries() async {
    final entries = await DiaryUtils.loadDiaryEntries();
    debugPrint('Loaded ${entries.length} diary entries');
    if (mounted) {
      setState(() {
        _diaryEntries = entries;
      });
    }
  }

  /// 处理搜索查询
  Future<void> _handleSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // 执行搜索
    final results = await DiaryUtils.searchDiaryEntries(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _onDayClicked(DateTime selectedDay, DateTime focusedDay) {
    // 标准化选中的日期，只保留年月日
    final normalizedSelectedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    setState(() {
      _selectedDay = normalizedSelectedDay;
      _focusedDay = focusedDay;
    });

    // 更新路由信息，使"询问当前上下文"功能能获取到当前日期
    final dateStr =
        '${normalizedSelectedDay.year}-${normalizedSelectedDay.month.toString().padLeft(2, '0')}-${normalizedSelectedDay.day.toString().padLeft(2, '0')}';
    NavigationHelper.updateRouteWithArguments(
      context,
      '/diary_detail',
      {'date': dateStr},
    );
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _extractImagesFromContent(String content) {
    // Simple regex to find markdown images ![alt](url)
    final regex = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('diary_myDiary'.tr),
      largeTitle: 'diary_myDiary'.tr,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      enableSearchBar: true,
      searchPlaceholder: 'diary_searchPlaceholder'.tr,
      onSearchChanged: _handleSearch,
      onSearchSubmitted: _handleSearch,
      body: _buildCalendarView(),
      searchBody: _buildSearchResults(),
    );
  }

  /// 构建搜索结果视图
  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? Theme.of(context).scaffoldBackgroundColor : _backgroundColor;
    final textColor = isDark ? Colors.white : _primaryTextColor;
    final primaryColor =
        isDark ? Theme.of(context).colorScheme.primary : _primaryColor;

    return Container(
      color: bgColor,
      child:
          _searchResults.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: textColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '没有找到匹配的日记',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '搜索词：$_searchQuery',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final entry = _searchResults[index];
                  return _buildSearchResultCard(
                    entry,
                    textColor,
                    primaryColor,
                    isDark,
                  );
                },
              ),
    );
  }

  /// 构建搜索结果卡片
  Widget _buildSearchResultCard(
    DiaryEntry entry,
    Color textColor,
    Color primaryColor,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEntry(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期和心情
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy年MM月dd日').format(entry.date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (entry.mood != null)
                    Text(entry.mood!, style: const TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 8),

              // 标题
              if (entry.title.isNotEmpty) ...[
                Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // 内容预览（使用QuillViewer，支持Markdown格式化显示）
              SizedBox(
                height: 80, // 限制高度，显示3-4行内容
                child: QuillViewer(
                  data: entry.content,
                  selectable: false, // 只读模式
                ),
              ),
              const SizedBox(height: 12),

              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.content.length} 字',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 跳转到指定日记条目
  void _navigateToEntry(DiaryEntry entry) {
    NavigationHelper.push(
      context,
      DiaryEditorScreen(
        date: entry.date,
        storage: widget.storage,
        initialTitle: entry.title,
        initialContent: entry.content,
      ),
    ).then((_) => _loadDiaryEntries());
  }

  /// 构建日历视图
  Widget _buildCalendarView() {
    // 确保_selectedDay也是标准化的
    final normalizedSelectedDay =
        _selectedDay != null
            ? DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            )
            : null;
    final selectedEntry =
        normalizedSelectedDay != null
            ? _diaryEntries[normalizedSelectedDay]
            : null;
    // Check if current theme is dark
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _primaryTextColor;
    final primaryColor =
        isDark ? Theme.of(context).colorScheme.primary : _primaryColor;

    return Stack(
      children: [
        SingleChildScrollView(
            child: Column(
              children: [
                // Month Selector
                MonthSelector(
                  selectedMonth: _focusedDay,
                  maxDate: DateTime.now(), // 限制不能选择未来月份
                  onMonthSelected: (month) {
                    setState(() {
                      _focusedDay = DateTime(
                        month.year,
                        month.month,
                        _focusedDay.day,
                      );
                      // 同步更新日历控制器的显示日期
                      _calendarController.displayDate = _focusedDay;
                    });
                  },
                  getMonthStats: (month) {
                    // For diary plugin, we'll show entry count instead of financial stats
                    final monthEntries =
                        _diaryEntries.entries.where((entry) {
                          return entry.key.year == month.year &&
                              entry.key.month == month.month;
                        }).toList();

                    final entryCount = monthEntries.length;
                    final totalWords = monthEntries.fold(
                      0,
                      (sum, entry) => sum + entry.value.content.length,
                    );

                    return {
                      'income': entryCount.toDouble(), // Use income for entry count
                      'expense':
                          totalWords.toDouble(), // Use expense for word count
                    };
                  },
                  primaryColor: primaryColor,
                  customStatsBuilder: (stats) {
                    final entryCount = stats['income']?.toInt() ?? 0;
                    final wordCount = stats['expense']?.toInt() ?? 0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$entryCount篇日记',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2ECC71), // 绿色
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          wordCount >= 1000
                              ? '${(wordCount / 1000).toStringAsFixed(1)}k字'
                              : '$wordCount字',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3498DB), // 蓝色
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Calendar
                SfCalendar(
                  controller: _calendarController,
                  view: CalendarView.month,
                  initialDisplayDate: _focusedDay,
                  minDate: DateTime.utc(2020, 1, 1),
                  maxDate: DateTime.now(),
                  headerHeight: 0,
                  viewHeaderHeight: 40,
                  showNavigationArrow: false,
                  monthViewSettings: MonthViewSettings(
                    showTrailingAndLeadingDates: false,
                    dayFormat: 'EEE',
                    monthCellStyle: MonthCellStyle(
                      textStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  cellBorderColor: Colors.transparent,
                  selectionDecoration: const BoxDecoration(),
                  todayHighlightColor: Colors.transparent,
                  monthCellBuilder: (BuildContext context, MonthCellDetails details) {
                    final day = details.date;
                    final normalizedDay = DateTime(day.year, day.month, day.day);
                    final entry = _diaryEntries[normalizedDay];
                    final isToday = _isSameDay(DateTime.now(), day);
                    final isSelected = _isSameDay(_selectedDay, day);

                    return _buildCalendarCellWithMood(
                      day,
                      textColor,
                      isToday || isSelected ? primaryColor : null,
                      isDark,
                      entry,
                      isToday: isToday,
                      isSelected: isSelected,
                    );
                  },
                  onTap: (CalendarTapDetails details) {
                    if (details.date != null) {
                      _onDayClicked(details.date!, details.date!);
                      setState(() {
                        _calendarController.selectedDate = details.date;
                      });
                    }
                  },
                  onViewChanged: (ViewChangedDetails details) {
                    if (details.visibleDates.isNotEmpty) {
                      final newFocusedDay = details.visibleDates[details.visibleDates.length ~/ 2];
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _focusedDay = newFocusedDay;
                          });
                        }
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Selected Day Details
                if (_selectedDay != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    margin: const EdgeInsets.only(bottom: 80), // Add padding for FAB
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期和编辑按钮行
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM d, yyyy').format(_selectedDay!),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Material(
                              key: _editButtonKey,
                              elevation: 2,
                              borderRadius: BorderRadius.circular(20),
                              color: primaryColor,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  final targetDay = _selectedDay ?? DateTime.now();
                                  final normalizedTargetDay = DateTime(
                                    targetDay.year,
                                    targetDay.month,
                                    targetDay.day,
                                  );
                                  NavigationHelper.openContainerWithHero(
                                    context,
                                    (_) => DiaryEditorScreen(
                                      date: normalizedTargetDay,
                                      storage: widget.storage,
                                      initialTitle: selectedEntry?.title ?? '',
                                      initialContent: selectedEntry?.content ?? '',
                                    ),
                                    sourceKey: _editButtonKey,
                                    heroTag: 'diary_edit_button',
                                    closedColor: primaryColor,
                                    closedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ).then((_) => _loadDiaryEntries());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        selectedEntry != null ? Icons.edit : Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        selectedEntry != null
                                            ? 'diary_edit'.tr
                                            : 'diary_create'.tr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedEntry != null) ...[
                          // Images list (if any)
                          Builder(
                            builder: (context) {
                              final images = _extractImagesFromContent(
                                selectedEntry.content,
                              );
                              if (images.isEmpty) return const SizedBox.shrink();
                              return Container(
                                height: 100,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            images[index],
                                          ), // Or FileImage if local
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 200, // Minimum height for better UX
                            ),
                            child: QuillViewer(
                              data: selectedEntry.content,
                              selectable: true,
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    size: 48,
                                    color: textColor.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'diary_noDiaryForDate'.tr,
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 80), // Placeholder when no date is selected
              ],
            ),
          ),
          // FAB with container transform animation
          Positioned(
            bottom: 16,
            right: 16,
            child: Material(
              key: _fabKey,
              elevation: 6,
              shape: const CircleBorder(),
              color: primaryColor,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  final targetDay = _selectedDay ?? DateTime.now();
                  final normalizedTargetDay = DateTime(
                    targetDay.year,
                    targetDay.month,
                    targetDay.day,
                  );
                  // 获取当前选中日期的条目
                  final entry = _diaryEntries[normalizedTargetDay];
                  NavigationHelper.openContainerWithHero(
                    context,
                    (_) => DiaryEditorScreen(
                      date: normalizedTargetDay,
                      storage: widget.storage,
                      initialTitle: entry?.title ?? '',
                      initialContent: entry?.content ?? '',
                    ),
                    sourceKey: _fabKey,
                    heroTag: 'diary_fab_add',
                    closedColor: primaryColor,
                    closedShape: const CircleBorder(),
                  ).then((_) => _loadDiaryEntries());
                },
                child: const SizedBox(
                  height: 56,
                  width: 56,
                  child: Center(
                    child: Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarCellWithMood(
    DateTime day,
    Color textColor,
    Color? borderColor,
    bool isDark,
    DiaryEntry? entry, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final hasEntry = entry != null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:
            (isSelected || isToday)
                ? Border.all(color: borderColor ?? Colors.transparent, width: 2)
                : null,
        color:
            hasEntry
                ? (isDark ? Colors.white10 : Colors.grey.shade100)
                : Colors.transparent,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (entry != null)
            Positioned(
              top: 4,
              right: 4,
              child:
                  entry.mood != null
                      ? Text(
                        entry.mood!,
                        style: const TextStyle(fontSize: 14),
                      )
                      : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: borderColor ?? textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
            ),
        ],
      ),
    );
  }
}
