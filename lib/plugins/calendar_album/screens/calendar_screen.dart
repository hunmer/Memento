import 'dart:io' show Platform, File;
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:Memento/widgets/enhanced_calendar/index.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'package:Memento/plugins/calendar_album/widgets/entry_list.dart';
import 'entry_editor_screen.dart';
import 'entry_detail_screen.dart';
import 'package:Memento/plugins/calendar_album/utils/date_utils.dart';
import 'package:intl/intl.dart';

final DateTime _calendarMinMonth = DateTime(2010, 1, 1);
final DateTime _calendarMaxMonth = DateTime(2030, 12, 31);
const int _calendarLoadBatchSize = 3;

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
  bool _isInitialized = false;
  // 搜索相关状态
  String _searchQuery = '';
  Map<String, bool> _searchFilters = {
    'title': true,
    'content': true,
    'tag': true,
  };
  List<CalendarEntry> _searchResults = [];
  // 移除水平视图，只保留垂直视图

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

  /// 获取图片的绝对路径
  Future<String> _getImagePath(String relativePath) async {
    try {
      return await ImageUtils.getAbsolutePath(relativePath);
    } catch (e) {
      debugPrint('获取图片路径失败: $e');
      return relativePath;
    }
  }

  /// 执行搜索操作
  void _performSearch(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final calendarController = Provider.of<CalendarController>(
      context,
      listen: false,
    );

    final allEntries = <CalendarEntry>[];
    // 获取所有日记条目
    calendarController.entries.forEach((date, entries) {
      allEntries.addAll(entries);
    });

    // 根据过滤器条件搜索
    _searchResults =
        allEntries.where((entry) {
          bool matches = false;

          // 搜索标题
          if (_searchFilters['title'] == true) {
            if (entry.title.toLowerCase().contains(query.toLowerCase())) {
              matches = true;
            }
          }

          // 搜索内容
          if (_searchFilters['content'] == true && !matches) {
            if (entry.content.toLowerCase().contains(query.toLowerCase())) {
              matches = true;
            }
          }

          // 搜索标签
          if (_searchFilters['tag'] == true && !matches) {
            if (entry.tags.any(
              (tag) => tag.toLowerCase().contains(query.toLowerCase()),
            )) {
              matches = true;
            }
          }

          return matches;
        }).toList();

    // 按创建时间倒序排列
    _searchResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final calendarController = Provider.of<CalendarController>(context);
    final tagController = Provider.of<TagController>(context);
    final selectedDate = calendarController.selectedDate;
    final theme = Theme.of(context);
    final l10n = CalendarAlbumLocalizations.of(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: calendarController),
        ChangeNotifierProvider.value(value: tagController),
      ],
      child: SuperCupertinoNavigationWrapper(
        title: Text(
          CalendarAlbumLocalizations.of(context).calendarDiary,
          style: TextStyle(
            fontSize: 18,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        largeTitle: l10n.calendarDiary,
        automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
        // 启用搜索栏
        enableSearchBar: true,
        searchPlaceholder: l10n.searchDiaryPlaceholder,
        onSearchChanged: (query) {
          _performSearch(query);
        },
        onSearchSubmitted: (query) {
          _performSearch(query);
        },
        // 启用搜索过滤器
        enableSearchFilter: true,
        filterLabels: {'title': l10n.title, 'content': l10n.content, 'tag': l10n.tag},
        onSearchFilterChanged: (filters) {
          setState(() {
            _searchFilters = Map.from(filters);
          });
          // 重新执行搜索以应用新的过滤器
          if (_searchQuery.isNotEmpty) {
            _performSearch(_searchQuery);
          }
        },
        // 搜索结果页面
        searchBody: _buildSearchResults(calendarController, tagController),
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: theme.iconTheme.color),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                Provider.of<CalendarController>(
                  context,
                  listen: false,
                ).selectDate(DateTime.now());
              });
            },
            tooltip: l10n.backToCurrentMonth,
          ),
        ],
        body: _buildCalendarListView(calendarController, selectedDate),
      ),
    );
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults(
    CalendarController calendarController,
    TagController tagController,
  ) {
    final theme = Theme.of(context);

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.enterKeywordToSearch,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noMatchingDiaries,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryOtherKeywords,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final entry = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              entry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  entry.content.length > 100
                      ? '${entry.content.substring(0, 100)}...'
                      : entry.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 8),
                // 显示图片缩略图
                if (entry.imageUrls.isNotEmpty)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          entry.imageUrls.length > 3
                              ? 3
                              : entry.imageUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = entry.imageUrls[index];
                        return Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.dividerColor.withOpacity(0.3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<String>(
                              future: _getImagePath(imageUrl),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.file(
                                    File(snapshot.data!),
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  );
                                }
                                return Icon(
                                  Icons.image,
                                  color: theme.iconTheme.color?.withOpacity(
                                    0.3,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (entry.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children:
                        entry.tags.map((tag) {
                          return Chip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy-MM-dd').format(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () async {
              await NavigationHelper.push(
                context,
                MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryDetailScreen(entry: entry),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
        );
      },
    );
  }

  void _navigateToNewEntry(BuildContext context) {
    final calendarController = Provider.of<CalendarController>(
      context,
      listen: false,
    );
    final tagController = Provider.of<TagController>(context, listen: false);

    NavigationHelper.push(context, MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: calendarController),
                ChangeNotifierProvider.value(value: tagController),
              ],
              child: EntryEditorScreen(
                initialDate: calendarController.selectedDate,
                isEditing: false,),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildCalendarListView(
    CalendarController calendarController,
    DateTime selectedDate,
  ) {
    final l10n = CalendarAlbumLocalizations.of(context);
    return _VerticalCalendarView(
      calendarController: calendarController,
      selectedDate: selectedDate,
      focusedDay: _focusedDay,
      onDateSelected: (selectedDay) {
        calendarController.selectDate(selectedDay);
        setState(() => _focusedDay = selectedDay);
        // 选中日期后自动弹出抽屉
        _showEntryDrawer(context, calendarController, selectedDay, l10n);
      },
      onDateLongPressed: (pressedDay) {
        // 长按可以选择日期并打开编辑器
        calendarController.selectDate(pressedDay);
        setState(() => _focusedDay = pressedDay);
        NavigationHelper.push(context, MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(
                value: Provider.of<TagController>(context, listen: false),
              ),
                  ],
                  child: EntryEditorScreen(
                    initialDate: pressedDay,
                    isEditing: false,
                  ),
          ),
        );
      },
      onHeaderTapped: (focusedMonth) {
        _showDatePicker(context, calendarController);
      },
    );
  }

  void _showEntryDrawer(
    BuildContext context,
    CalendarController calendarController,
    DateTime selectedDate,
    dynamic l10n,
  ) {
    // 在 showModalBottomSheet 之前获取 TagController 实例
    final tagController = Provider.of<TagController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: calendarController),
              ChangeNotifierProvider.value(value: tagController),
            ],
            child: DraggableScrollableSheet(
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
                                  ' ${DateFormat('yyyy年MM月dd日').format(selectedDate)}${l10n.diaryForDate}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context); // 关闭抽屉
                                  NavigationHelper.push(context, MultiProvider(
                                            providers: [
                                              ChangeNotifierProvider.value(
                                                value: calendarController,
                                              ),
                                              ChangeNotifierProvider.value(
                                                value: tagController,
                                              ),
                                            ],
                                            child: EntryEditorScreen(
                                              initialDate: selectedDate,
                                              isEditing: false,),
                                    ),
                                  ).then((_) {
                                    if (mounted) setState(() {});
                                  });
                                },
                                icon: const Icon(Icons.add),
                                tooltip: l10n.newDiary,
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
        await NavigationHelper.push(context, MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryDetailScreen(entry: entry),
          ),
        );
        if (mounted) setState(() {});
      },
      onEdit: (entry) async {
        Navigator.pop(context); // 关闭抽屉
        await NavigationHelper.push(context, MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryEditorScreen(entry: entry, isEditing: true),
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
      onCreateNew: () {
        Navigator.pop(context); // 关闭抽屉
        NavigationHelper.push(context, MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: calendarController),
                    ChangeNotifierProvider.value(value: tagController),
                  ],
                  child: EntryEditorScreen(
                    initialDate: selectedDate,
                    isEditing: false,),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    CalendarController calendarController,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: _calendarMinMonth,
      lastDate: _calendarMaxMonth,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.year,
      helpText: l10n.selectMonth,
      cancelText: l10n.cancel,
      confirmText: l10n.confirm,
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
  late ScrollController _scrollController;
  final List<DateTime> _months = [];
  final Map<String, Map<DateTime, CalendarDayData>> _cachedDayData = {};
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeMonths();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    // 监听 CalendarController 的变化，数据更新时清除缓存
    widget.calendarController.addListener(_onCalendarDataChanged);
  }

  void _onCalendarDataChanged() {
    // 清除所有缓存，强制重新加载数据
    if (mounted) {
      setState(() {
        _cachedDayData.clear();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    widget.calendarController.removeListener(_onCalendarDataChanged);
    super.dispose();
  }

  /// 初始化月份列表（从当前月份开始，从大到小显示）
  void _initializeMonths() {
    _months.clear();
    final now = DateTime.now();

    debugPrint('=== 垂直视图：初始化月份列表 ===');

    // 从当前月份开始，添加几个月份用于初始化显示
    for (int i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(month);
      debugPrint('初始化月份: ${month.year}-${month.month}');
    }

    debugPrint(
      '初始化完成，月份范围: ${_months.first.year}-${_months.first.month} 到 ${_months.last.year}-${_months.last.month}',
    );
  }

  /// 加载更多月份（向下滚动时加载更早的月份）
  bool _loadMorePreviousMonths() {
    if (_months.isEmpty || _isLoading) return false;

    setState(() => _isLoading = true);

    final addedMonths = <DateTime>[];
    bool hasChanges = false;

    debugPrint('=== 垂直视图：向下滚动，加载更早的月份 ===');
    debugPrint(
      '加载前月份范围: ${_months.first.year}-${_months.first.month} 到 ${_months.last.year}-${_months.last.month}',
    );

    // 获取最早的月份，然后添加更早的月份
    final earliestMonth = _months.last; // 因为列表是从大到小排列，所以最后的是最早的
    var currentMonth = DateTime(earliestMonth.year, earliestMonth.month - 1, 1);

    for (int i = 0; i < _calendarLoadBatchSize; i++) {
      if (currentMonth.isBefore(_calendarMinMonth)) {
        debugPrint('已达到最小月份限制: ${currentMonth.year}-${currentMonth.month}');
        break;
      }

      _months.add(currentMonth);
      addedMonths.add(currentMonth);
      hasChanges = true;
      debugPrint('✓ 添加月份: ${currentMonth.year}-${currentMonth.month}');

      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    }

    debugPrint('当前月份总数: ${_months.length}');

    setState(() => _isLoading = false);

    // 触发数据缓存
    for (final added in addedMonths) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCalendarDayData(added);
      });
    }

    return hasChanges;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoading) return;

    const threshold = 200.0;
    final position = _scrollController.position;

    // 只有向下滚动到底部时才加载更早的月份
    if (position.maxScrollExtent > 0 &&
        (position.maxScrollExtent - position.pixels) <= threshold) {
      debugPrint('=== 滚动到底部，加载更早的月份 ===');
      _loadMorePreviousMonths();
    }
  }

  /// 生成月份的唯一key
  String _getMonthKey(DateTime month) {
    final key = 'vertical_${month.year}_${month.month}';
    debugPrint('垂直视图生成月份Key: ${month.year}-${month.month} -> $key');
    return key;
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
          // 简化的月份标题 - 只显示文本
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              DateFormat('yyyy年MM月').format(month),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // 日历内容 - 使用 GestureDetector 包装，确保滚动事件透传给外层 ListView
          Padding(
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 400, // 限制最大高度，防止内部滚动
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: EnhancedCalendarWidget(
                  dayData: _getCalendarDayData(month),
                  focusedMonth: month,
                  selectedDate: widget.selectedDate,
                  onDaySelected: widget.onDateSelected,
                  onHeaderTapped: widget.onHeaderTapped,
                  enableNavigation: false, // 禁用内置导航，使用外部控制
                  locale: 'zh_CN',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    debugPrint('=== 垂直视图：构建月份显示 ===');
    debugPrint('显示月份总数: ${_months.length}');
    debugPrint(
      '显示月份顺序: ${_months.map((m) => '${m.year}-${m.month}').join(', ')}',
    );

    return Column(
      children: [
        // 垂直滚动的日历列表
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _months.length,
                itemBuilder: (context, index) {
                  final month = _months[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: KeyedSubtree(
                      key: ValueKey('vertical_${_getMonthKey(month)}'),
                      child: _buildMonthCalendar(month),
                    ),
                  );
                },
              ),
              if (_isLoading)
                const Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
