import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/notes/screens/notes_screen.dart';
import 'package:Memento/plugins/notes/screens/note_edit_screen.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:Memento/plugins/store/widgets/store_view/store_main.dart';
import 'package:Memento/plugins/store/widgets/product_items_page.dart';
import 'package:Memento/plugins/store/widgets/user_item_detail_page.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/plugins/todo/views/todo_bottombar_view.dart';
import 'package:Memento/plugins/timer/views/timer_task_details_page.dart';
import 'package:Memento/plugins/tts/screens/tts_services_screen.dart';
import 'package:Memento/plugins/webview/screens/webview_browser_screen.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';
import 'package:Memento/screens/settings_screen/settings_screen.dart';
import 'package:Memento/screens/js_console/js_console_screen.dart';
import 'package:Memento/screens/json_dynamic_test/json_dynamic_test_screen.dart';
import 'package:Memento/screens/notification_test/notification_test_page.dart';
import 'package:Memento/screens/floating_widget_screen/floating_widget_screen.dart';
import 'package:Memento/screens/data_selector_test/data_selector_test_screen.dart';
import 'package:Memento/screens/toast_test/toast_test_screen.dart';
import 'package:Memento/screens/test_screens/swipe_action_test_screen.dart';
import 'package:Memento/screens/settings_screen/screens/live_activities_test_screen.dart';
import 'package:Memento/screens/form_fields_test/form_fields_test_screen.dart';
import 'package:Memento/screens/widgets_gallery/widgets_gallery_screen.dart';
import 'package:Memento/screens/widgets_gallery/screens/color_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/icon_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/avatar_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/circle_icon_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/calendar_strip_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/image_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/location_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/backup_time_picker_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/memento_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/data_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/enhanced_calendar_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/group_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/simple_group_selector_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/tag_manager_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/statistics_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/custom_dialog_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/smooth_bottom_sheet_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/file_preview_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/app_drawer_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/widget_config_editor_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/preset_edit_form_example.dart';
import 'package:Memento/screens/widgets_gallery/screens/super_cupertino_navigation_example.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:get/get.dart';

// 插件路由导入
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/screens/activity_weekly_config_screen.dart';
import 'package:Memento/plugins/activity/screens/activity_daily_config_screen.dart';
import 'package:Memento/plugins/activity/screens/tag_statistics_screen.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/chat_screen.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/bill/screens/bill_edit_screen.dart';
import 'package:Memento/plugins/bill/screens/bill_shortcuts_selector_screen.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar/screens/calendar_month_selector_screen.dart';
import 'package:Memento/plugins/calendar/widgets/event_detail_card.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/plugins/calendar_album/screens/calendar_album_weekly_selector_screen.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/contact/widgets/contact_form.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/screens/habit_timer_selector_screen.dart';
import 'package:Memento/plugins/habits/screens/habits_weekly_config_screen.dart';
import 'package:Memento/plugins/habits/screens/habit_group_list_selector_screen.dart';
import 'package:Memento/plugins/habits/widgets/timer_dialog.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/scripts_center/scripts_center_plugin.dart';
import 'package:Memento/plugins/timer/views/timer_main_view.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:Memento/plugins/tracker/screens/tracker_goal_selector_screen.dart';
import 'package:Memento/plugins/tracker/screens/tracker_goal_progress_selector_screen.dart';

// 插件路由处理器导入
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/checkin/checkin_route_handler.dart';
import 'package:Memento/plugins/todo/todo_route_handler.dart';
import 'package:Memento/plugins/goods/goods_route_handler.dart';
import 'package:Memento/plugins/habits/habits_route_handler.dart';
import 'package:Memento/plugins/tracker/tracker_route_handler.dart';

class AppRoutes extends NavigatorObserver {
  // 插件路由处理器列表
  static final List<PluginRouteHandler> _pluginRouteHandlers = [
    CheckinRouteHandler(),
    TodoRouteHandler(),
    GoodsRouteHandler(),
    HabitsRouteHandler(),
    TrackerRouteHandler(),
  ];

  // 判断是否可以返回上一级路由
  static bool canPop(BuildContext context) {
    final navigator = Navigator.of(context);
    // 如果当前路由是根路由(/)或者没有上一级路由，则不能返回
    return ModalRoute.of(context)?.settings.name != home && navigator.canPop();
  }

  // 路由路径常量
  static const String home = '/';
  static const String chat = '/chat';
  static const String diary = '/diary';
  static const String activity = '/activity';
  static const String checkin = '/checkin';
  static const String settings = '/settings';
  static const String jsConsole = '/js_console';
  static const String jsonDynamicTest = '/json_dynamic_test';
  static const String notificationTest = '/notification_test';
  static const String superCupertinoTest = '/super_cupertino_test';
  static const String overlayTest = '/overlay_test';
  static const String formFieldsTest = '/form_fields_test';
  static const String widgetsGallery = '/widgets_gallery';

  // 插件路由路径
  static const String agentChat = '/agent_chat';
  static const String bill = '/bill';
  static const String calendar = '/calendar';
  static const String calendarAlbum = '/calendar_album';
  static const String contact = '/contact';
  static const String database = '/database';
  static const String day = '/day';
  static const String goods = '/goods';
  static const String habits = '/habits';
  static const String nodes = '/nodes';
  static const String tts = '/tts';
  static const String notes = '/notes';
  static const String notesCreate = '/notes/create';
  static const String openai = '/openai';
  static const String scriptsCenter = '/scripts_center';
  static const String store = '/store';
  static const String timer = '/timer';
  static const String todo = '/todo';
  static const String tracker = '/tracker';
  static const String floatingBall = '/floating_ball';
  static const String widgetsConfig = '/widgets_config';

