import 'package:flutter/services.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/diary/models/diary_entry.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/timer/timer_plugin.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:intl/intl.dart';

/// WatchConnectivity 服务
///
/// 处理来自 iOS Watch 应用的数据请求
class WatchConnectivityService {
  static const _channelName = 'github.hunmer.memento/watch_connectivity';

  static WatchConnectivityService? _instance;
  final MethodChannel _methodChannel;
  final ConversationService _conversationService;
  final MessageService _messageService;

  bool _isInitialized = false;

  WatchConnectivityService._({
    required ConversationService conversationService,
    required MessageService messageService,
  }) : _conversationService = conversationService,
       _messageService = messageService,
       _methodChannel = const MethodChannel(_channelName);

  /// 获取单例实例
  static WatchConnectivityService get instance {
    if (_instance == null) {
      throw Exception('WatchConnectivityService 未初始化，请先调用 initialize()');
    }
    return _instance!;
  }

  /// 初始化服务
  static void initialize({
    required ConversationService conversationService,
    required MessageService messageService,
  }) {
    if (_instance != null) {
      print('[WatchConnectivityService] 已初始化，跳过');
      return;
    }

    _instance = WatchConnectivityService._(
      conversationService: conversationService,
      messageService: messageService,
    );
    _instance!._setupMethodHandler();
  }

  /// 设置 MethodChannel 处理器
  void _setupMethodHandler() {
    _methodChannel.setMethodCallHandler((call) async {
      print('[WatchConnectivityService] 收到请求: ${call.method}');

      try {
        switch (call.method) {
          case 'getWatchChatChannels':
            return await _getWatchChatChannels();
          case 'getWatchChatMessages':
            return await _getWatchChatMessages(call.arguments);
          case 'getWatchDiaryEntries':
            return await _getWatchDiaryEntries();
          case 'getWatchDiaryEntry':
            return await _getWatchDiaryEntry(call.arguments);
          case 'getWatchDiaryStats':
            return await _getWatchDiaryStats();
          case 'getWatchActivityData':
            return await _getWatchActivityData(call.arguments);
          case 'getWatchActivityToday':
            return await _getWatchActivityToday();
          case 'getWatchCheckinItems':
            return await _getWatchCheckinItems();
          case 'getWatchContactItems':
            return await _getWatchContactItems();
          case 'getWatchHabits':
            return await _getWatchHabits();
          case 'getWatchTimers':
            return await _getWatchTimers();
          case 'getWatchTodoTasks':
            return await _getWatchTodoTasks();
          case 'getWatchDayItems':
            return await _getWatchDayItems();
          case 'getWatchTrackerGoals':
            return await _getWatchTrackerGoals();
          case 'getWatchBillItems':
            return await _getWatchBillItems();
          case 'getWatchNotes':
            return await _getWatchNotes();
          case 'getWatchStoreProducts':
            return await _getWatchStoreProducts();
          case 'getWatchUserItems':
            return await _getWatchUserItems();
          case 'getWatchNodesNotebooks':
            return await _getWatchNodesNotebooks();
          case 'getWatchNodes':
            return await _getWatchNodes(call.arguments);
          case 'getWatchGoodsWarehouses':
            return await _getWatchGoodsWarehouses();
          case 'getWatchGoodsItems':
            return await _getWatchGoodsItems(call.arguments);
          case 'getWatchCalendarEvents':
            return await _getWatchCalendarEvents();
          case 'getWatchCalendarAlbumEntries':
            return await _getWatchCalendarAlbumEntries();
          default:
            throw PlatformException(
              code: 'UNIMPLEMENTED',
              message: '未实现的方法: ${call.method}',
            );
        }
      } catch (e) {
        print('[WatchConnectivityService] 处理请求失败: $e');
        rethrow;
      }
    });

    _isInitialized = true;
    print('[WatchConnectivityService] 初始化完成');
  }

  /// 获取会话列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchChatChannels() async {
    final conversations = _conversationService.conversations;

    // 转换为 watchOS 需要的格式
    final channelList =
        conversations.map((conv) => _conversationToWatchChannel(conv)).toList();

