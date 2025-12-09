import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:Memento/plugins/chat/home_widgets.dart';
import 'package:Memento/plugins/diary/home_widgets.dart';
import 'package:Memento/plugins/activity/home_widgets.dart';
import 'package:Memento/plugins/agent_chat/home_widgets.dart';
import 'package:Memento/plugins/openai/home_widgets.dart';
import 'package:Memento/plugins/notes/home_widgets.dart';
import 'package:Memento/plugins/goods/home_widgets.dart';
import 'package:Memento/plugins/bill/home_widgets.dart';
import 'package:Memento/plugins/todo/home_widgets.dart';
import 'package:Memento/plugins/checkin/home_widgets.dart';
import 'package:Memento/plugins/calendar/home_widgets.dart';
import 'package:Memento/plugins/timer/home_widgets.dart';
import 'package:Memento/plugins/day/home_widgets.dart';
import 'package:Memento/plugins/tracker/home_widgets.dart';
import 'package:Memento/plugins/store/home_widgets.dart';
import 'package:Memento/plugins/nodes/home_widgets.dart';
import 'package:Memento/plugins/contact/home_widgets.dart';
import 'package:Memento/plugins/habits/home_widgets.dart';
import 'package:Memento/plugins/database/home_widgets.dart';
import 'package:Memento/plugins/calendar_album/home_widgets.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/route.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:memento_widgets/memento_widgets.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/global_flags.dart';

/// 初始化主页小组件系统
Future<void> initializeHomeWidgets() async {
  try {
    // 注册所有插件的小组件
    ChatHomeWidgets.register();
    DiaryHomeWidgets.register();
    ActivityHomeWidgets.register();
    AgentChatHomeWidgets.register();
    OpenAIHomeWidgets.register();
    NotesHomeWidgets.register();
    GoodsHomeWidgets.register();
    BillHomeWidgets.register();
    TodoHomeWidgets.register();
    CheckinHomeWidgets.register();
    CalendarHomeWidgets.register();
    TimerHomeWidgets.register();
    DayHomeWidgets.register();
    TrackerHomeWidgets.register();
    StoreHomeWidgets.register();
    NodesHomeWidgets.register();
    ContactHomeWidgets.register();
    HabitsHomeWidgets.register();
    DatabaseHomeWidgets.register();
    CalendarAlbumHomeWidgets.register();

    // 初始化布局管理器
    final layoutManager = HomeLayoutManager();
    await layoutManager.initialize();

    debugPrint('主页小组件系统初始化完成');
  } catch (e) {
    debugPrint('主页小组件系统初始化失败: $e');
  }
}

/// 设置桌面小组件点击监听器
Future<void> setupWidgetClickListener() async {
  // home_widget 插件只支持 Android 和 iOS 平台
  if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
    debugPrint('跳过小组件点击监听器设置（当前平台不支持 home_widget 插件）');
    return;
  }

  // 初始化 memento_widgets 插件的 MyWidgetManager
  try {
    final widgetManager = MyWidgetManager();
    await widgetManager.init(null); // Android 不需要 App Group ID
    debugPrint('memento_widgets 插件初始化成功');
  } catch (e) {
    debugPrint('memento_widgets 插件初始化失败: $e');
  }

  // 初始化 HomeWidget (必须在监听前调用)
  // 只在 iOS 平台上设置 App Group ID，因为 setAppGroupId 只在 iOS 上有效
  if (UniversalPlatform.isIOS) {
    await HomeWidget.setAppGroupId('group.github.hunmer.memento');
  }

  // 监听 HomeWidget 的点击事件（备用方式）
  HomeWidget.widgetClicked.listen((Uri? uri) {
    if (uri != null) {
      handleWidgetClick(uri.toString());
    }
  });

  // 监听 Android 原生通过 MethodChannel 发送的小组件点击事件
  const platform = MethodChannel('github.hunmer.memento/widget');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onWidgetClicked') {
      final url = call.arguments as String?;
      if (url != null) {
        handleWidgetClick(url);
      }
    }
  });

  // 注册 Android 广播监听器（用于接收小组件广播事件）
  if (UniversalPlatform.isAndroid) {
    await _registerBroadcastReceiver();
  }

  debugPrint('桌面小组件点击监听器已设置');
}

