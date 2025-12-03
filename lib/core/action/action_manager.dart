/// 动作管理器
/// 单例模式，管理所有动作的注册、验证和执行
library action_manager;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../floating_ball/models/floating_ball_gesture.dart';
import 'models/action_definition.dart';
import 'models/action_instance.dart';
import 'models/action_group.dart';
import 'action_executor.dart';

/// 动作管理器单例
class ActionManager {
  static final ActionManager _instance = ActionManager._internal();
  factory ActionManager() => _instance;
  ActionManager._internal();

  // 私有字段
  final Map<String, ActionDefinition> _actions = {};
  final Map<String, ActionInstance> _customActions = {};
  final Map<String, ActionGroup> _actionGroups = {};
  final Map<FloatingBallGesture, GestureActionConfig> _gestureActions = {};
  final StreamController<ActionExecutionEvent> _eventController =
      StreamController<ActionExecutionEvent>.broadcast();

  // 初始化标志
  bool _initialized = false;

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  /// 事件流
  Stream<ActionExecutionEvent> get events => _eventController.stream;

  /// 获取所有已注册的动作
  List<ActionDefinition> get allActions => _actions.values.toList();

  /// 获取所有自定义动作实例
  List<ActionInstance> get customActions => _customActions.values.toList();

  /// 获取所有动作组
  List<ActionGroup> get actionGroups => _actionGroups.values.toList();

  /// 初始化管理器
  Future<void> initialize() async {
    if (_initialized) return;

    _registerBuiltInActions();
    await _loadConfig();

    _initialized = true;
  }

  /// 注册内置动作
  void _registerBuiltInActions() {
    // 打开插件
    registerAction(
      ActionDefinition(
        id: BuiltInActions.openPlugin,
        title: '打开插件',
        description: '打开指定的插件',
        icon: Icons.extension,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.openPlugin),
        isBuiltIn: true,
      ),
    );

