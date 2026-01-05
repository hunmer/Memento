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

part 'checkin_js_api.dart';
part 'checkin_data_selectors.dart';

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

}