  // Agent Chat 子页面路由
  static const String toolTemplate = '/tool_template';
  static const String toolManagement = '/tool_management';

  // 打卡小组件配置路由
  static const String checkinItemSelector = '/checkin_item_selector';

  // 待办列表小组件配置路由
  static const String todoListSelector = '/todo_list_selector';

  // 待办任务详情路由（从小组件打开）
  static const String todoTaskDetail = '/todo_task_detail';

  // 待办添加任务路由（从小组件打开）
  static const String todoAdd = '/todo_add';

  // 日历月视图小组件配置路由
  static const String calendarMonthSelector = '/calendar_month_selector';

  // 目标追踪进度增减小组件配置路由
  static const String trackerGoalSelector = '/tracker_goal_selector';

  // 目标追踪进度条小组件配置路由
  static const String trackerGoalProgressSelector =
      '/tracker_goal_progress_selector';

  // 习惯计时器小组件配置路由
  static const String habitTimerSelector = '/habit_timer_selector';

  // 快捷记账小组件配置路由
  static const String billShortcutsSelector = '/bill_shortcuts_selector';

  // 活动周视图小组件配置路由
  static const String activityWeeklyConfig = '/activity_weekly_config';

  // 活动日视图小组件配置路由
  static const String activityDailyConfig = '/activity_daily_config';

  // 习惯计时器对话框路由（从小组件打开）
  static const String habitTimerDialog = '/habit_timer_dialog';

  // 习惯分组列表小组件配置路由
  static const String habitGroupListSelector = '/habit_group_list_selector';

  // 每周相册小组件配置路由
  static const String calendarAlbumWeeklySelector =
      '/calendar_album_weekly_selector';

  // 标签统计页面路由（从小组件打开）
  static const String tagStatistics = '/tag_statistics';