/// 注册 Android 广播监听器
Future<void> _registerBroadcastReceiver() async {
  const platform = MethodChannel('github.hunmer.memento/widget_broadcast');

  try {
    await platform.invokeMethod('registerBroadcastReceiver', <String, dynamic>{
      'actions': [
        'github.hunmer.memento.REFRESH_ACTIVITY_WEEKLY_WIDGET',
        'github.hunmer.memento.REFRESH_ACTIVITY_DAILY_WIDGET',
        'github.hunmer.memento.REFRESH_HABITS_WEEKLY_WIDGET',
        'github.hunmer.memento.REFRESH_CHECKIN_WEEKLY_WIDGET',
        'github.hunmer.memento.REFRESH_CALENDAR_ALBUM_WEEKLY_WIDGET',
        'github.hunmer.memento.REFRESH_TODO_QUADRANT_WIDGET',
        'github.hunmer.memento.CLEANUP_WIDGET_IDS',
      ],
    });

    // 监听广播事件
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onBroadcastReceived') {
        final action = call.arguments['action'] as String;
        final data = call.arguments['data'] as Map?;

        debugPrint('收到小组件广播: $action, 数据: $data');

        try {
          // 处理活动周视图小组件刷新
          if (action ==
              'github.hunmer.memento.REFRESH_ACTIVITY_WEEKLY_WIDGET') {
            final widgetId = data?['widgetId'] as int?;
            final weekOffset = data?['weekOffset'] as int?;

            debugPrint(
              '活动周视图小组件刷新请求: widgetId=$widgetId, weekOffset=$weekOffset',
            );

            if (widgetId != null && weekOffset != null) {
              // 更新 SharedPreferences 中的 weekOffset
              final widgetDataJson = await HomeWidget.getWidgetData<String>(
                'activity_weekly_data_$widgetId',
              );

              if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
                final widgetData =
                    jsonDecode(widgetDataJson) as Map<String, dynamic>;
                final configJson =
                    widgetData['config'] as Map<String, dynamic>?;

                if (configJson != null) {
                  configJson['currentWeekOffset'] = weekOffset;
                  widgetData['config'] = configJson;

                  // 保存更新后的配置
                  await HomeWidget.saveWidgetData<String>(
                    'activity_weekly_data_$widgetId',
                    jsonEncode(widgetData),
                  );

                  debugPrint('已更新 weekOffset 为 $weekOffset');
                }
              }

              // 同步数据
              await PluginWidgetSyncHelper.instance.syncActivityWeeklyWidget();

              // 通知 Android 小组件刷新
              await HomeWidget.updateWidget(
                name: 'ActivityWeeklyWidgetProvider',
                iOSName: 'ActivityWeeklyWidget',
                qualifiedAndroidName:
                    'github.hunmer.memento.widgets.providers.ActivityWeeklyWidgetProvider',
              );

              debugPrint('活动周视图小组件刷新完成');
            }
          }
          // 处理活动日视图小组件刷新
          else if (action ==
              'github.hunmer.memento.REFRESH_ACTIVITY_DAILY_WIDGET') {
            final widgetId = data?['widgetId'] as int?;
            final dayOffset = data?['dayOffset'] as int?;

            debugPrint(
              '活动日视图小组件刷新请求: widgetId=$widgetId, dayOffset=$dayOffset',
            );

            if (widgetId != null && dayOffset != null) {
              // 更新 SharedPreferences 中的 dayOffset
              final widgetDataJson = await HomeWidget.getWidgetData<String>(
                'activity_daily_data_$widgetId',
              );

              if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
                final widgetData =
                    jsonDecode(widgetDataJson) as Map<String, dynamic>;
                final configJson =
                    widgetData['config'] as Map<String, dynamic>?;

                if (configJson != null) {
                  configJson['currentDayOffset'] = dayOffset;
                  widgetData['config'] = configJson;

                  // 保存更新后的配置
                  await HomeWidget.saveWidgetData<String>(
                    'activity_daily_data_$widgetId',
                    jsonEncode(widgetData),
                  );

                  debugPrint('已更新 dayOffset 为 $dayOffset');
                }
              }

              // 同步数据
              await PluginWidgetSyncHelper.instance.syncActivityDailyWidget();

              // 通知 Android 小组件刷新
              await HomeWidget.updateWidget(
                name: 'ActivityDailyWidgetProvider',
                iOSName: 'ActivityDailyWidget',
                qualifiedAndroidName:
                    'github.hunmer.memento.widgets.providers.ActivityDailyWidgetProvider',
              );

              debugPrint('活动日视图小组件刷新完成');
            }
          }
          // 处理习惯周视图小组件刷新
          else if (action ==
              'github.hunmer.memento.REFRESH_HABITS_WEEKLY_WIDGET') {
            debugPrint('习惯周视图小组件刷新请求');
            await PluginWidgetSyncHelper.instance.syncHabitsWeeklyWidget();
            await HomeWidget.updateWidget(
              name: 'HabitsWeeklyWidgetProvider',
              iOSName: 'HabitsWeeklyWidget',
              qualifiedAndroidName:
                  'github.hunmer.memento.widgets.providers.HabitsWeeklyWidgetProvider',
            );
          }
          // 处理签到周视图小组件刷新
          else if (action ==
              'github.hunmer.memento.REFRESH_CHECKIN_WEEKLY_WIDGET') {
            debugPrint('签到周视图小组件刷新请求');
            await PluginWidgetSyncHelper.instance.syncCheckinWeeklyWidget();
            await HomeWidget.updateWidget(
              name: 'CheckinWeeklyWidgetProvider',
              iOSName: 'CheckinWeeklyWidget',
              qualifiedAndroidName:
                  'github.hunmer.memento.widgets.providers.CheckinWeeklyWidgetProvider',
            );
          }
          // 处理每周相册小组件刷新
          else if (action ==
              'github.hunmer.memento.REFRESH_CALENDAR_ALBUM_WEEKLY_WIDGET') {
            final widgetId = data?['widgetId'] as int?;
            final weekOffset = data?['weekOffset'] as int?;

            debugPrint(
              '每周相册小组件刷新请求: widgetId=$widgetId, weekOffset=$weekOffset',
            );

            if (widgetId != null && weekOffset != null) {
              // 更新 SharedPreferences 中的 weekOffset
              final widgetDataJson = await HomeWidget.getWidgetData<String>(
                'calendar_album_weekly_data_$widgetId',
              );

              if (widgetDataJson != null && widgetDataJson.isNotEmpty) {
                final widgetData =
                    jsonDecode(widgetDataJson) as Map<String, dynamic>;
                widgetData['weekOffset'] = weekOffset;

                // 保存更新后的配置
                await HomeWidget.saveWidgetData<String>(
                  'calendar_album_weekly_data_$widgetId',
                  jsonEncode(widgetData),
                );

                debugPrint('已更新 weekOffset 为 $weekOffset');
              }

              // 同步数据
              await PluginWidgetSyncHelper.instance.syncCalendarAlbumWeeklyWidget();

              // 通知 Android 小组件刷新
              await HomeWidget.updateWidget(
                name: 'CalendarAlbumWeeklyWidgetProvider',
                iOSName: 'CalendarAlbumWeeklyWidget',
                qualifiedAndroidName:
                    'github.hunmer.memento.widgets.providers.CalendarAlbumWeeklyWidgetProvider',
              );

              debugPrint('每周相册小组件刷新完成');
            }
          }
          // 处理四象限任务小组件刷新
          else if (action ==
              'github.hunmer.memento.REFRESH_TODO_QUADRANT_WIDGET') {
            debugPrint('四象限任务小组件刷新请求');
            await PluginWidgetSyncHelper.instance.syncTodoQuadrantWidget();
            await HomeWidget.updateWidget(
              name: 'TodoQuadrantWidgetProvider',
              iOSName: 'TodoQuadrantWidgetProvider',
              qualifiedAndroidName:
                  'github.hunmer.memento.widgets.providers.TodoQuadrantWidgetProvider',
            );
          }
          // 处理小组件清理请求（删除时）
          else if (action == 'github.hunmer.memento.CLEANUP_WIDGET_IDS') {
            final widgetType = data?['widgetType'] as String?;
            final deletedWidgetIds = data?['deletedWidgetIds'] as List?;

            debugPrint('小组件清理请求: widgetType=$widgetType, deletedWidgetIds=$deletedWidgetIds');

            if (widgetType == 'activity_weekly' && deletedWidgetIds != null) {
              await _cleanupWidgetIds('activity_weekly_widget_ids', deletedWidgetIds.cast<int>());
            }
          }
        } catch (e) {
          debugPrint('处理广播事件失败: $e');
        }
      }
    });

    debugPrint('Android 广播监听器注册成功');
  } catch (e) {
    debugPrint('注册 Android 广播监听器失败: $e');
  }
}

