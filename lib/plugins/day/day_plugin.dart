import 'dart:convert';
import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:Memento/plugins/day/l10n/day_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../base_plugin.dart';
import 'screens/day_home_screen.dart';
import 'controllers/day_controller.dart';
import 'models/memorial_day.dart';

/// 纪念日插件主视图
class DayMainView extends StatefulWidget {
  const DayMainView({super.key});
  @override
  State<DayMainView> createState() => _DayMainViewState();
}

class _DayMainViewState extends State<DayMainView> {
  @override
  Widget build(BuildContext context) {
    return const DayHomeScreen();
  }
}

class DayPlugin extends BasePlugin with JSBridgePlugin {
  static DayPlugin? _instance;
  static DayPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('day') as DayPlugin?;
      if (_instance == null) {
        throw StateError('DayPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late DayController _controller;
  bool _isInitialized = false;

  @override
  final String id = 'day';

  @override
  Color get color => Colors.black87;

  @override
  IconData get icon => Icons.event_outlined;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  @override
  String? getPluginName(context) {
    return DayLocalizations.of(context).name;
  }

  @override
  Future<void> initialize() async {
    // 确保纪念日数据目录存在
    await storage.createDirectory('day');
    _controller = DayController();
    await _controller.initialize();

    _isInitialized = true;

    // 注册 JS API（最后一步）
    await registerJSAPI();
  }

  // 获取纪念日总数
  int getMemorialDayCount() {
    if (!_isInitialized) return 0;
    return _controller.memorialDays.length;
  }

  // 获取即将到来的纪念日（7天内）
  List<String> getUpcomingMemorialDays() {
    if (!_isInitialized) return [];
    return _controller.memorialDays
        .where((day) {
          final daysRemaining = day.daysRemaining;
          return daysRemaining >= 0 && daysRemaining <= 7;
        })
        .map((day) => day.title)
        .toList();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    if (!_isInitialized) return null;

    final theme = Theme.of(context);
    final upcomingDays = getUpcomingMemorialDays();
    final totalCount = getMemorialDayCount();

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
                DayLocalizations.of(context).name,

                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 纪念日数
              Column(
                children: [
                  Text(
                    DayLocalizations.of(context).memorialDaysCount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$totalCount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 即将到来
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    DayLocalizations.of(context).upcoming,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    upcomingDays.isNotEmpty ? upcomingDays.join('，') : '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMainView(BuildContext context) {
    return DayMainView();
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 纪念日管理
      'getMemorialDays': _jsGetMemorialDays,
      'createMemorialDay': _jsCreateMemorialDay,
      'updateMemorialDay': _jsUpdateMemorialDay,
      'deleteMemorialDay': _jsDeleteMemorialDay,

      // 工具方法
      'getDaysUntil': _jsGetDaysUntil,
      'getUpcomingDays': _jsGetUpcomingDays,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有纪念日
  Future<String> _jsGetMemorialDays(Map<String, dynamic> params) async {
    final days = _controller.memorialDays;
    return jsonEncode(days.map((d) => d.toJson()).toList());
  }

  /// 创建纪念日
  Future<String> _jsCreateMemorialDay(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? name = params['name'];
      if (name == null) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final String? date = params['date'];
      if (date == null) {
        return jsonEncode({'error': '缺少必需参数: date'});
      }

      // 解析日期
      final targetDate = DateTime.parse(date);

      // 可选参数
      final String? id = params['id'];
      final String? notesJson = params['notesJson'];
      final int? backgroundColor = params['backgroundColor'];

      // 解析笔记
      List<String> notes = [];
      if (notesJson != null && notesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(notesJson);
          if (decoded is List) {
            notes = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // 如果解析失败,当作单个笔记处理
          notes = [notesJson];
        }
      }

      // 创建纪念日
      final memorialDay = MemorialDay(
        id: id, // 支持传入自定义ID，如果为null则自动生成
        title: name,
        targetDate: targetDate,
        notes: notes,
        backgroundColor: backgroundColor != null
            ? Color(backgroundColor)
            : null,
      );

      // 添加到控制器
      await _controller.addMemorialDay(memorialDay);

      return jsonEncode({
        'success': true,
        'data': memorialDay.toJson(),
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 更新纪念日
  Future<String> _jsUpdateMemorialDay(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? id = params['id'];
      if (id == null) {
        return jsonEncode({'error': '缺少必需参数: id'});
      }

      // 查找现有纪念日
      final existingDay = _controller.memorialDays
          .firstWhere((d) => d.id == id, orElse: () => throw Exception('未找到 ID 为 $id 的纪念日'));

      // 可选参数
      final String? name = params['name'];
      final String? date = params['date'];
      final String? notesJson = params['notesJson'];
      final int? backgroundColor = params['backgroundColor'];

      // 解析新日期
      DateTime? targetDate;
      if (date != null && date.isNotEmpty) {
        targetDate = DateTime.parse(date);
      }

      // 解析新笔记
      List<String>? notes;
      if (notesJson != null && notesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(notesJson);
          if (decoded is List) {
            notes = decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          notes = [notesJson];
        }
      }

      // 更新纪念日
      final updatedDay = existingDay.copyWith(
        title: name,
        targetDate: targetDate,
        notes: notes,
        backgroundColor: backgroundColor != null
            ? Color(backgroundColor)
            : null,
      );

      await _controller.updateMemorialDay(updatedDay);

      return jsonEncode({
        'success': true,
        'data': updatedDay.toJson(),
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 删除纪念日
  Future<String> _jsDeleteMemorialDay(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? id = params['id'];
      if (id == null) {
        return jsonEncode({'error': '缺少必需参数: id'});
      }

      await _controller.deleteMemorialDay(id);
      return jsonEncode({
        'success': true,
        'message': '纪念日已删除',
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 获取距离指定日期的天数
  Future<String> _jsGetDaysUntil(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? date = params['date'];
      if (date == null) {
        return jsonEncode({'error': '缺少必需参数: date'});
      }

      final targetDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final days = target.difference(today).inDays;

      return jsonEncode({
        'success': true,
        'days': days,
        'isExpired': days < 0,
        'isToday': days == 0,
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 获取即将到来的纪念日
  Future<String> _jsGetUpcomingDays(Map<String, dynamic> params) async {
    try {
      // 可选参数
      final int withinDays = params['withinDays'] ?? 7;

      final upcomingDays = _controller.memorialDays
          .where((day) {
            final daysRemaining = day.daysRemaining;
            return daysRemaining >= 0 && daysRemaining <= withinDays;
          })
          .toList();

      return jsonEncode({
        'success': true,
        'count': upcomingDays.length,
        'days': upcomingDays.map((d) => d.toJson()).toList(),
      });
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  void dispose() {
    // Cleanup resources if needed
  }
}
