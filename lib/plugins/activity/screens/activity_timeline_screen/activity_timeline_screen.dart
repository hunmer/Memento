import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/picker/calendar_strip_date_picker.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/plugins/activity/widgets/activity_timeline.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/activity/screens/activity_calendar_screen.dart';
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
  String _searchQuery = '';
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // 监听通知点击事件
    eventManager.subscribe(
      'activity_notification_tapped',
      _onNotificationTapped,
    );

    // 监听活动添加事件
    eventManager.subscribe(
      'activity_added',
      _onActivityChanged,
    );

    // 监听活动删除事件
    eventManager.subscribe(
      'activity_deleted',
      _onActivityChanged,
    );

    // 监听活动更新事件(如果存在)
    eventManager.subscribe(
      'activity_updated',
      _onActivityChanged,
    );

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
      onActivitiesChanged: () {
        if (mounted) setState(() {});
      },
    );

    _tagController = TagController(
      activityService: _activityService,
      onTagsChanged: () {
        if (mounted) setState(() {});
      },
    );

    _viewModeController = ViewModeController();
    _viewModeController.addListener(() {
      if (mounted) setState(() {});
    });

    await _tagController.initialize();
    await _activityController.loadActivities(_selectedDate);

    // 初始化时设置当前日期的路由上下文
    _updateRouteContext(_selectedDate);
  }

  void _onDateChanged(DateTime date) {
    if (date == _selectedDate) return;

    setState(() {
      _selectedDate = date;
    });
    _activityController.loadActivities(_selectedDate);

    // 更新路由上下文
    _updateRouteContext(date);
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前日期
  void _updateRouteContext(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    RouteHistoryManager.updateCurrentContext(
      pageId: "/activity_timeline",
      title: '活动时间轴 - $dateStr',
      params: {'date': dateStr},
    );
  }

  @override
  void dispose() {
    // 清理事件监听
    eventManager.unsubscribe(
      'activity_notification_tapped',
      _onNotificationTapped,
    );
    eventManager.unsubscribe(
      'activity_added',
      _onActivityChanged,
    );
    eventManager.unsubscribe(
      'activity_deleted',
      _onActivityChanged,
    );
    eventManager.unsubscribe(
      'activity_updated',
      _onActivityChanged,
    );

    // 清理控制器
    _viewModeController.dispose();
    super.dispose();
  }

  /// 处理活动变更事件(添加、删除、更新)
  void _onActivityChanged(EventArgs args) {
    debugPrint('[ActivityTimelineScreen] 收到活动变更事件: ${args.eventName}');

    if (!_isInitialized || !mounted) return;

    // 重新加载当前日期的活动列表
    _activityController.loadActivities(_selectedDate);
  }

  /// 处理通知点击事件
  void _onNotificationTapped(EventArgs args) {
    debugPrint('[ActivityTimelineScreen] 收到通知点击事件: ${args.eventName}');

    if (!_isInitialized) {
      // 如果还没初始化完成，延迟处理
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showActivityFormFromNotification();
        }
      });
    } else {
      _showActivityFormFromNotification();
    }
  }

  /// 从通知点击显示活动表单
  void _showActivityFormFromNotification() {
    // 显示一个提示信息
    Toast.show('正在打开活动记录表单...');

    // 延迟一点时间确保SnackBar显示后再打开表单
    Future.delayed(const Duration(milliseconds: 500), () {
      _showQuickActivityForm();
    });
  }

  /// 显示快速活动表单
  void _showQuickActivityForm() async {
    if (!mounted) return;

    try {
      ActivityController.showAddActivityScreen(context);
    } catch (e) {
      debugPrint('[ActivityTimelineScreen] 打开活动表单失败: $e');

      if (mounted) {
        Toast.error('打开表单失败: $e');
      }
    }
  }

  /// 处理搜索过滤器变更
  void _onSearchFilterChanged(Map<String, bool> filters) {
    setState(() {
      _searchFilters.addAll(filters);
    });

    debugPrint('[ActivityTimelineScreen] 搜索过滤器变更: $_searchFilters');

    // 如果有搜索词，重新执行搜索
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  /// 执行搜索
  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    debugPrint('[ActivityTimelineScreen] 执行搜索: "$_searchQuery"');

    final results = <dynamic>[];

    // 搜索活动标题
    if (_searchFilters['activity'] == true) {
      for (final activity in _activityController.activities) {
        if (activity.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
          results.add({
            'type': 'activity',
            'data': activity,
            'title': activity.title,
            'subtitle': '活动',
          });
        }
      }
    }

    // 搜索标签
    if (_searchFilters['tag'] == true) {
      for (final activity in _activityController.activities) {
        for (final tag in activity.tags) {
          if (tag.toLowerCase().contains(_searchQuery.toLowerCase())) {
            final existing = results.firstWhere(
              (item) => item['data'] == activity,
              orElse: () => null,
            );
            if (existing == null) {
              results.add({
                'type': 'activity_tag',
                'data': activity,
                'title': activity.title,
                'subtitle': '标签匹配',
                'tag': tag,
              });
            }
            break;
          }
        }
      }
    }

    // 搜索注释/描述
    if (_searchFilters['comment'] == true) {
      for (final activity in _activityController.activities) {
        if (activity.description?.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ==
            true) {
          results.add({
            'type': 'activity_comment',
            'data': activity,
            'title': activity.title,
            'subtitle': '注释匹配',
            'description': activity.description,
          });
        }
      }
    }

    setState(() {
      _searchResults = results;
    });

    debugPrint('[ActivityTimelineScreen] 搜索完成，找到 ${results.length} 个结果');
  }

  /// 处理搜索内容变更
  void _onSearchChanged(String value) {
    _searchQuery = value;
    _performSearch();
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '输入关键词搜索' : '未找到匹配结果',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试调整搜索条件或过滤器',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final activity = result['data'];
        final type = result['type'];
        final title = result['title'];
        final subtitle = result['subtitle'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActivityColor(activity),
              child: Icon(_getActivityIcon(type), color: Colors.white),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                if (result['tag'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Chip(
                      label: Text(
                        result['tag'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (result['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      result['description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            onTap: () {
              _activityController.editActivity(context, activity);
            },
          ),
        );
      },
    );
  }

  /// 获取活动颜色
  Color _getActivityColor(dynamic activity) {
    if (activity.color != null) {
      return activity.color;
    }
    return Colors.blue;
  }

  /// 获取活动图标
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'activity':
        return Icons.event;
      case 'activity_tag':
        return Icons.label;
      case 'activity_comment':
        return Icons.comment;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SuperCupertinoNavigationWrapper(
      title: Text('activity_myActivities'.tr),
      largeTitle: 'activity_myActivities'.tr,
      enableSearchBar: true,
      searchPlaceholder: 'activity_searchPlaceholder'.tr,
      onSearchChanged: _onSearchChanged,
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
                height: 70,
                itemWidth: 54,
                itemSpacing: 12,
                listPadding: const EdgeInsets.only(left: 16, right: 8),
                calendarButtonPadding: const EdgeInsets.only(right: 16),
                showCalendarButton: true,
              ),
              // 根据视图模式显示不同的视图
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child:
                      _viewModeController.isGridMode
                          ? ActivityGridView(
                            key: ValueKey(
                              'grid_${_selectedDate.millisecondsSinceEpoch}',
                            ),
                            activities: _activityController.activities,
                            selectedDate: _selectedDate,
                            onActivityTap:
                                (activity) => _activityController.editActivity(
                                  context,
                                  activity,
                                ),
                            onUnrecordedTimeTap: (start, end) {
                              ActivityController.showAddActivityScreen(
                                context,
                                start: start,
                                end: end,
                              );
                            },
                            onSelectionChanged: (start, end) {
                              if (start != null && end != null) {
                                final minutes = end.difference(start).inMinutes;
                                final hours = minutes ~/ 60;
                                final mins = minutes % 60;
                                final durationText = hours > 0
                                    ? '$hours小时$mins分钟' : '$mins分钟';
                                Toast.show(
                                  '${DateFormat('H:mm').format(start)} - ${DateFormat('H:mm').format(end)} ($durationText)',
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                            },
                          )
                          : ActivityTimeline(
                            key: ValueKey(
                              'timeline_${_selectedDate.millisecondsSinceEpoch}',
                            ),
                            activities: _activityController.activities,
                            onDeleteActivity:
                                _activityController.deleteActivity,
                            onActivityTap:
                                (activity) => _activityController.editActivity(
                                  context,
                                  activity,
                                ),
                            onUnrecordedTimeTap: (start, end) {
                              ActivityController.showAddActivityScreen(context);
                            },
                            getTagIcons: _tagController.getTagIcons,
                            getTagColors: _tagController.getTagColors,
                          ),
                ),
              ),
            ],
          ),
          // FloatingActionButton - 移到右上角作为 actions
        ],
      ),
      // 搜索结果页面
      searchBody: _buildSearchResults(),
      enableLargeTitle: true,
      actions: [
        // 日历视图按钮
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityCalendarScreen(
                    activityService: _activityService,
                  ),
                ),
              );
            },
            tooltip: '日历视图',
          ),
        ),
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
        // 添加活动的按钮（使用IconButton避免Hero冲突）
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => ActivityController.showAddActivityScreen(context),
            tooltip: '添加活动',
          ),
        ),
      ],
    );
  }
}
