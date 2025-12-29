import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'screens/day_home_screen.dart';
import 'controllers/day_controller.dart';
import 'models/memorial_day.dart';
import 'repositories/client_day_repository.dart';
import 'package:shared_models/usecases/day/day_usecase.dart';

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
  late ClientDayRepository _repository;
  late DayUseCase _useCase;
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
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  String? getPluginName(context) {
    return 'day_name'.tr;
  }

  @override
  Future<void> initialize() async {
    // 确保纪念日数据目录存在
    await storage.createDirectory('day');

    // 初始化控制器
    _controller = DayController();
    await _controller.initialize();

    // 创建 Repository 和 UseCase
    _repository = ClientDayRepository(
      controller: _controller,
    );
    _useCase = DayUseCase(_repository);

    _isInitialized = true;

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
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

  // 获取即将到来的纪念日数量（7天内）
  int getUpcomingMemorialDayCount() {
    if (!_isInitialized) return 0;
    return _controller.memorialDays
        .where((day) {
          final daysRemaining = day.daysRemaining;
          return daysRemaining >= 0 && daysRemaining <= 7;
        })
        .length;
  }

  // 获取今日纪念日数量
  int getTodayMemorialDayCount() {
    if (!_isInitialized) return 0;
    return _controller.memorialDays
        .where((day) => day.isToday)
        .length;
  }

  /// 根据 ID 获取纪念日（供小组件使用）
  MemorialDay? getMemorialDayById(String id) {
    if (!_isInitialized) return null;
    try {
      return _controller.memorialDays.firstWhere((day) => day.id == id);
    } catch (e) {
      return null;
    }
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
                'day_name'.tr,

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
                    'day_memorialDaysCount'.tr,
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
                    'day_upcoming'.tr,
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

      // 查找方法
      'findMemorialDayBy': _jsFindMemorialDayBy,
      'findMemorialDayById': _jsFindMemorialDayById,
      'findMemorialDayByName': _jsFindMemorialDayByName,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有纪念日
  Future<String> _jsGetMemorialDays(Map<String, dynamic> params) async {
    try {
      final result = await _useCase.getMemorialDays(params);
      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }
      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 创建纪念日
  Future<String> _jsCreateMemorialDay(Map<String, dynamic> params) async {
    try {
      final result = await _useCase.createMemorialDay(params);
      if (result.isFailure) {
        return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
      }
      return jsonEncode({'success': true, 'data': result.dataOrNull});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 更新纪念日
  Future<String> _jsUpdateMemorialDay(Map<String, dynamic> params) async {
    try {
      final result = await _useCase.updateMemorialDay(params);
      if (result.isFailure) {
        return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
      }
      return jsonEncode({'success': true, 'data': result.dataOrNull});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 删除纪念日
  Future<String> _jsDeleteMemorialDay(Map<String, dynamic> params) async {
    try {
      final result = await _useCase.deleteMemorialDay(params);
      if (result.isFailure) {
        return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
      }
      return jsonEncode({'success': true, 'message': '纪念日已删除'});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取距离指定日期的天数
  Future<String> _jsGetDaysUntil(Map<String, dynamic> params) async {
    try {
      final String? date = params['date'];
      if (date == null) {
        return jsonEncode({'error': '缺少必需参数: date'});
      }

      final targetDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final days = target.difference(today).inDays;

      return jsonEncode({
        'success': true,
        'days': days,
        'isExpired': days < 0,
        'isToday': days == 0,
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取即将到来的纪念日
  Future<String> _jsGetUpcomingDays(Map<String, dynamic> params) async {
    try {
      final int withinDays = params['withinDays'] ?? 7;

      final upcomingDays = _controller.memorialDays.where((day) {
        final daysRemaining = day.daysRemaining;
        return daysRemaining >= 0 && daysRemaining <= withinDays;
      }).toList();

      return jsonEncode({
        'success': true,
        'count': upcomingDays.length,
        'days': upcomingDays.map((d) => d.toJson()).toList(),
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  // ==================== 查找方法 ====================

  /// 通用纪念日查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindMemorialDayBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;

      final days = _controller.memorialDays;
      final List<MemorialDay> matchedDays = [];

      for (final day in days) {
        final dayJson = day.toJson();

        // 检查字段是否匹配
        if (dayJson.containsKey(field) && dayJson[field] == value) {
          matchedDays.add(day);
          if (!findAll) break; // 只找第一个
        }
      }

      if (findAll) {
        return jsonEncode(matchedDays.map((d) => d.toJson()).toList());
      } else {
        if (matchedDays.isEmpty) {
          return jsonEncode(null);
        }
        return jsonEncode(matchedDays.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 根据ID查找纪念日
  /// @param params.id 纪念日ID (必需)
  Future<String> _jsFindMemorialDayById(Map<String, dynamic> params) async {
    try {
      final result = await _useCase.getMemorialDayById(params);
      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }
      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 根据名称查找纪念日
  /// @param params.name 纪念日名称 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindMemorialDayByName(Map<String, dynamic> params) async {
    try {
      final String? name = params['name'];
      if (name == null || name.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final bool fuzzy = params['fuzzy'] ?? false;
      final bool findAll = params['findAll'] ?? false;

      final days = _controller.memorialDays;
      final List<MemorialDay> matchedDays = [];

      for (final day in days) {
        bool matches = false;
        if (fuzzy) {
          matches = day.title.contains(name);
        } else {
          matches = day.title == name;
        }

        if (matches) {
          matchedDays.add(day);
          if (!findAll) break;
        }
      }

      if (findAll) {
        return jsonEncode(matchedDays.map((d) => d.toJson()).toList());
      } else {
        if (matchedDays.isEmpty) {
          return jsonEncode(null);
        }
        return jsonEncode(matchedDays.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  // ==================== 数据选择器注册 ====================

  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'day.memorial',
      pluginId: id,
      name: '选择纪念日',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'memorial',
          title: '选择纪念日',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return _controller.memorialDays.map((day) {
              // 计算倒计时文本
              String subtitle;
              if (day.isToday) {
                subtitle = '今天';
              } else if (day.daysRemaining > 0) {
                subtitle = '剩余 ${day.daysRemaining} 天';
              } else {
                subtitle = '已过 ${day.daysPassed} 天';
              }

              // 添加日期信息
              subtitle += ' · ${day.formattedTargetDate}';

              return SelectableItem(
                id: day.id,
                title: day.title,
                subtitle: subtitle,
                icon: Icons.event_outlined,
                rawData: day,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery)
            ).toList();
          },
        ),
      ],
    ));
  }

  void dispose() {
    // Cleanup resources if needed
  }
}