  // 自定义页面过渡动画 - 无动画
  static Route _createRoute(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: Duration(milliseconds: 0),
      reverseTransitionDuration: Duration(milliseconds: 0),
    );
  }

  // 创建错误页面的辅助函数
  static Route _createErrorRoute(
    String titleKey,
    String messageKey, {
    String? messageParam,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        String title;
        String message;

        // 根据键获取本地化文本
        switch (titleKey) {
          case 'error':
            title = 'screens_error'.tr;
            break;
          default:
            title = titleKey;
        }

        switch (messageKey) {
          case 'errorWidgetIdMissing':
            message = 'screens_errorWidgetIdMissing'.tr;
            break;
          case 'errorHabitIdRequired':
            message = 'screens_errorHabitIdRequired'.tr;
            break;
          case 'errorHabitsPluginNotFound':
            message = 'screens_errorHabitsPluginNotFound'.tr;
            break;
          case 'errorHabitNotFound':
            message = 'screens_errorHabitNotFound'.trParams({
              'id': messageParam ?? '',
            });
            break;
          default:
            message = messageKey;
        }

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text(message)),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: Duration(milliseconds: 0),
      reverseTransitionDuration: Duration(milliseconds: 0),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // 尝试使用插件路由处理器处理路由
    for (final handler in _pluginRouteHandlers) {
      final route = handler.handleRoute(settings);
      if (route != null) {
        return route;
      }
    }

    // 如果插件路由处理器无法处理，使用原有的路由逻辑
    final routeName = settings.name ?? '/';

    switch (routeName) {
      case '/':
        return _createRoute(const HomeScreen());
      case '/tts':
      case 'tts':
        return _createRoute(const TTSServicesScreen());
      case '/diary':
      case 'diary':
        return _createRoute(const DiaryMainView(), settings: settings);
      case '/diary_detail':
      case 'diary_detail':
        // 支持通过 date 参数打开指定日期的日记
        DateTime? selectedDate;
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final dateStr = args['date'] as String?;
          if (dateStr != null) {
            try {
              selectedDate = DateTime.parse(dateStr);
            } catch (e) {
              debugPrint('解析日期失败: $e');
            }
          }
        }
        return _createRoute(DiaryMainView(initialDate: selectedDate), settings: settings);
      case '/activity':
      case 'activity':
        return _createRoute(const ActivityMainView());
      case '/checkin':
      case 'checkin':
        return _createRoute(const CheckinMainView());
      case '/settings':
      case 'settings':
        return _createRoute(const SettingsScreen());
      case '/agent_chat':
      case 'agent_chat':
        // 支持通过 conversationId 参数直接打开指定对话
        String? conversationId;
        if (settings.arguments is Map<String, String>) {
          conversationId =
              (settings.arguments as Map<String, String>)['conversationId'];
        } else if (settings.arguments is String) {
          conversationId = settings.arguments as String;
        }
        return _createRoute(AgentChatMainView(conversationId: conversationId));

      case '/agent_chat/chat':
      case 'agent_chat/chat':
        String? chatConversationId;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          chatConversationId = args['conversationId'] as String?;
        }

        if (chatConversationId == null) {
          debugPrint('错误: 缺少必需参数 conversationId');
          return _createRoute(const AgentChatMainView());
        }

        debugPrint('打开 Agent Chat 聊天页: conversationId=$chatConversationId');

        // 获取插件实例
        final agentChatPlugin = AgentChatPlugin.instance;
        final controller = agentChatPlugin.conversationController;

        if (controller == null) {
          debugPrint('错误: conversationController 未初始化');
          return _createRoute(const AgentChatMainView());
        }

        // 查找指定的会话
        try {
          final conversation = controller.conversations.firstWhere(
            (c) => c.id == chatConversationId,
          );

          return _createRoute(
            ChatScreen(
              conversation: conversation,
              storage: controller.storage,
              conversationService: controller.conversationService,
              getSettings: () => agentChatPlugin.settings,
            ),
          );
        } catch (e) {
          debugPrint('错误: 找不到会话 $chatConversationId');
          return _createRoute(const AgentChatMainView());
        }

      case '/bill':
      case 'bill':
        // 调试：打印传入的参数
        debugPrint('[Route] ========== /bill 路由开始 ==========');
        debugPrint('[Route] settings.name: ${settings.name}');
        debugPrint('[Route] settings.arguments: ${settings.arguments}');
        debugPrint('[Route] 参数类型: ${settings.arguments?.runtimeType}');

        // 获取 BillPlugin 实例
        final billPlugin =
            PluginManager.instance.getPlugin('bill') as BillPlugin?;

        if (billPlugin == null) {
          debugPrint('[Route] BillPlugin 未初始化，回退到主视图');
          return _createRoute(const BillMainView(), settings: settings);
        }

        // 检查参数并处理
        if (settings.arguments != null) {
          debugPrint('[Route] 开始解析参数...');
          Map<String, dynamic> args;
          try {
            args = Map<String, dynamic>.from(settings.arguments as Map);
          } catch (e) {
            debugPrint('[Route] 参数转换失败: $e，使用空 Map');
            args = {};
          }

          debugPrint('[Route] 解析后的参数: $args');

          // 1. 检查是否是创建账单动作（来自创建账单快捷入口小组件）
          if (args['action'] == 'create') {
            debugPrint('[Route] 检测到 action=create，开始创建账单');
            final String? accountId = args['accountId'] as String?;
            final bool? isExpense =
                args['isExpense'] != null
                    ? (args['isExpense'].toString().toLowerCase() == 'true')
                    : null;

            debugPrint('[Route] accountId: $accountId, isExpense: $isExpense');

            // 如果缺少 accountId，使用默认账户
            final finalAccountId = accountId ??
                (billPlugin.selectedAccount?.id ??
                 (billPlugin.accounts.isNotEmpty ? billPlugin.accounts.first.id : ''));

            if (finalAccountId.isEmpty) {
              debugPrint('[Route] 没有可用账户，回退到主视图');
              return _createRoute(const BillMainView(), settings: settings);
            }

            debugPrint('[Route] 打开 BillEditScreen，accountId: $finalAccountId');
            // 直接打开账单编辑页面（创建模式）
            return _createRoute(
              BillEditScreen(
                billPlugin: billPlugin,
                accountId: finalAccountId,
                initialIsExpense: isExpense,
              ),
              settings: settings,
            );
          }

          // 2. 检查是否来自快捷记账小组件（带有预填充参数）
          if (args.containsKey('category')) {
            debugPrint('[Route] 检测到 category 参数');
            final String? accountId = args['accountId'] as String?;
            final String? category = args['category'] as String?;
            final double? amount =
                args['amount'] != null
                    ? double.tryParse(args['amount'].toString())
                    : null;
            final bool? isExpense =
                args['isExpense'] != null
                    ? (args['isExpense'].toString().toLowerCase() == 'true')
                    : null;

            if (accountId == null || accountId.isEmpty) {
              debugPrint('[Route] 缺少 accountId 参数，回退到主视图');
              return _createRoute(const BillMainView(), settings: settings);
            }

            return _createRoute(
              BillEditScreen(
                billPlugin: billPlugin,
                accountId: accountId,
                initialCategory: category,
                initialAmount: amount,
                initialIsExpense: isExpense,
              ),
              settings: settings,
            );
          }

          debugPrint('[Route] 未匹配任何特殊参数，打开默认视图');
        }

        // 默认打开账单主视图
        debugPrint('[Route] 打开 BillMainView');
        return _createRoute(const BillMainView(), settings: settings);
      case '/calendar':
      case 'calendar':
        return _createRoute(const CalendarMainView());
      case '/calendar_album':
      case 'calendar_album':
        return _createRoute(const CalendarAlbumMainView());
      case '/contact':
      case 'contact':
        return _createRoute(const ContactMainView());
      case '/contact/detail':
      case 'contact/detail':
        // 联系人详情页（从小组件打开）
        String? contactId;
        if (settings.arguments is Map<String, dynamic>) {
          contactId = (settings.arguments as Map<String, dynamic>)['contactId'] as String?;
        }

        // 异步加载联系人数据并打开编辑表单
        if (contactId != null && contactId.isNotEmpty) {
          // 使用 FutureBuilder 来处理异步加载
          return _createRoute(
            _ContactDetailLoader(contactId: contactId),
          );
        }
        return _createRoute(const ContactMainView());
      case '/database':
      case 'database':
        return _createRoute(const DatabaseMainView());
      case '/day':
      case 'day':
        return _createRoute(const DayMainView());
      case '/goods':
      case 'goods':
        return _createRoute(const GoodsMainView());
      case '/habits':
      case 'habits':
        // 支持从小组件跳转并传递 habitId 参数
        String? habitId;
        if (settings.arguments is Map<String, dynamic>) {
          habitId = (settings.arguments as Map<String, dynamic>)['habitId'] as String?;
        }
        return _createRoute(HabitsMainView(habitId: habitId));
      case '/nodes':
      case 'nodes':
        return _createRoute(const NodesMainView());
      case '/notes':
      case 'notes':
        return _createRoute(const NotesMainView());
      case '/notes/create':
      case 'notes/create':
        // 快速创建笔记页面
        String? folderId;
        if (settings.arguments is Map<String, dynamic>) {
          folderId = (settings.arguments as Map<String, dynamic>)['folderId'] as String?;
        }
        return _createRoute(NoteEditScreen(
          onSave: (title, content) async {
            final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
            if (plugin != null) {
              await plugin.controller.createNote(
                title.isEmpty ? 'untitled'.tr : title,
                content,
                folderId ?? 'root',
              );
            }
          },
        ));
      case '/openai':
      case 'openai':
        return _createRoute(const OpenAIMainView());
      case '/scripts_center':
      case 'scripts_center':
        return _createRoute(const ScriptsCenterMainView());
      case '/store':
      case 'store':
        // 支持通过 itemId 参数跳转到用户物品详情
        String? itemId;
        bool autoUse = false;
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          itemId = args['itemId'] as String?;
          autoUse = args['autoUse'] as bool? ?? false;
        }
        debugPrint('[Route] /store: itemId=$itemId, autoUse=$autoUse');
        if (itemId != null) {
          return _createRoute(
            _StoreUserItemRoute(itemId: itemId, autoUse: autoUse),
          );
        }
        return _createRoute(const StoreMainView());
      case '/store/product_items':
      case 'store/product_items':
        // 商品物品列表页面
        String? productId;
        String? productName;
        bool autoUse = false;
        bool autoBuy = false;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          productId = args['productId'] as String?;
          productName = args['productName'] as String?;
          autoUse = args['autoUse'] as bool? ?? false;
          autoBuy = args['autoBuy'] as bool? ?? false;
        }

        if (productId == null) {
          debugPrint('错误: 缺少必需参数 productId');
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('参数错误：缺少商品ID')),
            ),
          );
        }

        debugPrint('打开商品物品列表: productId=$productId, productName=$productName, autoUse=$autoUse, autoBuy=$autoBuy');

        final storePlugin =
            PluginManager.instance.getPlugin('store') as StorePlugin?;
        if (storePlugin == null) {
          debugPrint('错误: Store 插件未初始化');
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('Store 插件未初始化')),
            ),
          );
        }

        return _createRoute(
          ProductItemsPage(
            productId: productId,
            productName: productName ?? '商品',
            controller: storePlugin.controller,
            autoUse: autoUse,
            autoBuy: autoBuy,
          ),
        );
      case '/store/user_item':
      case 'store/user_item':
        // 用户物品详情页面
        String? itemId;
        bool autoUse = false;
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          itemId = args['itemId'] as String?;
          autoUse = args['autoUse'] as bool? ?? false;
        }

        if (itemId == null) {
          debugPrint('错误: 缺少必需参数 itemId');
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('参数错误：缺少物品ID')),
            ),
          );
        }

        debugPrint('[Route] /store/user_item: itemId=$itemId, autoUse=$autoUse');

        final storePlugin =
            PluginManager.instance.getPlugin('store') as StorePlugin?;
        if (storePlugin == null) {
          debugPrint('错误: Store 插件未初始化');
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('Store 插件未初始化')),
            ),
          );
        }

        debugPrint('[Route] 当前 userItems 数量: ${storePlugin.controller.userItems.length}');
        for (var item in storePlugin.controller.userItems) {
          debugPrint('[Route]  - item.id: ${item.id} (类型: ${item.id.runtimeType})');
        }

        // 根据 itemId 查找用户物品
        final userItem = storePlugin.controller.userItems.firstWhereOrNull(
          (item) => item.id.toString() == itemId.toString(),
        );

        if (userItem == null) {
          debugPrint('[Route] 物品不存在: itemId=$itemId');
          return _createRoute(
            const Scaffold(
              body: Center(child: Text('物品不存在')),
            ),
          );
        }

        debugPrint('[Route] 创建 UserItemDetailPage: autoUse=$autoUse, itemName=${userItem.productName}');
        return _createRoute(
          UserItemDetailPage(
            controller: storePlugin.controller,
            items: [userItem],
            initialIndex: 0,
            autoUse: autoUse,
          ),
        );
      case '/timer':
      case 'timer':
        return _createRoute(const TimerMainView());
      case '/timer_details':
        final arguments = settings.arguments as Map<String, dynamic>?;
        final taskId = arguments?['taskId'] as String?;
        if (taskId != null) {
          return _createRoute(_TimerDetailsRoute(taskId: taskId));
        }
        return _createRoute(const TimerMainView());
      case '/todo':
      case 'todo':
        return _createRoute(const TodoBottomBarView());
      case '/tracker':
      case 'tracker':
        // 支持通过 goalId 参数跳转到目标详情页面
        String? goalId;
        if (settings.arguments is Map<String, dynamic>) {
          goalId = (settings.arguments as Map<String, dynamic>)['goalId'] as String?;
        }
        debugPrint('[Route] /tracker: goalId=$goalId');

        // 如果有 goalId，直接打开目标详情页面
        if (goalId != null) {
          return _createRoute(
            GoalDetailScreen(goalId: goalId),
            settings: settings,
          );
        }
        // 没有 goalId，打开主视图
        return _createRoute(const TrackerMainView());
      case '/floating_ball':
      case 'floating_ball':
        return _createRoute(const FloatingBallScreen());
      case '/js_console':
      case 'js_console':
        return _createRoute(const JSConsoleScreen());
      case '/json_dynamic_test':
      case 'json_dynamic_test':
        return _createRoute(const JsonDynamicTestScreen());
      case '/notification_test':
      case 'notification_test':
        return _createRoute(const NotificationTestPage());
      case '/data_selector_test':
      case 'data_selector_test':
        return _createRoute(const DataSelectorTestScreen());
      case '/toast_test':
      case 'toast_test':
        return _createRoute(const ToastTestScreen());
      case '/swipe_action_test':
      case 'swipe_action_test':
        return _createRoute(const SwipeActionTestScreen());
      case '/live_activities_test':
      case 'live_activities_test':
        return _createRoute(const LiveActivitiesTestScreen());
      case '/form_fields_test':
      case 'form_fields_test':
        return _createRoute(const FormFieldsTestScreen());
      case '/widgets_gallery':
      case 'widgets_gallery':
        return _createRoute(const WidgetsGalleryScreen());
      case '/widgets_gallery/color_picker':
        return _createRoute(const ColorPickerExample());
      case '/widgets_gallery/icon_picker':
        return _createRoute(const IconPickerExample());
      case '/widgets_gallery/avatar_picker':
        return _createRoute(const AvatarPickerExample());
      case '/widgets_gallery/circle_icon_picker':
        return _createRoute(const CircleIconPickerExample());
      case '/widgets_gallery/calendar_strip_picker':
        return _createRoute(const CalendarStripPickerExample());
      case '/widgets_gallery/image_picker':
        return _createRoute(const ImagePickerExample());
      case '/widgets_gallery/location_picker':
        return _createRoute(const LocationPickerExample());
      case '/widgets_gallery/backup_time_picker':
        return _createRoute(const BackupTimePickerExample());
      case '/widgets_gallery/memento_editor':
        return _createRoute(const MementoEditorExample());
      case '/widgets_gallery/data_selector':
        return _createRoute(const DataSelectorExample());
      case '/widgets_gallery/enhanced_calendar':
        return _createRoute(const EnhancedCalendarExample());
      case '/widgets_gallery/group_selector':
        return _createRoute(const GroupSelectorExample());
      case '/widgets_gallery/simple_group_selector':
        return _createRoute(const SimpleGroupSelectorExample());
      case '/widgets_gallery/tag_manager':
        return _createRoute(const TagManagerExample());
      case '/widgets_gallery/statistics':
        return _createRoute(const StatisticsExample());
      case '/widgets_gallery/custom_dialog':
        return _createRoute(const CustomDialogExample());
      case '/widgets_gallery/smooth_bottom_sheet':
        return _createRoute(const SmoothBottomSheetExample());
      case '/widgets_gallery/file_preview':
        return _createRoute(const FilePreviewExample());
      case '/widgets_gallery/app_drawer':
        return _createRoute(const AppDrawerExample());
      case '/widgets_gallery/widget_config_editor':
        return _createRoute(const WidgetConfigEditorExample());
      case '/widgets_gallery/preset_edit_form':
        return _createRoute(const PresetEditFormExample());
      case '/widgets_gallery/super_cupertino_navigation':
        return _createRoute(const SuperCupertinoNavigationExample());
      case '/chat':
      case 'chat':
        // 支持通过 channelId 参数直接打开指定频道
        String? channelId;
        if (settings.arguments is Map<String, String>) {
          channelId = (settings.arguments as Map<String, String>)['channelId'];
        } else if (settings.arguments is String) {
          channelId = settings.arguments as String;
        }
        return _createRoute(ChatMainView(channelId: channelId));

      case '/chat/channel':
      case 'chat/channel':
        // 专门用于从选择器小组件导航到频道
        String? chatChannelId;

        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          chatChannelId = args['channelId'] as String?;
        }

        if (chatChannelId == null) {
          debugPrint('错误: 缺少必需参数 channelId');
          return _createRoute(const ChatMainView());
        }

        debugPrint('打开 Chat 频道: channelId=$chatChannelId');
        return _createRoute(ChatMainView(channelId: chatChannelId));

      case '/calendar_month_selector':
      case 'calendar_month_selector':
        // 日历月视图小组件配置界面
        int? widgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            widgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            widgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          widgetId = settings.arguments as int;
        }

        return _createRoute(CalendarMonthSelectorScreen(widgetId: widgetId));
      case '/tracker_goal_selector':
      case 'tracker_goal_selector':
        // 目标追踪进度增减小组件配置界面
        int? trackerWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            trackerWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            trackerWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          trackerWidgetId = settings.arguments as int;
        }

        return _createRoute(
          TrackerGoalSelectorScreen(widgetId: trackerWidgetId),
        );
      case '/tracker_goal_progress_selector':
      case 'tracker_goal_progress_selector':
        // 目标追踪进度条小组件配置界面
        int? trackerProgressWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            trackerProgressWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            trackerProgressWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          trackerProgressWidgetId = settings.arguments as int;
        }

        return _createRoute(
          TrackerGoalProgressSelectorScreen(widgetId: trackerProgressWidgetId),
        );
      case '/habit_timer_selector':
      case 'habit_timer_selector':
        // 习惯计时器小组件配置界面
        int? habitTimerWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            habitTimerWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            habitTimerWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          habitTimerWidgetId = settings.arguments as int;
        }

        return _createRoute(
          HabitTimerSelectorScreen(widgetId: habitTimerWidgetId),
        );
      case '/bill_shortcuts_selector':
      case 'bill_shortcuts_selector':
        // 快捷记账小组件配置界面
        int? billShortcutsWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            billShortcutsWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            billShortcutsWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          billShortcutsWidgetId = settings.arguments as int;
        }

        return _createRoute(
          BillShortcutsSelectorScreen(widgetId: billShortcutsWidgetId ?? 0),
        );
      case '/activity_weekly_config':
      case 'activity_weekly_config':
        // 活动周视图小组件配置界面
        int? activityWeeklyWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            activityWeeklyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            activityWeeklyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          activityWeeklyWidgetId = settings.arguments as int;
        }

        if (activityWeeklyWidgetId == null) {
          return _createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return _createRoute(
          ActivityWeeklyConfigScreen(widgetId: activityWeeklyWidgetId),
        );
      case '/activity_daily_config':
      case 'activity_daily_config':
        // 活动日视图小组件配置界面
        int? activityDailyWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            activityDailyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            activityDailyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          activityDailyWidgetId = settings.arguments as int;
        }

        if (activityDailyWidgetId == null) {
          return _createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return _createRoute(
          ActivityDailyConfigScreen(widgetId: activityDailyWidgetId),
        );
      case '/habits_weekly_config':
      case 'habits_weekly_config':
        // 习惯周视图小组件配置界面
        int? habitsWeeklyWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            habitsWeeklyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            habitsWeeklyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          habitsWeeklyWidgetId = settings.arguments as int;
        }

        if (habitsWeeklyWidgetId == null) {
          return _createErrorRoute('error', 'errorWidgetIdMissing');
        }

        return _createRoute(
          HabitsWeeklyConfigScreen(widgetId: habitsWeeklyWidgetId),
        );
      case '/habit_group_list_selector':
      case 'habit_group_list_selector':
        // 习惯分组列表小组件配置界面
        int? habitGroupListWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            habitGroupListWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            habitGroupListWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          habitGroupListWidgetId = settings.arguments as int;
        }

        return _createRoute(
          HabitGroupListSelectorScreen(widgetId: habitGroupListWidgetId),
        );
      case '/calendar_album_weekly_selector':
      case 'calendar_album_weekly_selector':
        // 每周相册小组件配置界面
        int? weeklyWidgetId;

        // 从 arguments 中解析 widgetId
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          // widgetId 可能是字符串或整数
          final widgetIdValue = args['widgetId'];
          if (widgetIdValue is int) {
            weeklyWidgetId = widgetIdValue;
          } else if (widgetIdValue is String) {
            weeklyWidgetId = int.tryParse(widgetIdValue);
          }
        } else if (settings.arguments is int) {
          weeklyWidgetId = settings.arguments as int;
        }

        return _createRoute(
          CalendarAlbumWeeklySelectorScreen(widgetId: weeklyWidgetId),
        );
      case '/habit_timer_dialog':
      case 'habit_timer_dialog':
        // 习惯计时器对话框（从小组件打开）
        String? habitId;

        // 从 arguments 中解析 habitId
        if (settings.arguments is Map<String, dynamic>) {
          habitId = (settings.arguments as Map<String, dynamic>)['habitId'];
        } else if (settings.arguments is String) {
          habitId = settings.arguments as String;
        }

        if (habitId == null) {
          return _createErrorRoute('error', 'errorHabitIdRequired');
        }

        // 获取 HabitsPlugin 实例
        final habitsPlugin =
            PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
        if (habitsPlugin == null) {
          return _createErrorRoute('error', 'errorHabitsPluginNotFound');
        }

        // 查找对应的 Habit
        final habitController = habitsPlugin.getHabitController();
        final habits = habitController.getHabits();
        final habit = habits.cast<dynamic>().firstWhere(
          (h) => h.id == habitId,
          orElse: () => null,
        );

        if (habit == null) {
          return _createErrorRoute(
            'error',
            'errorHabitNotFound',
            messageParam: habitId,
          );
        }

        // 返回包含 TimerDialog 的页面
        return _createRoute(
          Scaffold(
            backgroundColor: Colors.black.withOpacity(0.5),
            body: Center(
              child: TimerDialog(
                habit: habit,
                controller: habitController,
                initialTimerData: habitsPlugin.timerController.getTimerData(
                  habitId,
                ),
              ),
            ),
          ),
        );
      case '/calendar_month/event':
      case 'calendar_month/event':
        // 日历事件详情路由（从桌面小组件打开）
        String? eventId;

        // 从 arguments 中解析 eventId
        if (settings.arguments is Map<String, String>) {
          eventId = (settings.arguments as Map<String, String>)['eventId'];
        } else if (settings.arguments is Map<String, dynamic>) {
          eventId =
              (settings.arguments as Map<String, dynamic>)['eventId']
                  as String?;
        }

        // 备用：从 URI 中解析 eventId
        if (eventId == null) {
          final uri = Uri.parse(settings.name ?? '');
          eventId = uri.queryParameters['eventId'];
        }

        debugPrint('打开日历事件详情: eventId=$eventId');

        if (eventId == null) {
          // 没有 eventId 参数，回退到日历主视图
          return _createRoute(const CalendarMainView());
        }

        // 获取日历插件实例
        final calendarPlugin = CalendarPlugin.instance;
        if (calendarPlugin == null) {
          debugPrint('CalendarPlugin 未初始化，回退到主视图');
          return _createRoute(const CalendarMainView());
        }

        // 从日历控制器中查找事件
        final calendarController = calendarPlugin.controller;
        List<CalendarEvent> allEvents = calendarController.getAllEvents();

        CalendarEvent? event =
            allEvents.where((e) => e.id == eventId).isNotEmpty
                ? allEvents.firstWhere((e) => e.id == eventId)
                : null;

        // 如果在日历中找不到事件，尝试从Todo插件中查找（针对todo_前缀的ID）
        if (event == null && eventId.startsWith('todo_')) {
          final todoPlugin = TodoPlugin.instance;
          // 提取真正的任务ID（去掉 todo_ 前缀）
          final taskId = eventId.substring(5);
          final task =
              todoPlugin.taskController.tasks
                      .where((t) => t.id == taskId)
                      .isNotEmpty
                  ? todoPlugin.taskController.tasks.firstWhere(
                    (t) => t.id == taskId,
                  )
                  : null;

          if (task != null) {
            // 将 Todo 任务转换为 CalendarEvent
            event = _convertTaskToEvent(task);
          }
        }

        if (event != null) {
          // 找到事件，显示详情对话框
          final isTodoEvent = event.source == 'todo';
          final taskId = isTodoEvent ? event.id.substring(5) : null;

          // 确保 event 是 non-nullable
          final CalendarEvent eventData = event;

          return _createRoute(
            Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: EventDetailCard(
                  event: eventData,
                  onEdit: () {
                    // 编辑事件
                    Navigator.of(navigatorKey.currentContext!).pop();
                    if (isTodoEvent && taskId != null) {
                      // Todo 任务事件不允许编辑
                      Toast.warning('任务事件不支持编辑，请前往待办事项中修改');
                    } else {
                      // 普通日历事件可以编辑
                      calendarPlugin.showEventEditPage(
                        navigatorKey.currentContext!,
                        eventData,
                      );
                    }
                  },
                  onComplete: () {
                    // 标记事件为完成
                    Navigator.of(navigatorKey.currentContext!).pop();
                    if (isTodoEvent && taskId != null) {
                      // Todo 任务事件：标记任务为完成
                      final todoPlugin = TodoPlugin.instance;
                      todoPlugin.taskController.updateTaskStatus(
                        taskId,
                        TaskStatus.done,
                      );
                    } else {
                      // 普通日历事件
                      calendarController.completeEvent(eventData);
                    }
                  },
                  onDelete: () {
                    // 删除事件
                    Navigator.of(navigatorKey.currentContext!).pop();
                    if (isTodoEvent && taskId != null) {
                      // Todo 任务事件：删除任务
                      final todoPlugin = TodoPlugin.instance;
                      todoPlugin.taskController.updateTaskStatus(
                        taskId,
                        TaskStatus.done,
                      );
                      Toast.success('任务已完成并移入历史记录');
                    } else {
                      // 普通日历事件
                      calendarController.deleteEvent(eventData);
                    }
                  },
                ),
              ),
            ),
          );
        }

        // 没有找到事件，回退到日历主视图
        debugPrint('未找到事件: $eventId');
        return _createRoute(const CalendarMainView());
      case '/tag_statistics':
      case 'tag_statistics':
        // 标签统计页面（从桌面小组件打开）
        String? tagName;

        // 从 arguments 中解析 tag 参数
        if (settings.arguments is Map<String, dynamic>) {
          tagName =
              (settings.arguments as Map<String, dynamic>)['tag'] as String?;
        } else if (settings.arguments is String) {
          tagName = settings.arguments as String;
        }

        debugPrint('打开标签统计页面: tag=$tagName');

        if (tagName == null || tagName.isEmpty) {
          // 没有 tag 参数，回退到活动插件主页
          return _createRoute(const ActivityMainView());
        }

        // 获取活动插件实例
        final activityPlugin =
            PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
        if (activityPlugin == null) {
          debugPrint('ActivityPlugin 未初始化，回退到主视图');
          return _createRoute(const ActivityMainView());
        }

        // 返回标签统计页面
        return _createRoute(
          TagStatisticsScreen(
            tagName: tagName,
            activityService: activityPlugin.activityService,
          ),
        );
      case '/webview/browser':
      case 'webview/browser':
        // WebView 浏览器页面
        String? url;
        String? title;
        String? cardId;

        // 从 arguments 中解析参数
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          url = args['url'] as String?;
          title = args['title'] as String?;
          cardId = args['cardId'] as String?;
        }

        debugPrint('打开 WebView 浏览器: url=$url, cardId=$cardId');

        return _createRoute(
          WebViewBrowserScreen(
            initialUrl: url,
            initialTitle: title,
            cardId: cardId,
          ),
        );
      default:
        return _createRoute(
          Scaffold(body: Center(child: CircularProgressIndicator())),
        );
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const HomeScreen(),
    chat: (context) => const ChatMainView(),
    diary: (context) => const DiaryMainView(),
    activity: (context) => const ActivityMainView(),
    checkin: (context) => const CheckinMainView(),
    settings: (context) => const SettingsScreen(),
    agentChat: (context) => const AgentChatMainView(),
    bill: (context) => const BillMainView(),
    calendar: (context) => const CalendarMainView(),
    contact: (context) => const ContactMainView(),
    database: (context) => const DatabaseMainView(),
    tts: (context) => const TTSServicesScreen(),
    day: (context) => const DayMainView(),
    goods: (context) => const GoodsMainView(),
    habits: (context) => const HabitsMainView(),
    store: (context) => const StoreMainView(),
    calendarAlbum: (context) => const CalendarAlbumMainView(),
    nodes: (context) => const NodesMainView(),
    notes: (context) => const NotesMainView(),
    openai: (context) => const OpenAIMainView(),
    scriptsCenter: (context) => const ScriptsCenterMainView(),
    timer: (context) => const TimerMainView(),
    todo: (context) => const TodoBottomBarView(),
    floatingBall: (context) => const FloatingBallScreen(),
    activityDailyConfig:
        (context) => const ActivityDailyConfigScreen(widgetId: 0),
    jsConsole: (context) => const JSConsoleScreen(),
    jsonDynamicTest: (context) => const JsonDynamicTestScreen(),
    notificationTest: (context) => const NotificationTestPage(),
    'data_selector_test': (context) => const DataSelectorTestScreen(),
    'live_activities_test': (context) => const LiveActivitiesTestScreen(),
  };

  static String get initialRoute => home;
}

