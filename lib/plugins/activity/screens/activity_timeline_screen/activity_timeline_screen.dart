import 'package:flutter/material.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../../../core/event/event.dart';
import '../../services/activity_service.dart';
import '../../widgets/activity_timeline.dart';
import '../../l10n/activity_localizations.dart';
import 'components/activity_grid_view.dart';
import 'components/timeline_app_bar.dart';
import 'controllers/activity_controller.dart';
import 'controllers/tag_controller.dart';
import 'controllers/view_mode_controller.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({super.key});

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  late DateTime _selectedDate;
  late ActivityService _activityService;
  late ActivityController _activityController;
  late TagController _tagController;
  late ViewModeController _viewModeController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // 监听通知点击事件
    eventManager.subscribe('activity_notification_tapped', _onNotificationTapped);

    _initializeService().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _initializeService() async {
    final storage = StorageManager();
    await storage.initialize();
    _activityService = ActivityService(storage, 'activity');
    
    _activityController = ActivityController(
      activityService: _activityService,
      onActivitiesChanged: () => setState(() {}),
    );
    
    _tagController = TagController(
      activityService: _activityService,
      onTagsChanged: () => setState(() {}),
    );
    
    _viewModeController = ViewModeController();
    _viewModeController.addListener(() {
      setState(() {});
    });

    await _tagController.initialize();
    await _activityController.loadActivities(_selectedDate);
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _activityController.loadActivities(_selectedDate);
  }

  @override
  void dispose() {
    // 清理事件监听
    eventManager.unsubscribe('activity_notification_tapped', _onNotificationTapped);

    // 清理控制器
    _viewModeController.dispose();
    super.dispose();
  }

  /// 处理通知点击事件
  void _onNotificationTapped(EventArgs args) {
    debugPrint('[ActivityTimelineScreen] 收到通知点击事件: ${args.eventName}');

    if (!_isInitialized) {
      // 如果还没初始化完成，延迟处理
      Future.delayed(const Duration(milliseconds: 500), () {
        _showActivityFormFromNotification();
      });
    } else {
      _showActivityFormFromNotification();
    }
  }

  /// 从通知点击显示活动表单
  void _showActivityFormFromNotification() {
    // 显示一个提示信息
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在打开活动记录表单...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 延迟一点时间确保SnackBar显示后再打开表单
    Future.delayed(const Duration(milliseconds: 500), () {
      _showQuickActivityForm();
    });
  }

  /// 显示快速活动表单
  void _showQuickActivityForm() async {
    if (!mounted) return;

    final now = DateTime.now();

    // 尝试检测最优的活动时间
    try {
      // 这里可以添加智能时间检测逻辑，但现在直接使用当前时间
      final optimalTime = now;

      await _activityController.addActivity(
        context,
        optimalTime,
        null, // 不预设开始时间，让用户在表单中选择
        null, // 不预设结束时间
        _tagController.updateRecentTags,
      );
    } catch (e) {
      debugPrint('[ActivityTimelineScreen] 打开活动表单失败: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开表单失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getWeekDayName(int weekday) {
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekDays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: TimelineAppBar(
        tagController: _tagController,
        activityController: _activityController,
        viewModeController: _viewModeController,
      ),
      body: Column(
        children: [
          // Calendar Strip Date Picker
          Container(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      itemBuilder: (context, index) {
                        // Calculate date for this item (Selected Date - 3 days + index)
                        // This keeps the selected date in the middle (index 3)
                        final date = _selectedDate
                            .subtract(const Duration(days: 3))
                            .add(Duration(days: index));
                        final isSelected = date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;
                        final isToday = date.year == DateTime.now().year &&
                            date.month == DateTime.now().month &&
                            date.day == DateTime.now().day;

                        return GestureDetector(
                          onTap: () => _onDateChanged(date),
                          child: Container(
                            width: 54,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 1,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getWeekDayName(date.weekday),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Fixed Date Picker Button
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.fromSeed(
                                seedColor: Theme.of(context).primaryColor,
                                brightness: Theme.of(context).brightness,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        _onDateChanged(picked);
                      }
                    },
                    child: Container(
                      width: 54,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 根据视图模式显示不同的视图
          Expanded(
            child: _viewModeController.isGridMode
                ? ActivityGridView(
                    activities: _activityController.activities,
                    selectedDate: _selectedDate,
                    onActivityTap: (activity) => _activityController.editActivity(context, activity),
                    onUnrecordedTimeTap: (start, end) {
                      _activityController.addActivity(
                        context,
                        _selectedDate,
                        TimeOfDay(hour: start.hour, minute: start.minute),
                        TimeOfDay(hour: end.hour, minute: end.minute),
                        _tagController.updateRecentTags,
                      ).then((_) {
                        _viewModeController.clearSelectedMinutes();
                      });
                    },
                    onSelectionChanged: (start, end) {
                      if (start != null && end != null) {
                        final minutes = end.difference(start).inMinutes;
                        _viewModeController.updateSelectedMinutes(minutes);
                      } else {
                        _viewModeController.clearSelectedMinutes();
                      }
                    },
                  )
                : ActivityTimeline(
                    activities: _activityController.activities,
                    onDeleteActivity: _activityController.deleteActivity,
                    onActivityTap: (activity) => _activityController.editActivity(context, activity),
                    onUnrecordedTimeTap: (start, end) {
                      _activityController.addActivity(
                        context,
                        _selectedDate,
                        TimeOfDay(hour: start.hour, minute: start.minute),
                        TimeOfDay(hour: end.hour, minute: end.minute),
                        _tagController.updateRecentTags,
                      );
                    },
                  ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _activityController.addActivity(
      //     context,
      //     _selectedDate,
      //     null,
      //     null,
      //     _tagController.updateRecentTags,
      //   ),
      //   tooltip:
      //       ActivityLocalizations.of(context).addActivity,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}