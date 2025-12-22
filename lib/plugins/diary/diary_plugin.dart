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
  Future<void> initialize() async {
    // 确保日记数据目录存在
    await storage.createDirectory('diary');

    // 初始化 UseCase
    final repository = ClientDiaryRepository();
    _diaryUseCase = DiaryUseCase(repository);

    // 注册数据选择器
    _registerDataSelectors();

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  /// 注册日记数据选择器
  void _registerDataSelectors() {
    // 日记条目选择器 - 使用日历视图
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'diary.entry',
      pluginId: id,
      name: '选择日记',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'entry',
          title: '选择日期',
          viewType: SelectorViewType.calendar,
          isFinalStep: true,
          dataLoader: (_) async {
            final entries = await DiaryUtils.loadDiaryEntries();
            return entries.entries.map((e) {
              final entry = e.value;
              return SelectableItem(
                id: DateFormat('yyyy-MM-dd').format(e.key),
                title: entry.title.isNotEmpty
                    ? entry.title
                    : DateFormat('yyyy-MM-dd').format(e.key),
                subtitle: entry.content.length > 50
                    ? '${entry.content.substring(0, 50)}...'
                    : entry.content,
                icon: Icons.article,
                color: color,
                rawData: entry,
                metadata: {
                  'date': e.key,
                  'mood': entry.mood,
                  'wordCount': entry.content.length,
                },
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final entry = item.rawData as DiaryEntry;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  entry.content.toLowerCase().contains(lowerQuery) ||
                  (entry.mood?.contains(query) ?? false);
            }).toList();
          },
        ),
      ],
    ));
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
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取指定日期范围的日记
  /// 参数: {"startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD", "offset": number, "count": number}
  /// 返回: JSON 字符串，包含日记列表
  Future<Map<String, dynamic>> _jsGetDiaries(
    Map<String, dynamic> params,
  ) async {
    try {
      // 验证必需参数
      if (!params.containsKey('startDate')) {
        return {'error': '缺少必需参数: startDate', 'total': 0, 'diaries': []};
      }
      if (!params.containsKey('endDate')) {
        return {'error': '缺少必需参数: endDate', 'total': 0, 'diaries': []};
      }

      // 使用 UseCase 获取日记列表
      final result = await _diaryUseCase.getEntries(params);

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误', 'total': 0, 'diaries': []};
      }

      final diaries = result.dataOrNull ?? [];

      // 检查是否需要分页格式
      final int? offset = params['offset'];
      final int? count = params['count'];

      // 如果没有分页参数，返回原格式（向后兼容）
      if (offset == null && count == null) {
        return {
          'total': diaries.length,
          'diaries': diaries,
        };
      }

      // 有分页参数时，返回分页格式
      return {
        'total': diaries.length,
        'offset': offset ?? 0,
        'count': count ?? 20,
        'hasMore': (offset ?? 0) + (count ?? 20) < diaries.length,
        'diaries': diaries,
      };
    } catch (e) {
      return {'error': '获取日记失败: $e', 'total': 0, 'diaries': []};
    }
  }

  /// 获取指定日期的日记
  /// 参数: {"date": "YYYY-MM-DD"}
  /// 返回: JSON 字符串，包含日记内容
  Future<Map<String, dynamic>> _jsGetDiary(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'exists': false, 'error': '缺少必需参数: date'};
      }

      // 使用 UseCase 获取日记
      final result = await _diaryUseCase.getEntryByDate(params);

      if (result.isFailure) {
        return {'exists': false, 'error': result.errorOrNull?.message ?? '未知错误'};
      }

      final entry = result.dataOrNull;

      if (entry == null) {
        return {'exists': false, 'error': '该日期没有日记'};
      }

      return {
        'exists': true,
        'date': entry['date'],
        'title': entry['title'],
        'content': entry['content'],
        'mood': entry['mood'],
        'wordCount': (entry['content'] as String).length,
        'createdAt': entry['createdAt'],
        'updatedAt': entry['updatedAt'],
      };
    } catch (e) {
      return {'exists': false, 'error': '获取日记失败: $e'};
    }
  }

  /// 保存日记
  /// 参数: {"date": "YYYY-MM-DD", "content": "日记内容", "title": "标题（可选）", "mood": "心情（可选）"}
  /// 返回: JSON 字符串，包含成功状态
  Future<Map<String, dynamic>> _jsSaveDiary(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'success': false, 'error': '缺少必需参数: date'};
      }
      if (!params.containsKey('content')) {
        return {'success': false, 'error': '缺少必需参数: content'};
      }

      // 先检查是否已存在
      final checkResult = await _diaryUseCase.getEntryByDate({'date': params['date']});
      final exists = checkResult.dataOrNull != null;

      // 使用 UseCase 保存日记
      final result = exists
          ? await _diaryUseCase.updateEntry(params)
          : await _diaryUseCase.createEntry(params);

      if (result.isFailure) {
        return {'success': false, 'error': result.errorOrNull?.message ?? '未知错误'};
      }

      return {'success': true, 'message': '日记保存成功', 'date': params['date']};
    } catch (e) {
      return {'success': false, 'error': '保存日记失败: $e'};
    }
  }

  /// 删除日记
  /// 参数: {"date": "YYYY-MM-DD"}
  /// 返回: JSON 字符串，包含成功状态
  Future<Map<String, dynamic>> _jsDeleteDiary(
    Map<String, dynamic> params,
  ) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'success': false, 'error': '缺少必需参数: date'};
      }

      // 使用 UseCase 删除日记
      final result = await _diaryUseCase.deleteEntry(params);

      if (result.isFailure) {
        return {'success': false, 'error': result.errorOrNull?.message ?? '未知错误'};
      }

      final data = result.dataOrNull;
      final deleted = data?['deleted'] ?? false;

      return {
        'success': deleted,
        'message': deleted ? '日记删除成功' : '该日期没有日记',
        'date': params['date'],
      };
    } catch (e) {
      return {'success': false, 'error': '删除日记失败: $e'};
    }
  }

  /// 获取今日统计
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: JSON 字符串，包含今日字数
  Future<Map<String, dynamic>> _jsGetTodayStats(
    Map<String, dynamic> params,
  ) async {
    try {
      // 使用 UseCase 获取今日字数
      final result = await _diaryUseCase.getTodayWordCount(params);

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误', 'wordCount': 0};
      }

      final wordCount = result.dataOrNull ?? 0;
      final today = DateTime.now();

      return {
        'date': today.toIso8601String().split('T')[0],
        'wordCount': wordCount,
      };
    } catch (e) {
      return {'error': '获取今日统计失败: $e', 'wordCount': 0};
    }
  }

  /// 获取本月统计
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: JSON 字符串，包含本月字数和进度
  Future<Map<String, dynamic>> _jsGetMonthStats(
    Map<String, dynamic> params,
  ) async {
    try {
      // 使用 UseCase 获取本月字数和进度
      final wordCountResult = await _diaryUseCase.getMonthWordCount(params);
      final progressResult = await _diaryUseCase.getMonthProgress(params);

      if (wordCountResult.isFailure || progressResult.isFailure) {
        return {
          'error': '获取本月统计失败',
          'wordCount': 0,
          'completedDays': 0,
          'totalDays': 0,
          'progress': '0.0',
        };
      }

      final wordCount = wordCountResult.dataOrNull ?? 0;
      final progress = progressResult.dataOrNull ?? {};
      final completedDays = progress['completedDays'] ?? 0;
      final totalDays = progress['totalDays'] ?? 0;
      final now = DateTime.now();

      return {
        'year': now.year,
        'month': now.month,
        'wordCount': wordCount,
        'completedDays': completedDays,
        'totalDays': totalDays,
        'progress': totalDays > 0
            ? (completedDays / totalDays * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      return {
        'error': '获取本月统计失败: $e',
        'wordCount': 0,
        'completedDays': 0,
        'totalDays': 0,
        'progress': '0.0',
      };
    }
  }

  // ==================== 新增 JS API 实现 ====================

  /// 获取今日字数（直接返回数字）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 数字，今日字数
  Future<int> _jsGetTodayWordCount(Map<String, dynamic> params) async {
    final result = await _diaryUseCase.getTodayWordCount(params);
    return result.dataOrNull ?? 0;
  }

  /// 获取本月字数（直接返回数字）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 数字，本月总字数
  Future<int> _jsGetMonthWordCount(Map<String, dynamic> params) async {
    final result = await _diaryUseCase.getMonthWordCount(params);
    return result.dataOrNull ?? 0;
  }

  /// 获取本月进度（直接返回对象）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 对象，包含 completedDays 和 totalDays
  Future<Map<String, int>> _jsGetMonthProgress(
    Map<String, dynamic> params,
  ) async {
    final result = await _diaryUseCase.getMonthProgress(params);
    final progress = result.dataOrNull ?? {};
    return {
      'completedDays': progress['completedDays'] ?? 0,
      'totalDays': progress['totalDays'] ?? 0,
    };
  }

  /// 加载日记条目（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD"}
  /// 返回: 日记对象或 null
  Future<Map<String, dynamic>?> _jsLoadDiaryEntry(
    Map<String, dynamic> params,
  ) async {
    try {
      if (!params.containsKey('dateStr')) {
        return {'error': '缺少必需参数: dateStr'};
      }

      // 使用 UseCase 获取日记
      final result = await _diaryUseCase.getEntryByDate({'date': params['dateStr']});

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误'};
      }

      return result.dataOrNull;
    } catch (e) {
      return {'error': '加载日记失败: $e'};
    }
  }

  /// 保存日记条目（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD", "content": "内容", "title": "标题（可选）", "mood": "心情（可选）"}
  /// 返回: 保存后的日记对象
  Future<Map<String, dynamic>> _jsSaveDiaryEntry(
    Map<String, dynamic> params,
  ) async {
    try {
      if (!params.containsKey('dateStr') || !params.containsKey('content')) {
        return {'error': '缺少必需参数: dateStr 或 content'};
      }

      // 转换参数格式
      final saveParams = {
        'date': params['dateStr'],
        'content': params['content'],
        'title': params['title'] ?? '',
        'mood': params['mood'],
      };

      // 先检查是否已存在
      final checkResult = await _diaryUseCase.getEntryByDate({'date': params['dateStr']});
      final exists = checkResult.dataOrNull != null;

      // 使用 UseCase 保存
      final result = exists
          ? await _diaryUseCase.updateEntry(saveParams)
          : await _diaryUseCase.createEntry(saveParams);

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误'};
      }

      return result.dataOrNull ?? {};
    } catch (e) {
      return {'error': '保存日记失败: $e'};
    }
  }

  /// 删除日记条目（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD"}
  /// 返回: 布尔值，删除成功返回 true
  Future<bool> _jsDeleteDiaryEntry(Map<String, dynamic> params) async {
    try {
      if (!params.containsKey('dateStr')) {
        return false;
      }

      // 使用 UseCase 删除
      final result = await _diaryUseCase.deleteEntry({'date': params['dateStr']});

      if (result.isFailure) {
        debugPrint('Delete diary entry error: ${result.errorOrNull?.message ?? '未知错误'}');
        return false;
      }

      final data = result.dataOrNull;
      return data?['deleted'] ?? false;
    } catch (e) {
      debugPrint('Delete diary entry error: $e');
      return false;
    }
  }

  /// 检查日期是否有日记（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD"}
  /// 返回: 布尔值，存在返回 true
  Future<bool> _jsHasEntryForDate(Map<String, dynamic> params) async {
    try {
      if (!params.containsKey('dateStr')) {
        return false;
      }

      // 使用 UseCase 获取日记
      final result = await _diaryUseCase.getEntryByDate({'date': params['dateStr']});
      return result.dataOrNull != null;
    } catch (e) {
      debugPrint('Check diary entry error: $e');
      return false;
    }
  }

  /// 获取日记统计（直接操作方法）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 统计对象
  Future<Map<String, dynamic>> _jsGetDiaryStats(
    Map<String, dynamic> params,
  ) async {
    final result = await _diaryUseCase.getStats(params);
    return result.dataOrNull ?? {};
  }
}