/// 计时器详情页面路由
class _TimerDetailsRoute extends StatelessWidget {
  final String taskId;

  const _TimerDetailsRoute({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return TimerTaskDetailsPage(taskId: taskId);
  }
}

/// 将 Todo 任务转换为日历事件
CalendarEvent _convertTaskToEvent(Task task) {
  // 根据任务优先级设置颜色
  Color priorityColor;
  switch (task.priority) {
    case TaskPriority.high:
      priorityColor = Colors.red.shade300;
      break;
    case TaskPriority.medium:
      priorityColor = Colors.orange.shade300;
      break;
    case TaskPriority.low:
      priorityColor = Colors.blue.shade300;
      break;
  }

  // 设置图标（使用任务状态图标）
  IconData iconData;
  switch (task.status) {
    case TaskStatus.todo:
      iconData = Icons.radio_button_unchecked;
      break;
    case TaskStatus.inProgress:
      iconData = Icons.play_circle_outline;
      break;
    case TaskStatus.done:
      iconData = Icons.check_circle_outline;
      break;
  }

  return CalendarEvent(
    id: 'todo_${task.id}',
    title: task.title,
    description: task.description ?? '',
    startTime: task.startDate ?? task.dueDate ?? DateTime.now(),
    endTime: task.dueDate,
    icon: iconData,
    color: priorityColor,
    source: 'todo', // 标记为来自 Todo 插件
  );
}

/// Store 插件用户物品详情路由
class _StoreUserItemRoute extends StatelessWidget {
  final String itemId;
  final bool autoUse;

