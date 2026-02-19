import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:get/get.dart';
import 'screens/diary_calendar_screen.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'models/diary_entry.dart';
import 'utils/diary_utils.dart';
import 'repositories/client_diary_repository.dart';
import 'package:shared_models/usecases/diary/diary_usecase.dart';

part 'diary_js_api.dart';
part 'diary_data_selectors.dart';

/// 日记创建事件参数
class DiaryEntryCreatedEventArgs extends EventArgs {
  final DiaryEntry entry;

  DiaryEntryCreatedEventArgs(this.entry) : super('diary_entry_created');
}

/// 日记更新事件参数
class DiaryEntryUpdatedEventArgs extends EventArgs {
  final DiaryEntry entry;

  DiaryEntryUpdatedEventArgs(this.entry) : super('diary_entry_updated');
}

/// 日记删除事件参数
class DiaryEntryDeletedEventArgs extends EventArgs {
  final DateTime date;

  DiaryEntryDeletedEventArgs(this.date) : super('diary_entry_deleted');
}

/// 日记缓存更新事件参数（携带数据，性能优化）
class DiaryCacheUpdatedEventArgs extends EventArgs {
  /// 本月日记条目列表（日期, 条目）
  final List<(DateTime, DiaryEntry)> entries;

  /// 当前月份
  final DateTime month;

  /// 条目数量
  final int count;

  DiaryCacheUpdatedEventArgs({
    required this.entries,
    required this.month,
  }) : count = entries.length,
       super('diary_cache_updated');
}

/// 日记插件主视图
class DiaryMainView extends StatefulWidget {
  final DateTime? initialDate;

  const DiaryMainView({super.key, this.initialDate});

  @override
  State<DiaryMainView> createState() => _DiaryMainViewState();
}

class _DiaryMainViewState extends State<DiaryMainView> {
  late DiaryPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin;
  }

  @override
  Widget build(BuildContext context) {
    return DiaryCalendarScreen(
      storage: _plugin.storage,
      initialDate: widget.initialDate,
    );
  }
}

