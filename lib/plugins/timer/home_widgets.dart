import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'timer_plugin.dart';
import 'models/timer_task.dart';
import 'models/timer_item.dart';

/// 实时计时显示小组件
class _TimerDisplayWidget extends StatefulWidget {
  final String taskId;
  final Color taskColor;

  const _TimerDisplayWidget({required this.taskId, required this.taskColor});

  @override
  State<_TimerDisplayWidget> createState() => _TimerDisplayWidgetState();
}

class _TimerDisplayWidgetState extends State<_TimerDisplayWidget> {
  Duration _displayedDuration = Duration.zero;
  int _targetDuration = 0;
  int _type = 0; // 0: 正计时, 1: 倒计时, 2: 番茄钟

  TimerTask? _currentTask;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    _subscribeToEvents();
  }

  @override
  void dispose() {
    _unsubscribeFromEvents();
    super.dispose();
  }

  void _loadTaskData() {
    try {
      final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (plugin == null) return;

      final tasks = plugin.getTasks();
      _currentTask = tasks.firstWhere((task) => task.id == widget.taskId);

      if (_currentTask!.timerItems.isNotEmpty) {
        final firstTimer = _currentTask!.timerItems.first;
        _type = firstTimer.type.index;
        _targetDuration = firstTimer.duration.inSeconds;
        _displayedDuration = firstTimer.completedDuration;
      }
    } catch (e) {
      // 任务不存在，不更新
    }
  }

  void _subscribeToEvents() {
    EventManager.instance.subscribe('timer_item_progress', _onTimerProgress);
    EventManager.instance.subscribe('timer_task_changed', _onTaskChanged);
  }

  void _unsubscribeFromEvents() {
    EventManager.instance.unsubscribe('timer_item_progress', _onTimerProgress);
    EventManager.instance.unsubscribe('timer_task_changed', _onTaskChanged);
  }

  void _onTaskChanged(EventArgs args) {
    if (args is TimerTaskEventArgs && args.task.id == widget.taskId) {
      _currentTask = args.task;
      if (args.task.timerItems.isNotEmpty) {
        final firstTimer = args.task.timerItems.first;
        _type = firstTimer.type.index;
        _targetDuration = firstTimer.duration.inSeconds;
        _displayedDuration = firstTimer.completedDuration;
      }
      if (mounted) setState(() {});
    }
  }

  void _onTimerProgress(EventArgs args) {
    if (args is TimerItemEventArgs) {
      // 检查是否是当前任务的计时器
      if (_currentTask != null) {
        final timerItems = _currentTask!.timerItems;
        if (timerItems.any((item) => item.id == args.timer.id)) {
          _displayedDuration = args.timer.completedDuration;
          if (mounted) setState(() {});
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String displayText;

    if (_type == 1) {
      // 倒计时
      final remaining = Duration(seconds: _targetDuration) - _displayedDuration;
      if (remaining.isNegative) {
        displayText = '-${_formatDuration(remaining.abs())}';
      } else {
        displayText = _formatDuration(remaining);
      }
    } else {
      // 正计时和番茄钟
      displayText = _formatDuration(_displayedDuration);
    }

    return Text(
      displayText,
      style: theme.textTheme.displayMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: widget.taskColor,
        fontFamily: 'monospace',
      ),
    );
  }
}

/// 计时器插件的主页小组件注册
class TimerHomeWidgets {
  /// 注册所有计时器插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'timer_icon',
        pluginId: 'timer',
        name: 'timer_widgetName'.tr,
        description: 'timer_widgetDescription'.tr,
        icon: Icons.timer,
        color: Colors.blueGrey,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.timer,
              color: Colors.blueGrey,
              name: 'timer_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'timer_overview',
        pluginId: 'timer',
        name: 'timer_overviewName'.tr,
        description: 'timer_overviewDescription'.tr,
        icon: Icons.timer_outlined,
        color: Colors.blueGrey,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 计时器选择器小组件 - 快速访问指定计时器详情
    registry.register(
      HomeWidget(
        id: 'timer_task_selector',
        pluginId: 'timer',
        name: 'timer_quickAccess'.tr,
        description: 'timer_quickAccessDesc'.tr,
        icon: Icons.timer,
        color: Colors.blueGrey,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        selectorId: 'timer.task',
        dataRenderer: _renderTimerData,
        navigationHandler: _navigateToTimerDetail,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('timer_task_selector')!,
              config: config,
            ),
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (plugin == null) return [];

      final tasks = plugin.getTasks();
      final totalCount = tasks.length;
      final runningCount = tasks.where((task) => task.isRunning).length;

      return [
        StatItemData(
          id: 'total_count',
          label: 'timer_totalTimer'.tr,
          value: '$totalCount',
          highlight: false,
        ),
        StatItemData(
          id: 'running_count',
          label: 'timer_running'.tr,
          value: '$runningCount',
          highlight: runningCount > 0,
          color: Colors.blueGrey,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'timer',
        pluginName: 'timer_name'.tr,
        pluginIcon: Icons.timer,
        pluginDefaultColor: Colors.blueGrey,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 计时器选择器小组件相关方法 =====

  /// 从 SelectorResult 获取任务数据 Map（单选时取第一个）
  static Map<String, dynamic>? _getTaskData(SelectorResult result) {
    if (result.data == null) return null;
    // result.data 是 List，取第一个元素
    if (result.data is List && result.data.isNotEmpty) {
      return result.data.first as Map<String, dynamic>;
    }
    if (result.data is Map<String, dynamic>) {
      return result.data as Map<String, dynamic>;
    }
    return null;
  }

  /// 渲染计时器数据
  static Widget _renderTimerData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);
    final taskData = _getTaskData(result);

    if (taskData == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    final colorValue = taskData['color'] as int? ?? 4284513675;
    final taskColor = Color(colorValue);
    final taskId = taskData['id'] as String?;

    // 获取计时器信息
    final timerItems = taskData['timerItems'] as List? ?? [];
    String timerType = '';
    if (timerItems.isNotEmpty) {
      final firstTimer = timerItems.first;
      final type = firstTimer['type'] as int? ?? 0;
      final duration = firstTimer['duration'] as int? ?? 0;

      switch (type) {
        case 0: // 正计时
          timerType = '正计时';
          break;
        case 1: // 倒计时
          timerType = '倒计时 ${duration}s';
          break;
        case 2: // 番茄钟
          timerType = '番茄钟';
          break;
      }
    }

    return SizedBox.expand(
      child: GestureDetector(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Icon(
              taskData['icon'] != null
                  ? IconData(
                    taskData['icon'] as int,
                    fontFamily: 'MaterialIcons',
                  )
                  : Icons.timer,
              size: 32,
              color: taskColor,
            ),
            const SizedBox(height: 8),
            // 计时器名称
            Text(
              taskData['name'] as String? ?? '未知计时器',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 计时类型 badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: taskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                timerType,
                style: theme.textTheme.labelSmall?.copyWith(color: taskColor),
              ),
            ),
            const SizedBox(height: 8),
            // 计时显示 (00:00) - 实时更新
            _TimerDisplayWidget(taskId: taskId ?? '', taskColor: taskColor),
          ],
        ),
      ),
    );
  }

  /// 导航到计时器详情页面
  static void _navigateToTimerDetail(
    BuildContext context,
    SelectorResult result,
  ) {
    final taskData = _getTaskData(result);
    final taskId = taskData?['id'] as String?;
    if (taskId == null) return;

    NavigationHelper.pushNamed(
      context,
      '/timer_details',
      arguments: {'taskId': taskId},
    );
  }
}
