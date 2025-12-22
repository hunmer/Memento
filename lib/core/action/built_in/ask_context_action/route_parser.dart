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
    '/todo_list': '用户正在查看待办事项列表（{taskCount} 个任务，{viewMode} 视图）',
    '/todo_list_search': '用户正在搜索待办事项：{searchQuery}（找到 {resultCount} 个结果）',
    '/todo_history': '用户正在查看已完成的待办历史记录（共 {completedCount} 个）',
    '/todo_detail': '用户正在查看待办任务：{taskTitle}（ID: {taskId}，状态: {taskStatus}）',
    '/todo_form_new': '用户正在新建待办任务',
    '/todo_form_edit': '用户正在编辑待办任务：{taskTitle}（ID: {taskId}）',

    // 账单插件
    '/bill': '用户正在查看账单',
    '/bill_list': '用户正在查看 {date} 的账单列表',
    '/bill_stats': '用户正在分析 {month} 的账单统计',
    '/bill_create': '用户正在新建账单',
    '/bill_edit': '用户正在编辑账单 {billId}',
    '/bill_subscriptions': '用户正在管理订阅服务',
    '/bill_subscription_create': '用户正在新建订阅',
    '/bill_subscription_edit': '用户正在编辑订阅 {subscriptionId}',
    '/bill_accounts': '用户正在管理账单账户',

    // 日历插件
    '/calendar': '用户正在查看日历',
    '/calendar_main': '用户正在查看日历 - {viewMode}（{timeRange}）',
    '/calendar_event_list': '用户正在查看所有日历事件（共 {totalCount} 个事件）',
    '/calendar_event_detail': '用户正在查看事件详情：{eventTitle}（ID: {eventId}，日期: {startDate}）',
    '/calendar_event_new': '用户正在新建日历事件',
    '/calendar_event_edit': '用户正在编辑日历事件：{eventTitle}（ID: {eventId}）',

    // AI插件
    '/agent_chat': '用户正在使用AI对话',
    '/openai': '用户正在管理AI助手',

    // 活动插件
    '/activity': '用户正在查看活动记录',
    '/activity_timeline': '用户正在查看 {date} 的活动时间轴',

    // 其他插件
    '/tracker': '用户正在查看目标追踪',
    '/habits': '用户正在查看习惯管理',
    '/habits_list': '用户正在查看习惯列表',
    '/skills_list': '用户正在查看技能列表',
    '/habit_form': '用户正在{mode}习惯（{habitTitle}）',
    '/skill_form': '用户正在{mode}技能（{skillTitle}）',
    '/habit_timer': '用户正在为习惯 {habitTitle} 计时',
    '/skill_detail': '用户正在查看技能 {skillTitle} 的{tab}',
    '/notes': '用户正在查看笔记',
    '/notes_list': '用户正在查看笔记列表 - {folderName}',
    '/note_edit': '用户正在编辑笔记 {noteTitle}',
    '/checkin': '用户正在查看打卡记录',
    '/checkin_list': '用户正在查看 {group} 分组的打卡列表',
    '/checkin_stats': '用户正在查看打卡统计',
    '/checkin_form_new': '用户正在新建打卡项目',
    '/checkin_form_edit': '用户正在编辑打卡项目 {itemName}',
    '/checkin_record': '用户正在查看 {itemName} 的打卡记录',
    '/contact': '用户正在查看联系人',
    '/goods': '用户正在查看商品管理',
    '/goods/warehouses': '用户正在查看所有仓库列表',
    '/goods/warehouse_detail': '用户正在查看仓库: {warehouseName}',
    '/goods/items_all': '用户正在查看所有物品列表',
    '/goods/items_filtered': '用户正在查看仓库 {warehouseName} 的物品列表',
    '/goods/item_history': '用户正在查看物品 {itemName} 的使用记录',
    '/goods/item_form': '用户正在编辑物品: {itemName}',
    '/goods/item_dialog_edit': '用户正在编辑物品: {itemName}',
    '/goods/item_dialog_new': '用户正在创建新物品',
    '/chat': '用户正在查看聊天',
    '/chat/channels': '用户正在查看聊天频道列表',
    '/chat/timeline': '用户正在查看聊天时间线',
    '/chat/tags': '用户正在查看聊天标签',
    '/chat/channel': '用户正在 {channelName} 频道中聊天',
    '/calendar_album': '用户正在查看日历相册',
    '/calendar_album_calendar': '用户正在查看 {date} 的日历日记',
    '/calendar_album_entry_detail': '用户正在查看 {date} 的日记：{title}（ID: {entryId}）',
    '/calendar_album_tags': '用户正在查看标签管理（已选择 {tagCount} 个标签：{tags}）',
    '/calendar_album_album': '用户正在浏览相册（共 {photoCount} 张照片）',
    '/calendar_album_entry_editor': '用户正在{mode}日记：{title}（日期: {date}）',
    '/database': '用户正在查看自定义数据库',
    '/day': '用户正在查看日计划',
    '/day_list': '用户正在查看纪念日列表（共 {count} 个）',
    '/day_detail': '用户正在查看纪念日详情 - {title}（日期: {date}）',
    '/day_new': '用户正在新建纪念日',
    '/nodes': '用户正在查看知识库',
    '/scripts_center': '用户正在查看脚本中心',
    '/store': '用户正在查看商店',
    '/timer': '用户正在查看计时器',
    '/timer_main': '用户正在查看 {group} 分组的计时器列表',
    '/timer_details': '用户正在查看计时器任务 {taskName} 的详情（当前计时器: {currentTimerName}，状态: {isRunning}）',
    '/timer_edit': '用户正在{mode}计时器: {taskName}',
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
