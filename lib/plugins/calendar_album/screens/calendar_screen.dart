import 'dart:io' show File;

import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:Memento/plugins/calendar_album/widgets/entry_list.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/enhanced_calendar/syncfusion_calendar.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'entry_detail_screen.dart';
import 'entry_editor_screen.dart';

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
    // 使用 addPostFrameCallback 确保在第一帧渲染后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CalendarController>(
          context,
          listen: false,
        ).selectDate(DateTime.now());
        // 初始化时设置路由上下文
        _updateRouteContext(DateTime.now());
      }
    });
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前日期
  void _updateRouteContext(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    RouteHistoryManager.updateCurrentContext(
      pageId: '/calendar_album_calendar',
      title: '日历日记 - $dateStr',
      params: {'date': dateStr},
    );
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: calendarController),
        ChangeNotifierProvider.value(value: tagController),
      ],
      child: SuperCupertinoNavigationWrapper(
        title: Text(
          'calendar_album_calendar_diary'.tr,
          style: TextStyle(
            fontSize: 18,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        largeTitle: 'calendar_album_calendar_diary'.tr,
        // 启用搜索栏
        enableSearchBar: true,
        searchPlaceholder: 'calendar_album_search_diary_placeholder'.tr,
        onSearchChanged: (query) {
          _performSearch(query);
        },
        onSearchSubmitted: (query) {
          _performSearch(query);
        },
        // 启用搜索过滤器
        enableSearchFilter: true,
        filterLabels: {
          'title': 'calendar_album_title'.tr,
          'content': 'calendar_album_content'.tr,
          'tag': 'calendar_album_tag'.tr,
        },
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
              // 更新路由上下文
              _updateRouteContext(DateTime.now());
            },
            tooltip: 'calendar_album_back_to_current_month'.tr,
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
              'calendar_album_enter_keyword_to_search'.tr,
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
              'calendar_album_no_matching_diaries'.tr,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'calendar_album_try_other_keywords'.tr,
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

  Widget _buildCalendarListView(
    CalendarController calendarController,
    DateTime selectedDate,
  ) {
    return _VerticalCalendarView(
      calendarController: calendarController,
      selectedDate: selectedDate,
      focusedDay: _focusedDay,
      onDateSelected: (selectedDay) {
        calendarController.selectDate(selectedDay);
        setState(() => _focusedDay = selectedDay);
        // 更新路由上下文
        _updateRouteContext(selectedDay);
        // 选中日期后自动弹出抽屉
        _showEntryDrawer(context, calendarController, selectedDay);
      },
      onDateLongPressed: (pressedDay) {
        // 长按可以选择日期并打开编辑器
        calendarController.selectDate(pressedDay);
        setState(() => _focusedDay = pressedDay);
        // 更新路由上下文
        _updateRouteContext(pressedDay);
        NavigationHelper.push(
          context,
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: calendarController),
              ChangeNotifierProvider.value(
                value: Provider.of<TagController>(context, listen: false),
              ),
            ],
            child: EntryEditorScreen(initialDate: pressedDay, isEditing: false),
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
  ) {
    // 在 SmoothBottomSheet.show 之前获取 TagController 实例
    final tagController = Provider.of<TagController>(context, listen: false);

    SmoothBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: calendarController),
                ChangeNotifierProvider.value(value: tagController),
              ],
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ' ${DateFormat('yyyy年MM月dd日').format(selectedDate)}${'calendar_album_diary_for_date'.tr}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context); // 关闭抽屉
                            NavigationHelper.push(
                              context,
                              MultiProvider(
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
                                  isEditing: false,
                                ),
                              ),
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                          icon: const Icon(Icons.add),
                          tooltip: 'calendar_album_new_diary'.tr,
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
  ) {
    return EntryList(
      entries: calendarController.getEntriesForDate(selectedDate),
      onTap: (entry) async {
        Navigator.pop(context); // 关闭抽屉
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
      onEdit: (entry) async {
        Navigator.pop(context); // 关闭抽屉
        await NavigationHelper.push(
          context,
          MultiProvider(
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
                  title: Text('common_delete'.tr),
                  content: Text(
                    '${'common_confirmDelete'.tr} "${entry.title}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('chat_cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        calendarController.deleteEntry(entry);
                        Navigator.pop(context); // 关闭对话框
                        Navigator.pop(context); // 关闭抽屉并刷新
                        setState(() {});
                      },
                      child: Text('common_delete'.tr),
                    ),
                  ],
                ),
          ),
      onCreateNew: () {
        Navigator.pop(context); // 关闭抽屉
        NavigationHelper.push(
          context,
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: calendarController),
              ChangeNotifierProvider.value(value: tagController),
            ],
            child: EntryEditorScreen(
              initialDate: selectedDate,
              isEditing: false,
            ),
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
      helpText: 'calendar_album_select_month'.tr,
      cancelText: 'calendar_album_cancel'.tr,
      confirmText: 'calendar_album_confirm'.tr,
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

    // 从当前月份开始，添加几个月份用于初始化显示
    for (int i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      _months.add(month);
    }
  }

  /// 加载更多月份（向下滚动时加载更早的月份）
  bool _loadMorePreviousMonths() {
    if (_months.isEmpty || _isLoading) return false;

    setState(() => _isLoading = true);

    final addedMonths = <DateTime>[];
    bool hasChanges = false;

    // 获取最早的月份，然后添加更早的月份
    final earliestMonth = _months.last; // 因为列表是从大到小排列，所以最后的是最早的
    var currentMonth = DateTime(earliestMonth.year, earliestMonth.month - 1, 1);

    for (int i = 0; i < _calendarLoadBatchSize; i++) {
      if (currentMonth.isBefore(_calendarMinMonth)) {
        break;
      }

      _months.add(currentMonth);
      addedMonths.add(currentMonth);
      hasChanges = true;

      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    }

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

    // 使用 addPostFrameCallback 确保不在 build 阶段访问 position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _isLoading) return;

      const threshold = 200.0;
      final position = _scrollController.position;

      // 只有向下滚动到底部时才加载更早的月份
      if (position.maxScrollExtent > 0 &&
          (position.maxScrollExtent - position.pixels) <= threshold) {
        _loadMorePreviousMonths();
      }
    });
  }

  /// 生成月份的唯一key
  String _getMonthKey(DateTime month) {
    return 'vertical_${month.year}_${month.month}';
  }

  /// 获取指定月份的日历数据（带缓存）- 垂直视图
  /// 注意: isSelected 和 isToday 状态由 EnhancedCalendar 内部的 _dayBuilder 处理，
  /// 这里只需要提供背景图片和条目数量等静态数据
  Map<DateTime, CalendarDayData> _getCalendarDayData(DateTime month) {
    final monthKey = _getMonthKey(month);

    // 检查缓存 - 直接返回，不修改缓存中的选中/今日状态
    // EnhancedCalendar._dayBuilder 会自己计算这些动态状态
    if (_cachedDayData.containsKey(monthKey)) {
      return _cachedDayData[monthKey]!;
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
          // 以下状态由 EnhancedCalendar._dayBuilder 内部计算，这里设置默认值
          isSelected: false,
          isToday: false,
          isCurrentMonth: date.year == month.year && date.month == month.month,
        );
      }
    });

    // 缓存数据
    _cachedDayData[monthKey] = dayData;
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
                // 为每个月份的日历添加独立 key，确保它们完全独立管理自己的状态
                child: SyncfusionCalendarWidget(
                  key: ValueKey(
                    'syncfusion_calendar_${month.year}_${month.month}',
                  ),
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
