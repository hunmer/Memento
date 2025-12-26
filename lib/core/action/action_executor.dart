/// 动作执行引擎
/// 负责执行各种动作类型的逻辑
library;
import 'dart:async';
import 'dart:convert';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/event/plugin_action_event_args.dart';
import 'package:get/get.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/dialogs/plugin_list_dialog.dart';
import 'package:Memento/widgets/route_history_dialog/route_history_dialog.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/theme_controller.dart';
import 'action_manager.dart';
import 'models/action_definition.dart';
import 'models/action_group.dart';
import 'built_in/ask_context_action/route_parser.dart';
import 'built_in/ask_context_action/widgets/context_query_drawer.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/route_viewer_dialog.dart';

/// 执行结果
class ExecutionResult {
  /// 是否成功
  final bool success;

  /// 执行时间（毫秒）
  final int executionTimeMs;

  /// 结果数据
  final Map<String, dynamic>? data;

  /// 错误信息（失败时）
  final String? error;

  /// 错误堆栈（失败时）
  final String? stackTrace;

  const ExecutionResult({
    required this.success,
    required this.executionTimeMs,
    this.data,
    this.error,
    this.stackTrace,
  });

  factory ExecutionResult.success({
    int? executionTimeMs,
    Map<String, dynamic>? data,
  }) {
    return ExecutionResult(
      success: true,
      executionTimeMs: executionTimeMs ?? 0,
      data: data,
    );
  }

  factory ExecutionResult.failure({
    required String error,
    String? stackTrace,
    int? executionTimeMs,
  }) {
    return ExecutionResult(
      success: false,
      executionTimeMs: executionTimeMs ?? 0,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'executionTimeMs': executionTimeMs,
      'data': data,
      'error': error,
      'stackTrace': stackTrace,
    };
  }
}

/// 动作执行器抽象基类
abstract class ActionExecutor {
  /// 执行动作
  /// [context] BuildContext，用于导航和UI操作
  /// [data] 执行数据，包含动作所需的参数
  /// 返回执行结果
  Future<ExecutionResult> execute(
    BuildContext context,
    Map<String, dynamic>? data,
  );
}

/// 内置动作执行器
/// 处理系统内置的各种动作
class BuiltInActionExecutor implements ActionExecutor {
  final String actionId;

  const BuiltInActionExecutor(this.actionId);

  @override
  Future<ExecutionResult> execute(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      switch (actionId) {
        case BuiltInActions.openPlugin:
          return await _executeOpenPlugin(context, data);

        case BuiltInActions.goBack:
          return await _executeGoBack(context, data);

        case BuiltInActions.goHome:
          return await _executeGoHome(context, data);

        case BuiltInActions.openSettings:
          return await _executeOpenSettings(context, data);

        case BuiltInActions.refresh:
          return await _executeRefresh(context, data);

        case BuiltInActions.showRouteHistory:
          return await _executeShowRouteHistory(context, data);

        case BuiltInActions.reopenLastRoute:
          return await _executeReopenLastRoute(context, data);

        case BuiltInActions.openLastPlugin:
          return await _executeOpenLastPlugin(context, data);

        case BuiltInActions.selectPlugin:
          return await _executeSelectPlugin(context, data);

        case BuiltInActions.routeViewer:
          return await _executeRouteViewer(context, data);

        case BuiltInActions.askContext:
          return await _executeAskContext(context, data);

        case BuiltInActions.toggleTheme:
          return await _executeToggleTheme(context, data);

        default:
          return ExecutionResult.failure(
            error: 'Unknown action: $actionId',
            executionTimeMs: stopwatch.elapsedMilliseconds,
          );
      }
    } catch (e, stack) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 执行打开插件
  Future<ExecutionResult> _executeOpenPlugin(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    final pluginId = data?['plugin'] as String? ?? 'home';

    final plugin = globalPluginManager.getPlugin(pluginId);
    if (plugin == null) {
      return ExecutionResult.failure(error: 'Plugin not found: $pluginId');
    }

    globalPluginManager.openPlugin(context, plugin);

    return ExecutionResult.success(data: {'pluginId': pluginId});
  }

  /// 执行返回上一页
  Future<ExecutionResult> _executeGoBack(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (Navigator.canPop(context)) {
      Navigator.maybePop(context);
      return ExecutionResult.success(data: {'action': 'goBack'});
    }

    return ExecutionResult.failure(error: 'Cannot go back, no previous route');
  }

  /// 执行返回首页
  Future<ExecutionResult> _executeGoHome(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    return ExecutionResult.success(data: {'action': 'goHome'});
  }

