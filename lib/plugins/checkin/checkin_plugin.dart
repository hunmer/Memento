import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:shared_models/shared_models.dart';
import 'models/checkin_item.dart';
import 'screens/checkin_list_screen/checkin_list_screen.dart';
import 'screens/checkin_stats_screen/checkin_stats_screen.dart';
import 'screens/checkin_form_screen.dart';
import 'controllers/checkin_list_controller.dart';
import 'repositories/client_checkin_repository.dart';

class CheckinMainView extends StatefulWidget {
  /// 可选的打卡项目ID，用于从小组件跳转时自动打开打卡记录对话框
  final String? itemId;

  /// 可选的目标日期（格式：YYYY-MM-DD），用于打开指定日期的打卡记录
  final String? targetDate;

  const CheckinMainView({super.key, this.itemId, this.targetDate});

  @override
  State<CheckinMainView> createState() => _CheckinMainViewState();
}

class _CheckinMainViewState extends State<CheckinMainView>
    with SingleTickerProviderStateMixin {
  final CheckinPlugin checkinPlugin = CheckinPlugin.instance;
  late TabController _tabController;
  late int _currentPage;
  final GlobalKey _bottomBarKey = GlobalKey();
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

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: checkinPlugin.color,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: () async {
        final newItem = await NavigationHelper.openContainer<CheckinItem>(
          context,
          (context) => const CheckinFormScreen(),
        );
        if (newItem != null) {
          await checkinPlugin.addCheckinItem(newItem);
          if (mounted) {
            setState(() {});
          }
        }
      },
      child: Icon(
        Icons.add,
        color: checkinPlugin.color.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              final listController = CheckinListController(
                context: context,
                onStateChanged: () {
                  setState(() {});
                  CheckinPlugin.instance.triggerSave();
                },
              );
              return CheckinListScreen(
                controller: listController,
                initialItemId: widget.itemId,
                targetDate: widget.targetDate,
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: ValueNotifier(
              CheckinPlugin.instance.checkinItems,
            ),
            builder: (context, _, __) {
              return CheckinStatsScreen(
                checkinItems: CheckinPlugin.instance.checkinItems,
              );
            },
          ),
        ],
      ),
      fab: _buildFab(),
      children: [
        Tab(
          icon: Icon(Icons.check_circle_outline),
          text: 'checkin_checkinList'.tr,
        ),
        Tab(
          icon: Icon(Icons.bar_chart_outlined),
          text: 'checkin_checkinStats'.tr,
        ),
      ],
    );
  }
}

class CheckinPlugin extends BasePlugin with JSBridgePlugin {
  static final CheckinPlugin _instance = CheckinPlugin._internal();
  factory CheckinPlugin() => _instance;
  CheckinPlugin._internal();
  static CheckinPlugin get instance => _instance;

  @override
  String get id => 'checkin';

  @override
  Color get color => Colors.teal;

  @override
  IconData get icon => Icons.checklist;

  List<CheckinItem> _checkinItems = [];

  // UseCase 实例
  late final CheckinUseCase _checkinUseCase;
  CheckinUseCase get checkinUseCase => _checkinUseCase;

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
    // 初始化 Repository 和 UseCase
    final repository = ClientCheckinRepository(storage: storage, pluginId: id);
    _checkinUseCase = CheckinUseCase(repository);

    // 从 UseCase 加载保存的打卡项目
    final itemsResult = await _checkinUseCase.getItems({});
    if (itemsResult.isSuccess) {
      final jsonList = itemsResult.dataOrNull as List<dynamic>;
      final items = jsonList
          .map((json) => CheckinItemDto.fromJson(json as Map<String, dynamic>))
          .toList();
      _checkinItems = items
          .map((dto) => _dtoToCheckinItem(dto))
          .toList();
    }

