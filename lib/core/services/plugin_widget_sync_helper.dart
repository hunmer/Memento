import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:memento_widgets/memento_widgets.dart';
import 'system_widget_service.dart';
import '../plugin_manager.dart';

// 导入所有插件
import '../../plugins/todo/todo_plugin.dart';
import '../../plugins/timer/timer_plugin.dart';
import '../../plugins/bill/bill_plugin.dart';
import '../../plugins/calendar/calendar_plugin.dart';
import '../../plugins/activity/activity_plugin.dart';
import '../../plugins/tracker/tracker_plugin.dart';
import '../../plugins/habits/habits_plugin.dart';
import '../../plugins/diary/diary_plugin.dart';
import '../../plugins/checkin/checkin_plugin.dart';
import '../../plugins/nodes/nodes_plugin.dart';
import '../../plugins/database/database_plugin.dart';
import '../../plugins/contact/contact_plugin.dart';
import '../../plugins/day/day_plugin.dart';
import '../../plugins/goods/goods_plugin.dart';
import '../../plugins/notes/notes_plugin.dart';
import '../../plugins/store/store_plugin.dart';
import '../../plugins/openai/openai_plugin.dart';
import '../../plugins/agent_chat/agent_chat_plugin.dart';
import '../../plugins/calendar_album/calendar_album_plugin.dart';
import '../../plugins/chat/chat_plugin.dart';

/// 插件小组件同步帮助类
///
/// 提供统一的方式来同步所有插件的小组件数据
class PluginWidgetSyncHelper {
  static final PluginWidgetSyncHelper _instance = PluginWidgetSyncHelper._internal();
  factory PluginWidgetSyncHelper() => _instance;
  PluginWidgetSyncHelper._internal();

  static PluginWidgetSyncHelper get instance => _instance;

  /// 同步所有插件的小组件数据
  Future<void> syncAllPlugins() async {
    // 检查平台是否支持小组件
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping all widget sync');
      return;
    }