    print('[WatchConnectivityService] 返回 ${channelList.length} 个会话');
    return channelList;
  }

  /// 获取指定会话的消息（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchChatMessages(
    dynamic arguments,
  ) async {
    if (arguments is! Map) {
      throw ArgumentError('参数必须是 Map 类型');
    }

    final channelId = arguments['channelId'] as String?;
    if (channelId == null) {
      throw ArgumentError('缺少 channelId 参数');
    }

    final messages = await _messageService.getMessages(channelId);

    // 转换为 watchOS 需要的格式
    final messageList =
        messages.map((msg) => _messageToWatchMessage(msg)).toList();

    print('[WatchConnectivityService] 返回 ${messageList.length} 条消息');
    return messageList;
  }

  /// 将 Conversation 转换为 watchOS 需要的 ChatChannel 格式
  Map<String, dynamic> _conversationToWatchChannel(Conversation conv) {
    return {
      'id': conv.id,
      'name': conv.title,
      'description': conv.lastMessagePreview ?? '暂无消息',
      'unreadCount': conv.unreadCount,
      'createdAt': conv.createdAt.toIso8601String(),
      'lastActiveAt': conv.lastMessageAt.toIso8601String(),
    };
  }

  /// 将 ChatMessage 转换为 watchOS 需要的格式
  Map<String, dynamic> _messageToWatchMessage(ChatMessage msg) {
    return {
      'id': msg.id,
      'channelId': msg.conversationId,
      'content': msg.content,
      'senderId': msg.isUser ? 'me' : msg.generatedByAgentId ?? 'assistant',
      'senderName': msg.isUser ? '我' : 'AI',
      'timestamp': msg.timestamp.toIso8601String(),
      'isMe': msg.isUser,
    };
  }

  // ============== 日记相关方法 ==============

  /// 获取本月日记列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchDiaryEntries() async {
    final diaryPlugin = DiaryPlugin.instance;
    final entries = diaryPlugin.getMonthlyDiaryEntriesSync();

    // 转换为 watchOS 需要的格式
    final entryList =
        entries.map((tuple) {
          final date = tuple.$1;
          final entry = tuple.$2;
          return {
            'date': DateFormat('yyyy-MM-dd').format(date),
            'title': entry.title,
            'contentPreview':
                entry.content.length > 100
                    ? '${entry.content.substring(0, 100)}...'
                    : entry.content,
            'wordCount': entry.content.length,
            'mood': entry.mood,
            'updatedAt': entry.updatedAt.toIso8601String(),
          };
        }).toList();

    print('[WatchConnectivityService] 返回 ${entryList.length} 条日记');
    return entryList;
  }

  /// 获取指定日期的日记详情（供 watchOS 使用）
  Future<Map<String, dynamic>> _getWatchDiaryEntry(dynamic arguments) async {
    if (arguments is! Map) {
      throw ArgumentError('参数必须是 Map 类型');
    }

    final dateStr = arguments['date'] as String?;
    if (dateStr == null) {
      throw ArgumentError('缺少 date 参数');
    }

    final diaryPlugin = DiaryPlugin.instance;
    final date = DateTime.parse(dateStr);
    final entries = diaryPlugin.getMonthlyDiaryEntriesSync();

    // 查找指定日期的日记
    DiaryEntry? entry;
    for (final tuple in entries) {
      final entryDate = tuple.$1;
      if (entryDate.year == date.year &&
          entryDate.month == date.month &&
          entryDate.day == date.day) {
        entry = tuple.$2;
        break;
      }
    }

    if (entry == null) {
      throw Exception('未找到日期为 $dateStr 的日记');
    }

    final result = {
      'date': dateStr,
      'title': entry.title,
      'content': entry.content,
      'wordCount': entry.content.length,
      'mood': entry.mood,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
    };

    print('[WatchConnectivityService] 返回日记详情: $dateStr');
    return result;
  }

  /// 获取日记统计数据（供 watchOS 使用）
  Future<Map<String, dynamic>> _getWatchDiaryStats() async {
    final diaryPlugin = DiaryPlugin.instance;
    final todayWordCount = diaryPlugin.getTodayWordCountSync();
    final monthWordCount = diaryPlugin.getMonthWordCountSync();
    final monthProgress = diaryPlugin.getMonthProgressSync();

    final result = {
      'todayWordCount': todayWordCount,
      'monthWordCount': monthWordCount,
      'completedDays': monthProgress.$1,
      'totalDays': monthProgress.$2,
    };

    print('[WatchConnectivityService] 返回日记统计: $result');
    return result;
  }

  // ============== 活动相关方法 ==============

  /// 获取今日活动数据（供 watchOS 使用）
  Future<Map<String, dynamic>> _getWatchActivityToday() async {
    try {
      final activityPlugin = ActivityPlugin.instance;
      final todayActivities = activityPlugin.getTodayActivitiesSync();
      final todayCount = activityPlugin.getTodayActivityCountSync();
      final todayDuration = activityPlugin.getTodayActivityDurationSync();
      final remainingTime = activityPlugin.getTodayRemainingTime();

      final result = {
        'todayCount': todayCount,
        'todayDuration': todayDuration,
        'remainingTime': remainingTime,
        'activities':
            todayActivities
                .map(
                  (activity) => {
                    'id': activity.id,
                    'title': activity.title,
                    'startTime': activity.startTime.toIso8601String(),
                    'endTime': activity.endTime.toIso8601String(),
                    'duration': activity.durationInMinutes,
                    'tags': activity.tags,
                    'description': activity.description,
                    'mood': activity.mood,
                  },
                )
                .toList(),
      };

      print(
        '[WatchConnectivityService] 返回今日活动统计: todayCount=$todayCount, todayDuration=$todayDuration',
      );
      return result;
    } catch (e) {
      print('[WatchConnectivityService] 获取今日活动数据失败: $e');
      return {
        'todayCount': 0,
        'todayDuration': 0,
        'remainingTime': 0,
        'activities': [],
      };
    }
  }

  /// 获取指定日期范围的活动数据（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchActivityData(
    dynamic arguments,
  ) async {
    try {
      final activityPlugin = ActivityPlugin.instance;
      List<ActivityRecord> activities;

      if (arguments is Map && arguments['date'] != null) {
        // 获取指定日期的活动
        final dateStr = arguments['date'] as String;
        final date = DateTime.parse(dateStr);
        activities = activityPlugin.getActivitiesForDateSync(date);
      } else {
        // 默认获取今天的活动
        activities = activityPlugin.getTodayActivitiesSync();
      }

      // 转换为 watchOS 需要的格式
      final activityList =
          activities
              .map(
                (activity) => {
                  'id': activity.id,
                  'title': activity.title,
                  'startTime': activity.startTime.toIso8601String(),
                  'endTime': activity.endTime.toIso8601String(),
                  'duration': activity.durationInMinutes,
                  'tags': activity.tags,
                  'description': activity.description,
                  'mood': activity.mood,
                },
              )
              .toList();

      print('[WatchConnectivityService] 返回 ${activityList.length} 条活动');
      return activityList;
    } catch (e) {
      print('[WatchConnectivityService] 获取活动数据失败: $e');
      return [];
    }
  }

  // ============== 打卡相关方法 ==============

  /// 获取打卡项目列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchCheckinItems() async {
    try {
      final checkinPlugin = CheckinPlugin.instance;
      final items = checkinPlugin.getWatchCheckinItemsSync();

      print('[WatchConnectivityService] 返回 ${items.length} 个打卡项目');
      print('[WatchConnectivityService] 数据: $items');
      return items;
    } catch (e) {
      print('[WatchConnectivityService] 获取打卡数据失败: $e');
      return [];
    }
  }

  // ============== 联系人相关方法 ==============

  /// 获取联系人列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchContactItems() async {
    try {
      final contactPlugin = ContactPlugin.instance;
      final items = await contactPlugin.getWatchContactItems();

      print('[WatchConnectivityService] 返回 ${items.length} 个联系人');
      return items;
    } catch (e) {
      print('[WatchConnectivityService] 获取联系人数据失败: $e');
      return [];
    }
  }

  // ============== 习惯相关方法 ==============

  /// 获取习惯列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchHabits() async {
    try {
      final habitsPlugin = HabitsPlugin.instance;
      final habits = habitsPlugin.getHabitController().getHabits();
      final skillController = habitsPlugin.getSkillController();
      final recordController = habitsPlugin.getRecordController();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1)); // 本周一

      final List<Map<String, dynamic>> habitItems = [];
      for (final habit in habits) {
        String? skillName;
        int skillColor = 0xFF39FF14; // 默认霓虹绿
        if (habit.skillId != null) {
          final skill = skillController.getSkillById(habit.skillId!);
          if (skill != null) {
            skillName = skill.title;
            // 根据技能名称分配颜色
            skillColor = _getSkillColor(skill.title);
          }
        }

        // 计算本周每日完成情况
        final dailyMinutes = await _calculateDailyMinutes(
          habit.id,
          weekStart,
          recordController,
        );

        // 获取今日累计时长
        final todayMinutes =
            dailyMinutes.isNotEmpty ? dailyMinutes[now.weekday - 1] : 0;
        final targetMinutes = habit.durationMinutes;

        final data = <String, dynamic>{
          'id': habit.id,
          'title': habit.title,
          'skillName': skillName ?? habit.group ?? 'General',
          'skillColor': skillColor,
          'icon': habit.icon,
          'todayMinutes': todayMinutes,
          'targetMinutes': targetMinutes,
          'totalDurationMinutes': habit.totalDurationMinutes,
          'dailyMinutes': dailyMinutes,
        };

        // 移除所有 null 值
        data.removeWhere((key, value) => value == null);
        habitItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${habitItems.length} 个习惯');
      return habitItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取习惯数据失败: $e');
      return [];
    }
  }

  /// 计算本周每日完成时长（分钟）
  Future<List<int>> _calculateDailyMinutes(
    String habitId,
    DateTime weekStart,
    dynamic recordController,
  ) async {
    final dailyMinutes = List<int>.filled(7, 0);

    try {
      final records = await recordController.getHabitCompletionRecords(habitId);

      for (final record in records) {
        final recordDate = record.date;
        // 检查记录是否在本周
        if (recordDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            recordDate.isBefore(weekStart.add(const Duration(days: 7)))) {
          final dayIndex = recordDate.weekday - 1;
          dailyMinutes[dayIndex] += record.duration.inMinutes as int;
        }
      }
    } catch (e) {
      print('[WatchConnectivityService] 计算每日时长失败: $e');
    }

    return dailyMinutes;
  }

  /// 根据技能名称获取颜色
  int _getSkillColor(String skillName) {
    final lowerName = skillName.toLowerCase();

    if (lowerName.contains('fitness') ||
        lowerName.contains('运动') ||
        lowerName.contains('健康') ||
        lowerName.contains('health')) {
      return 0xFF39FF14; // 霓虹绿
    } else if (lowerName.contains('mental') ||
        lowerName.contains('心理') ||
        lowerName.contains('冥想') ||
        lowerName.contains('meditation')) {
      return 0xFFBC13FE; // 霓虹紫
    } else if (lowerName.contains('focus') ||
        lowerName.contains('专注') ||
        lowerName.contains('学习') ||
        lowerName.contains('read') ||
        lowerName.contains('阅读')) {
      return 0xFF0FF0FC; // 霓虹蓝
    } else if (lowerName.contains('creative') ||
        lowerName.contains('创意') ||
        lowerName.contains('艺术') ||
        lowerName.contains('writing') ||
        lowerName.contains('写作')) {
      return 0xFFFF6B35; // 橙色
    } else if (lowerName.contains('work') ||
        lowerName.contains('工作') ||
        lowerName.contains('效率')) {
      return 0xFFFFD700; // 金色
    }

    return 0xFF39FF14; // 默认霓虹绿
  }

  // ============== 计时器相关方法 ==============

  /// 获取计时器列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchTimers() async {
    try {
      final timerPlugin = TimerPlugin.instance;
      final tasks = timerPlugin.getTasks();

      final List<Map<String, dynamic>> timerItems = [];
      for (final task in tasks) {
        // 获取当前活动的计时器
        final activeTimer = task.activeTimer;

        // 转换 TimerItem 列表为 watchOS 格式
        final subTimers =
            task.timerItems.map((item) {
              final data = <String, dynamic>{
                'id': item.id,
                'name': item.name,
                'type':
                    item.type.index, // 0: countUp, 1: countDown, 2: pomodoro
                'duration': item.duration.inSeconds,
                'completedDuration': item.completedDuration.inSeconds,
                'isRunning': item.isRunning,
                'isCompleted': item.isCompleted,
                'repeatCount': item.repeatCount,
              };

              // 番茄钟特有属性
              if (item.type == TimerType.pomodoro) {
                data['workDuration'] = item.workDuration?.inSeconds;
                data['breakDuration'] = item.breakDuration?.inSeconds;
                data['cycles'] = item.cycles;
                data['currentCycle'] = item.currentCycle;
                data['isWorkPhase'] = item.isWorkPhase;
              }

              // 移除所有 null 值
              data.removeWhere((key, value) => value == null);
              return data;
            }).toList();

        final data = <String, dynamic>{
          'id': task.id,
          'name': task.name,
          'color': task.color.toARGB32(),
          'icon': task.icon.codePoint,
          'group': task.group,
          'isRunning': task.isRunning,
          'isCompleted': task.isCompleted,
          'repeatCount': task.repeatCount,
          'timerItems': subTimers,
          'activeTimerId': activeTimer?.id,
          'createdAt': task.createdAt.toIso8601String(),
        };

        // 移除所有 null 值
        data.removeWhere((key, value) => value == null);
        timerItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${timerItems.length} 个计时器任务');
      return timerItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取计时器数据失败: $e');
      return [];
    }
  }

  // ============== 待办任务相关方法 ==============

  /// 获取待办任务列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchTodoTasks() async {
    try {
      final todoPlugin = TodoPlugin.instance;
      final tasks = todoPlugin.getWatchTodoTasksSync();

      print('[WatchConnectivityService] 返回 ${tasks.length} 个待办任务');
      return tasks;
    } catch (e) {
      print('[WatchConnectivityService] 获取待办任务数据失败: $e');
      return [];
    }
  }

  // ============== 纪念日相关方法 ==============

  /// 获取纪念日列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchDayItems() async {
    try {
      final dayPlugin = DayPlugin.instance;
      final memorialDays = dayPlugin.getAllMemorialDays();

      // 转换为 watchOS 需要的格式
      final dayItems =
          memorialDays.map((day) {
            final data = <String, dynamic>{
              'id': day.id,
              'title': day.title,
              'targetDate': DateFormat('yyyy-MM-dd').format(day.targetDate),
              'daysRemaining': day.daysRemaining,
              'isExpired': day.isExpired,
              'isToday': day.isToday,
              'backgroundColor': day.backgroundColor.toARGB32(),
              'backgroundImageUrl': day.backgroundImageUrl,
              'notes': day.notes,
            };

            // 移除所有 null 值，避免 WCSession 传输问题
            data.removeWhere((key, value) => value == null);
            return data;
          }).toList();

      print('[WatchConnectivityService] 返回 ${dayItems.length} 个纪念日');
      return dayItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取纪念日数据失败: $e');
      return [];
    }
  }

  // ============== 目标追踪相关方法 ==============

  /// 获取追踪目标列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchTrackerGoals() async {
    try {
      final trackerPlugin = TrackerPlugin.instance;
      final controller = trackerPlugin.controller;
      final goals = controller.goals;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      final List<Map<String, dynamic>> goalItems = [];
      for (final goal in goals) {
        // 计算本周每日完成情况
        final dailyCompleted = await _calculateDailyCompleted(
          goal.id,
          weekStart,
          controller,
        );

        // 根据分组分配颜色
        final accentColor = _getGoalAccentColor(goal.group);

        final data = <String, dynamic>{
          'id': goal.id,
          'name': goal.name,
          'icon': goal.icon,
          'iconColor': goal.iconColor,
          'unitType': goal.unitType,
          'targetValue': goal.targetValue,
          'currentValue': goal.currentValue,
          'progress':
              goal.targetValue > 0 ? goal.currentValue / goal.targetValue : 0,
          'isCompleted': goal.isCompleted,
          'group': goal.group,
          'accentColor': accentColor,
          'dateSettingsType': goal.dateSettings.type,
          'dailyCompleted': dailyCompleted,
        };

        // 移除所有 null 值，避免 WCSession 传输问题
        data.removeWhere((key, value) => value == null);
        goalItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${goalItems.length} 个追踪目标');
      return goalItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取追踪目标数据失败: $e');
      return [];
    }
  }

  /// 计算本周每日完成情况（是否达到目标）
  Future<List<bool>> _calculateDailyCompleted(
    String goalId,
    DateTime weekStart,
    dynamic controller,
  ) async {
    final dailyCompleted = List<bool>.filled(7, false);

    try {
      final records = await controller.getRecordsForGoal(goalId);

      // 按天分组计算
      final dailyTotals = <int, double>{};
      for (final record in records as List) {
        final recordDate = record.recordedAt as DateTime;
        // 检查记录是否在本周
        if (recordDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            recordDate.isBefore(weekStart.add(const Duration(days: 7)))) {
          final dayIndex = recordDate.weekday - 1;
          dailyTotals[dayIndex] =
              (dailyTotals[dayIndex] ?? 0) + (record.value as double);
        }
      }

      // 找到对应的目标 targetValue
      final goals = controller.goals as List;
      double targetValue = 1; // 默认值
      for (final g in goals) {
        if ((g as Goal).id == goalId) {
          targetValue = g.targetValue;
          break;
        }
      }

      // 标记完成的天
      for (final entry in dailyTotals.entries) {
        dailyCompleted[entry.key] = entry.value >= targetValue;
      }
    } catch (e) {
      print('[WatchConnectivityService] 计算每日完成情况失败: $e');
    }

    return dailyCompleted;
  }

  /// 根据目标分组获取颜色
  int _getGoalAccentColor(String group) {
    final lowerGroup = group.toLowerCase();

    if (lowerGroup.contains('健康') ||
        lowerGroup.contains('运动') ||
        lowerGroup.contains('fitness') ||
        lowerGroup.contains('health')) {
      return 0xFF39FF14; // 霓虹绿
    } else if (lowerGroup.contains('学习') ||
        lowerGroup.contains('阅读') ||
        lowerGroup.contains('study') ||
        lowerGroup.contains('read')) {
      return 0xFF00F3FF; // 霓虹青
    } else if (lowerGroup.contains('工作') ||
        lowerGroup.contains('效率') ||
        lowerGroup.contains('work')) {
      return 0xFFBC13FE; // 霓虹紫
    } else if (lowerGroup.contains('生活') ||
        lowerGroup.contains('日常') ||
        lowerGroup.contains('life')) {
      return 0xFFFF6B35; // 橙色
    }

    return 0xFF39FF14; // 默认霓虹绿
  }

  // ============== 账单相关方法 ==============

  /// 获取账单列表（供 watchOS 使用）
  /// 返回最近 7 天的账单，按日期分组
  Future<List<Map<String, dynamic>>> _getWatchBillItems() async {
    try {
      final billPlugin = BillPlugin.instance;
      final controller = billPlugin.controller;

      // 获取最近 7 天的账单
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));

      // 收集所有账户的账单
      final allBills = <Map<String, dynamic>>[];
      for (final account in controller.accounts) {
        for (final bill in account.bills) {
          // 筛选最近 7 天的账单
          if (bill.date.isAfter(startDate) ||
              bill.date.isAtSameMomentAs(startDate)) {
            final data = <String, dynamic>{
              'id': bill.id,
              'title': bill.title,
              'category': bill.category,
              'amount': bill.amount,
              'date': DateFormat('yyyy-MM-dd').format(bill.date),
              'isExpense': bill.isExpense,
              'icon': bill.icon.codePoint,
              'iconColor': bill.iconColor.toARGB32(),
              'note': bill.note,
              'isSubscription': bill.isSubscription,
            };

            // 移除所有 null 值，避免 WCSession 传输问题
            data.removeWhere((key, value) => value == null);
            allBills.add(data);
          }
        }
      }

      // 按日期降序排序
      allBills.sort(
        (a, b) => (b['date'] as String).compareTo(a['date'] as String),
      );

      print('[WatchConnectivityService] 返回 ${allBills.length} 条账单');
      return allBills;
    } catch (e) {
      print('[WatchConnectivityService] 获取账单数据失败: $e');
      return [];
    }
  }

  // ============== 笔记相关方法 ==============

  /// 获取笔记列表（供 watchOS 使用）
  /// 返回最近更新的笔记，按文件夹分组显示
  Future<List<Map<String, dynamic>>> _getWatchNotes() async {
    try {
      final notesPlugin = NotesPlugin.instance;
      final controller = notesPlugin.controller;

      // 获取所有笔记
      final allNotes = controller.searchNotes(query: '');

      // 按更新时间降序排序，取最近的笔记
      allNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final recentNotes = allNotes.take(20).toList(); // 限制为最近 20 条

      final List<Map<String, dynamic>> noteItems = [];
      for (final note in recentNotes) {
        // 获取笔记所属文件夹信息
        final folder = note.folderId != null ? controller.getFolder(note.folderId!) : null;
        String folderName = '默认';
        int folderColor = 0xFFEC5B13; // 默认主题色
        int folderIcon = 0xe2c7; // folder 图标

        if (folder != null) {
          folderName = folder.name;
          folderColor = folder.color.toARGB32();
          folderIcon = folder.icon.codePoint;
        }

        // 根据文件夹名称分配霓虹边框颜色
        final neonBorderColor = _getNoteNeonColor(folderName);

        final data = <String, dynamic>{
          'id': note.id,
          'title': note.title,
          'contentPreview':
              note.content.length > 50
                  ? '${note.content.substring(0, 50)}...'
                  : note.content,
          'folderId': note.folderId,
          'folderName': folderName,
          'folderColor': folderColor,
          'folderIcon': folderIcon,
          'neonBorderColor': neonBorderColor,
          'tags': note.tags,
          'createdAt': note.createdAt.toIso8601String(),
          'updatedAt': note.updatedAt.toIso8601String(),
        };

        // 移除所有 null 值，避免 WCSession 传输问题
        data.removeWhere((key, value) => value == null);
        noteItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${noteItems.length} 条笔记');
      return noteItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取笔记数据失败: $e');
      return [];
    }
  }

  /// 根据文件夹名称获取霓虹边框颜色
  int _getNoteNeonColor(String folderName) {
    final lowerName = folderName.toLowerCase();

    if (lowerName.contains('work') ||
        lowerName.contains('工作') ||
        lowerName.contains('项目')) {
      return 0xFF00F2FF; // 霓虹青
    } else if (lowerName.contains('personal') ||
        lowerName.contains('个人') ||
        lowerName.contains('生活')) {
      return 0xFFBC13FE; // 霓虹紫
    } else if (lowerName.contains('idea') ||
        lowerName.contains('想法') ||
        lowerName.contains('创意')) {
      return 0xFF39FF14; // 霓虹绿
    } else if (lowerName.contains('study') ||
        lowerName.contains('学习') ||
        lowerName.contains('笔记')) {
      return 0xFFFFD700; // 金色
    }

    return 0xFF00F2FF; // 默认霓虹青
  }

  // ============== 商店相关方法 ==============

  /// 获取商品列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchStoreProducts() async {
    try {
      final storePlugin = StorePlugin.instance;
      final controller = storePlugin.controller;

      // 获取所有商品（去重）
      final uniqueProducts =
          controller.products
              .fold<Map<String, Product>>({}, (map, product) {
                if (!map.containsKey(product.id)) {
                  map[product.id] = product;
                }
                return map;
              })
              .values
              .toList();

      final now = DateTime.now();

      final List<Map<String, dynamic>> productItems = [];
      for (final product in uniqueProducts) {
        // 检查商品是否可兑换
        final isInExchangePeriod =
            now.isAfter(product.exchangeStart) &&
            now.isBefore(product.exchangeEnd);
        final isAvailable = product.stock > 0 && isInExchangePeriod;

        final data = <String, dynamic>{
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'stock': product.stock,
          'isAvailable': isAvailable,
          'useDuration': product.useDuration,
        };

        // 移除所有 null 值，避免 WCSession 传输问题
        data.removeWhere((key, value) => value == null);
        productItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${productItems.length} 个商品');
      return productItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取商品数据失败: $e');
      return [];
    }
  }

  /// 获取用户物品列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchUserItems() async {
    try {
      final storePlugin = StorePlugin.instance;
      final controller = storePlugin.controller;

      final now = DateTime.now();

      // 按商品分组物品
      final groupedItems = <String, List<UserItem>>{};
      for (final item in controller.userItems) {
        final key = item.productId;
        if (groupedItems[key] == null) {
          groupedItems[key] = [];
        }
        groupedItems[key]!.add(item);
      }

      final List<Map<String, dynamic>> userItemGroups = [];
      for (final entry in groupedItems.entries) {
        final productId = entry.key;
        final items = entry.value;

        // 获取第一个物品作为代表
        final firstItem = items.first;
        final isExpired = now.isAfter(firstItem.expireDate);

        // 计算最早过期时间
        final sortedByExpiry = List<UserItem>.from(items)
          ..sort((a, b) => a.expireDate.compareTo(b.expireDate));
        final earliestExpiry = sortedByExpiry.first.expireDate;

        // 计算剩余天数
        final daysRemaining = earliestExpiry.difference(now).inDays;

        final data = <String, dynamic>{
          'productId': productId,
          'productName': firstItem.productName,
          'count': items.length,
          'isExpired': isExpired,
          'earliestExpiry': earliestExpiry.toIso8601String(),
          'daysRemaining': isExpired ? 0 : daysRemaining,
          'purchasePrice': firstItem.purchasePrice,
        };

        // 移除所有 null 值，避免 WCSession 传输问题
        data.removeWhere((key, value) => value == null);
        userItemGroups.add(data);
      }

      // 按过期状态排序（未过期的在前，然后按剩余天数排序）
      userItemGroups.sort((a, b) {
        final aExpired = a['isExpired'] as bool;
        final bExpired = b['isExpired'] as bool;
        if (aExpired != bExpired) {
          return aExpired ? 1 : -1;
        }
        final aDays = a['daysRemaining'] as int;
        final bDays = b['daysRemaining'] as int;
        return aDays.compareTo(bDays);
      });

      print('[WatchConnectivityService] 返回 ${userItemGroups.length} 个物品分组');
      return userItemGroups;
    } catch (e) {
      print('[WatchConnectivityService] 获取用户物品数据失败: $e');
      return [];
    }
  }

  // ============== 节点笔记本相关方法 ==============

  /// 获取节点笔记本列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchNodesNotebooks() async {
    try {
      final nodesPlugin = NodesPlugin.instance;
      final controller = nodesPlugin.controller;
      final notebooks = controller.notebooks;

      final List<Map<String, dynamic>> notebookItems = [];
      for (final notebook in notebooks) {
        // 递归计算节点数量
        int nodeCount = _countAllNodes(notebook.nodes);

        final data = <String, dynamic>{
          'id': notebook.id,
          'title': notebook.title,
          'icon': notebook.icon.codePoint,
          'color': notebook.color.toARGB32(),
          'nodeCount': nodeCount,
        };

        // 移除所有 null 值
        data.removeWhere((key, value) => value == null);
        notebookItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${notebookItems.length} 个节点笔记本');
      return notebookItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取节点笔记本数据失败: $e');
      return [];
    }
  }

  /// 递归计算所有节点数量
  int _countAllNodes(List<dynamic> nodes) {
    int count = nodes.length;
    for (var node in nodes) {
      final children = (node as dynamic).children as List;
      count += _countAllNodes(children);
    }
    return count;
  }

  /// 获取指定笔记本的节点列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchNodes(dynamic arguments) async {
    try {
      if (arguments is! Map) {
        throw ArgumentError('参数必须是 Map 类型');
      }

      final notebookId = arguments['notebookId'] as String?;
      if (notebookId == null) {
        throw ArgumentError('缺少 notebookId 参数');
      }

      final nodesPlugin = NodesPlugin.instance;
      final controller = nodesPlugin.controller;
      final notebook = controller.getNotebook(notebookId);

      if (notebook == null) {
        throw Exception('未找到笔记本: $notebookId');
      }

      // 递归处理节点
      List<Map<String, dynamic>> processNodes(List<dynamic> nodes, int depth) {
        final List<Map<String, dynamic>> result = [];
        for (var node in nodes) {
          final nodeMap = node.toMap() as Map<String, dynamic>;
          final children = (node as dynamic).children as List;

          final data = <String, dynamic>{
            'id': nodeMap['id'],
            'title': nodeMap['title'] ?? '',
            'status': nodeMap['status'] ?? 3, // 默认 none
            'color': (nodeMap['color'] as int?) ?? 0xFF9E9E9E,
            'tags': nodeMap['tags'] ?? [],
            'notes': _truncateText(nodeMap['notes'] ?? '', 100),
            'depth': depth,
            'hasChildren': children.isNotEmpty,
            'childrenCount': children.length,
          };

          // 移除所有 null 值
          data.removeWhere((key, value) => value == null);
          result.add(data);

          // 递归处理子节点
          if (children.isNotEmpty) {
            result.addAll(processNodes(children, depth + 1));
          }
        }
        return result;
      }

      final nodeItems = processNodes(notebook.nodes, 0);

      print('[WatchConnectivityService] 返回 ${nodeItems.length} 个节点');
      return nodeItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取节点数据失败: $e');
      return [];
    }
  }

  /// 截断文本
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ============== 物品管理相关方法 ==============

  /// 获取仓库列表（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchGoodsWarehouses() async {
    try {
      final goodsPlugin = GoodsPlugin.instance;
      final warehouses = goodsPlugin.warehouses;

      final List<Map<String, dynamic>> warehouseItems = [];
      for (final warehouse in warehouses) {
        // 计算仓库内物品总数
        int itemCount = warehouse.items.length;

        final data = <String, dynamic>{
          'id': warehouse.id,
          'title': warehouse.title,
          'icon': warehouse.icon.codePoint,
          'iconColor': warehouse.iconColor.toARGB32(),
          'itemCount': itemCount,
        };

        // 移除所有 null 值
        data.removeWhere((key, value) => value == null);
        warehouseItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${warehouseItems.length} 个仓库');
      return warehouseItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取仓库数据失败: $e');
      return [];
    }
  }

  /// 获取物品列表（供 watchOS 使用）
  /// 可以指定仓库ID来过滤，如果 warehouseId 为空则返回所有物品
  Future<List<Map<String, dynamic>>> _getWatchGoodsItems(
    dynamic arguments,
  ) async {
    try {
      final goodsPlugin = GoodsPlugin.instance;
      String? warehouseId;

      if (arguments is Map) {
        warehouseId = arguments['warehouseId'] as String?;
      }

      final List<Map<String, dynamic>> goodsItems = [];

      for (final warehouse in goodsPlugin.warehouses) {
        // 如果指定了仓库ID，只返回该仓库的物品
        if (warehouseId != null && warehouse.id != warehouseId) {
          continue;
        }

        for (final item in warehouse.items) {
          // 计算最后使用时间
          String? lastUsedText;
          if (item.lastUsedDate != null) {
            final now = DateTime.now();
            final diff = now.difference(item.lastUsedDate!);
            if (diff.inDays == 0) {
              lastUsedText = '今天';
            } else if (diff.inDays == 1) {
              lastUsedText = '昨天';
            } else if (diff.inDays < 7) {
              lastUsedText = '${diff.inDays}天前';
            } else {
              lastUsedText = DateFormat('MM-dd').format(item.lastUsedDate!);
            }
          }

          // 格式化价格
          String? priceText;
          if (item.purchasePrice != null) {
            priceText = '¥${item.purchasePrice!.toStringAsFixed(0)}';
          }

          final data = <String, dynamic>{
            'id': item.id,
            'title': item.title,
            'warehouseId': warehouse.id,
            'warehouseName': warehouse.title,
            'tags': item.tags,
            'purchasePrice': item.purchasePrice,
            'priceText': priceText,
            'status': item.status ?? 'normal',
            'lastUsedText': lastUsedText,
            'hasSubItems': item.subItems.isNotEmpty,
            'subItemsCount': item.subItems.length,
          };

          // 移除所有 null 值
          data.removeWhere((key, value) => value == null);
          goodsItems.add(data);
        }
      }

      print('[WatchConnectivityService] 返回 ${goodsItems.length} 个物品');
      return goodsItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取物品数据失败: $e');
      return [];
    }
  }

  // ============== 日历事件相关方法 ==============

  /// 获取日历事件列表（供 watchOS 使用）
  /// 返回今天和未来 7 天的事件
  Future<List<Map<String, dynamic>>> _getWatchCalendarEvents() async {
    try {
      final calendarPlugin = CalendarPlugin.instance;
      final controller = calendarPlugin.controller;

      // 获取所有事件
      final allEvents = controller.getAllEvents();

      // 筛选今天和未来 7 天的事件
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekEnd = today.add(const Duration(days: 8));

      final upcomingEvents =
          allEvents.where((event) {
            final eventDate = DateTime(
              event.startTime.year,
              event.startTime.month,
              event.startTime.day,
            );
            return (eventDate.isAtSameMomentAs(today) ||
                    eventDate.isAfter(today)) &&
                eventDate.isBefore(weekEnd);
          }).toList();

      // 按开始时间排序
      upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      final List<Map<String, dynamic>> eventItems = [];
      for (final event in upcomingEvents) {
        // 格式化时间显示
        final timeFormat = DateFormat('HH:mm');
        final startTimeStr = timeFormat.format(event.startTime);
        final endTimeStr =
            event.endTime != null ? timeFormat.format(event.endTime!) : null;

        // 计算日期状态
        final eventDate = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        String dateStatus;
        if (eventDate.isAtSameMomentAs(today)) {
          dateStatus = 'Today';
        } else {
          final diff = eventDate.difference(today).inDays;
          dateStatus = 'Day $diff';
        }

        // 格式化创建日期
        final dateFormat = DateFormat('MMM d');

        // 根据事件颜色分配霓虹边框颜色
        final neonBorderColor = _getCalendarNeonColor(event.color);

        final data = <String, dynamic>{
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'startTime': event.startTime.toIso8601String(),
          'endTime': event.endTime?.toIso8601String(),
          'startTimeStr': startTimeStr,
          'endTimeStr': endTimeStr,
          'icon': event.icon.codePoint,
          'color': event.color.toARGB32(),
          'source': event.source,
          'neonBorderColor': neonBorderColor,
          'dateStatus': dateStatus,
          'createdDate': dateFormat.format(event.startTime),
        };

        // 移除所有 null 值
        data.removeWhere((key, value) => value == null);
        eventItems.add(data);
      }

      print('[WatchConnectivityService] 返回 ${eventItems.length} 个日历事件');
      return eventItems;
    } catch (e) {
      print('[WatchConnectivityService] 获取日历事件数据失败: $e');
      return [];
    }
  }

  /// 获取日历相册数据（供 watchOS 使用）
  Future<List<Map<String, dynamic>>> _getWatchCalendarAlbumEntries() async {
    try {
      final plugin = CalendarAlbumPlugin.instance;
      final controller = plugin.calendarController;

      if (controller == null) {
        print('[WatchConnectivityService] calendarController 未初始化');
        return [];
      }

      // 获取最近 30 天的日记条目
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final List<Map<String, dynamic>> albumEntries = [];
      final Map<String, List<Map<String, dynamic>>> groupedByDate = {};

      // 遍历所有日期的日记
      controller.entries.forEach((date, entries) {
        if (date.isAfter(thirtyDaysAgo) ||
            date.isAtSameMomentAs(thirtyDaysAgo)) {
          for (final entry in entries) {
            // 获取所有图片（imageUrls + Markdown中的图片）
            final allImages = <String>[
              ...entry.imageUrls,
              ...entry.extractImagesFromMarkdown(),
            ];

            final dateStr = DateFormat('MMM d').format(entry.createdAt);
            final timeStr = DateFormat('HH:mm').format(entry.createdAt);

            // 根据日记标签或心情分配霓虹颜色
            final neonBorderColor = _getAlbumNeonColor(
              entry.tags,
              entry.mood,
            );

            final entryData = <String, dynamic>{
              'id': entry.id,
              'title': entry.title,
              'contentPreview':
                  entry.content.length > 100
                      ? '${entry.content.substring(0, 100)}...'
                      : entry.content,
              'createdAt': entry.createdAt.toIso8601String(),
              'updatedAt': entry.updatedAt.toIso8601String(),
              'dateStr': dateStr,
              'timeStr': timeStr,
              'tags': entry.tags,
              'location': entry.location,
              'mood': entry.mood,
              'weather': entry.weather,
              'imageCount': allImages.length,
              'neonBorderColor': neonBorderColor,
              'wordCount': entry.wordCount,
            };

            // 移除所有 null 值
            entryData.removeWhere((key, value) => value == null);

            // 按日期分组
            final dateKey = DateFormat('yyyy-MM-dd').format(entry.createdAt);
            groupedByDate.putIfAbsent(dateKey, () => []).add(entryData);
          }
        }
      });

      // 转换为列表并按日期降序排序
      final sortedDates =
          groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

      for (final dateKey in sortedDates) {
        albumEntries.addAll(groupedByDate[dateKey]!);
      }

      print('[WatchConnectivityService] 返回 ${albumEntries.length} 个相册条目');
      return albumEntries;
    } catch (e) {
      print('[WatchConnectivityService] 获取日历相册数据失败: $e');
      return [];
    }
  }

  /// 根据标签和心情获取相册霓虹边框颜色
  int _getAlbumNeonColor(List<String> tags, String? mood) {
    // 根据标签分配颜色
    final tagColors = {
      '旅行': 0xFF00F3FF, // neon-cyan
      '户外': 0xFF00F3FF, // neon-cyan
      '运动': 0xFF39FF14, // neon-green
      '健身': 0xFF39FF14, // neon-green
      '美食': 0xFFEC5B13, // neon-orange
      '聚会': 0xFFBC13FF, // neon-purple
      '音乐': 0xFFBC13FF, // neon-purple
      '艺术': 0xFFBC13FF, // neon-purple
    };

    for (final tag in tags) {
      if (tagColors.containsKey(tag)) {
        return tagColors[tag]!;
      }
    }

    // 根据心情分配颜色
    final moodColors = <String, int>{
      '😊': 0xFF00F3FF, // neon-cyan - 开心
      '😄': 0xFF00F3FF, // neon-cyan
      '🎉': 0xFFBC13FF, // neon-purple - 庆祝
      '😍': 0xFFBC13FF, // neon-purple
      '😢': 0xFF39FF14, // neon-green - 悲伤（绿色）
      '😡': 0xFFEC5B13, // neon-orange - 愤怒
    };

    if (mood != null && moodColors.containsKey(mood)) {
      return moodColors[mood]!;
    }

    // 默认使用青色
    return 0xFF00F3FF; // neon-cyan
  }

  /// 根据事件颜色获取霓虹边框颜色
  int _getCalendarNeonColor(Color eventColor) {
    // 根据 RGB 值判断颜色倾向
    final r = eventColor.red;
    final g = eventColor.green;
    final b = eventColor.blue;

    // 青色系
    if (g > 200 && b > 200 && r < 100) {
      return 0xFF00FFFF; // neon-cyan
    }
    // 紫色系
    if (b > 150 && r > 100 && g < 150) {
      return 0xFFBC13FE; // neon-purple
    }
    // 绿色系
    if (g > 150 && r < 150 && b < 150) {
      return 0xFF39FF14; // neon-green
    }
    // 橙色/红色系
    return 0xFFEC5B13; // neon-orange
  }
}
