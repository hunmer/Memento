// 导入所有同步器
import 'sync/todo_syncer.dart';
import 'sync/timer_syncer.dart';
import 'sync/bill_syncer.dart';
import 'sync/calendar_syncer.dart';
import 'sync/activity_syncer.dart';
import 'sync/tracker_syncer.dart';
import 'sync/habits_syncer.dart';
import 'sync/diary_syncer.dart';
import 'sync/checkin_syncer.dart';
import 'sync/nodes_syncer.dart';
import 'sync/database_syncer.dart';
import 'sync/contact_syncer.dart';
import 'sync/day_syncer.dart';
import 'sync/goods_syncer.dart';
import 'sync/notes_syncer.dart';
import 'sync/store_syncer.dart';
import 'sync/openai_syncer.dart';
import 'sync/agent_chat_syncer.dart';
import 'sync/calendar_album_syncer.dart';
import 'sync/chat_syncer.dart';

/// 插件小组件同步帮助类
///
/// 提供统一的方式来同步所有插件的小组件数据
///
/// 架构说明：
/// - 主协调器：负责管理所有插件同步器的生命周期
/// - 插件同步器：每个插件有独立的同步器文件，继承自 PluginWidgetSyncer
/// - 统一接口：所有同步器通过 sync() 方法暴露同步功能
class PluginWidgetSyncHelper {
  static final PluginWidgetSyncHelper _instance = PluginWidgetSyncHelper._internal();
  factory PluginWidgetSyncHelper() => _instance;
  PluginWidgetSyncHelper._internal() {
    _initializeSyncers();
  }

  static PluginWidgetSyncHelper get instance => _instance;

  // 所有插件同步器
  late final TodoSyncer _todoSyncer;
  late final TimerSyncer _timerSyncer;
  late final BillSyncer _billSyncer;
  late final CalendarSyncer _calendarSyncer;
  late final ActivitySyncer _activitySyncer;
  late final TrackerSyncer _trackerSyncer;
  late final HabitsSyncer _habitsSyncer;
  late final DiarySyncer _diarySyncer;
  late final CheckinSyncer _checkinSyncer;
  late final NodesSyncer _nodesSyncer;
  late final DatabaseSyncer _databaseSyncer;
  late final ContactSyncer _contactSyncer;
  late final DaySyncer _daySyncer;
  late final GoodsSyncer _goodsSyncer;
  late final NotesSyncer _notesSyncer;
  late final StoreSyncer _storeSyncer;
  late final OpenaiSyncer _openaiSyncer;
  late final AgentChatSyncer _agentChatSyncer;
  late final CalendarAlbumSyncer _calendarAlbumSyncer;
  late final ChatSyncer _chatSyncer;

  /// 初始化所有同步器
  void _initializeSyncers() {
    _todoSyncer = TodoSyncer();
    _timerSyncer = TimerSyncer();
    _billSyncer = BillSyncer();
    _calendarSyncer = CalendarSyncer();
    _activitySyncer = ActivitySyncer();
    _trackerSyncer = TrackerSyncer();
    _habitsSyncer = HabitsSyncer();
    _diarySyncer = DiarySyncer();
    _checkinSyncer = CheckinSyncer();
    _nodesSyncer = NodesSyncer();
    _databaseSyncer = DatabaseSyncer();
    _contactSyncer = ContactSyncer();
    _daySyncer = DaySyncer();
    _goodsSyncer = GoodsSyncer();
    _notesSyncer = NotesSyncer();
    _storeSyncer = StoreSyncer();
    _openaiSyncer = OpenaiSyncer();
    _agentChatSyncer = AgentChatSyncer();
    _calendarAlbumSyncer = CalendarAlbumSyncer();
    _chatSyncer = ChatSyncer();
  }

  /// 同步所有插件的小组件数据
  Future<void> syncAllPlugins() async {
    await Future.wait([
      // 基础插件
      _todoSyncer.sync(),
      _timerSyncer.sync(),
      _billSyncer.sync(),
      _calendarSyncer.sync(),
      _activitySyncer.sync(),
      _trackerSyncer.sync(),
      _habitsSyncer.sync(),
      _diarySyncer.sync(),
      _checkinSyncer.sync(),
      _nodesSyncer.sync(),
      _databaseSyncer.sync(),
      _contactSyncer.sync(),
      _daySyncer.sync(),
      _goodsSyncer.sync(),
      _notesSyncer.sync(),
      _storeSyncer.sync(),
      _openaiSyncer.sync(),
      _agentChatSyncer.sync(),
      _calendarAlbumSyncer.sync(),
      _chatSyncer.sync(),

      // 自定义小组件
      _checkinSyncer.syncCheckinItemWidget(),
      _todoSyncer.syncTodoListWidget(),
      _checkinSyncer.syncCheckinWeeklyWidget(),
      _trackerSyncer.syncTrackerGoalWidget(),
      _activitySyncer.syncActivityWeeklyWidget(),
      _habitsSyncer.syncHabitsWeeklyWidget(),
    ]);
  }