    // 返回上一页
    registerAction(
      ActionDefinition(
        id: BuiltInActions.goBack,
        title: '返回上一页',
        description: '返回到上一个页面',
        icon: Icons.arrow_back,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.goBack),
        isBuiltIn: true,
      ),
    );

    // 返回首页
    registerAction(
      ActionDefinition(
        id: BuiltInActions.goHome,
        title: '返回首页',
        description: '返回到应用首页',
        icon: Icons.home,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.goHome),
        isBuiltIn: true,
      ),
    );

    // 打开设置
    registerAction(
      ActionDefinition(
        id: BuiltInActions.openSettings,
        title: '打开设置',
        description: '打开应用设置页面',
        icon: Icons.settings,
        category: ActionCategory.system,
        executor: BuiltInActionExecutor(BuiltInActions.openSettings),
        isBuiltIn: true,
      ),
    );

    // 刷新
    registerAction(
      ActionDefinition(
        id: BuiltInActions.refresh,
        title: '刷新页面',
        description: '刷新当前页面内容',
        icon: Icons.refresh,
        category: ActionCategory.system,
        executor: BuiltInActionExecutor(BuiltInActions.refresh),
        isBuiltIn: true,
      ),
    );

    // 显示路由历史
    registerAction(
      ActionDefinition(
        id: BuiltInActions.showRouteHistory,
        title: '路由历史记录',
        description: '查看页面访问历史',
        icon: Icons.history,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.showRouteHistory),
        isBuiltIn: true,
      ),
    );

    // 重新打开上个路由
    registerAction(
      ActionDefinition(
        id: BuiltInActions.reopenLastRoute,
        title: '打开上个路由',
        description: '重新打开上一个访问的页面',
        icon: Icons.redo,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.reopenLastRoute),
        isBuiltIn: true,
      ),
    );

    // 打开上次插件
    registerAction(
      ActionDefinition(
        id: BuiltInActions.openLastPlugin,
        title: '打开上次插件',
        description: '打开最近使用的插件（排除当前插件）',
        icon: Icons.history,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.openLastPlugin),
        isBuiltIn: true,
      ),
    );

    // 选择插件
    registerAction(
      ActionDefinition(
        id: BuiltInActions.selectPlugin,
        title: '选择打开插件',
        description: '显示插件选择对话框',
        icon: Icons.open_in_new,
        category: ActionCategory.navigation,
        executor: BuiltInActionExecutor(BuiltInActions.selectPlugin),
        isBuiltIn: true,
      ),
    );
  }

  /// 注册动作
  void registerAction(ActionDefinition action) {
    _actions[action.id] = action;
  }

  /// 批量注册动作
  void registerActions(List<ActionDefinition> actions) {
    for (final action in actions) {
      registerAction(action);
    }
  }

  /// 注销动作
  void unregisterAction(String actionId) {
    _actions.remove(actionId);
  }

  /// 获取动作定义
  ActionDefinition? getAction(String actionId) => _actions[actionId];

  /// 检查动作是否存在
  bool hasAction(String actionId) => _actions.containsKey(actionId);

  /// 获取所有内置动作
  List<ActionDefinition> getBuiltInActions() {
    return _actions.values.where((a) => a.isBuiltIn).toList();
  }

  /// 获取所有自定义动作
  List<ActionDefinition> getCustomActions() {
    return _actions.values.where((a) => !a.isBuiltIn).toList();
  }

  /// 按分类获取动作
  List<ActionDefinition> getActionsByCategory(ActionCategory category) {
    return _actions.values
        .where((action) => action.category == category)
        .toList();
  }

  /// 执行动作
  Future<ExecutionResult> execute(
    String actionId,
    BuildContext context, {
    Map<String, dynamic>? data,
  }) async {
    // 发送开始事件
    _eventController.add(
      ActionExecutionEvent(
        type: ExecutionEventType.started,
        actionId: actionId,
        data: data,
      ),
    );

    final definition = getAction(actionId);
    if (definition == null) {
      final result = ExecutionResult.failure(
        error: 'Action not found: $actionId',
      );

      // 发送失败事件
      _eventController.add(
        ActionExecutionEvent(
          type: ExecutionEventType.failed,
          actionId: actionId,
          data: data,
          result: result,
        ),
      );

      return result;
    }

    // 执行动作
    final result = await definition.executor.execute(context, data);

    // 发送完成事件
    _eventController.add(
      ActionExecutionEvent(
        type:
            result.success
                ? ExecutionEventType.completed
                : ExecutionEventType.failed,
        actionId: actionId,
        data: data,
        result: result,
      ),
    );

    return result;
  }

  /// 执行动作组
  Future<ExecutionResult> executeGroup(
    String groupId,
    BuildContext context, {
    Map<String, dynamic>? data,
  }) async {
    final group = _actionGroups[groupId];
    if (group == null) {
      return ExecutionResult.failure(error: 'Action group not found: $groupId');
    }

    // 发送开始事件
    _eventController.add(
      ActionExecutionEvent(
        type: ExecutionEventType.groupStarted,
        actionId: groupId,
        data: data,
      ),
    );

    final executor = GroupActionExecutor(group);
    final result = await executor.execute(context, data);

    // 发送完成事件
    _eventController.add(
      ActionExecutionEvent(
        type:
            result.success
                ? ExecutionEventType.groupCompleted
                : ExecutionEventType.groupFailed,
        actionId: groupId,
        data: data,
        result: result,
      ),
    );

    return result;
  }

  /// 验证动作
  bool validateAction(String actionId, Map<String, dynamic> data) {
    final definition = getAction(actionId);
    if (definition == null) return false;

    final errors = definition.validate(data);
    return errors.isEmpty;
  }

  /// 获取验证错误
  List<String> getValidationErrors(String actionId, Map<String, dynamic> data) {
    final definition = getAction(actionId);
    if (definition == null) return ['Action not found: $actionId'];

    return definition.validate(data);
  }

  // === 手势动作管理 ===

  /// 设置手势动作
  Future<void> setGestureAction(
    FloatingBallGesture gesture,
    GestureActionConfig config,
  ) async {
    _gestureActions[gesture] = config;
    await _saveGestureActions();
  }

  /// 获取手势动作
  GestureActionConfig? getGestureAction(FloatingBallGesture gesture) {
    return _gestureActions[gesture];
  }

  /// 清除手势动作
  Future<void> clearGestureAction(FloatingBallGesture gesture) async {
    _gestureActions.remove(gesture);
    await _saveGestureActions();
  }

  /// 获取所有手势动作
  Map<FloatingBallGesture, GestureActionConfig> get allGestureActions {
    return Map.from(_gestureActions);
  }

  /// 执行手势动作
  Future<ExecutionResult> executeGestureAction(
    FloatingBallGesture gesture,
    BuildContext context, {
    Map<String, dynamic>? data,
  }) async {
    final config = getGestureAction(gesture);
    if (config == null || config.isEmpty) {
      return ExecutionResult.failure(
        error: 'No action configured for gesture: ${gesture.name}',
      );
    }

    // 发送手势事件
    _eventController.add(
      ActionExecutionEvent(
        type: ExecutionEventType.gestureStarted,
        actionId: 'gesture_${gesture.name}',
        data: data,
      ),
    );

    ExecutionResult? result;

    if (config.group != null) {
      result = await executeGroup(config.group!.id!, context, data: data);
    } else if (config.singleAction != null) {
      result = await execute(
        config.singleAction!.actionId,
        context,
        data: {...?data, ...config.singleAction!.data},
      );
    }

    result ??= ExecutionResult.failure(
      error: 'Invalid gesture action configuration',
    );

    // 发送完成事件
    _eventController.add(
      ActionExecutionEvent(
        type: ExecutionEventType.gestureCompleted,
        actionId: 'gesture_${gesture.name}',
        data: data,
        result: result,
      ),
    );

    return result;
  }

  // === 配置存储 ===

  /// 保存配置到文件
  Future<void> saveConfig() async {
    // TODO: 实现保存到 storage/floating_ball_config_v1.json
    // 使用 storage_manager.write()
  }

  /// 从文件加载配置
  Future<void> _loadConfig() async {
    // TODO: 实现从 storage/floating_ball_config_v1.json 加载
    // 使用 storage_manager.read()
  }

  /// 保存手势动作配置
  Future<void> _saveGestureActions() async {
    // TODO: 实现保存到 storage
  }

  // === 自定义动作实例管理 ===

  /// 保存自定义动作实例
  void saveCustomAction(ActionInstance instance) {
    if (instance.id == null) {
      throw ArgumentError('Action instance must have an ID');
    }
    _customActions[instance.id!] = instance;
  }

  /// 获取自定义动作实例
  ActionInstance? getCustomAction(String id) => _customActions[id];

  /// 删除自定义动作实例
  void deleteCustomAction(String id) {
    _customActions.remove(id);
  }

  // === 动作组管理 ===

  /// 保存动作组
  void saveActionGroup(ActionGroup group) {
    if (group.id == null) {
      throw ArgumentError('Action group must have an ID');
    }
    _actionGroups[group.id!] = group;
  }

  /// 获取动作组
  ActionGroup? getActionGroup(String id) => _actionGroups[id];

  /// 删除动作组
  void deleteActionGroup(String id) {
    _actionGroups.remove(id);
  }

  // === 资源清理 ===

  /// 销毁管理器
  void dispose() {
    _eventController.close();
    _actions.clear();
    _customActions.clear();
    _actionGroups.clear();
    _gestureActions.clear();
  }

  // === 调试和日志 ===

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'totalActions': _actions.length,
      'builtInActions': _actions.values.where((a) => a.isBuiltIn).length,
      'customActions': _actions.values.where((a) => !a.isBuiltIn).length,
      'actionGroups': _actionGroups.length,
      'customActionInstances': _customActions.length,
      'gestureActions': _gestureActions.length,
    };
  }

  /// 导出配置
  String exportConfig() {
    final config = {
      'version': '1.0',
      'exportTime': DateTime.now().toIso8601String(),
      'actions': _actions.values.map((a) => a.toJson()).toList(),
      'customActions': _customActions.values.map((a) => a.toJson()).toList(),
      'actionGroups': _actionGroups.values.map((g) => g.toJson()).toList(),
      'gestureActions': _gestureActions.map(
        (k, v) => MapEntry(k.name, v.toJson()),
      ),
      'statistics': getStatistics(),
    };

    return JsonEncoder.withIndent('  ').convert(config);
  }

  /// 导入配置
  Future<void> importConfig(String jsonString) async {
    // TODO: 实现配置导入
  }
}

/// 动作执行事件
class ActionExecutionEvent {
  final ExecutionEventType type;
  final String actionId;
  final Map<String, dynamic>? data;
  final ExecutionResult? result;
  final DateTime timestamp;

  ActionExecutionEvent({
    required this.type,
    required this.actionId,
    this.data,
    this.result,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 执行事件类型
enum ExecutionEventType {
  started,
  completed,
  failed,
  groupStarted,
  groupCompleted,
  groupFailed,
  gestureStarted,
  gestureCompleted,
  gestureFailed,
}
