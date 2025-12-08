import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:Memento/core/floating_ball/floating_widget_controller.dart';
import 'package:Memento/core/action/action_manager.dart';
import 'package:Memento/core/app_initializer.dart';

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

    // 使用 ActionManager 执行动作
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('navigatorKey.currentContext 为 null，无法执行动作');
      return;
    }

    // 特殊处理 home 别名
    if (action == 'home') {
      action = 'goHome';
    }

    // 通过 ActionManager 执行动作
    ActionManager().execute(
      action,
      context,
      data: args,
    ).then((result) {
      if (!result.success) {
        debugPrint('动作执行失败: $action, 错误: ${result.error}');
      } else {
        debugPrint('动作执行成功: $action');
      }
    }).catchError((error) {
      debugPrint('动作执行异常: $action, 错误: $error');
    });
  });

  debugPrint('悬浮球按钮事件全局监听器已设置');
}
