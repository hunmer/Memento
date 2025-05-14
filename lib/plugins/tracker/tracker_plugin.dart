
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/plugins/tracker/utils/tracker_notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:provider/provider.dart';
import 'controllers/tracker_controller.dart';
import 'screens/home_screen.dart';

export 'models/goal.dart';
export 'models/record.dart';
export 'controllers/tracker_controller.dart';
export 'widgets/goal_card.dart';
export 'widgets/goal_detail_page.dart';
export 'widgets/goal_edit_page.dart';
export 'widgets/record_dialog.dart';
export 'utils/date_utils.dart';
export 'utils/tracker_notification_utils.dart';
export 'l10n/tracker_localizations.dart';

class TrackerPlugin extends PluginBase with ChangeNotifier {
  late final TrackerController _controller = TrackerController();
  Map<String, dynamic> _settings = {};

  TrackerController get controller => _controller;
  @override
  String get id => 'tracker_plugin';

  @override
  String get name => '目标跟踪';

  @override
  String get version => '1.0.0';

  @override
  String get description => '用于跟踪和管理个人目标的插件';

  @override
  String get author => 'Memento团队';

  @override
  IconData get icon => Icons.track_changes;

  @override
  Future<void> initialize() async {
    await TrackerNotificationUtils.initialize();
    await _controller.loadInitialData();
  }

    static TrackerPlugin? _instance;
  
  // 获取插件实例的静态方法
  static TrackerPlugin get instance {
    if (_instance == null) {
      throw StateError('''
TrackerPlugin has not been initialized. 
Please initialize the plugin first by calling:
await TrackerPlugin.initializeAndRegister(pluginManager, configManager);
''');
    }
    return _instance!;
  }

  // 初始化并注册插件的静态方法
  static Future<TrackerPlugin> initializeAndRegister(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    if (_instance == null) {
      _instance = TrackerPlugin();
      await _instance!.initialize();
      await _instance!.registerToApp(pluginManager, configManager);
    }
    return _instance!;
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 注册插件到应用
    await pluginManager.registerPlugin(this);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const HomeScreen(),
    );
  }

  /// 打开目标详情页
  void openGoalDetail(BuildContext context, Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _controller,
          child: GoalDetailScreen(goal: goal),
        ),
      ),
    );
  }

  @override
  Widget buildCardView(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TrackerController();

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
                  color: color?.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
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

          // 统计信息卡片
          Column(
            children: [
              // 第一行 - 今日完成和本月完成
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 今日完成
                  Column(
                    children: [
                      Text('今日完成', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.getTodayCompletedGoals()} 个',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  // 本月完成
                  Column(
                    children: [
                      Text('本月完成', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.getMonthCompletedGoals()} 个',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 第二行 - 本月新增
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text('本月新增', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.getMonthAddedGoals()} 个',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
  }
}
