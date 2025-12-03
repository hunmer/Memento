import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../core/floating_ball/floating_widget_controller.dart';
import '../app_initializer.dart';

/// 恢复悬浮球状态
Future<void> restoreFloatingBallState() async {
  try {
    // 仅在 Android 平台恢复悬浮球
    if (!UniversalPlatform.isAndroid) {
      debugPrint('跳过悬浮球恢复（非 Android 平台）');
      return;
    }

    // 初始化悬浮球控制器
    final controller = FloatingWidgetController();
    await controller.initialize();

    // 设置全局按钮事件监听器
    setupFloatingBallButtonListener(controller);

    await controller.performAutoRestore();

    debugPrint('悬浮球状态已恢复');
  } catch (e, stack) {
    debugPrint('恢复悬浮球状态失败: $e');
    debugPrint('堆栈: $stack');
  }
}

/// 设置悬浮球按钮事件全局监听器
void setupFloatingBallButtonListener(FloatingWidgetController controller) {
  controller.buttonEvents.listen((event) {
    debugPrint(
      '全局悬浮球按钮事件: ${event.title}, data: ${event.data}, type: ${event.data.runtimeType}',
    );

    if (event.data == null) {
      debugPrint('悬浮球按钮事件 data 为 null');
      return;
    }

    // 安全地提取 action，处理可能的类型问题
    final data = event.data!;
    String? action;
    Map<String, dynamic>? args;

    try {
      // 尝试直接获取 action
      action = data['action']?.toString();

      // 尝试获取 args，并转换为正确的类型
      final rawArgs = data['args'];
      if (rawArgs is Map) {
        args = Map<String, dynamic>.from(rawArgs);
      }
    } catch (e) {
      debugPrint('解析悬浮球按钮事件数据失败: $e');
      return;
    }

    debugPrint('解析结果 - action: $action, args: $args');

    if (action == null) {
      debugPrint('悬浮球按钮事件没有 action 字段');
      return;
    }

    switch (action) {
      case 'openPlugin':
        // 打开指定插件
        final pluginId = args?['plugin']?.toString();
        if (pluginId != null) {
          final plugin = globalPluginManager.getPlugin(pluginId);
          if (plugin != null) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              debugPrint('悬浮球打开插件: $pluginId');
              globalPluginManager.openPlugin(context, plugin);
            } else {
              debugPrint('navigatorKey.currentContext 为 null');
            }
          } else {
            debugPrint('插件不存在: $pluginId');
          }
        } else {
          debugPrint('openPlugin action 缺少 plugin 参数');
        }
        break;

      case 'openSettings':
        // 打开设置页面
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          debugPrint('悬浮球打开设置');
          navigator.pushNamed('/settings');
        } else {
          debugPrint('navigatorKey.currentState 为 null');
        }
        break;

      case 'goHome':
      case 'home':
        // 返回首页
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          debugPrint('悬浮球返回首页');
          navigator.pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          debugPrint('navigatorKey.currentState 为 null');
        }
        break;

      case 'goBack':
        // 返回上一页
        final navigator = navigatorKey.currentState;
        if (navigator != null && navigator.canPop()) {
          debugPrint('悬浮球返回上一页');
          navigator.pop();
        } else {
          debugPrint('无法返回上一页');
        }
        break;

      default:
        debugPrint('未知的悬浮球动作: $action');
    }
  });

  debugPrint('悬浮球按钮事件全局监听器已设置');
}