    // 如果没有数据，创建默认的四个打卡项目
    if (_checkinItems.isEmpty) {
      final defaultItems = [
        {
          'name': '早起',
          'icon': Icons.wb_sunny.codePoint,
          'color': Colors.orange.value,
          'group': '健康习惯',
          'description': '每天早起，开启美好一天',
        },
        {
          'name': '运动',
          'icon': Icons.directions_run.codePoint,
          'color': Colors.green.value,
          'group': '健康习惯',
          'description': '坚持运动，保持健康',
        },
        {
          'name': '阅读',
          'icon': Icons.menu_book.codePoint,
          'color': Colors.blue.value,
          'group': '学习成长',
          'description': '每天阅读，丰富知识',
        },
        {
          'name': '喝水',
          'icon': Icons.local_drink.codePoint,
          'color': Colors.cyan.value,
          'group': '健康习惯',
          'description': '每天喝足够的水，保持健康',
        },
      ];

      for (final item in defaultItems) {
        await _checkinUseCase.createItem(item);
        final dto = _paramsToDto(item);
        _checkinItems.add(_dtoToCheckinItem(dto));
      }
    }

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 注册数据选择器
    _registerDataSelectors();
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const CheckinMainView();
  }

  // 注册数据选择器
  void _registerDataSelectors() {
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'checkin.item',
      pluginId: id,
      name: '选择签到项',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'item',
          title: '选择签到项',
          viewType: SelectorViewType.grid,
          isFinalStep: true,
          dataLoader: (_) async {
            return _checkinItems.map((item) => SelectableItem(
              id: item.id,
              title: item.name,
              subtitle: item.group,
              icon: item.icon,
              color: item.color,
              rawData: item,
            )).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery) ||
              (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
            ).toList();
          },
        ),
      ],
    ));
  }

  // 添加打卡项目
  Future<void> addCheckinItem(CheckinItem item) async {
    try {
      // 通过 UseCase 创建项目
      final params = {
        'id': item.id,
        'name': item.name,
        'icon': item.icon.codePoint,
        'color': item.color.value,
        'group': item.group,
        'description': item.description,
        'cardStyle': item.cardStyle.index,
        'reminderSettings': item.reminderSettings?.toJson(),
      };

      final result = await _checkinUseCase.createItem(params);

      if (result.isSuccess) {
        // 创建成功后，重新加载数据
        await _saveCheckinItems();
      } else {
        final error = result.errorOrNull;
        final message = error != null ? error.message : '创建打卡项目失败';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('创建打卡项目失败: $e');
    }
  }

  // 删除打卡项目
  Future<void> removeCheckinItem(CheckinItem item) async {
    try {
      // 通过 UseCase 删除项目
      final result = await _checkinUseCase.deleteItem({'id': item.id});

      if (result.isSuccess) {
        // 删除成功后，重新加载数据
        await _saveCheckinItems();
      } else {
        final error = result.errorOrNull;
        final message = error != null ? error.message : '删除打卡项目失败';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('删除打卡项目失败: $e');
    }
  }

  // 更新打卡项目
  Future<void> updateCheckinItem(
    CheckinItem oldItem,
    CheckinItem newItem,
  ) async {
    try {
      // 通过 UseCase 更新项目
      final params = {
        'id': oldItem.id,
        'name': newItem.name,
        'icon': newItem.icon.codePoint,
        'color': newItem.color.value,
        'group': newItem.group,
        'description': newItem.description,
        'cardStyle': newItem.cardStyle.index,
        'reminderSettings': newItem.reminderSettings?.toJson(),
      };

      final result = await _checkinUseCase.updateItem(params);

      if (result.isSuccess) {
        // 更新成功后，重新加载数据
        await _saveCheckinItems();
      } else {
        final error = result.errorOrNull;
        final message = error != null ? error.message : '更新打卡项目失败';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('更新打卡项目失败: $e');
    }
  }

  // 保存打卡项目到存储（同步 UseCase 和本地列表）
  Future<void> _saveCheckinItems() async {
    // 重新从 UseCase 加载数据
    final itemsResult = await _checkinUseCase.getItems({});
    if (itemsResult.isSuccess) {
      final jsonList = itemsResult.dataOrNull as List<dynamic>;
      final items = jsonList
          .map((json) => CheckinItemDto.fromJson(json as Map<String, dynamic>))
          .toList();
      _checkinItems = items.map((dto) => _dtoToCheckinItem(dto)).toList();
    }
    // 同步到小组件
    await _syncWidget();
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncCheckin();
    // 同步打卡项目小组件（支持配置特定打卡项的小组件）
    await PluginWidgetSyncHelper.instance.syncCheckinItemWidget();
    // 同步打卡周视图小组件
    await PluginWidgetSyncHelper.instance.syncCheckinWeeklyWidget();
  }

  // ============ 辅助转换方法 ============

  /// 将 Map 参数转换为 CheckinItemDto
  CheckinItemDto _paramsToDto(Map<String, dynamic> params) {
    // 如果没有提供 id 或 id 为空，生成一个新的 UUID
    final id = params['id'] as String?;
    final itemId = (id != null && id.isNotEmpty) ? id : const Uuid().v4();

    return CheckinItemDto(
      id: itemId,
      name: params['name'] as String,
      icon: params['icon'] as int,
      color: params['color'] as int,
      group: params['group'] as String? ?? '默认分组',
      description: params['description'] as String? ?? '',
      cardStyle: params['cardStyle'] as int? ?? 0,
      reminderSettings: params['reminderSettings'] != null
          ? ReminderSettingsDto.fromJson(params['reminderSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 将 CheckinItemDto 转换为 CheckinItem
  CheckinItem _dtoToCheckinItem(CheckinItemDto dto) {
    // 将 icon codePoint 转换为 IconData
    final icon = IconData(dto.icon, fontFamily: 'MaterialIcons');
    // 将 color int 转换为 Color
    final color = Color(dto.color);

    // 将 checkInRecords 转换
    final records = <String, List<CheckinRecord>>{};
    dto.checkInRecords.forEach((date, recordDtos) {
      records[date] = recordDtos.map((r) => CheckinRecord(
        startTime: r.startTime,
        endTime: r.endTime,
        checkinTime: r.checkinTime,
        note: r.note,
      )).toList();
    });

    // 转换提醒设置
    ReminderSettings? reminderSettings;
    if (dto.reminderSettings != null) {
      final rs = dto.reminderSettings!;
      reminderSettings = ReminderSettings(
        type: _dtoReminderTypeToLocal(rs.type),
        weekdays: rs.weekdays,
        dayOfMonth: rs.dayOfMonth,
        specificDate: rs.specificDate,
        timeOfDay: TimeOfDay(hour: rs.hour, minute: rs.minute),
      );
    }

    return CheckinItem(
      id: dto.id,
      name: dto.name,
      icon: icon,
      color: color,
      group: dto.group,
      description: dto.description,
      cardStyle: _dtoCardStyleToLocal(dto.cardStyle),
      reminderSettings: reminderSettings,
      checkInRecords: records,
    );
  }

  /// 转换提醒类型
  ReminderType _dtoReminderTypeToLocal(int dtoType) {
    switch (dtoType) {
      case 0:
        return ReminderType.weekly;
      case 1:
        return ReminderType.monthly;
      case 2:
        return ReminderType.specific;
      default:
        return ReminderType.weekly;
    }
  }

  /// 转换卡片样式
  CheckinCardStyle _dtoCardStyleToLocal(int dtoStyle) {
    switch (dtoStyle) {
      case 0:
        return CheckinCardStyle.weekly;
      case 1:
        return CheckinCardStyle.small;
      case 2:
        return CheckinCardStyle.calendar;
      default:
        return CheckinCardStyle.weekly;
    }
  }

  @override
  Future<void> registerToApp(
    
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
  }

  @override
  String? getPluginName(context) {
    return 'checkin_name'.tr;
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
                'checkin_name'.tr,
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
                    'checkin_todayCheckin'.tr,
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
                    'checkin_totalCheckinCount'.tr,
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
    try {
      // 使用 UseCase 获取数据
      final result = await _checkinUseCase.getItems(params);

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
      }

      final jsonDataList = result.dataOrNull as List<dynamic>;
      final items = jsonDataList
          .map((json) => CheckinItemDto.fromJson(json as Map<String, dynamic>))
          .toList();

      // 转换为前端需要的格式
      final jsonList = items.map((dto) {
        final item = _dtoToCheckinItem(dto);
        return {
          'id': item.id,
          'name': item.name,
          'group': item.group,
          'description': item.description,
          'icon': item.icon.codePoint,
          'color': '0x${item.color.value.toRadixString(16).padLeft(8, '0')}',
          'frequency': item.frequency,
          'consecutiveDays': item.getConsecutiveDays(),
          'isCheckedToday': item.isCheckedToday(),
          'lastCheckinDate': item.lastCheckinDate?.toIso8601String(),
        };
      }).toList();

      // UseCase 已经处理了分页，直接返回
      return jsonEncode(jsonList);
    } catch (e) {
      return jsonEncode({'error': '获取签到项目失败: $e'});
    }
  }

  /// 执行签到
  Future<String> _jsCheckin(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? itemId = params['itemId'];
      if (itemId == null) {
        return jsonEncode({'error': '缺少必需参数: itemId'});
      }

      // 可选参数
      final String? note = params['note'];

      // 创建签到记录
      final now = DateTime.now();
      final record = {
        'startTime': now.toIso8601String(),
        'endTime': now.toIso8601String(),
        'checkinTime': now.toIso8601String(),
        'note': note,
      };

      // 使用 UseCase 添加打卡记录
      final result = await _checkinUseCase.addCheckinRecord({
        'itemId': itemId,
        ...record,
      });

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
      }

      // 更新本地列表
      await _saveCheckinItems();

      // 查找对应的项目以获取连续天数
      final item = _checkinItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('签到项目不存在'),
      );

      return jsonEncode({
        'success': true,
        'message': '签到成功',
        'consecutiveDays': item.getConsecutiveDays(),
        'checkinTime': now.toIso8601String(),
      });
    } catch (e) {
      return jsonEncode({'error': '签到失败: $e'});
    }
  }

  /// 获取签到历史
  Future<String> _jsGetCheckinHistory(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? itemId = params['itemId'];
      if (itemId == null) {
        return jsonEncode({'error': '缺少必需参数: itemId'});
      }

      // 获取项目信息
      final itemResult = await _checkinUseCase.getItemById({'id': itemId});
      if (itemResult.isFailure || itemResult.dataOrNull == null) {
        return jsonEncode({'error': '签到项目不存在: $itemId'});
      }

      final json = itemResult.dataOrNull as Map<String, dynamic>;
      final itemDto = CheckinItemDto.fromJson(json);
      final item = _dtoToCheckinItem(itemDto);

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
    } catch (e) {
      return jsonEncode({'error': '获取签到历史失败: $e'});
    }
  }

  /// 获取统计信息
  Future<String> _jsGetStats(Map<String, dynamic> params) async {
    try {
      // 可选参数
      final String? itemId = params['itemId'];

      if (itemId != null) {
        // 获取单个项目的统计信息
        final itemResult = await _checkinUseCase.getItemById({'id': itemId});
        if (itemResult.isFailure || itemResult.dataOrNull == null) {
          return jsonEncode({'error': '签到项目不存在: $itemId'});
        }

        final json = itemResult.dataOrNull as Map<String, dynamic>;
        final itemDto = CheckinItemDto.fromJson(json);
        final item = _dtoToCheckinItem(itemDto);

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
        // 使用 UseCase 获取全局统计信息
        final statsResult = await _checkinUseCase.getStats({});
        if (statsResult.isFailure) {
          return jsonEncode({'error': statsResult.errorOrNull?.message ?? '未知错误'});
        }

        final stats = statsResult.dataOrNull as CheckinStatsDto;

        return jsonEncode({
          'totalItems': stats.totalItems,
          'todayCheckins': stats.todayCheckins,
          'totalCheckins': stats.totalCheckins,
          'completionRate': stats.completionRate,
        });
      }
    } catch (e) {
      return jsonEncode({'error': '获取统计信息失败: $e'});
    }
  }

  /// 创建签到项目
  Future<String> _jsCreateCheckinItem(Map<String, dynamic> params) async {
    try {
      // 必需参数验证
      final String? name = params['name'];
      if (name == null) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      // 可选参数
      final String? id = params['id'];
      final String? group = params['group'];
      final String? description = params['description'];
      final int? icon = params['icon'] ?? Icons.check_circle.codePoint;
      final int? color = params['color'] ?? Colors.blue.value;

      // 使用 UseCase 创建项目
      final result = await _checkinUseCase.createItem({
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'group': group ?? '默认分组',
        'description': description ?? '',
      });

      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message ?? '未知错误'});
      }

      // 更新本地列表
      await _saveCheckinItems();

      final json = result.dataOrNull as Map<String, dynamic>;
      final itemDto = CheckinItemDto.fromJson(json);
      final item = _dtoToCheckinItem(itemDto);

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
    } catch (e) {
      return jsonEncode({'error': '创建签到项目失败: $e'});
    }
  }
}
