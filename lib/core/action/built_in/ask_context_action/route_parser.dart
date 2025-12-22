import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'models/route_context.dart';

/// 路由解析器
///
/// 负责将路由信息转换为人类可读的上下文描述
class RouteParser {
  /// 路由解释模板映射表
  ///
  /// 键：路由名称
  /// 值：解释文本模板，支持 {参数名} 占位符
  static const Map<String, String> _routeTemplates = {
    // 核心路由
    '/': '用户位于首页',
    '/settings': '用户正在设置页面',

    // 日记插件
    '/diary': '用户正在查看日记列表',
    '/diary_detail': '用户正在查看 {date} 的日记',
    '/diary_edit': '用户正在编辑 {date} 的日记',

    // 待办插件
    '/todo': '用户正在查看待办事项',
    '/todo_task_detail': '用户正在查看待办任务',
    '/todo_add': '用户正在添加新待办',

    // 账单插件
    '/bill': '用户正在查看账单',
    '/bill_edit': '用户正在编辑账单',

    // 日历插件
    '/calendar': '用户正在查看日历',
    '/calendar_event_detail': '用户正在查看日程',

    // AI插件
    '/agent_chat': '用户正在使用AI对话',
    '/openai': '用户正在管理AI助手',

    // 其他插件
    '/activity': '用户正在查看活动记录',
    '/tracker': '用户正在查看目标追踪',
    '/habits': '用户正在查看习惯管理',
    '/notes': '用户正在查看笔记',
    '/checkin': '用户正在查看打卡记录',
    '/contact': '用户正在查看联系人',
    '/goods': '用户正在查看商品管理',
    '/chat': '用户正在查看聊天',
    '/calendar_album': '用户正在查看日历相册',
    '/database': '用户正在查看自定义数据库',
    '/day': '用户正在查看日计划',
    '/nodes': '用户正在查看知识库',
    '/scripts_center': '用户正在查看脚本中心',
    '/store': '用户正在查看商店',
    '/timer': '用户正在查看计时器',
    '/tts': '用户正在设置文本转语音',
    '/webview': '用户正在使用内置浏览器',
    '/nfc': '用户正在使用NFC功能',
  };

  /// 解析当前路由
  ///
  /// 从BuildContext中提取路由信息并转换为RouteContext对象
  /// 优先级：RouteHistoryManager（手动设置） > GetX 路由 > Flutter 原生路由
  static RouteContext parseRoute(BuildContext context) {
    try {
      String? routeName;
      dynamic arguments;

      // 最高优先级：使用 RouteHistoryManager 中手动设置的当前上下文
      // 这允许页面在不刷新的情况下更新上下文信息
      final currentContext = RouteHistoryManager.getCurrentContext();
      if (currentContext != null) {
        routeName = currentContext.pageId;
        arguments = currentContext.params;
        debugPrint('RouteParser: 使用 RouteHistoryManager 上下文 - route: $routeName, args: $arguments');
      }

      // 第二优先级：使用 GetX 路由信息
      if (routeName == null || routeName.isEmpty || routeName == '/') {
        if (Get.routing.current.isNotEmpty) {
          routeName = Get.routing.current;
          // GetX 的路由参数通过 Get.arguments 获取
          arguments = Get.arguments;
          debugPrint('RouteParser: 使用 GetX 路由信息 - route: $routeName, args: $arguments');
        }
      }

      // 第三优先级：回退到 Flutter 原生路由
      if (routeName == null || routeName.isEmpty || routeName == '/') {
        final route = ModalRoute.of(context)?.settings;
        final fallbackRouteName = route?.name;
        final fallbackArguments = route?.arguments;

        // 只有当找到了有效的路由时才覆盖
        if (fallbackRouteName != null && fallbackRouteName.isNotEmpty) {
          routeName = fallbackRouteName;
          arguments ??= fallbackArguments;
          debugPrint('RouteParser: 回退到原生路由 - route: $routeName, args: $arguments');
        }
      }

      // 确保至少有一个有效的路由名称
      routeName ??= '/';

      // 获取路由模板
      String description = _routeTemplates[routeName] ?? '用户正在查看：$routeName';

      // 处理参数替换
      if (arguments != null && arguments is Map<String, dynamic>) {
        description = _replaceParameters(description, arguments);
      }

      return RouteContext(
        routeName: routeName,
        arguments: arguments,
        description: description,
      );
    } catch (e) {
      // 解析失败时返回默认描述
      debugPrint('路由解析失败: $e');
      return const RouteContext(routeName: '/', description: '用户正在使用应用');
    }
  }

  /// 替换描述文本中的参数占位符
  ///
  /// 将 {参数名} 替换为实际值，如果参数不存在则替换为 [未知]
  static String _replaceParameters(
    String template,
    Map<String, dynamic> arguments,
  ) {
    String result = template;

    // 提取所有占位符 {xxx}
    final placeholderPattern = RegExp(r'\{(\w+)\}');
    final matches = placeholderPattern.allMatches(template);

    for (final match in matches) {
      final paramName = match.group(1)!;
      final paramValue = arguments[paramName];

      if (paramValue != null) {
        result = result.replaceAll('{$paramName}', paramValue.toString());
      } else {
        // 参数不存在，使用友好提示
        result = result.replaceAll('{$paramName}', '[未知]');
      }
    }

    return result;
  }

  /// 检查路由是否已注册
  static bool isRouteRegistered(String routeName) {
    return _routeTemplates.containsKey(routeName);
  }
}
