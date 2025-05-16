import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/widgets/store_view.dart';
import 'package:Memento/plugins/store/events/point_award_event.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';

/// 物品兑换插件
class StorePlugin extends BasePlugin {
  @override
  String get id => 'store_plugin';

  @override
  String get name => '物品兑换';

  @override
  String get version => '1.0.0';

  @override
  String get description => '提供物品兑换和管理功能';

  @override
  String get author => '系统团队';

   @override
  IconData get icon => Icons.store;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();
  }

  StoreController? _controller;
  PointAwardEvent? _pointAwardEvent;
  bool _isInitialized = false;

  /// 获取商店控制器
  StoreController get controller {
    assert(_isInitialized, 'StorePlugin must be initialized before accessing controller');
    return _controller!;
  }

  /// 默认积分配置
  static const Map<String, dynamic> defaultPointSettings = {
    'point_awards': {
      'activity_added': 3,      // 添加活动奖励
      'checkin_completed': 10,  // 签到完成奖励
      'task_completed': 20,     // 完成任务奖励
      'note_added': 10,         // 添加笔记奖励
      'goods_added': 5,         // 添加物品奖励
      'onMessageSent': 1,       // 发送消息奖励
      'onRecordAdded': 2,       // 添加记录奖励
      'onDiaryAdded': 5,        // 添加日记奖励
    }
  };

  /// 获取事件积分配置
  Map<String, int> get pointAwardSettings => 
    (settings['point_awards'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int)
    );

  @override
  Future<void> initialize() async {
    if (!_isInitialized) {
      await loadSettings(defaultPointSettings);
      _controller = StoreController(this);
      await _controller!.loadFromStorage();
      _pointAwardEvent = PointAwardEvent(this);
      _isInitialized = true;
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    assert(_controller != null, 'StoreController must be initialized first');
    return StoreView(controller: _controller!);
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
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, size: 24, color: Colors.blue),
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
              // 第一行 - 商品数量和物品数量
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 商品数量
                  Column(
                    children: [
                      Text('商品数量', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.getGoodsCount()} 件',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // 物品数量
                  Column(
                    children: [
                      Text('物品数量', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.getItemsCount()} 件',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 第二行 - 我的积分和七天到期
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 我的积分
                  Column(
                    children: [
                      Text('我的积分', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.currentPoints} 分',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  // 七天到期
                  Column(
                    children: [
                      Text('七天到期', style: theme.textTheme.bodyMedium),
                      Text(
                        '${controller.getExpiringItemsCount()} 件',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
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

  @override
  Widget buildSettingsView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '积分奖励设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: pointAwardSettings.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getEventDisplayName(entry.key),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: entry.value.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffix: Text('积分'),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) async {
                            final points = int.tryParse(value) ?? entry.value;
                            final newSettings = Map<String, dynamic>.from(settings);
                            (newSettings['point_awards'] as Map<String, dynamic>)[entry.key] = points;
                            await updateSettings(newSettings);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取事件显示名称
  String _getEventDisplayName(String eventKey) {
    switch (eventKey) {
      case 'activity_added':
        return '添加活动';
      case 'checkin_completed':
        return '完成签到';
      case 'task_completed':
        return '完成任务';
      case 'note_added':
        return '添加笔记';
      case 'goods_added':
        return '添加物品';
      case 'onMessageSent':
        return '发送消息';
      case 'onRecordAdded':
        return '添加记录';
      case 'onDiaryAdded':
        return '添加日记';
      default:
        return eventKey;
    }
  }
}