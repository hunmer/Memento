import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../../core/services/plugin_widget_sync_helper.dart';
import '../base_plugin.dart';
import 'l10n/checkin_localizations.dart';
import 'models/checkin_item.dart';
import 'screens/checkin_list_screen/checkin_list_screen.dart';
import 'screens/checkin_stats_screen/checkin_stats_screen.dart';
import 'screens/checkin_form_screen.dart';
import 'controllers/checkin_list_controller.dart';

class CheckinMainView extends StatefulWidget {
  const CheckinMainView({super.key});

  @override
  State<CheckinMainView> createState() => _CheckinMainViewState();
}

class _CheckinMainViewState extends State<CheckinMainView>
    with SingleTickerProviderStateMixin {
  final CheckinPlugin checkinPlugin = CheckinPlugin.instance;
  late TabController _tabController;
  late int _currentPage;
  final List<Color> _colors = [
    Colors.teal,
    Colors.blue,
    Colors.cyan,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(CheckinLocalizations.of(context).name),
      ),
      body: BottomBar(
        fit: StackFit.expand,
        icon:
            (width, height) => Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // 滚动到顶部功能
                  if (_tabController.indexIsChanging) return;

                  // 切换到第一个tab
                  if (_currentPage != 0) {
                    _tabController.animateTo(0);
                  }
                },
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  color: _colors[_currentPage],
                  size: width,
                ),
              ),
            ),
        borderRadius: BorderRadius.circular(25),
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        showIcon: true,
        width: MediaQuery.of(context).size.width * 0.85,
        barColor:
            _colors[_currentPage].computeLuminance() > 0.5
                ? Colors.black
                : Colors.white,
        start: 2,
        end: 0,
        offset: 12,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 35,
        iconWidth: 35,
        reverse: false,
        barDecoration: BoxDecoration(
          color: _colors[_currentPage].withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _colors[_currentPage].withOpacity(0.3),
            width: 1,
          ),
        ),
        iconDecoration: BoxDecoration(
          color: _colors[_currentPage].withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _colors[_currentPage].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        hideOnScroll: true,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body:
            (context, controller) => TabBarView(
              controller: _tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: [
                // 打卡列表页面
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    final listController = CheckinListController(
                      context: context,
                      checkinItems: CheckinPlugin.instance.checkinItems,
                      onStateChanged: () {
                        setState(() {});
                        CheckinPlugin.instance.triggerSave();
                      },
                    );
                    return CheckinListScreen(controller: listController);
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
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color:
                      _currentPage < 2
                          ? _colors[_currentPage]
                          : unselectedColor,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              labelColor:
                  _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
              unselectedLabelColor: unselectedColor,
              tabs: [
                Tab(
                  icon: Icon(Icons.check_circle_outline),
                  text: CheckinLocalizations.of(context).checkinList,
                ),
                Tab(
                  icon: Icon(Icons.bar_chart_outlined),
                  text: CheckinLocalizations.of(context).checkinStats,
                ),
              ],
            ),
            Positioned(
              top: -25,
              child: FloatingActionButton(
                backgroundColor: checkinPlugin.color,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CheckinFormScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    // 同步到小组件
    await _syncWidget();
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    try {
      await PluginWidgetSyncHelper.instance.syncCheckin();
    } catch (e) {
      debugPrint('Failed to sync checkin widget: $e');
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

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取签到项目列表
  /// 支持分页参数: offset, count
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

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        items,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

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

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        history,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode({
        'itemId': itemId,
        'itemName': item.name,
        'history': paginated['data'],
        'total': paginated['total'],
        'offset': paginated['offset'],
        'count': paginated['count'],
        'hasMore': paginated['hasMore'],
      });
    }

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