  /// 执行打开设置
  Future<ExecutionResult> _executeOpenSettings(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    // 导航到设置页面
    NavigationHelper.push(context, const SettingsScreen(),
    );

    return ExecutionResult.success(data: {'action': 'openSettings'});
  }

  /// 执行刷新
  Future<ExecutionResult> _executeRefresh(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    // 触发刷新事件
    eventManager.broadcast('refresh', EventArgs());

    return ExecutionResult.success(data: {'action': 'refresh'});
  }

  /// 执行显示路由历史
  Future<ExecutionResult> _executeShowRouteHistory(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    showDialog(
      context: context,
      builder: (context) => const RouteHistoryDialog(),
    );

    return ExecutionResult.success(data: {'action': 'showRouteHistory'});
  }

  /// 执行重新打开上个路由
  Future<ExecutionResult> _executeReopenLastRoute(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    final lastPage = RouteHistoryManager.getLastVisitedPage();

    if (lastPage == null) {
      Toast.show('没有历史记录');
      return ExecutionResult.success(
        data: {'action': 'reopenLastRoute', 'message': 'No history'},
      );
    }

    // 记录访问历史
    RouteHistoryManager.recordPageVisit(
      pageId: lastPage.pageId,
      title: lastPage.title,
      icon: lastPage.icon,
    );

    // 根据页面ID导航到对应页面
    bool navigated = false;

    // 如果是插件页面，则打开插件
    if (lastPage.pageId.startsWith('plugin:')) {
      final pluginId = lastPage.pageId.substring(7); // 移除 'plugin:' 前缀
      final plugin = globalPluginManager.getPlugin(pluginId);
      if (plugin != null) {
        globalPluginManager.openPlugin(context, plugin);
        navigated = true;
      }
    }
    // 如果是设置页面
    else if (lastPage.pageId == 'settings') {
      NavigationHelper.push(context, const SettingsScreen(),
      );
      navigated = true;
    }
    // 如果是路由历史页面
    else if (lastPage.pageId == 'route_history') {
      showDialog(
        context: context,
        builder: (context) => const RouteHistoryDialog(),
      );
      navigated = true;
    }
    // 其他页面类型可以在这里扩展

    if (!navigated) {
      Toast.error('无法打开页面: ${lastPage.pageId}');
    }

    return ExecutionResult.success(
      data: {
        'action': 'reopenLastRoute',
        'pageId': lastPage.pageId,
        'navigated': navigated,
      },
    );
  }

  /// 执行打开上次插件
  Future<ExecutionResult> _executeOpenLastPlugin(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    final currentPluginId = globalPluginManager.getCurrentPluginId();
    if (currentPluginId == null) {
      return ExecutionResult.failure(error: 'No current plugin');
    }

    final lastPlugin = globalPluginManager.getLastOpenedPlugin(
      excludePluginId: currentPluginId,
    );

    if (lastPlugin == null) {
      if (context.mounted) {
        Toast.show('floating_ball_noRecentPlugin'.tr);
      }
      return ExecutionResult.success(
        data: {'action': 'openLastPlugin', 'message': 'No recent plugin'},
      );
    }

    globalPluginManager.openPlugin(context, lastPlugin);

    return ExecutionResult.success(
      data: {'action': 'openLastPlugin', 'pluginId': lastPlugin.id},
    );
  }

  /// 执行选择插件
  Future<ExecutionResult> _executeSelectPlugin(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    showPluginListDialog(context);

    return ExecutionResult.success(data: {'action': 'selectPlugin'});
  }

  /// 执行路由查看器
  Future<ExecutionResult> _executeRouteViewer(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    RouteViewerDialog.show(context);

    return ExecutionResult.success(data: {'action': 'routeViewer'});
  }

  /// 执行询问当前上下文
  Future<ExecutionResult> _executeAskContext(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    try {
      // 解析当前路由
      final routeContext = RouteParser.parseRoute(context);

      // 显示上下文查询抽屉
      await SmoothBottomSheet.show(
        context: context,
        isScrollControlled: true,
        builder: (context) => ContextQueryDrawer(
          routeContext: routeContext,
        ),
      );

      return ExecutionResult.success(
        data: {
          'action': 'askContext',
          'route': routeContext.routeName,
        },
      );
    } catch (e, stack) {
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
      );
    }
  }

  /// 执行切换主题
  Future<ExecutionResult> _executeToggleTheme(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (!context.mounted) {
      return ExecutionResult.failure(error: 'Context not mounted');
    }

    ThemeController.toggleTheme(context);

    return ExecutionResult.success(data: {'action': 'toggleTheme'});
  }
}