    await Future.wait([
      syncTodo(),
      syncTimer(),
      syncBill(),
      syncCalendar(),
      syncActivity(),
      syncTracker(),
      syncHabits(),
      syncDiary(),
      syncCheckin(),
      syncNodes(),
      syncDatabase(),
      syncContact(),
      syncDay(),
      syncGoods(),
      syncNotes(),
      syncStore(),
      syncOpenai(),
      syncAgentChat(),
      syncCalendarAlbum(),
      syncChat(),
      syncCheckinItemWidget(),
    ]);
  }

  /// 同步待办事项插件
  Future<void> syncTodo() async {
    try {
      final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
      if (plugin == null) return;

      final totalTasks = plugin.taskController.getTotalTaskCount();
      final incompleteTasks = plugin.taskController.getIncompleteTaskCount();

      await _updateWidget(
        pluginId: 'todo',
        pluginName: '待办事项',
        iconCodePoint: Icons.check_box.codePoint,
        colorValue: Colors.blue.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总任务', value: '$totalTasks'),
          WidgetStatItem(
            id: 'incomplete',
            label: '未完成',
            value: '$incompleteTasks',
            highlight: incompleteTasks > 0,
            colorValue: incompleteTasks > 0 ? Colors.orange.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync todo widget: $e');
    }
  }

  /// 同步计时器插件
  Future<void> syncTimer() async {
    try {
      final plugin = PluginManager.instance.getPlugin('timer') as TimerPlugin?;
      if (plugin == null) return;

      final tasks = plugin.getTasks();
      final totalCount = tasks.length;
      final runningCount = tasks.where((task) => task.isRunning).length;

      await _updateWidget(
        pluginId: 'timer',
        pluginName: '计时器',
        iconCodePoint: Icons.timer.codePoint,
        colorValue: Colors.blueGrey.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总计时器', value: '$totalCount'),
          WidgetStatItem(
            id: 'running',
            label: '运行中',
            value: '$runningCount',
            highlight: runningCount > 0,
            colorValue: runningCount > 0 ? Colors.green.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync timer widget: $e');
    }
  }

  /// 同步账单插件
  Future<void> syncBill() async {
    try {
      final plugin = PluginManager.instance.getPlugin('bill') as BillPlugin?;
      if (plugin == null) return;

      final todayFinance = plugin.controller.getTodayFinance();
      final monthFinance = plugin.controller.getMonthFinance();

      await _updateWidget(
        pluginId: 'bill',
        pluginName: '账单',
        iconCodePoint: Icons.account_balance_wallet.codePoint,
        colorValue: Colors.green.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日',
            value: '¥${todayFinance.toStringAsFixed(0)}',
            colorValue: todayFinance >= 0 ? Colors.green.value : Colors.red.value,
          ),
          WidgetStatItem(
            id: 'month',
            label: '本月',
            value: '¥${monthFinance.toStringAsFixed(0)}',
            colorValue: monthFinance >= 0 ? Colors.green.value : Colors.red.value,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync bill widget: $e');
    }
  }

  /// 同步日历插件
  Future<void> syncCalendar() async {
    try {
      final plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (plugin == null) return;

      // 获取统计数据
      final todayCount = plugin.getTodayEventCount();
      final weekCount = plugin.getWeekEventCount();
      final pendingCount = plugin.getPendingEventCount();

      await _updateWidget(
        pluginId: 'calendar',
        pluginName: '日历',
        iconCodePoint: Icons.calendar_today.codePoint,
        colorValue: Colors.teal.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日事件',
            value: '$todayCount',
            highlight: todayCount > 0,
            colorValue: todayCount > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'week',
            label: '本周事件',
            value: '$weekCount',
          ),
          WidgetStatItem(
            id: 'pending',
            label: '待办事件',
            value: '$pendingCount',
            highlight: pendingCount > 0,
            colorValue: pendingCount > 0 ? Colors.orange.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync calendar widget: $e');
    }
  }

  /// 同步活动记录插件
  Future<void> syncActivity() async {
    // 检查平台是否支持小组件
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for activity');
      return;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('activity') as ActivityPlugin?;
      if (plugin == null) return;

      // 获取今日统计数据
      final activityCount = await plugin.getTodayActivityCount();
      final durationMinutes = await plugin.getTodayActivityDuration();
      final remainingMinutes = plugin.getTodayRemainingTime();

      // 转换为小时（保留一位小数）
      final durationHours = (durationMinutes / 60.0).toStringAsFixed(1);
      final remainingHours = (remainingMinutes / 60.0).toStringAsFixed(1);

      // 计算记录覆盖率
      final totalDayMinutes = 24 * 60;
      final coveragePercent = (durationMinutes / totalDayMinutes * 100).toStringAsFixed(0);

      await _updateWidget(
        pluginId: 'activity',
        pluginName: '活动',
        iconCodePoint: Icons.timeline.codePoint,
        colorValue: Colors.purple.value,
        stats: [
          WidgetStatItem(id: 'count', label: '今日活动', value: '$activityCount'),
          WidgetStatItem(id: 'duration', label: '已记录', value: '${durationHours}h'),
          WidgetStatItem(
            id: 'remaining',
            label: '剩余时间',
            value: '${remainingHours}h',
            highlight: remainingMinutes < 120,
            colorValue: remainingMinutes < 120 ? Colors.red.value : null,
          ),
          WidgetStatItem(id: 'coverage', label: '覆盖率', value: '$coveragePercent%'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync activity widget: $e');
    }
  }

  /// 同步目标追踪插件
  Future<void> syncTracker() async {
    try {
      final plugin = PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;
      if (plugin == null) return;

      // 获取统计数据
      final totalGoals = plugin.getGoalCount();
      final activeGoals = plugin.getActiveGoalCount();
      final todayRecords = plugin.getTodayRecordCount();

      await _updateWidget(
        pluginId: 'tracker',
        pluginName: '目标',
        iconCodePoint: Icons.track_changes.codePoint,
        colorValue: Colors.orange.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总目标数', value: '$totalGoals'),
          WidgetStatItem(
            id: 'active',
            label: '进行中',
            value: '$activeGoals',
            highlight: activeGoals > 0,
            colorValue: activeGoals > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'records',
            label: '今日记录',
            value: '$todayRecords',
            highlight: todayRecords > 0,
            colorValue: todayRecords > 0 ? Colors.green.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync tracker widget: $e');
    }
  }

  /// 同步习惯插件
  Future<void> syncHabits() async {
    // 检查平台是否支持小组件
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for habits');
      return;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('habits') as HabitsPlugin?;
      if (plugin == null) return;

      final habitCount = plugin.getHabitController().getHabits().length;
      final skillCount = plugin.getSkillController().getSkills().length;

      await _updateWidget(
        pluginId: 'habits',
        pluginName: '习惯',
        iconCodePoint: Icons.auto_awesome.codePoint,
        colorValue: Colors.amber.value,
        stats: [
          WidgetStatItem(id: 'habits', label: '习惯', value: '$habitCount'),
          WidgetStatItem(id: 'skills', label: '技能', value: '$skillCount'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync habits widget: $e');
    }
  }

  /// 同步日记插件
  Future<void> syncDiary() async {
    // 检查平台是否支持小组件
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for diary');
      return;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('diary') as DiaryPlugin?;
      if (plugin == null) return;

      final todayCount = await plugin.getTodayWordCount();
      final monthCount = await plugin.getMonthWordCount();
      final progress = await plugin.getMonthProgress();
      final completedDays = progress.$1;
      final totalDays = progress.$2;

      await _updateWidget(
        pluginId: 'diary',
        pluginName: '日记',
        iconCodePoint: Icons.book.codePoint,
        colorValue: Colors.brown.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日字数',
            value: '$todayCount',
            highlight: todayCount > 0,
            colorValue: todayCount > 0 ? Colors.deepOrange.value : null,
          ),
          WidgetStatItem(
            id: 'month',
            label: '本月字数',
            value: '$monthCount',
          ),
          WidgetStatItem(
            id: 'progress',
            label: '本月进度',
            value: '$completedDays/$totalDays',
            highlight: completedDays == totalDays,
            colorValue: completedDays == totalDays ? Colors.green.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync diary widget: $e');
    }
  }

  /// 同步签到插件
  Future<void> syncCheckin() async {
    // 检查平台是否支持小组件
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for checkin');
      return;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) return;

      final todayCount = plugin.getTodayCheckins();
      final totalItems = plugin.checkinItems.length;
      final totalCheckins = plugin.getTotalCheckins();

      // 计算最大连续天数
      int maxConsecutiveDays = 0;
      for (final item in plugin.checkinItems) {
        final consecutive = item.getConsecutiveDays();
        if (consecutive > maxConsecutiveDays) {
          maxConsecutiveDays = consecutive;
        }
      }

      await _updateWidget(
        pluginId: 'checkin',
        pluginName: '签到',
        iconCodePoint: Icons.check_circle.codePoint,
        colorValue: Colors.teal.value,
        stats: [
          WidgetStatItem(
            id: 'today',
            label: '今日完成',
            value: '$todayCount/$totalItems',
            highlight: todayCount == totalItems && totalItems > 0,
            colorValue: todayCount == totalItems && totalItems > 0
                ? Colors.green.value
                : null,
          ),
          WidgetStatItem(
            id: 'total',
            label: '总签到数',
            value: '$totalCheckins',
          ),
          WidgetStatItem(
            id: 'streak',
            label: '最长连续',
            value: '$maxConsecutiveDays天',
            highlight: maxConsecutiveDays >= 7,
            colorValue: maxConsecutiveDays >= 7 ? Colors.amber.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync checkin widget: $e');
    }
  }

  /// 同步节点插件
  Future<void> syncNodes() async {
    try {
      final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (plugin == null) return;

      // 获取统计数据
      final notebookCount = plugin.getNotebookCount();
      final totalNodes = plugin.getTotalNodeCount();
      final todayAdded = plugin.getTodayAddedNodeCount();

      await _updateWidget(
        pluginId: 'nodes',
        pluginName: '节点',
        iconCodePoint: Icons.account_tree.codePoint,
        colorValue: Colors.cyan.value,
        stats: [
          WidgetStatItem(id: 'notebooks', label: '笔记本数', value: '$notebookCount'),
          WidgetStatItem(id: 'nodes', label: '总节点数', value: '$totalNodes'),
          WidgetStatItem(
            id: 'today',
            label: '今日新增',
            value: '$todayAdded',
            highlight: todayAdded > 0,
            colorValue: todayAdded > 0 ? Colors.green.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync nodes widget: $e');
    }
  }

  /// 同步数据库插件
  Future<void> syncDatabase() async {
    try {
      final plugin = PluginManager.instance.getPlugin('database') as DatabasePlugin?;
      if (plugin == null) return;

      final databaseCount = await plugin.service.getDatabaseCount();
      final todayRecordCount = await plugin.service.getTodayRecordCount(plugin.controller);
      final totalRecordCount = await plugin.service.getTotalRecordCount(plugin.controller);

      await _updateWidget(
        pluginId: 'database',
        pluginName: '数据库',
        iconCodePoint: Icons.storage.codePoint,
        colorValue: Colors.grey.value,
        stats: [
          WidgetStatItem(
            id: 'total_records',
            label: '总记录数',
            value: '$totalRecordCount',
          ),
          WidgetStatItem(
            id: 'today_records',
            label: '今日新增',
            value: '$todayRecordCount',
            highlight: todayRecordCount > 0,
            colorValue: todayRecordCount > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(
            id: 'databases',
            label: '数据库表数',
            value: '$databaseCount',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync database widget: $e');
    }
  }

  /// 同步联系人插件
  Future<void> syncContact() async {
    try {
      final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
      if (plugin == null) return;

      final allContacts = await plugin.controller.getAllContacts();
      final totalContacts = allContacts.length;
      final todayInteractionCount = await plugin.controller.getTodayInteractionCount();
      final recentContactsCount = await plugin.controller.getRecentlyContactedCount();

      await _updateWidget(
        pluginId: 'contact',
        pluginName: '联系人',
        iconCodePoint: Icons.contacts.codePoint,
        colorValue: Colors.lightBlue.value,
        stats: [
          WidgetStatItem(
            id: 'total',
            label: '总联系人数',
            value: '$totalContacts',
          ),
          WidgetStatItem(
            id: 'today_interaction',
            label: '今日互动次数',
            value: '$todayInteractionCount',
            highlight: todayInteractionCount > 0,
            colorValue: todayInteractionCount > 0 ? Colors.orange.value : null,
          ),
          WidgetStatItem(
            id: 'recent',
            label: '最近联系人数',
            value: '$recentContactsCount',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync contact widget: $e');
    }
  }

  /// 同步纪念日插件
  Future<void> syncDay() async {
    try {
      final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
      if (plugin == null) return;

      final totalCount = plugin.getMemorialDayCount();
      final upcomingCount = plugin.getUpcomingMemorialDayCount();
      final todayCount = plugin.getTodayMemorialDayCount();

      await _updateWidget(
        pluginId: 'day',
        pluginName: '纪念日',
        iconCodePoint: Icons.celebration.codePoint,
        colorValue: Colors.pink.value,
        stats: [
          WidgetStatItem(
            id: 'total',
            label: '总纪念日数',
            value: '$totalCount',
          ),
          WidgetStatItem(
            id: 'upcoming',
            label: '即将到来',
            value: '$upcomingCount',
            highlight: upcomingCount > 0,
            colorValue: upcomingCount > 0 ? Colors.amber.value : null,
          ),
          WidgetStatItem(
            id: 'today',
            label: '今日纪念日',
            value: '$todayCount',
            highlight: todayCount > 0,
            colorValue: todayCount > 0 ? Colors.red.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync day widget: $e');
    }
  }

  /// 同步物品管理插件
  Future<void> syncGoods() async {
    try {
      final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
      if (plugin == null) return;

      final totalItems = plugin.getTotalItemsCount();
      final todayUsage = plugin.getTodayUsageCount();
      final warehouseCount = plugin.warehouses.length;

      await _updateWidget(
        pluginId: 'goods',
        pluginName: '物品',
        iconCodePoint: Icons.inventory.codePoint,
        colorValue: Colors.deepOrange.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总物品数', value: '$totalItems'),
          WidgetStatItem(
            id: 'today_usage',
            label: '今日使用',
            value: '$todayUsage',
            highlight: todayUsage > 0,
            colorValue: todayUsage > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(id: 'warehouses', label: '仓库数', value: '$warehouseCount'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync goods widget: $e');
    }
  }

  /// 同步笔记插件
  Future<void> syncNotes() async {
    try {
      final plugin = PluginManager.instance.getPlugin('notes') as NotesPlugin?;
      if (plugin == null) return;

      final totalNotes = plugin.getTotalNotesCount();
      final todayNotes = plugin.getTodayNotesCount();
      final totalWords = plugin.getTotalWordCount();

      await _updateWidget(
        pluginId: 'notes',
        pluginName: '笔记',
        iconCodePoint: Icons.note.codePoint,
        colorValue: Colors.yellow.shade700.value,
        stats: [
          WidgetStatItem(id: 'total', label: '总笔记数', value: '$totalNotes'),
          WidgetStatItem(
            id: 'today',
            label: '今日新增',
            value: '$todayNotes',
            highlight: todayNotes > 0,
            colorValue: todayNotes > 0 ? Colors.deepOrange.value : null,
          ),
          WidgetStatItem(id: 'words', label: '总字数', value: '$totalWords'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync notes widget: $e');
    }
  }

  /// 同步AI对话插件
  Future<void> syncAgentChat() async {
    try {
      final plugin = PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;
      if (plugin == null) return;

      // 获取统计数据
      final totalConversations = plugin.getTotalConversationsCount();
      final todayMessages = await plugin.getTodayMessagesCount();
      final activeConversations = await plugin.getActiveConversationsCount();

      await _updateWidget(
        pluginId: 'agent_chat',
        pluginName: 'AI对话',
        iconCodePoint: Icons.smart_toy.codePoint,
        colorValue: Colors.tealAccent.shade700.value,
        stats: [
          WidgetStatItem(
            id: 'conversations',
            label: '总对话',
            value: '$totalConversations',
            highlight: totalConversations > 0,
            colorValue: totalConversations > 0 ? Colors.teal.value : null,
          ),
          WidgetStatItem(
            id: 'today_messages',
            label: '今日消息',
            value: '$todayMessages',
            highlight: todayMessages > 0,
            colorValue: todayMessages > 0 ? Colors.blue.value : null,
          ),
          WidgetStatItem(
            id: 'active',
            label: '活跃会话',
            value: '$activeConversations',
            highlight: activeConversations > 0,
            colorValue: activeConversations > 0 ? Colors.green.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync agent_chat widget: $e');
    }
  }




















  /// 同步商店插件
  Future<void> syncStore() async {
    try {
      final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (plugin == null) return;

      final totalProducts = plugin.controller.getGoodsCount();
      final todayRedeemCount = plugin.controller.getTodayRedeemCount();
      final currentPoints = plugin.controller.currentPoints;

      await _updateWidget(
        pluginId: 'store',
        pluginName: '商店',
        iconCodePoint: Icons.store.codePoint,
        colorValue: Colors.red.value,
        stats: [
          WidgetStatItem(id: 'products', label: '总商品数', value: '$totalProducts'),
          WidgetStatItem(
            id: 'today_redeem',
            label: '今日兑换',
            value: '$todayRedeemCount',
            highlight: todayRedeemCount > 0,
            colorValue: todayRedeemCount > 0 ? Colors.purple.value : null,
          ),
          WidgetStatItem(
            id: 'points',
            label: '可用积分',
            value: '$currentPoints',
            highlight: currentPoints > 0,
            colorValue: currentPoints > 0 ? Colors.orange.value : null,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync store widget: $e');
    }
  }

  /// 同步OpenAI插件
  Future<void> syncOpenai() async {
    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (plugin == null) return;

      // 获取统计数据
      final totalAgents = await plugin.getTotalAgentsCount();
      final todayRequests = await plugin.getTodayRequestCount();
      final availableModels = await plugin.getAvailableModelsCount();

      await _updateWidget(
        pluginId: 'openai',
        pluginName: 'AI助手',
        iconCodePoint: Icons.psychology.codePoint,
        colorValue: Colors.deepPurple.value,
        stats: [
          WidgetStatItem(
            id: 'assistants',
            label: '总助手',
            value: '$totalAgents',
            highlight: totalAgents > 0,
            colorValue: totalAgents > 0 ? Colors.deepPurple.value : null,
          ),
          WidgetStatItem(
            id: 'requests',
            label: '今日请求',
            value: '$todayRequests',
            highlight: todayRequests > 0,
            colorValue: todayRequests > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(
            id: 'models',
            label: '可用模型',
            value: '$availableModels',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync openai widget: $e');
    }
  }

  /// 同步日记相册插件
  Future<void> syncCalendarAlbum() async {
    try {
      final plugin = PluginManager.instance.getPlugin('calendar_album') as CalendarAlbumPlugin?;
      if (plugin == null) return;

      // 获取统计数据
      final totalPhotos = plugin.getTotalPhotosCount();
      final todayPhotos = plugin.getTodayPhotosCount();
      final tagsCount = plugin.getTagsCount();

      await _updateWidget(
        pluginId: 'calendar_album',
        pluginName: '相册',
        iconCodePoint: Icons.photo_album.codePoint,
        colorValue: Colors.lime.shade700.value,
        stats: [
          WidgetStatItem(
            id: 'total_photos',
            label: '总照片',
            value: '$totalPhotos',
            highlight: totalPhotos > 0,
            colorValue: totalPhotos > 0 ? Colors.lime.value : null,
          ),
          WidgetStatItem(
            id: 'today_photos',
            label: '今日新增',
            value: '$todayPhotos',
            highlight: todayPhotos > 0,
            colorValue: todayPhotos > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(
            id: 'tags',
            label: '标签数',
            value: '$tagsCount',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync calendar_album widget: $e');
    }
  }

  /// 同步自定义签到项小组件
  Future<void> syncCheckinItemWidget() async {
    try {
      // 获取签到插件数据
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) {
        debugPrint('Checkin plugin not found, skipping checkin_item widget sync');
        return;
      }

      // 构建签到项列表数据
      final items = plugin.checkinItems.map((item) {
        // 获取最近7天的打卡状态(周一到周日)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final List<String> weekChecks = [];

        // 从周一开始计算(weekday 1-7,周一=1)
        final mondayOffset = today.weekday - 1; // 0 表示今天是周一
        final monday = today.subtract(Duration(days: mondayOffset));

        for (int i = 0; i < 7; i++) {
          final date = monday.add(Duration(days: i));
          final hasCheckin = item.getDateRecords(date).isNotEmpty;
          weekChecks.add(hasCheckin ? '1' : '0');
        }

        // 获取本月的打卡日期列表（用于月份视图小组件）
        final firstDayOfMonth = DateTime(today.year, today.month, 1);
        final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
        final List<int> monthChecks = [];

        for (int day = 1; day <= lastDayOfMonth.day; day++) {
          final date = DateTime(today.year, today.month, day);
          final hasCheckin = item.getDateRecords(date).isNotEmpty;
          if (hasCheckin) {
            monthChecks.add(day);
          }
        }

        return {
          'id': item.id,
          'name': item.name,
          'weekChecks': weekChecks.join(','),
          'monthChecks': monthChecks.join(','), // 本月打卡日期列表
        };
      }).toList();

      // 保存为 JSON 格式到 SharedPreferences
      final data = {'items': items};
      final jsonString = jsonEncode(data);
      await MyWidgetManager().saveString('checkin_item_widget_data', jsonString);

      // 更新打卡项小组件
      await SystemWidgetService.instance.updateWidget('checkin_item');

      // 同时更新打卡月份视图小组件（使用相同的数据）
      await SystemWidgetService.instance.updateWidget('checkin_month');

      debugPrint('Synced checkin widgets (item & month) with ${items.length} items');
    } catch (e) {
      debugPrint('Failed to sync checkin_item widget: $e');
    }
  }

  Future<void> syncChat() async {
    // 检查平台是否支持小组件
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      debugPrint('Widget not supported on this platform, skipping update for chat');
      return;
    }

    try {
      final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
      if (plugin == null) return;

      final channels = plugin.channelService.channels;
      final channelCount = channels.length;

      // 计算所有消息总数
      int totalMessageCount = 0;
      for (final channel in channels) {
        totalMessageCount += channel.messages.length;
      }

      // 获取最近一条消息的时间（用于显示最后更新时间）
      DateTime? lastMessageTime;
      for (final channel in channels) {
        if (channel.messages.isNotEmpty) {
          final channelLastTime = channel.messages.last.date;
          if (lastMessageTime == null ||
              channelLastTime.isAfter(lastMessageTime)) {
            lastMessageTime = channelLastTime;
          }
        }
      }

      await _updateWidget(
        pluginId: 'chat',
        pluginName: '聊天',
        iconCodePoint: Icons.chat.codePoint,
        colorValue: Colors.lightGreen.value,
        stats: [
          WidgetStatItem(
            id: 'channels',
            label: '频道数',
            value: '$channelCount',
          ),
          WidgetStatItem(
            id: 'messages',
            label: '消息数',
            value: '$totalMessageCount',
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync chat widget: $e');
    }
  }

  /// 更新小组件数据的通用方法
  Future<void> _updateWidget({
    required String pluginId,
    required String pluginName,
    required int iconCodePoint,
    required int colorValue,
    required List<WidgetStatItem> stats,
  }) async {
    final widgetData = PluginWidgetData(
      pluginId: pluginId,
      pluginName: pluginName,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      stats: stats,
    );

    await SystemWidgetService.instance.updateWidgetData(pluginId, widgetData);
  }
}
