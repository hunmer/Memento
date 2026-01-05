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

part 'day_js_api.dart';
part 'day_data_selectors.dart';

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

  /// 获取所有纪念日（供小组件使用）
  List<MemorialDay> getAllMemorialDays() {
    if (!_isInitialized) return [];
    return List.from(_controller.memorialDays);
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

  void dispose() {
    // Cleanup resources if needed
  }
}