/// 清理已删除的 widgetId
Future<void> _cleanupWidgetIds(String listKey, List<int> deletedWidgetIds) async {
  try {
    final existingIdsJson = await HomeWidget.getWidgetData<String>(listKey);

    if (existingIdsJson == null || existingIdsJson.isEmpty) {
      debugPrint('Cleanup: No existing widget IDs found for $listKey');
      return;
    }

    final widgetIds = List<int>.from(jsonDecode(existingIdsJson) as List);
    final originalCount = widgetIds.length;

    // 移除已删除的 widgetId
    widgetIds.removeWhere((id) => deletedWidgetIds.contains(id));

    final removedCount = originalCount - widgetIds.length;
    debugPrint('Cleanup: Removed $removedCount widget IDs from $listKey (remaining: ${widgetIds.length})');

    // 保存更新后的列表
    if (widgetIds.isEmpty) {
      // 如果列表为空，删除整个键
      await HomeWidget.saveWidgetData<String>(listKey, '');
    } else {
      await HomeWidget.saveWidgetData<String>(
        listKey,
        jsonEncode(widgetIds),
      );
    }

    debugPrint('Cleanup: Updated $listKey with remaining IDs: $widgetIds');
  } catch (e) {
    debugPrint('Cleanup failed for $listKey: $e');
  }
}

