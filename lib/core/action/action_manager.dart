/// 动作管理器
/// 单例模式，管理所有动作的注册、验证和执行
library;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Memento/core/floating_ball/models/floating_ball_gesture.dart';
import 'models/action_definition.dart';
import 'models/action_instance.dart';
import 'models/action_group.dart';
import 'action_executor.dart';
import 'package:Memento/core/app_initializer.dart';

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
    _registerDefaultCustomActions();
    await _loadConfig();

    _initialized = true;
  }

  /// 注册默认的自定义动作
  void _registerDefaultCustomActions() {
    // 注册一个默认的JavaScript执行动作（无预设代码）
    registerJavaScriptAction(
      id: 'js_custom_executor',
      title: '自定义执行JavaScript代码',
      description: '允许用户输入并执行自定义的JavaScript代码',
      script: '', // 空脚本，用户可以修改
      icon: Icons.code,
    );
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

    // 询问当前上下文
    registerAction(
      ActionDefinition(
        id: BuiltInActions.askContext,
        title: '询问当前上下文',
        description: '基于当前页面信息向AI提问',
        icon: Icons.chat,
        category: ActionCategory.system,
        executor: BuiltInActionExecutor(BuiltInActions.askContext),
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

  // === 自定义动作注册方法 ===

  /// 注册JavaScript动作
  void registerJavaScriptAction({
    required String id,
    required String title,
    required String script,
    String? description,
    IconData? icon,
  }) {
    final action = ActionDefinition(
      id: id,
      title: title,
      description: description,
      icon: icon ?? Icons.code,
      category: ActionCategory.custom,
      executor: CustomActionExecutor(
        script: script,
        scriptType: 'javascript',
        actionId: id,
      ),
      isBuiltIn: false,
    );
    registerAction(action);
  }

  /// 注册Dart动作
  void registerDartAction({
    required String id,
    required String title,
    required String script,
    String? description,
    IconData? icon,
  }) {
    final action = ActionDefinition(
      id: id,
      title: title,
      description: description,
      icon: icon ?? Icons.code_off,
      category: ActionCategory.custom,
      executor: CustomActionExecutor(script: script, scriptType: 'dart'),
      isBuiltIn: false,
    );
    registerAction(action);
  }

  /// 注册表达式动作
  void registerExpressionAction({
    required String id,
    required String title,
    required String expression,
    String? description,
    IconData? icon,
  }) {
    final action = ActionDefinition(
      id: id,
      title: title,
      description: description,
      icon: icon ?? Icons.calculate,
      category: ActionCategory.custom,
      executor: CustomActionExecutor(script: expression, scriptType: 'expression'),
      isBuiltIn: false,
    );
    registerAction(action);
  }

  /// 创建并注册临时JavaScript动作
  Future<ExecutionResult> executeJavaScript(
    BuildContext context,
    String script, {
    Map<String, dynamic>? data,
    String? actionId,
  }) async {
    final executor = CustomActionExecutor(
      script: script,
      scriptType: 'javascript',
      actionId: actionId,
    );
    return await executor.execute(context, data);
  }

  /// 创建并注册临时Dart动作
  Future<ExecutionResult> executeDart(
    BuildContext context,
    String script, {
    Map<String, dynamic>? data,
  }) async {
    final executor = CustomActionExecutor(script: script, scriptType: 'dart');
    return await executor.execute(context, data);
  }

  /// 创建并注册临时表达式动作
  Future<ExecutionResult> executeExpression(
    BuildContext context,
    String expression, {
    Map<String, dynamic>? data,
  }) async {
    final executor = CustomActionExecutor(script: expression, scriptType: 'expression');
    return await executor.execute(context, data);
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
    try {
      final config = {
        'version': '1.0',
        'saveTime': DateTime.now().toIso8601String(),
        'actions': _actions.values.map((a) => a.toJson()).toList(),
        'customActions': _customActions.values.map((a) => a.toJson()).toList(),
        'actionGroups': _actionGroups.values.map((g) => g.toJson()).toList(),
        'gestureActions': _gestureActions.map(
          (k, v) => MapEntry(k.name, v.toJson()),
        ),
        'statistics': getStatistics(),
      };

      await globalStorage.write('floating_ball_config_v1', config);
    } catch (e) {
      print('Error saving action config: $e');
      rethrow;
    }
  }

  /// 从文件加载配置
  Future<void> _loadConfig() async {
    try {
      // 加载手势动作配置
      final gestureActionsData = await globalStorage.read('floating_ball_gesture_actions');
      if (gestureActionsData != null && gestureActionsData is Map) {
        _gestureActions.clear();
        for (final entry in gestureActionsData.entries) {
          final gestureName = entry.key as String;
          final configData = entry.value as Map<String, dynamic>;

          final gesture = FloatingBallGesture.values.firstWhere(
            (g) => g.name == gestureName,
            orElse: () => throw Exception('Unknown gesture: $gestureName'),
          );

          _gestureActions[gesture] = GestureActionConfig.fromJson(configData);
        }
      }

      // 加载动作组配置
      final groupsData = await globalStorage.read('floating_ball_action_groups');
      if (groupsData != null && groupsData is Map) {
        _actionGroups.clear();
        for (final entry in groupsData.entries) {
          final groupId = entry.key as String;
          final groupData = entry.value as Map<String, dynamic>;
          _actionGroups[groupId] = ActionGroup.fromJson(groupData);
        }
      }
    } catch (e) {
      print('Error loading gesture actions: $e');
    }
  }

  /// 保存手势动作配置
  Future<void> _saveGestureActions() async {
    try {
      final gestureActionsData = <String, Map<String, dynamic>>{};

      for (final entry in _gestureActions.entries) {
        gestureActionsData[entry.key.name] = entry.value.toJson();
      }

      await globalStorage.write('floating_ball_gesture_actions', gestureActionsData);
    } catch (e) {
      print('Error saving gesture actions: $e');
    }
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
  Future<void> saveActionGroup(ActionGroup group) async {
    if (group.id == null) {
      throw ArgumentError('Action group must have an ID');
    }
    _actionGroups[group.id!] = group;
    await _saveActionGroups();
  }

  /// 获取动作组
  ActionGroup? getActionGroup(String id) => _actionGroups[id];

  /// 删除动作组
  Future<void> deleteActionGroup(String id) async {
    _actionGroups.remove(id);
    await _saveActionGroups();
  }

  /// 保存动作组到存储
  Future<void> _saveActionGroups() async {
    try {
      final groupsData = <String, Map<String, dynamic>>{};
      for (final entry in _actionGroups.entries) {
        groupsData[entry.key] = entry.value.toJson();
      }
      await globalStorage.write('floating_ball_action_groups', groupsData);
    } catch (e) {
      print('Error saving action groups: $e');
    }
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
    try {
      final configData = jsonDecode(jsonString) as Map<String, dynamic>;

      final version = configData['version'] as String?;
      if (version == null) {
        throw ArgumentError('Invalid config: missing version');
      }

      // 导入动作
      if (configData['actions'] != null) {
        final actions = configData['actions'] as List;
        for (final actionJson in actions) {
          final action = ActionDefinition.fromJson(
            actionJson as Map<String, dynamic>,
          );
          _actions[action.id] = action;
        }
      }

      // 导入自定义动作实例
      if (configData['customActions'] != null) {
        final customActions = configData['customActions'] as List;
        for (final actionJson in customActions) {
          final action = ActionInstance.fromJson(
            actionJson as Map<String, dynamic>,
          );
          _customActions[action.id!] = action;
        }
      }

      // 导入动作组
      if (configData['actionGroups'] != null) {
        final groups = configData['actionGroups'] as List;
        for (final groupJson in groups) {
          final group = ActionGroup.fromJson(
            groupJson as Map<String, dynamic>,
          );
          if (group.id != null) {
            _actionGroups[group.id!] = group;
          }
        }
      }

      // 导入手势动作
      if (configData['gestureActions'] != null) {
        final gestureActions = configData['gestureActions'] as Map;
        for (final entry in gestureActions.entries) {
          final gestureName = entry.key as String;
          final configMap = entry.value as Map<String, dynamic>;

          final gesture = FloatingBallGesture.values.firstWhere(
            (g) => g.name == gestureName,
            orElse: () => throw Exception('Unknown gesture: $gestureName'),
          );

          _gestureActions[gesture] = GestureActionConfig.fromJson(configMap);
        }
      }

      await _saveGestureActions();
      await _saveActionGroups();
    } catch (e) {
      print('Error importing action config: $e');
      rethrow;
    }
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
