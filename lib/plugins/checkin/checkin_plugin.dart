import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import 'models/checkin_item.dart';
import 'screens/checkin_list_screen.dart';
import 'controllers/checkin_list_controller.dart';

class CheckinPlugin extends BasePlugin {
  // 单例模式
  static final CheckinPlugin _instance = CheckinPlugin._internal();

  // 工厂构造函数
  factory CheckinPlugin() => _instance;

  // 私有构造函数
  CheckinPlugin._internal();

  // 单例实例访问器
  static CheckinPlugin get instance => _instance;

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

  List<CheckinItem> _checkinItems = [];
  static const String _storageKey = 'checkin_items';

  // 获取实例的公共方法
  static CheckinPlugin get shared => instance;

  // 获取打卡项目列表
  List<CheckinItem> get checkinItems => _checkinItems;

  // 触发保存的公共方法
  Future<void> triggerSave() async {
    await _saveCheckinItems();
  }

  @override
  Future<void> initialize() async {
    try {
      // 从存储中加载保存的打卡项目
      final pluginPath = 'checkin/$_storageKey';
      if (await storage.fileExists(pluginPath)) {
        final Map<String, dynamic> storedData = await storage.readJson(
          pluginPath,
        );
        if (storedData.containsKey('items')) {
          _checkinItems =
              (storedData['items'] as List)
                  .map(
                    (item) =>
                        CheckinItem.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
        }
      }
    } catch (e) {
      debugPrint('初始化打卡项目失败: $e');
      // 使用默认数据
      _checkinItems = [
        CheckinItem(name: '早起', icon: Icons.wb_sunny),
        CheckinItem(name: '早睡', icon: Icons.nightlight_round),
        CheckinItem(name: '运动', icon: Icons.fitness_center),
      ];
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final controller = CheckinListController(
          context: context,
          checkinItems: _checkinItems,
          onStateChanged: () {
            setState(() {});
            _saveCheckinItems();
          },
          expandedGroups: {},
        );

        return CheckinListScreen(controller: controller);
      },
    );
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
}