  const _StoreUserItemRoute({required this.itemId, this.autoUse = false});

  @override
  Widget build(BuildContext context) {
    debugPrint('[Route] _StoreUserItemRoute.build: itemId=$itemId, autoUse=$autoUse');
    final storePlugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
    if (storePlugin == null) {
      debugPrint('[Route] Store 插件未初始化');
      return const Scaffold(
        body: Center(child: Text('Store 插件未初始化')),
      );
    }

    // 根据 itemId 查找用户物品
    final userItem = storePlugin.controller.userItems.firstWhereOrNull(
      (item) => item.id == itemId,
    );

    if (userItem == null) {
      debugPrint('[Route] 物品不存在: itemId=$itemId');
      return const Scaffold(
        body: Center(child: Text('物品不存在')),
      );
    }

    debugPrint('[Route] 创建 UserItemDetailPage: autoUse=$autoUse');
    return UserItemDetailPage(
      controller: storePlugin.controller,
      items: [userItem],
      initialIndex: 0,
      autoUse: autoUse,
    );
  }
}

/// 联系人详情页加载器
/// 用于从小组件导航到联系人编辑页面
class _ContactDetailLoader extends StatelessWidget {
  final String contactId;

  const _ContactDetailLoader({required this.contactId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContactPlugin?>(
      future: _loadContactPlugin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final plugin = snapshot.data;
        if (plugin == null) {
          return Scaffold(
            body: Center(
              child: Text('contact_pluginNotFound'.tr),
            ),
          );
        }

        return FutureBuilder<Contact?>(
          future: plugin.controller.getContact(contactId),
          builder: (context, contactSnapshot) {
            if (contactSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final contact = contactSnapshot.data;
            if (contact == null) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('contact_notFound'.tr),
                    ],
                  ),
                ),
              );
            }

            // 导航到联系人编辑表单
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ContactForm(
                    contact: contact,
                    onSave: (savedContact) async {
                      await plugin.controller.updateContact(savedContact);
                    },
                  ),
                ),
              );
            });

            // 显示加载界面
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  Future<ContactPlugin?> _loadContactPlugin() async {
    return PluginManager.instance.getPlugin('contact') as ContactPlugin?;
  }
}