/// 插件动作执行器
/// 处理插件特定的动作
class PluginActionExecutor implements ActionExecutor {
  final String pluginId;
  final String actionName;

  const PluginActionExecutor({
    required this.pluginId,
    required this.actionName,
  });

  @override
  Future<ExecutionResult> execute(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 检查插件是否存在
      final plugin = globalPluginManager.getPlugin(pluginId);
      if (plugin == null) {
        return ExecutionResult.failure(
          error: 'Plugin not found: $pluginId',
          executionTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 广播插件动作事件，让插件自行处理
      eventManager.broadcast(
        'plugin_action',
        PluginActionEventArgs(
          pluginId: pluginId,
          actionName: actionName,
          data: data,
        ),
      );

      return ExecutionResult.success(
        data: {
          'pluginId': pluginId,
          'actionName': actionName,
          'inputData': data,
        },
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}

/// 动作组执行器
/// 负责执行包含多个动作的动作组
class GroupActionExecutor implements ActionExecutor {
  final ActionGroup group;

  const GroupActionExecutor(this.group);

  @override
  Future<ExecutionResult> execute(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      switch (group.operator) {
        case GroupOperator.sequence:
          return await _executeSequence(context, data, stopwatch);

        case GroupOperator.parallel:
          return await _executeParallel(context, data, stopwatch);

        case GroupOperator.condition:
          return await _executeCondition(context, data, stopwatch);
      }
    } catch (e, stack) {
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 顺序执行
  Future<ExecutionResult> _executeSequence(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    final results = <String, ExecutionResult>{};

    for (final action in group.actions) {
      if (!action.enabled) continue;

      // 执行单个动作
      final mergedData = <String, dynamic>{}
        ..addAll(data ?? {})
        ..addAll(action.data);
      final result = await ActionManager().execute(
        action.actionId,
        context,
        data: mergedData,
      );

      results[action.actionId] = result;

      // 如果失败且配置为全部执行则中断
      if (group.executionMode == GroupExecutionMode.all) {
        if (!result.success) {
          stopwatch.stop();
          return ExecutionResult.failure(
            error: 'Action ${action.actionId} failed: ${result.error}',
            executionTimeMs: stopwatch.elapsedMilliseconds,
          );
        }
      }
    }

    stopwatch.stop();
    return ExecutionResult.success(
      data: {
        'groupId': group.id,
        'operator': 'sequence',
        'results': results,
        'inputData': data,
      },
      executionTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 并行执行
  Future<ExecutionResult> _executeParallel(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    final results = <String, ExecutionResult>{};
    final futures = <String, Future<ExecutionResult>>{};

    // 启动所有动作
    for (final action in group.actions) {
      if (!action.enabled) continue;

      final mergedData = <String, dynamic>{}
        ..addAll(data ?? {})
        ..addAll(action.data);
      futures[action.actionId] = ActionManager().execute(
        action.actionId,
        context,
        data: mergedData,
      );
    }

    // 等待所有动作完成
    if (futures.isNotEmpty) {
      final completedResults = await Future.wait(futures.values);
      int index = 0;
      for (final key in futures.keys) {
        results[key] = completedResults[index++];
      }
    }

    stopwatch.stop();
    return ExecutionResult.success(
      data: {
        'groupId': group.id,
        'operator': 'parallel',
        'results': results,
        'inputData': data,
      },
      executionTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 条件执行
  Future<ExecutionResult> _executeCondition(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    // 解析条件表达式并执行

    final condition = group.condition;
    if (condition == null || condition.isEmpty) {
      return ExecutionResult.failure(
        error: 'Condition is required for conditional execution',
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    // 临时实现：简单条件检查
    final conditionMet = _evaluateCondition(condition, data);

    if (!conditionMet) {
      stopwatch.stop();
      return ExecutionResult.success(
        data: {
          'groupId': group.id,
          'operator': 'condition',
          'condition': condition,
          'conditionMet': false,
          'message': 'Condition not met, skipping execution',
        },
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    // 条件满足，执行第一个动作
    if (group.actions.isNotEmpty && group.actions.first.enabled) {
      final mergedData = <String, dynamic>{}
        ..addAll(data ?? {})
        ..addAll(group.actions.first.data);
      final result = await ActionManager().execute(
        group.actions.first.actionId,
        context,
        data: mergedData,
      );

      stopwatch.stop();
      return ExecutionResult.success(
        data: {
          'groupId': group.id,
          'operator': 'condition',
          'condition': condition,
          'conditionMet': true,
          'result': result.toJson(),
        },
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    stopwatch.stop();
    return ExecutionResult.success(
      data: {
        'groupId': group.id,
        'operator': 'condition',
        'condition': condition,
        'conditionMet': true,
        'message': 'No actions to execute',
      },
      executionTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 简单条件求值
  bool _evaluateCondition(String condition, Map<String, dynamic>? data) {
    // 非常简单的条件求值实现
    // 实际项目中应该使用更强大的表达式求值库

    // 示例条件：
    // "plugin == 'chat'"
    // "time > '18:00'"
    // "day == 'Monday'"

    try {
      // 简单的键值比较
      if (condition.contains('==')) {
        final parts = condition.split('==');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim().replaceAll("'", "");
          final dataValue = data?[key]?.toString();
          return dataValue == value;
        }
      } else if (condition.contains('!=')) {
        final parts = condition.split('!=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim().replaceAll("'", "");
          final dataValue = data?[key]?.toString();
          return dataValue != value;
        }
      }

      // 默认返回 true（条件满足）
      return true;
    } catch (e) {
      // 如果条件解析失败，默认条件满足
      return true;
    }
  }
}

/// 自定义动作执行器
/// 用于执行用户自定义的脚本或代码
class CustomActionExecutor implements ActionExecutor {
  final String script;
  final String scriptType; // 'javascript', 'dart', 'expression' 等
  final String? actionId; // 可选的actionId，用于识别特定动作

  const CustomActionExecutor({
    required this.script,
    required this.scriptType,
    this.actionId,
  });

  @override
  Future<ExecutionResult> execute(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      switch (scriptType) {
        case 'javascript':
          return await _executeJavaScript(context, data, stopwatch);

        case 'dart':
          return await _executeDart(context, data, stopwatch);

        case 'expression':
          return await _executeExpression(context, data, stopwatch);

        default:
          return ExecutionResult.failure(
            error: 'Unsupported script type: $scriptType',
            executionTimeMs: stopwatch.elapsedMilliseconds,
          );
      }
    } catch (e, stack) {
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  Future<ExecutionResult> _executeJavaScript(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    // 获取脚本和输入数据
    String userScript = script;
    Map<String, dynamic>? inputData = data;

    // 如果是 js_custom_executor 且没有提供脚本，检查配置数据
    if (actionId == 'js_custom_executor') {
      // 从配置数据中获取脚本和输入数据
      if (data != null) {
        if (data.containsKey('script') && (data['script'] as String?) != null && (data['script'] as String).isNotEmpty) {
          userScript = data['script'] as String;
        }
        if (data.containsKey('inputData')) {
          final inputDataStr = data['inputData'] as String?;
          if (inputDataStr != null && inputDataStr.trim().isNotEmpty) {
            try {
              inputData = jsonDecode(inputDataStr);
            } catch (e) {
              stopwatch.stop();
              return ExecutionResult.failure(
                error: 'Invalid JSON in inputData: $e',
                executionTimeMs: stopwatch.elapsedMilliseconds,
              );
            }
          }
        }
      }

      // 如果还是没有脚本，则显示输入对话框
      if (userScript.trim().isEmpty) {
        return await _showJavaScriptInputDialog(context, data, stopwatch);
      }
    }

    // 使用 JavaScript 引擎执行脚本
    // TODO: 集成 JavaScript 引擎库

    try {
      // 临时实现：返回脚本内容供外部处理
      stopwatch.stop();
      return ExecutionResult.success(
        data: {
          'script': userScript,
          'scriptType': scriptType,
          'inputData': inputData,
          'message': 'JavaScript execution ready - integrate JS engine',
        },
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 显示JavaScript代码输入对话框
  Future<ExecutionResult> _showJavaScriptInputDialog(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    // 如果上下文未挂载，返回失败
    if (!context.mounted) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: 'Context not mounted',
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    final scriptController = TextEditingController();
    final inputDataController = TextEditingController(
      text: data?.toString() ?? '',
    );

    // 显示对话框
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('core_inputJavaScriptCode'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scriptController,
                decoration: const InputDecoration(
                  labelText: 'JavaScript代码',
                  hintText: '在这里输入您的JavaScript代码',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                minLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inputDataController,
                decoration: const InputDecoration(
                  labelText: '输入数据（JSON格式，可选）',
                  hintText: '{"key": "value"}',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              const Text(
                '提示：使用 inputData 访问输入数据，返回格式：{ success: true, ... }',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('core_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'script': scriptController.text,
                'data': inputDataController.text,
              });
            },
            child: Text('core_execute'.tr),
          ),
        ],
      ),
    );

    // 如果用户取消，返回失败
    if (result == null) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: 'User cancelled',
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    // 执行用户输入的JavaScript代码
    final userScript = result['script'] ?? '';
    if (userScript.trim().isEmpty) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: 'JavaScript code cannot be empty',
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    // 解析输入数据
    Map<String, dynamic>? inputData;
    try {
      if (result['data']?.trim().isNotEmpty == true) {
        inputData = jsonDecode(result['data']!);
      }
    } catch (e) {
      // 如果解析失败，使用原始字符串作为输入数据
      inputData = {'rawData': result['data']};
    }

    // 临时实现：返回用户输入的代码信息
    stopwatch.stop();
    return ExecutionResult.success(
      data: {
        'script': userScript,
        'scriptType': 'javascript',
        'inputData': inputData,
        'userInput': true,
        'message': 'JavaScript code received - ready for execution',
        'timestamp': DateTime.now().toIso8601String(),
      },
      executionTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  Future<ExecutionResult> _executeDart(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    // 安全执行 Dart 代码
    // 需要使用 isolates 或其他安全执行机制
    // TODO: 实现安全的 Dart 代码执行

    try {
      // 临时实现：返回脚本内容供外部处理
      stopwatch.stop();
      return ExecutionResult.success(
        data: {
          'script': script,
          'scriptType': scriptType,
          'inputData': data,
          'message': 'Dart execution ready - implement safety mechanism',
        },
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  Future<ExecutionResult> _executeExpression(
    BuildContext context,
    Map<String, dynamic>? data,
    Stopwatch stopwatch,
  ) async {
    // 执行简单表达式
    try {
      // 临时实现：简单的表达式求值
      // 实际项目中应该使用表达式求值库
      final result = _evaluateSimpleExpression(script, data);

      stopwatch.stop();
      return ExecutionResult.success(
        data: {
          'script': script,
          'scriptType': scriptType,
          'inputData': data,
          'result': result,
        },
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return ExecutionResult.failure(
        error: e.toString(),
        stackTrace: stack.toString(),
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 简单表达式求值
  dynamic _evaluateSimpleExpression(String expression, Map<String, dynamic>? data) {
    try {
      // 简单的数学表达式求值（仅支持基本运算）
      if (expression.contains(RegExp(r'[\+\-\*/()]'))) {
        // 将变量替换为实际值
        String processedExpression = expression;
        if (data != null) {
          for (final entry in data.entries) {
            processedExpression = processedExpression.replaceAll(
              '\$${entry.key}',
              entry.value.toString(),
            );
          }
        }

        // 简单的安全求值（仅用于演示，生产环境应使用专门的表达式求值库）
        // 这里返回一个模拟结果
        return 'Expression evaluated: $processedExpression';
      }

      // 如果不是数学表达式，直接返回字符串
      return expression;
    } catch (e) {
      return 'Error evaluating expression: $e';
    }
  }
}

/// 执行器工厂
class ActionExecutorFactory {
  /// 创建执行器
  static ActionExecutor create({
    required String type,
    String? actionId,
    String? pluginId,
    String? actionName,
    ActionGroup? group,
    String? script,
    String? scriptType,
    Map<String, dynamic>? extraParams,
  }) {
    switch (type) {
      case 'builtIn':
        if (actionId == null) {
          throw ArgumentError('actionId is required for builtIn executor');
        }
        return BuiltInActionExecutor(actionId);

      case 'plugin':
        if (pluginId == null || actionName == null) {
          throw ArgumentError(
            'pluginId and actionName are required for plugin executor',
          );
        }
        return PluginActionExecutor(pluginId: pluginId, actionName: actionName);

      case 'group':
        if (group == null) {
          throw ArgumentError('group is required for group executor');
        }
        return GroupActionExecutor(group);

      case 'custom':
        if (script == null || scriptType == null) {
          throw ArgumentError(
            'script and scriptType are required for custom executor',
          );
        }
        return CustomActionExecutor(script: script, scriptType: scriptType);

      default:
        throw ArgumentError('Unknown executor type: $type');
    }
  }

  /// 从 ActionDefinition 创建执行器
  static ActionExecutor fromDefinition(ActionDefinition definition) {
    // 根据定义中的信息创建合适的执行器
    // 这里可以根据不同的配置来创建不同的执行器

    return BuiltInActionExecutor(definition.id);
  }

  /// 从 JSON 创建执行器
  static ActionExecutor fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final actionId = json['actionId'] as String?;
    final pluginId = json['pluginId'] as String?;
    final actionName = json['actionName'] as String?;
    final script = json['script'] as String?;
    final scriptType = json['scriptType'] as String?;

    return create(
      type: type,
      actionId: actionId,
      pluginId: pluginId,
      actionName: actionName,
      script: script,
      scriptType: scriptType,
    );
  }
}
