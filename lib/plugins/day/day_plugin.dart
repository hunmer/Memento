import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:Memento/plugins/day/l10n/day_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'screens/day_home_screen.dart';
import 'controllers/day_controller.dart';
import 'controls/prompt_controller.dart';

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

class DayPlugin extends BasePlugin {
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
  late PromptController _promptController;
  bool _isInitialized = false;

  @override
  final String id = 'day';

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
    return DatabaseLocalizations.of(context).name;
  }

  @override
  Future<void> initialize() async {
    // 确保纪念日数据目录存在
    await storage.createDirectory('day');
    _controller = DayController();
    await _controller.initialize();

    // 初始化prompt控制器
    _promptController = PromptController();
    _promptController.initialize();

    _isInitialized = true;
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
                  color: theme.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                name,
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

  void dispose() {
    // 注销prompt替换方法
    _promptController.unregisterPromptMethods();
  }
}