  // ==================== 向后兼容的委托方法 ====================
  // 保留这些方法以确保现有调用不会中断

  /// 同步待办事项插件
  Future<void> syncTodo() => _todoSyncer.sync();

  /// 同步计时器插件
  Future<void> syncTimer() => _timerSyncer.sync();

  /// 同步账单插件
  Future<void> syncBill() => _billSyncer.sync();

  /// 同步日历插件
  Future<void> syncCalendar() => _calendarSyncer.sync();

  /// 同步活动记录插件
  Future<void> syncActivity() => _activitySyncer.sync();

  /// 同步目标追踪插件
  Future<void> syncTracker() => _trackerSyncer.sync();

  /// 同步习惯插件
  Future<void> syncHabits() => _habitsSyncer.sync();

  /// 同步日记插件
  Future<void> syncDiary() => _diarySyncer.sync();

  /// 同步签到插件
  Future<void> syncCheckin() => _checkinSyncer.sync();

  /// 同步节点插件
  Future<void> syncNodes() => _nodesSyncer.sync();

  /// 同步数据库插件
  Future<void> syncDatabase() => _databaseSyncer.sync();

  /// 同步联系人插件
  Future<void> syncContact() => _contactSyncer.sync();

  /// 同步纪念日插件
  Future<void> syncDay() => _daySyncer.sync();

  /// 同步物品管理插件
  Future<void> syncGoods() => _goodsSyncer.sync();

  /// 同步笔记插件
  Future<void> syncNotes() => _notesSyncer.sync();

  /// 同步商店插件
  Future<void> syncStore() => _storeSyncer.sync();

  /// 同步OpenAI插件
  Future<void> syncOpenai() => _openaiSyncer.sync();

  /// 同步AI对话插件
  Future<void> syncAgentChat() => _agentChatSyncer.sync();

  /// 同步日记相册插件
  Future<void> syncCalendarAlbum() => _calendarAlbumSyncer.sync();

  /// 同步聊天插件
  Future<void> syncChat() => _chatSyncer.sync();

  /// 同步自定义签到项小组件
  Future<void> syncCheckinItemWidget() => _checkinSyncer.syncCheckinItemWidget();

  /// 同步待办列表自定义小组件
  Future<void> syncTodoListWidget() => _todoSyncer.syncTodoListWidget();

  /// 应用启动时同步待处理的小组件任务变更
  /// 在 main.dart 中调用，确保用户在小组件上完成的任务能立即同步到应用
  Future<void> syncPendingTaskChangesOnStartup() => _todoSyncer.syncPendingTaskChangesOnStartup();

  /// 应用启动或恢复时同步待处理的日历事件完成操作
  /// 在 main.dart 中调用，确保用户在小组件上完成的日历事件能立即同步到应用
  Future<void> syncPendingCalendarEventsOnStartup() => _calendarSyncer.syncPendingEventsOnStartup();

  /// 同步打卡周视图小组件
  Future<void> syncCheckinWeeklyWidget() => _checkinSyncer.syncCheckinWeeklyWidget();

  /// 同步习惯周视图小组件
  Future<void> syncHabitsWeeklyWidget() => _habitsSyncer.syncHabitsWeeklyWidget();

  /// 同步目标进度自定义小组件
  Future<void> syncTrackerGoalWidget() => _trackerSyncer.syncTrackerGoalWidget();

  /// 应用启动或恢复时同步待处理的目标变更
  /// 在 main.dart 中调用，确保用户在小组件上增减的进度能立即同步到应用
  Future<void> syncPendingGoalChangesOnStartup() => _trackerSyncer.syncPendingGoalChangesOnStartup();

  /// 同步习惯计时器小组件
  Future<void> syncHabitTimerWidget() => _habitsSyncer.syncHabitTimerWidget();

  /// 应用启动或恢复时同步待处理的习惯计时器变更
  /// 在 main.dart 中调用，确保用户在小组件上启动/暂停的计时器能立即同步到应用
  Future<void> syncPendingHabitTimerChangesOnStartup() => _habitsSyncer.syncPendingHabitTimerChangesOnStartup();

  /// 同步活动周视图小组件
  Future<void> syncActivityWeeklyWidget() => _activitySyncer.syncActivityWeeklyWidget();
}
