import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'l10n/checkin_localizations.dart';
import 'models/checkin_item.dart';
import 'screens/checkin_list_screen/checkin_list_screen.dart';
import 'screens/checkin_stats_screen/checkin_stats_screen.dart';
import 'controllers/checkin_list_controller.dart';
import 'controls/prompt_controller.dart';

class CheckinMainView extends StatefulWidget {
  const CheckinMainView({super.key});

  @override
  State<CheckinMainView> createState() => _CheckinMainViewState();
}

class _CheckinMainViewState extends State<CheckinMainView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 打卡列表页面
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final controller = CheckinListController(
                context: context,
                checkinItems: CheckinPlugin.instance.checkinItems,
                onStateChanged: () {
                  setState(() {});
                  CheckinPlugin.instance.triggerSave();
                },
                expandedGroups: {},
              );
              return CheckinListScreen(controller: controller);
            },
          ),
          // 统计页面
          ValueListenableBuilder(
            valueListenable: ValueNotifier(CheckinPlugin.instance.checkinItems),
            builder: (context, _, __) {
              return CheckinStatsScreen(
                checkinItems: CheckinPlugin.instance.checkinItems,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: '打卡',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
    );
  }
}

class CheckinPlugin extends BasePlugin {
  static final CheckinPlugin _instance = CheckinPlugin._internal();
  factory CheckinPlugin() => _instance;
  CheckinPlugin._internal() {
    _promptController = PromptController();
  }
  static CheckinPlugin get instance => _instance;

  late final PromptController _promptController;

  @override
  String get id => 'checkin';

  @override
  String get name => '打卡';

  @override
  String get version => '1.0.0';

  String get pluginDir => 'checkin';

  @override
  String get description => '管理日常打卡项目';

  @override
  String get author => 'Memento Team';

  @override
  IconData get icon => Icons.checklist;

  List<CheckinItem> _checkinItems = [];
  static const String _storageKey = 'checkin_items';

  // 获取实例的公共方法
  static CheckinPlugin get shared => instance;

  // 获取打卡项目列表
  List<CheckinItem> get checkinItems => _checkinItems;

  // 获取总打卡数
  int getTotalCheckins() {
    return _checkinItems.fold(
      0,
      (sum, item) => sum + item.checkInRecords.length,
    );
  }

  // 获取今日打卡数
  int getTodayCheckins() {
    return _checkinItems.where((item) => item.isCheckedToday()).length;
  }

  // 触发保存的公共方法
  Future<void> triggerSave() async {
    await _saveCheckinItems();
  }

  @override
  Future<void> initialize() async {
    try {
      // 初始化prompt控制器
      _promptController.initialize();

      // 从存储中加载保存的打卡项目
      final pluginPath = 'checkin/$_storageKey';
      if (await storage.fileExists(pluginPath)) {
        final Map<String, dynamic>? storedData = await storage.readJson(
          pluginPath,
        );
        if (storedData != null && storedData.containsKey('items')) {
          _checkinItems = List.from(
            (storedData['items'] as List).map(
              (item) => CheckinItem.fromJson(item as Map<String, dynamic>),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('初始化打卡项目失败: $e');
    }
  }

  @override
  Future<void> uninstall() async {
    _promptController.unregisterPromptMethods();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const CheckinMainView();
  }

  // 添加打卡项目
  Future<void> addCheckinItem(CheckinItem item) async {
    _checkinItems.add(item);
    await _saveCheckinItems();
  }

  // 删除打卡项目
  Future<void> removeCheckinItem(CheckinItem item) async {
    _checkinItems.remove(item);
    await _saveCheckinItems();
  }

  // 更新打卡项目
  Future<void> updateCheckinItem(
    CheckinItem oldItem,
    CheckinItem newItem,
  ) async {
    final index = _checkinItems.indexOf(oldItem);
    if (index != -1) {
      _checkinItems[index] = newItem;
      await _saveCheckinItems();
    }
  }

  // 保存打卡项目到存储
  Future<void> _saveCheckinItems() async {
    try {
      final itemsJson = _checkinItems.map((item) => item.toJson()).toList();
      final pluginPath = 'checkin/$_storageKey';
      await storage.writeJson(pluginPath, {'items': itemsJson});
      // 通知监听者数据已更新
      (ValueNotifier(_checkinItems)..value = _checkinItems).notifyListeners();
    } catch (e) {
      debugPrint('保存打卡项目失败: $e');
    }
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

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
                child: Icon(icon, size: 24, color: color ?? theme.primaryColor),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 今日打卡数
              Column(
                children: [
                  Text(
                    CheckinLocalizations.of(context)!.todayCheckin,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${getTodayCheckins()}/${_checkinItems.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 总打卡数
              Column(
                children: [
                  Text(
                    CheckinLocalizations.of(context)!.totalCheckinCount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${getTotalCheckins()}',
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
    );
  }
}
