import 'package:flutter/material.dart';
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

      await _updateWidget(
        pluginId: 'calendar',
        pluginName: '日历',
        iconCodePoint: Icons.calendar_today.codePoint,
        colorValue: Colors.teal.value,
        stats: [
          WidgetStatItem(id: 'today', label: '今日', value: '-'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync calendar widget: $e');
    }
  }

  /// 同步活动记录插件
  Future<void> syncActivity() async {
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

      await _updateWidget(
        pluginId: 'tracker',
        pluginName: '目标',
        iconCodePoint: Icons.track_changes.codePoint,
        colorValue: Colors.orange.value,
        stats: [
          WidgetStatItem(id: 'goals', label: '目标', value: '-'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync tracker widget: $e');
    }
  }

  /// 同步习惯插件
  Future<void> syncHabits() async {
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

      await _updateWidget(
        pluginId: 'nodes',
        pluginName: '节点',
        iconCodePoint: Icons.account_tree.codePoint,
        colorValue: Colors.cyan.value,
        stats: [
          WidgetStatItem(id: 'nodes', label: '节点', value: '-'),
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

      await _updateWidget(
        pluginId: 'database',
        pluginName: '数据库',
        iconCodePoint: Icons.storage.codePoint,
        colorValue: Colors.grey.value,
        stats: [
          WidgetStatItem(id: 'records', label: '记录', value: '-'),
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

      await _updateWidget(
        pluginId: 'contact',
        pluginName: '联系人',
        iconCodePoint: Icons.contacts.codePoint,
        colorValue: Colors.lightBlue.value,
        stats: [
          WidgetStatItem(id: 'contacts', label: '联系人', value: '-'),
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

      await _updateWidget(
        pluginId: 'day',
        pluginName: '纪念日',
        iconCodePoint: Icons.celebration.codePoint,
        colorValue: Colors.pink.value,
        stats: [
          WidgetStatItem(id: 'days', label: '纪念日', value: '-'),
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

      await _updateWidget(
        pluginId: 'goods',
        pluginName: '物品',
        iconCodePoint: Icons.inventory.codePoint,
        colorValue: Colors.deepOrange.value,
        stats: [
          WidgetStatItem(id: 'items', label: '物品', value: '-'),
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

      await _updateWidget(
        pluginId: 'notes',
        pluginName: '笔记',
        iconCodePoint: Icons.note.codePoint,
        colorValue: Colors.yellow.shade700.value,
        stats: [
          WidgetStatItem(id: 'notes', label: '笔记', value: '-'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync notes widget: $e');
    }
  }

  /// 同步商店插件
  Future<void> syncStore() async {
    try {
      final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
      if (plugin == null) return;

      await _updateWidget(
        pluginId: 'store',
        pluginName: '商店',
        iconCodePoint: Icons.store.codePoint,
        colorValue: Colors.red.value,
        stats: [
          WidgetStatItem(id: 'products', label: '商品', value: '-'),
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

      await _updateWidget(
        pluginId: 'openai',
        pluginName: 'AI助手',
        iconCodePoint: Icons.psychology.codePoint,
        colorValue: Colors.deepPurple.value,
        stats: [
          WidgetStatItem(id: 'assistants', label: '助手', value: '-'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync openai widget: $e');
    }
  }

  /// 同步AI对话插件
  Future<void> syncAgentChat() async {
    try {
      final plugin = PluginManager.instance.getPlugin('agent_chat') as AgentChatPlugin?;
      if (plugin == null) return;

      await _updateWidget(
        pluginId: 'agent_chat',
        pluginName: 'AI对话',
        iconCodePoint: Icons.smart_toy.codePoint,
        colorValue: Colors.tealAccent.shade700.value,
        stats: [
          WidgetStatItem(id: 'chats', label: '对话', value: '-'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync agent_chat widget: $e');
    }
  }

  /// 同步日记相册插件
  Future<void> syncCalendarAlbum() async {
    try {
      final plugin = PluginManager.instance.getPlugin('calendar_album') as CalendarAlbumPlugin?;
      if (plugin == null) return;

      await _updateWidget(
        pluginId: 'calendar_album',
        pluginName: '相册',
        iconCodePoint: Icons.photo_album.codePoint,
        colorValue: Colors.lime.shade700.value,
        stats: [
          WidgetStatItem(id: 'photos', label: '照片', value: '-'),
        ],
      );
    } catch (e) {
      debugPrint('Failed to sync calendar_album widget: $e');
    }
  }

  /// 同步聊天插件
  Future<void> syncChat() async {
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

      // 计算未读消息数（如果实现了）
      int unreadCount = 0;
      for (final channel in channels) {
        if (channel.unreadCount != null) {
          unreadCount += channel.unreadCount!;
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
          WidgetStatItem(
            id: 'unread',
            label: '未读',
            value: '$unreadCount',
            highlight: unreadCount > 0,
            colorValue: unreadCount > 0 ? Colors.red.value : null,
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