/// 处理小组件点击事件
void handleWidgetClick(String url) {
  debugPrint('收到桌面小组件点击事件: $url');

  // 标记应用从小组件启动，防止错误地自动打开最后使用的插件
  isLaunchedFromWidget = true;

  try {
    final uri = Uri.parse(url);
    debugPrint('URI scheme: ${uri.scheme}');
    debugPrint('URI host: ${uri.host}');
    debugPrint('URI path: ${uri.path}');
    debugPrint('URI query: ${uri.query}');

    // 解析 URI 路径和参数
    // 支持多种格式:
    // 1. memento://widget/quick_send?channelId=xxx (path-based, host=widget)
    // 2. memento://habits_weekly_config?widgetId=35 (host-based, path=/)
    // 3. memento://checkin/item?itemId=xxx (host+path combined)
    String routePath = uri.path;

    // 如果 path 为空或只有斜杠，使用 host 作为路由路径
    if (routePath.isEmpty || routePath == '/') {
      routePath = '/${uri.host}';
      debugPrint('使用 host 作为路由路径: $routePath');
    } else if (uri.host != 'widget' && uri.host.isNotEmpty) {
      // 如果 host 不是 'widget' 且 path 不为空，组合 host 和 path
      // 例如: memento://checkin/item -> /checkin/item
      routePath = '/${uri.host}${uri.path}';
      debugPrint('组合 host 和 path 作为路由路径: $routePath');
    }

    // 移除 /widget 前缀（如果存在）
    if (routePath.startsWith('/widget/')) {
      routePath = routePath.substring(7); // 移除 "/widget"，保留 /quick_send
    } else if (routePath.startsWith('widget/')) {
      routePath = '/${routePath.substring(7)}'; // 添加前导斜杠
    }

    debugPrint('处理后的路由路径: $routePath');

    // 特殊处理：打卡小组件配置路由
    // 从 /checkin_item/config?widgetId=xxx 转换为 /checkin_item_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/checkin_item/config') {
      routePath = '/checkin_item_selector';
      debugPrint('打卡小组件配置路由转换为: $routePath');
    }

    // 特殊处理：待办列表小组件配置路由
    // 从 /todo_list/config?widgetId=xxx 转换为 /todo_list_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/todo_list/config') {
      routePath = '/todo_list_selector';
      debugPrint('待办列表小组件配置路由转换为: $routePath');
    }

    // 特殊处理：日历月视图小组件配置路由
    // 从 /calendar_month/config?widgetId=xxx 转换为 /calendar_month_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/calendar_month/config') {
      routePath = '/calendar_month_selector';
      debugPrint('日历月视图小组件配置路由转换为: $routePath');
    }

    // 特殊处理：每周相册小组件配置路由
    // 从 /calendar_album_weekly/config?widgetId=xxx 转换为 /calendar_album_weekly_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/calendar_album_weekly/config') {
      routePath = '/calendar_album_weekly_selector';
      debugPrint('每周相册小组件配置路由转换为: $routePath');
    }

    // 特殊处理：日历月视图小组件日期点击
    // 从 /calendar_month?date=YYYY-MM-DD 打开事件详情对话框
    if (routePath == '/calendar_month' &&
        uri.queryParameters.containsKey('date')) {
      final dateString = uri.queryParameters['date'];
      if (dateString != null) {
        // 打开日历插件并显示选中日期的事件
        routePath = '/calendar';
        debugPrint('日历月视图日期点击，打开日历插件: $dateString');
        // 注意：这里需要在日历插件中处理date参数来显示对应日期的事件
      }
    }

    // 特殊处理：目标追踪进度增减小组件配置路由
    // 从 /tracker_goal/config?widgetId=xxx 转换为 /tracker_goal_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/tracker_goal/config') {
      routePath = '/tracker_goal_selector';
      debugPrint('目标追踪进度增减小组件配置路由转换为: $routePath');
    }

    // 特殊处理：目标追踪进度条小组件配置路由
    // 从 /tracker_goal_progress/config?widgetId=xxx 转换为 /tracker_goal_progress_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/tracker_goal_progress/config') {
      routePath = '/tracker_goal_progress_selector';
      debugPrint('目标追踪进度条小组件配置路由转换为: $routePath');
    }

    // 特殊处理：快捷记账小组件配置路由
    // 从 /bill_shortcuts/config?widgetId=xxx 转换为 /bill_shortcuts_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/bill_shortcuts/config') {
      routePath = '/bill_shortcuts_selector';
      debugPrint('快捷记账小组件配置路由转换为: $routePath');
    }

    // 特殊处理：习惯计时器小组件配置路由
    // 从 /habit_timer/config?widgetId=xxx 转换为 /habit_timer_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/habit_timer/config') {
      routePath = '/habit_timer_selector';
      debugPrint('习惯计时器小组件配置路由转换为: $routePath');
    }

    // 特殊处理：习惯分组列表小组件配置路由
    // 从 /habit_group_list/config?widgetId=xxx 转换为 /habit_group_list_selector
    // widgetId 参数会在后面被提取到 arguments 中
    if (routePath == '/habit_group_list/config') {
      routePath = '/habit_group_list_selector';
      debugPrint('习惯分组列表小组件配置路由转换为: $routePath');
    }

    // 特殊处理：快捷记账添加账单路由
    // 从 /bill_shortcuts/add?accountId=xxx&category=xxx&amount=xxx&isExpense=true
    // 转换为 /bill 并传递参数
    if (routePath == '/bill_shortcuts/add') {
      routePath = '/bill';
      debugPrint('快捷记账添加账单路由转换为: $routePath，参数: ${uri.queryParameters}');
    }

    // 特殊处理：日历月视图小组件点击标题（打开日历插件）
    if (routePath == '/calendar' && uri.queryParameters.isEmpty) {
      // 直接打开日历插件主界面
      debugPrint('日历月视图标题点击，打开日历插件');
    }

    // 特殊处理：待办列表小组件任务详情路由
    // 从 /todo_list/detail?taskId=xxx 转换为 /todo_task_detail
    // taskId 参数会在后面被提取到 arguments 中
    if (routePath == '/todo_list/detail') {
      routePath = '/todo_task_detail';
      debugPrint('待办列表小组件任务详情路由转换为: $routePath');
    }

    // 特殊处理：待办添加任务路由
    // 从 /todo/add 转换为 /todo_add
    if (routePath == '/todo/add') {
      routePath = '/todo_add';
      debugPrint('待办添加任务路由转换为: $routePath');
    }

    // 特殊处理：目标追踪目标详情路由
    // 从 /plugin/tracker/goal/goalId 跳转到目标详情页
    if (routePath.startsWith('/plugin/tracker/goal/')) {
      final goalId = routePath.substring('/plugin/tracker/goal/'.length);
      debugPrint('目标追踪目标详情路由，goalId: $goalId');
      // 打开 tracker 插件并导航到目标详情页
      final trackerPlugin = TrackerPlugin.instance;
      final goal = trackerPlugin.controller.goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw Exception('Goal not found: $goalId'),
      );
      routePath = '/tracker';
      // 使用路由后回调导航到详情页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          trackerPlugin.openGoalDetail(navigatorKey.currentContext!, goal);
        }
      });
    }

    // 特殊处理：习惯计时器对话框路由
    // 从 /plugin/habits/timer?habitId=xxx 转换为 /habit_timer_dialog
    // habitId 参数会在后面被提取到 arguments 中
    if (routePath == '/plugin/habits/timer') {
      routePath = '/habit_timer_dialog';
      debugPrint('习惯计时器对话框路由转换为: $routePath');
    }

    // 特殊处理：习惯周小组件计时器对话框路由
    // 从 /timer 且 host 为 habits 时，说明是习惯插件的计时器
    // 例如: memento://habits/timer?habitId=xxx
    if (routePath == '/timer' && uri.host == 'habits') {
      routePath = '/habit_timer_dialog';
      debugPrint('习惯周小组件计时器对话框路由转换为: $routePath');
    }

    // 提取所有查询参数
    final queryParams = uri.queryParameters;

    // 将 queryParams 作为 arguments 传递，如果为空则传递 null
    final arguments = queryParams.isNotEmpty ? queryParams : null;

    debugPrint('导航到路由: $routePath, 参数: $arguments');

    // 延迟导航，确保应用完全启动
    Future.delayed(const Duration(milliseconds: 100), () {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        debugPrint(
          '执行导航: 重置路由栈并push RouteSettings($routePath, arguments: $arguments)',
        );
        try {
          // 从小组件进入时，重置路由栈为两层：首页 + 目标页面
          // 1. 先清除所有路由并回到首页
          navigator.pushNamedAndRemoveUntil('/', (route) => false);

          // 2. 延迟一帧后再推入目标路由，确保首页已经完全加载
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final route = AppRoutes.generateRoute(
              RouteSettings(name: routePath, arguments: arguments),
            );
            navigator.push(route);
            debugPrint('导航成功：路由栈现在有两层 (/ -> $routePath)');
          });
        } catch (error, stack) {
          debugPrint('路由导航失败: $error');
          debugPrint('堆栈: $stack');
        }
      } else {
        debugPrint('导航器尚未初始化，延迟500ms后重试');
        Future.delayed(const Duration(milliseconds: 500), () {
          final retryNavigator = navigatorKey.currentState;
          if (retryNavigator != null) {
            try {
              // 重试时也使用相同的两层路由栈逻辑
              retryNavigator.pushNamedAndRemoveUntil('/', (route) => false);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final route = AppRoutes.generateRoute(
                  RouteSettings(name: routePath, arguments: arguments),
                );
                retryNavigator.push(route);
                debugPrint('重试导航成功');
              });
            } catch (e) {
              debugPrint('重试导航失败: $e');
            }
          } else {
            debugPrint('导航器初始化失败');
          }
        });
      }
    });
  } catch (e, stack) {
    debugPrint('处理小组件点击失败: $e');
    debugPrint('堆栈: $stack');
  }
}
