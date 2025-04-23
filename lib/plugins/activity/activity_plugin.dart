import 'package:flutter/material.dart';
import '../base_plugin.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import 'screens/activity_timeline_screen.dart';
import 'screens/activity_statistics_screen.dart';

class ActivityPlugin extends BasePlugin {
  static final ActivityPlugin instance = ActivityPlugin._internal();
  ActivityPlugin._internal();

  @override
  final String id = 'activity_plugin';

  @override
  final String name = 'Activity';

  @override
  final String version = '1.0.0';

  @override
  final String pluginDir = 'activity';

  @override
  String get description => '活动记录插件';

  @override
  String get author => 'Zhuanz';

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();

    // 注册插件到插件管理器
    await pluginManager.registerPlugin(this);

    // 保存插件配置
    await configManager.savePluginConfig(id, {
      'version': version,
      'enabled': true,
      'settings': {'theme': 'light'},
    });
  }

  @override
  Future<void> initialize() async {
    // 确保活动记录数据目录存在
    await storage.createDirectory(pluginDir);
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const ActivityMainView();
  }
}

/// 活动插件主视图
class ActivityMainView extends StatefulWidget {
  const ActivityMainView({super.key});

  @override
  State<ActivityMainView> createState() => _ActivityMainViewState();
}

class _ActivityMainViewState extends State<ActivityMainView> {
  int _selectedIndex = 0;

  // 页面列表
  final List<Widget> _pages = const [
    ActivityTimelineScreen(),
    ActivityStatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timeline),
            label: '时间线',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
    );
  }
  @override
  Widget buildMainView(BuildContext context) {
    return const ActivityMainView();
  }
}