class DiaryPlugin extends BasePlugin with JSBridgePlugin {
  static DiaryPlugin? _instance;
  static DiaryPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
      if (_instance == null) {
        throw StateError('DiaryPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  // UseCase 实例
  late final DiaryUseCase _diaryUseCase;

  // 初始化标志
  bool _isInitialized = false;

  // 缓存统计数据（用于同步访问）
  int _cachedTodayWordCount = 0;
  int _cachedMonthWordCount = 0;
  (int, int) _cachedMonthProgress = (0, 0);
  DateTime? _cacheDateToday;
  DateTime? _cacheDateMonth;

  // 缓存本月日记列表（用于同步访问）
  List<(DateTime, DiaryEntry)> _cachedMonthlyDiaryEntries = [];
  DateTime? _cacheDateMonthlyEntries;
  bool _monthlyEntriesCacheValid = false;

  @override
  String get id => 'diary';

  @override
  Color get color => Colors.indigo;

  @override
  IconData get icon => Icons.book;

  @override
  String? getPluginName(context) {
    return 'diary_name'.tr;
  }

  // 获取今日文字数
  Future<int> getTodayWordCount() async {
    final today = DateTime.now();
    final todayFile = path.join(
      storage.getPluginStoragePath(id),
      '${DateFormat('yyyy-MM-dd').format(today)}.json',
    );

    int wordCount = 0;
    try {
      if (await storage.exists(todayFile)) {
        final content = await storage.readFile(todayFile);
        if (content.isNotEmpty) {
          // 解析 JSON 文件
          final jsonData = jsonDecode(content) as Map<String, dynamic>;
          final diaryContent = jsonData['content'] as String? ?? '';
          wordCount = diaryContent.trim().length;
        }
      }
    } catch (e) {
      debugPrint('Error reading today\'s diary: $e');
    }

    // 更新缓存
    _updateTodayCache(today, wordCount);

    return wordCount;
  }

  // 获取本月文字数
  Future<int> getMonthWordCount() async {
    final now = DateTime.now();
    var totalCount = 0;

    try {
      // 使用 DiaryUtils 加载所有日记条目
      final allEntries = await DiaryUtils.loadDiaryEntries();

      // 过滤本月的日记
      final currentMonthEntries = allEntries.entries.where((entry) {
        return entry.key.year == now.year && entry.key.month == now.month;
      });

      // 计算总字数
      for (final entry in currentMonthEntries) {
        totalCount += entry.value.content.trim().length;
      }
    } catch (e) {
      debugPrint('Error calculating month word count: $e');
    }

    // 更新缓存
    _updateMonthCache(now, totalCount, null);

    return totalCount;
  }

  // 获取本月完成进度
  Future<(int, int)> getMonthProgress() async {
    final now = DateTime.now();
    var completedDays = 0;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    try {
      // 使用 DiaryUtils 加载所有日记条目
      final allEntries = await DiaryUtils.loadDiaryEntries();

      // 过滤本月的日记并计算有日记的天数
      final currentMonthDates =
          allEntries.keys.where((date) {
            return date.year == now.year && date.month == now.month;
          }).toSet();

      completedDays = currentMonthDates.length;
    } catch (e) {
      debugPrint('Error calculating month progress: $e');
    }

    final progress = (completedDays, totalDays);

    // 更新缓存
    _updateMonthCache(now, null, progress);

    return progress;
  }

  // 获取本月日记列表（异步，用于缓存刷新）
  Future<List<(DateTime, DiaryEntry)>> getMonthlyDiaryEntries() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    try {
      // 使用 DiaryUtils 加载所有日记条目
      final allEntries = await DiaryUtils.loadDiaryEntries();

      // 过滤本月的日记
      final monthlyEntries = <(DateTime, DiaryEntry)>[];
      for (final entry in allEntries.entries) {
        if (entry.key.year == year && entry.key.month == month) {
          monthlyEntries.add((entry.key, entry.value));
        }
      }

      // 按日期排序（倒序）
      monthlyEntries.sort((a, b) => b.$1.compareTo(a.$1));

      // 更新缓存
      _updateMonthlyEntriesCache(now, monthlyEntries);

      return monthlyEntries;
    } catch (e) {
      debugPrint('[DiaryPlugin] 获取本月日记失败: $e');
      return [];
    }
  }

  // 同步获取本月日记列表（从缓存）
  List<(DateTime, DiaryEntry)> getMonthlyDiaryEntriesSync() {
    // 如果缓存无效，返回空列表并异步刷新
    if (!_monthlyEntriesCacheValid) {
      getMonthlyDiaryEntries();
      return [];
    }

    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final cachedMonth = _cacheDateMonthlyEntries != null
        ? DateTime(_cacheDateMonthlyEntries!.year, _cacheDateMonthlyEntries!.month)
        : null;

    if (cachedMonth == null || !cachedMonth.isAtSameMomentAs(month)) {
      // 日期不匹配，异步刷新并返回空列表
      getMonthlyDiaryEntries();
      return [];
    }

    return _cachedMonthlyDiaryEntries;
  }

  // 更新本月缓存
  void _updateMonthlyEntriesCache(DateTime date, List<(DateTime, DiaryEntry)> entries) {
    final month = DateTime(date.year, date.month);
    final cachedMonth = _cacheDateMonthlyEntries != null
        ? DateTime(_cacheDateMonthlyEntries!.year, _cacheDateMonthlyEntries!.month)
        : null;

    // 如果是新的月份，重置缓存
    if (cachedMonth == null || !cachedMonth.isAtSameMomentAs(month)) {
      _cachedMonthlyDiaryEntries = [];
      _cacheDateMonthlyEntries = month;
      _monthlyEntriesCacheValid = false;
    }

    // 更新缓存值
    _cachedMonthlyDiaryEntries = entries;
    _monthlyEntriesCacheValid = true;
  }

  // 更新今日缓存
  void _updateTodayCache(DateTime date, int wordCount) {
    final today = DateTime(date.year, date.month, date.day);
    final cachedDay =
        _cacheDateToday != null
            ? DateTime(
              _cacheDateToday!.year,
              _cacheDateToday!.month,
              _cacheDateToday!.day,
            )
            : null;

    // 如果是新的一天，重置缓存
    if (cachedDay == null || !cachedDay.isAtSameMomentAs(today)) {
      _cachedTodayWordCount = 0;
      _cacheDateToday = today;
    }

    // 更新缓存值
    _cachedTodayWordCount = wordCount;
  }

  // 更新本月缓存
  void _updateMonthCache(DateTime date, int? wordCount, (int, int)? progress) {
    final month = DateTime(date.year, date.month);
    final cachedMonth =
        _cacheDateMonth != null
            ? DateTime(_cacheDateMonth!.year, _cacheDateMonth!.month)
            : null;

    // 如果是新的月份，重置缓存
    if (cachedMonth == null || !cachedMonth.isAtSameMomentAs(month)) {
      _cachedMonthWordCount = 0;
      _cachedMonthProgress = (0, 0);
      _cacheDateMonth = month;
    }

    // 更新缓存值
    if (wordCount != null) _cachedMonthWordCount = wordCount;
    if (progress != null) _cachedMonthProgress = progress;
  }

  // 同步获取今日文字数（从缓存）
  int getTodayWordCountSync() {
    // 检查缓存是否是今天的
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cachedDay =
        _cacheDateToday != null
            ? DateTime(
              _cacheDateToday!.year,
              _cacheDateToday!.month,
              _cacheDateToday!.day,
            )
            : null;

    if (cachedDay != null && cachedDay.isAtSameMomentAs(today)) {
      return _cachedTodayWordCount;
    }

    // 如果缓存不可用，异步刷新缓存（不等待）
    getTodayWordCount();

    return 0;
  }

  // 同步获取本月文字数（从缓存）
  int getMonthWordCountSync() {
    // 检查缓存是否是本月的
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final cachedMonth =
        _cacheDateMonth != null
            ? DateTime(_cacheDateMonth!.year, _cacheDateMonth!.month)
            : null;

    if (cachedMonth != null && cachedMonth.isAtSameMomentAs(month)) {
      return _cachedMonthWordCount;
    }

    // 如果缓存不可用，异步刷新缓存（不等待）
    getMonthWordCount();

    return 0;
  }

  // 同步获取本月完成进度（从缓存）
  (int, int) getMonthProgressSync() {
    // 检查缓存是否是本月的
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final cachedMonth =
        _cacheDateMonth != null
            ? DateTime(_cacheDateMonth!.year, _cacheDateMonth!.month)
            : null;

    if (cachedMonth != null && cachedMonth.isAtSameMomentAs(month)) {
      return _cachedMonthProgress;
    }

    // 如果缓存不可用，异步刷新缓存（不等待）
    getMonthProgress();

    return (0, DateTime(now.year, now.month + 1, 0).day);
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 日记查询接口
      'getDiaries': _jsGetDiaries,
      'getDiary': _jsGetDiary,

      // 日记操作接口
      'saveDiary': _jsSaveDiary,
      'deleteDiary': _jsDeleteDiary,

      // 统计接口
      'getTodayStats': _jsGetTodayStats,
      'getMonthStats': _jsGetMonthStats,
      'getTodayWordCount': _jsGetTodayWordCount,
      'getMonthWordCount': _jsGetMonthWordCount,
      'getMonthProgress': _jsGetMonthProgress,

      // 日记条目操作接口（直接操作方法）
      'loadDiaryEntry': _jsLoadDiaryEntry,
      'saveDiaryEntry': _jsSaveDiaryEntry,
      'deleteDiaryEntry': _jsDeleteDiaryEntry,
      'hasEntryForDate': _jsHasEntryForDate,
      'getDiaryStats': _jsGetDiaryStats,

      // 日记查找接口
      'findDiaryBy': _jsFindDiaryBy,
      'findDiaryByDate': _jsFindDiaryByDate,
      'findDiaryByTitle': _jsFindDiaryByTitle,
    };
  }

