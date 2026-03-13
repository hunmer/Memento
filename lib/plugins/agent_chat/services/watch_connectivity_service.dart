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
import 'package:Memento/plugins/habits/models/habit.dart';
import 'package:Memento/plugins/timer/timer_plugin.dart';
import 'package:Memento/plugins/timer/models/timer_task.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
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
  })  : _conversationService = conversationService,
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
    final channelList = conversations
        .map((conv) => _conversationToWatchChannel(conv))
        .toList();

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
    final messageList = messages
        .map((msg) => _messageToWatchMessage(msg))
        .toList();

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
    final entryList = entries.map((tuple) {
      final date = tuple.$1;
      final entry = tuple.$2;
      return {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'title': entry.title,
        'contentPreview': entry.content.length > 100
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
        'activities': todayActivities.map((activity) => {
          'id': activity.id,
          'title': activity.title,
          'startTime': activity.startTime.toIso8601String(),
          'endTime': activity.endTime.toIso8601String(),
          'duration': activity.durationInMinutes,
          'tags': activity.tags,
          'description': activity.description,
          'mood': activity.mood,
        }).toList(),
      };

      print('[WatchConnectivityService] 返回今日活动统计: todayCount=$todayCount, todayDuration=$todayDuration');
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
  Future<List<Map<String, dynamic>>> _getWatchActivityData(dynamic arguments) async {
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
      final activityList = activities.map((activity) => {
        'id': activity.id,
        'title': activity.title,
        'startTime': activity.startTime.toIso8601String(),
        'endTime': activity.endTime.toIso8601String(),
        'duration': activity.durationInMinutes,
        'tags': activity.tags,
        'description': activity.description,
        'mood': activity.mood,
      }).toList();

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
        final subTimers = task.timerItems.map((item) {
          final data = <String, dynamic>{
            'id': item.id,
            'name': item.name,
            'type': item.type.index, // 0: countUp, 1: countDown, 2: pomodoro
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
}
