import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../base_plugin.dart';
import 'l10n/checkin_localizations.dart';
import 'models/checkin_item.dart';
import 'screens/checkin_list_screen/checkin_list_screen.dart';
import 'screens/checkin_stats_screen/checkin_stats_screen.dart';
import 'controllers/checkin_list_controller.dart';

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
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: CheckinLocalizations.of(context).checkinList,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: CheckinLocalizations.of(context).checkinStats,
          ),
        ],
      ),
    );
  }
}

class CheckinPlugin extends BasePlugin with JSBridgePlugin {
  static final CheckinPlugin _instance = CheckinPlugin._internal();
  factory CheckinPlugin() => _instance;
  CheckinPlugin._internal() {
  }
  static CheckinPlugin get instance => _instance;


  @override
  String get id => 'checkin';

  @override
  Color get color => Colors.teal;

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
    // 初始化prompt控制器

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

    // 注册 JS API（最后一步）
    await registerJSAPI();
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
    final itemsJson = _checkinItems.map((item) => item.toJson()).toList();
    final pluginPath = 'checkin/$_storageKey';
    await storage.writeJson(pluginPath, {'items': itemsJson});
    // 通知监听者数据已更新
    (ValueNotifier(_checkinItems)..value = _checkinItems).notifyListeners();
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  @override
  String? getPluginName(context) {
    return CheckinLocalizations.of(context).name;
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
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                CheckinLocalizations.of(context).name,
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
                    CheckinLocalizations.of(context).todayCheckin,
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
                    CheckinLocalizations.of(context).totalCheckinCount,
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

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 获取签到项目列表
      'getCheckinItems': _jsGetCheckinItems,

      // 执行签到
      'checkin': _jsCheckin,

      // 获取签到历史
      'getCheckinHistory': _jsGetCheckinHistory,

      // 获取统计信息
      'getStats': _jsGetStats,

      // 创建签到项目
      'createCheckinItem': _jsCreateCheckinItem,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取签到项目列表
  Future<String> _jsGetCheckinItems(Map<String, dynamic> params) async {
    final items =
        _checkinItems
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'group': item.group,
                'description': item.description,
                'icon': item.icon.codePoint,
                // ignore: deprecated_member_use
                'color':
                    '0x${item.color.value.toRadixString(16).padLeft(8, '0')}',
                'frequency': item.frequency,
                'consecutiveDays': item.getConsecutiveDays(),
                'isCheckedToday': item.isCheckedToday(),
                'lastCheckinDate': item.lastCheckinDate?.toIso8601String(),
              },
            )
            .toList();

    return jsonEncode(items);
  }

  /// 执行签到
  Future<String> _jsCheckin(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    final item = _checkinItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('签到项目不存在: $itemId'),
    );

    // 检查今天是否已签到
    if (item.isCheckedToday()) {
      return jsonEncode({'success': false, 'message': '今天已经签到过了'});
    }

    // 可选参数
    final String? note = params['note'];

    // 创建签到记录
    final now = DateTime.now();
    final record = CheckinRecord(
      startTime: now,
      endTime: now,
      checkinTime: now,
      note: note,
    );

    await item.addCheckinRecord(record);
    await _saveCheckinItems();

    return jsonEncode({
      'success': true,
      'message': '签到成功',
      'consecutiveDays': item.getConsecutiveDays(),
      'checkinTime': now.toIso8601String(),
    });
  }

  /// 获取签到历史
  Future<String> _jsGetCheckinHistory(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? itemId = params['itemId'];
    if (itemId == null) {
      return jsonEncode({'error': '缺少必需参数: itemId'});
    }

    final item = _checkinItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('签到项目不存在: $itemId'),
    );

    // 可选参数
    final String? startDate = params['startDate'];
    final String? endDate = params['endDate'];

    // 解析日期范围
    DateTime? start;
    DateTime? end;
    if (startDate != null) {
      start = DateTime.parse(startDate);
    }
    if (endDate != null) {
      end = DateTime.parse(endDate);
    }

    // 收集符合日期范围的记录
    final List<Map<String, dynamic>> history = [];

    item.checkInRecords.forEach((dateStr, records) {
      final date = DateTime.parse(dateStr);

      // 检查是否在日期范围内
      if (start != null && date.isBefore(start)) return;
      if (end != null && date.isAfter(end)) return;

      for (final record in records) {
        history.add({
          'date': dateStr,
          'checkinTime': record.checkinTime.toIso8601String(),
          'startTime': record.startTime.toIso8601String(),
          'endTime': record.endTime.toIso8601String(),
          'note': record.note,
        });
      }
    });

    // 按签到时间倒序排序
    history.sort((a, b) => b['checkinTime'].compareTo(a['checkinTime']));

    return jsonEncode({
      'itemId': itemId,
      'itemName': item.name,
      'history': history,
      'totalCount': history.length,
    });
  }

  /// 获取统计信息
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
    // 可选参数
    final String? itemId = params['itemId'];

    if (itemId != null) {
      // 获取单个项目的统计信息
      final item = _checkinItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('签到项目不存在: $itemId'),
      );

      return jsonEncode({
        'itemId': itemId,
        'itemName': item.name,
        'totalCheckins': item.checkInRecords.values.fold<int>(
          0,
          (sum, records) => sum + records.length,
        ),
        'consecutiveDays': item.getConsecutiveDays(),
        'isCheckedToday': item.isCheckedToday(),
        'lastCheckinDate': item.lastCheckinDate?.toIso8601String(),
      });
    } else {
      // 获取全局统计信息
      return jsonEncode({
        'totalItems': _checkinItems.length,
        'todayCheckins': getTodayCheckins(),
        'totalCheckins': getTotalCheckins(),
        'completionRate':
            _checkinItems.isEmpty
                ? 0.0
                : getTodayCheckins() / _checkinItems.length,
      });
    }
  }

  /// 创建签到项目
  Future<String> _jsCreateCheckinItem(Map<String, dynamic> params) async {
    // 必需参数验证
    final String? name = params['name'];
    if (name == null) {
      return jsonEncode({'error': '缺少必需参数: name'});
    }

    // 检查名称是否重复
    if (_checkinItems.any((item) => item.name == name)) {
      return jsonEncode({'success': false, 'message': '签到项目名称已存在: $name'});
    }

    // 可选参数
    final String? id = params['id'];
    final String? group = params['group'];
    final String? description = params['description'];

    // 检查自定义ID是否已存在
    if (id != null && _checkinItems.any((item) => item.id == id)) {
      return jsonEncode({'success': false, 'message': '签到项目ID已存在: $id'});
    }

    // 创建新项目
    final item = CheckinItem(
      id: id, // 如果传入null，会自动使用时间戳作为ID
      name: name,
      icon: Icons.check_circle,
      group: group ?? '默认分组',
      description: description ?? '',
    );

    await addCheckinItem(item);

    return jsonEncode({
      'success': true,
      'message': '创建成功',
      'item': {
        'id': item.id,
        'name': item.name,
        'group': item.group,
        'description': item.description,
      },
    });
  }
}