  @override
  Future<void> initialize() async {
    // 确保日记数据目录存在
    await storage.createDirectory('diary');

    // 初始化 UseCase
    final repository = ClientDiaryRepository();
    _diaryUseCase = DiaryUseCase(repository);

    // 注册数据选择器
    _registerDataSelectors();

    // 订阅日记事件以刷新缓存
    _setupEventListeners();

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 标记为已初始化
    _isInitialized = true;

    // 初始化完成后主动刷新缓存，确保首次加载有数据
    getMonthlyDiaryEntries();
  }

  // 设置事件监听器
  void _setupEventListeners() {
    eventManager.subscribe('diary_entry_created', (_) => _refreshMonthlyEntriesCache());
    eventManager.subscribe('diary_entry_updated', (_) => _refreshMonthlyEntriesCache());
    eventManager.subscribe('diary_entry_deleted', (_) => _refreshMonthlyEntriesCache());
  }

  // 刷新本月日记缓存
  Future<void> _refreshMonthlyEntriesCache() async {
    debugPrint('[DiaryPlugin] _refreshMonthlyEntriesCache called, _isInitialized=$_isInitialized');
    if (!_isInitialized) return;

    try {
      final entries = await getMonthlyDiaryEntries();
      final now = DateTime.now();

      debugPrint('[DiaryPlugin] Broadcasting diary_cache_updated with ${entries.length} entries');

      // 广播时携带数据（性能优化：小组件可直接使用，无需再次获取）
      eventManager.broadcast(
        'diary_cache_updated',
        DiaryCacheUpdatedEventArgs(
          entries: entries,
          month: DateTime(now.year, now.month),
        ),
      );
    } catch (e) {
      debugPrint('[DiaryPlugin] 刷新本月日记缓存失败: $e');
    }
  }

  @override
  Future<void> registerToApp(

    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  Future<void> dispose() async {
    // 清理资源
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DiaryMainView();
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<(int, int, int)>(
      future: Future.wait([
        getTodayWordCount(),
        getMonthWordCount(),
        getMonthProgress().then((value) => value.$1),
      ]).then((values) => (values[0], values[1], values[2])),
      builder: (context, snapshot) {
        final todayCount = snapshot.data?.$1 ?? 0;
        final monthCount = snapshot.data?.$2 ?? 0;
        final completedDays = snapshot.data?.$3 ?? 0;
        final totalDays =
            DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'diary_name'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息卡片
              Column(
                children: [
                  // 第一行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'diary_todayWordCount'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$todayCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  todayCount > 0
                                      ? theme.colorScheme.primary
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const VerticalDivider(),
                      Column(
                        children: [
                          Text(
                            'diary_monthWordCount'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$monthCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'diary_monthProgress'.tr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$completedDays/$totalDays',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  completedDays > 0
                                      ? theme.colorScheme.primary
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
