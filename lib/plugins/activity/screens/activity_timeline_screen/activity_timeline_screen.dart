import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../../../core/event/event.dart';
import '../../../../widgets/calendar_strip_date_picker.dart';
import '../../services/activity_service.dart';
import '../../widgets/activity_timeline.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import 'components/activity_grid_view.dart';
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
  final Map<String, bool> _searchFilters = {
    'activity': true,
    'tag': true,
    'comment': true,
  };

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

  /// 处理搜索过滤器变更
  void _onSearchFilterChanged(Map<String, bool> filters) {
    setState(() {
      _searchFilters.addAll(filters);
    });

    debugPrint('[ActivityTimelineScreen] 搜索过滤器变更: $_searchFilters');

    // TODO: 根据过滤器状态执行实际搜索逻辑
    // 例如：根据 activity、tag、comment 的勾选状态过滤搜索结果
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

    return SuperCupertinoNavigationWrapper(
      title: Text(
        _viewModeController.isGridMode && _viewModeController.selectedMinutes > 0
            ? '${_viewModeController.selectedMinutes}分钟已选择'
            : '活动',
      ),
      largeTitle: '活动',
      enableSearchBar: true,
      searchPlaceholder: '搜索活动、标签或注释...',
      enableSearchFilter: true,
      onSearchFilterChanged: _onSearchFilterChanged,
      body: Stack(
        children: [
          Column(
            children: [
              // Calendar Strip Date Picker
              CalendarStripDatePicker(
                selectedDate: _selectedDate,
                onDateChanged: _onDateChanged,
                displayDaysCount: 7,
                height: 70,
                itemWidth: 54,
                itemSpacing: 12,
                listPadding: const EdgeInsets.only(left: 16, right: 8),
                calendarButtonPadding: const EdgeInsets.only(right: 16),
                showCalendarButton: true,
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
          // FloatingActionButton - 移到右上角作为 actions
        ],
      ),
      enableLargeTitle: true,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      // 将原有的 AppBar actions 移到右上角
      actions: [
        // 视图切换按钮
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(
              _viewModeController.isGridMode ? Icons.timeline : Icons.grid_on,
            ),
            onPressed: _viewModeController.toggleViewMode,
            tooltip: _viewModeController.isGridMode ? '切换到时间轴视图' : '切换到网格视图',
          ),
        ),
        // 标签管理按钮
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: () => _tagController.showTagManagerDialog(context),
          tooltip: '标签管理',
        ),
        // 排序下拉菜单
        PopupMenuButton<int>(
          icon: const Icon(Icons.sort),
          tooltip: '排序',
          initialValue: _activityController.sortMode,
          onSelected: (int index) {
            _activityController.setSortMode(index);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 0,
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, size: 16),
                  SizedBox(width: 8),
                  Text('按开始时间升序'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16),
                  SizedBox(width: 8),
                  Text('按持续时间'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, size: 16),
                  SizedBox(width: 8),
                  Text('按开始时间降序'),
                ],
              ),
            ),
          ],
        ),
        // 添加活动的按钮（使用IconButton避免Hero冲突）
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _activityController.addActivity(
              context,
              _selectedDate,
              null,
              null,
              _tagController.updateRecentTags,
            ),
            tooltip: '添加活动',
          ),
        ),
      ],
    );
  }
}