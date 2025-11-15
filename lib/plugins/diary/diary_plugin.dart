import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/event/event.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import 'l10n/diary_localizations.dart';
import 'controls/prompt_controller.dart';
import 'screens/diary_calendar_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'models/diary_entry.dart';
import 'utils/diary_utils.dart';

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

/// 日记插件主视图
class DiaryMainView extends StatefulWidget {
  const DiaryMainView({super.key});
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
    return DiaryCalendarScreen(storage: _plugin.storage);
  }
}

class DiaryPlugin extends BasePlugin with JSBridgePlugin {
  late final DiaryPromptController _promptController;
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

  // 缓存统计数据（用于同步访问）
  int _cachedTodayWordCount = 0;
  int _cachedMonthWordCount = 0;
  (int, int) _cachedMonthProgress = (0, 0);
  DateTime? _cacheDateToday;
  DateTime? _cacheDateMonth;

  @override
  String get id => 'diary';

  @override
  Color get color => Colors.indigo;

  @override
  IconData get icon => Icons.book;

  @override
  String? getPluginName(context) {
    return DiaryLocalizations.of(context).name;
  }

  // 获取今日文字数
  Future<int> getTodayWordCount() async {
    final today = DateTime.now();
    final todayFile = path.join(
      storage.getPluginStoragePath(id),
      '${today.year}/${today.month}/${today.day}.md',
    );

    int wordCount = 0;
    try {
      if (await File(todayFile).exists()) {
        final content = await storage.readFile(todayFile);
        wordCount = content.trim().length;
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
    final monthDir = path.join(
      storage.getPluginStoragePath(id),
      '${now.year}/${now.month}',
    );

    try {
      final dir = Directory(monthDir);
      if (await dir.exists()) {
        await for (final file in dir.list()) {
          if (file.path.endsWith('.md')) {
            final content = await storage.readFile(file.path);
            totalCount += content.trim().length;
          }
        }
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
    final monthDir = path.join(
      storage.getPluginStoragePath(id),
      '${now.year}/${now.month}',
    );

    var completedDays = 0;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    try {
      final dir = Directory(monthDir);
      if (await dir.exists()) {
        await for (final file in dir.list()) {
          if (file.path.endsWith('.md')) {
            completedDays++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating month progress: $e');
    }

    final progress = (completedDays, totalDays);

    // 更新缓存
    _updateMonthCache(now, null, progress);

    return progress;
  }

  // 更新今日缓存
  void _updateTodayCache(DateTime date, int wordCount) {
    final today = DateTime(date.year, date.month, date.day);
    final cachedDay = _cacheDateToday != null
        ? DateTime(_cacheDateToday!.year, _cacheDateToday!.month, _cacheDateToday!.day)
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
    final cachedMonth = _cacheDateMonth != null
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
    final cachedDay = _cacheDateToday != null
        ? DateTime(_cacheDateToday!.year, _cacheDateToday!.month, _cacheDateToday!.day)
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
    final cachedMonth = _cacheDateMonth != null
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
    final cachedMonth = _cacheDateMonth != null
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
  Future<void> initialize() async {
    // 确保日记数据目录存在
    await storage.createDirectory('diary');

    // 初始化 prompt 控制器
    _promptController = DiaryPromptController(this);
    _promptController.initialize();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  Future<void> dispose() async {
    _promptController.unregisterPromptMethods();
    _promptController.dispose();
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
                    DiaryLocalizations.of(context).name,
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
                            DiaryLocalizations.of(context).todayWordCount,
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
                            DiaryLocalizations.of(context).monthWordCount,
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
                            DiaryLocalizations.of(context).monthProgress,
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
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取指定日期范围的日记
  /// 参数: {"startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD"}
  /// 返回: JSON 字符串，包含日记列表
  Future<String> _jsGetDiaries(String startDate, String endDate) async {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);

      final allEntries = await DiaryUtils.loadDiaryEntries();

      // 过滤日期范围
      final filteredEntries = allEntries.entries
          .where((entry) =>
              !entry.key.isBefore(start) && !entry.key.isAfter(end))
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key)); // 按日期排序

      final result = {
        'total': filteredEntries.length,
        'diaries': filteredEntries
            .map((entry) => {
                  'date': entry.key.toIso8601String().split('T')[0],
                  'title': entry.value.title,
                  'content': entry.value.content,
                  'mood': entry.value.mood,
                  'wordCount': entry.value.content.length,
                  'createdAt': entry.value.createdAt.toIso8601String(),
                  'updatedAt': entry.value.updatedAt.toIso8601String(),
                })
            .toList(),
      };

      return jsonEncode(result);
    } catch (e) {
      return jsonEncode({
        'error': '获取日记失败: $e',
        'total': 0,
        'diaries': [],
      });
    }
  }

  /// 获取指定日期的日记
  /// 参数: date (YYYY-MM-DD 格式)
  /// 返回: JSON 字符串，包含日记内容
  Future<String> _jsGetDiary(String date) async {
    try {
      final dateTime = DateTime.parse(date);
      final entry = await DiaryUtils.loadDiaryEntry(dateTime);

      if (entry == null) {
        return jsonEncode({
          'exists': false,
          'error': '该日期没有日记',
        });
      }

      return jsonEncode({
        'exists': true,
        'date': dateTime.toIso8601String().split('T')[0],
        'title': entry.title,
        'content': entry.content,
        'mood': entry.mood,
        'wordCount': entry.content.length,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      });
    } catch (e) {
      return jsonEncode({
        'exists': false,
        'error': '获取日记失败: $e',
      });
    }
  }

  /// 保存日记
  /// 参数: date, title, content, mood (可选)
  /// 返回: JSON 字符串，包含成功状态
  Future<String> _jsSaveDiary(
    String date,
    String title,
    String content, [
    String? mood,
  ]) async {
    try {
      final dateTime = DateTime.parse(date);

      await DiaryUtils.saveDiaryEntry(
        dateTime,
        content,
        title: title,
        mood: mood,
      );

      return jsonEncode({
        'success': true,
        'message': '日记保存成功',
        'date': date,
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': '保存日记失败: $e',
      });
    }
  }

  /// 删除日记
  /// 参数: date (YYYY-MM-DD 格式)
  /// 返回: JSON 字符串，包含成功状态
  Future<String> _jsDeleteDiary(String date) async {
    try {
      final dateTime = DateTime.parse(date);
      final success = await DiaryUtils.deleteDiaryEntry(dateTime);

      return jsonEncode({
        'success': success,
        'message': success ? '日记删除成功' : '该日期没有日记',
        'date': date,
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': '删除日记失败: $e',
      });
    }
  }

  /// 获取今日统计
  /// 返回: JSON 字符串，包含今日字数
  Future<String> _jsGetTodayStats() async {
    try {
      final wordCount = await getTodayWordCount();
      final today = DateTime.now();

      return jsonEncode({
        'date': today.toIso8601String().split('T')[0],
        'wordCount': wordCount,
      });
    } catch (e) {
      return jsonEncode({
        'error': '获取今日统计失败: $e',
        'wordCount': 0,
      });
    }
  }

  /// 获取本月统计
  /// 返回: JSON 字符串，包含本月字数和进度
  Future<String> _jsGetMonthStats() async {
    try {
      final monthWordCount = await getMonthWordCount();
      final progress = await getMonthProgress();
      final now = DateTime.now();

      return jsonEncode({
        'year': now.year,
        'month': now.month,
        'wordCount': monthWordCount,
        'completedDays': progress.$1,
        'totalDays': progress.$2,
        'progress': progress.$2 > 0
            ? (progress.$1 / progress.$2 * 100).toStringAsFixed(1)
            : '0.0',
      });
    } catch (e) {
      return jsonEncode({
        'error': '获取本月统计失败: $e',
        'wordCount': 0,
        'completedDays': 0,
        'totalDays': 0,
        'progress': '0.0',
      });
    }
  }
}
