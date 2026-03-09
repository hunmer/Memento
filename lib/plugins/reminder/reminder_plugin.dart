import 'package:flutter/material.dart';
import 'package:Memento/plugins/base_plugin.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'services/reminder_service.dart';
import 'services/reminder_scheduler.dart';
import 'screens/reminder_list_screen.dart';

/// 定时提醒插件
class ReminderPlugin extends BasePlugin {
  static ReminderPlugin? _instance;

  static ReminderPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('reminder') as ReminderPlugin?;
      if (_instance == null) {
        throw StateError('ReminderPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  late final ReminderService _service;
  late final ReminderScheduler _scheduler;

  @override
  String get id => 'reminder';

  @override
  Color get color => Colors.amber;

  @override
  IconData get icon => Icons.alarm;

  @override
  Future<void> initialize() async {
    // 初始化服务
    _service = ReminderService();
    await _service.initialize();

    // 初始化调度器
    _scheduler = ReminderScheduler();

    debugPrint('[ReminderPlugin] 插件初始化完成');
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 启动调度器
    _scheduler.start();
    debugPrint('[ReminderPlugin] 调度器已启动');
  }

  @override
  Widget buildMainView(BuildContext context) {
    return const ReminderListScreen();
  }

  @override
  String? getPluginName(context) {
    return '定时提醒';
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final enabledCount = _service.getEnabledReminders().length;
    final totalCount = _service.reminders.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                '定时提醒',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '启用提醒',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '$enabledCount/$totalCount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  /// 获取提醒服务
  ReminderService get service => _service;

  /// 获取调度器
  ReminderScheduler get scheduler => _scheduler;
}
