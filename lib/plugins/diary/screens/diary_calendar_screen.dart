import 'dart:io' show Platform;
import 'package:Memento/plugins/diary/l10n/diary_localizations.dart';
import 'package:Memento/plugins/bill/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import '../../../widgets/quill_viewer/index.dart';
import '../../../widgets/super_cupertino_navigation_wrapper.dart';
import 'diary_editor_screen.dart';
import '../models/diary_entry.dart';
import '../utils/diary_utils.dart';

class DiaryCalendarScreen extends StatefulWidget {
  final StorageManager storage;

  const DiaryCalendarScreen({super.key, required this.storage});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, DiaryEntry> _diaryEntries = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 搜索相关状态
  String _searchQuery = '';
  List<DiaryEntry> _searchResults = [];

  // Colors from design
  static const Color _primaryColor = Color(0xFFD8BFD8); // Dusty Rose
  static const Color _primaryTextColor = Color(0xFF4A4A4A); // Soft charcoal
  static const Color _backgroundColor = Color(0xFFFAF8F5); // Light cream

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _loadDiaryEntries();
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
    // 只选中日期，不直接打开编辑器
  }

  void _navigateToEditor() async {
    // If no day is selected, default to today
    final targetDay = _selectedDay ?? DateTime.now();

    // Standardize today's date
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Standardize target date
    final normalizedTargetDay = DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
    );

    // Check if target date is in the future
    if (normalizedTargetDay.isAfter(normalizedToday)) {
      Toast.warning(DiaryLocalizations.of(context).cannotSelectFutureDate);
      return;
    }

    // 从存储中获取最新的日记条目，而不是依赖内存缓存
    final entry = await DiaryUtils.loadDiaryEntry(normalizedTargetDay);
    debugPrint(
      'Loading editor for $normalizedTargetDay: ${entry != null ? "found" : "not found"}',
    );

    NavigationHelper.push(
      context,
      DiaryEditorScreen(
        date: normalizedTargetDay,
        storage: widget.storage,
        initialTitle: entry?.title ?? '',
        initialContent: entry?.content ?? '',
      ),
    ).then((_) => _loadDiaryEntries());
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
      title: Text(DiaryLocalizations.of(context).myDiary),
      largeTitle: DiaryLocalizations.of(context).myDiary,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      enableSearchBar: true,
      searchPlaceholder: '搜索日记内容...',
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
                  onMonthSelected: (month) {
                    setState(() {
                      _focusedDay = DateTime(
                        month.year,
                        month.month,
                        _focusedDay.day,
                      );
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
                TableCalendar<DiaryEntry>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDayClicked,
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) {
                    final normalizedDay = DateTime(day.year, day.month, day.day);
                    if (_diaryEntries.containsKey(normalizedDay)) {
                      return [_diaryEntries[normalizedDay]!];
                    }
                    return [];
                  },
                  rowHeight: 70, // Matches h-16 (approx 64px) + gap
                  daysOfWeekHeight: 40,
                  headerVisible: false, // We use custom header
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    weekendStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    dowTextFormatter:
                        (date, locale) =>
                            DateFormat.E(locale).format(date)[0], // S M T ...
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(4),
                    todayDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    defaultDecoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    weekendDecoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  calendarBuilders: CalendarBuilders<DiaryEntry>(
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildCalendarCell(day, textColor, null, isDark);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildCalendarCell(
                        day,
                        textColor,
                        primaryColor,
                        isDark,
                        isToday: true,
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildCalendarCell(
                        day,
                        textColor,
                        primaryColor,
                        isDark,
                        isSelected: true,
                      );
                    },
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      final entry = events.first;
                      return Positioned(
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
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                      );
                    },
                  ),
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
                            if (selectedEntry != null)
                              ElevatedButton.icon(
                                onPressed: _navigateToEditor,
                                icon: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  DiaryLocalizations.of(context).edit,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size(60, 32),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: _navigateToEditor,
                                icon: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  DiaryLocalizations.of(context).create,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size(60, 32),
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
                            constraints: BoxConstraints(
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
                                    DiaryLocalizations.of(context).noDiaryForDate,
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
          // FAB
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _navigateToEditor,
              backgroundColor: primaryColor,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarCell(
    DateTime day,
    Color textColor,
    Color? borderColor,
    bool isDark, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final entry = _diaryEntries[normalizedDay];

    // Simulate random-ish background for demo matching the design's visual interest
    // In a real app, maybe we use a specific color or pattern based on mood/content
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
        ],
      ),
    );
  }
}
