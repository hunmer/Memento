import 'package:flutter/material.dart';
import '../../../core/storage/storage_manager.dart';
import '../models/activity_record.dart';
import '../services/activity_service.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/activity_form.dart';
import '../widgets/tag_manager_dialog.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({super.key});

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  late ActivityService _activityService;
  List<ActivityRecord> _activities = [];
  // 排序方式：0-默认（起始时间），1-活动时长，2-起始时间
  int _sortMode = 0;
  List<String> _selectedTags = [];

  // 示例标签组
  final List<TagGroup> _tagGroups = [
    TagGroup(name: '工作', tags: ['会议', '编程', '写作', '阅读', '学习']),
    TagGroup(name: '生活', tags: ['运动', '购物', '休息', '娱乐', '社交']),
    TagGroup(name: '健康', tags: ['锻炼', '冥想', '饮食', '睡眠']),
  ];

  void _sortActivities() {
    setState(() {
      switch (_sortMode) {
        case 1: // 按活动时长排序
          _activities.sort(
            (a, b) => b.endTime
                .difference(b.startTime)
                .compareTo(a.endTime.difference(a.startTime)),
          );
          break;
        case 2: // 按起始时间排序（降序）
          _activities.sort((a, b) => b.startTime.compareTo(a.startTime));
          break;
        case 0: // 默认按起始时间排序（升序）
        default:
          _activities.sort((a, b) => a.startTime.compareTo(b.startTime));
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // 初始化服务
    _initializeService();
  }

  Future<void> _initializeService() async {
    final storage = StorageManager();
    await storage.initialize();
    _activityService = ActivityService(storage, 'activity');
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final activities = await _activityService.getActivitiesForDate(
      _selectedDate,
    );
    setState(() {
      _activities = activities;
    });
    _sortActivities();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadActivities();
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ActivityForm(
            onSave: (ActivityRecord activity) async {
              await _activityService.saveActivity(activity);
              _loadActivities();
            },
            selectedDate: _selectedDate,
          ),
    );
  }

  Future<void> _showTagManagerDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder:
          (context) =>
              TagManagerDialog(groups: _tagGroups, selectedTags: _selectedTags),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
      });
      // 这里可以根据选中的标签过滤活动
      _filterActivitiesByTags();
    }
  }

  void _filterActivitiesByTags() {
    if (_selectedTags.isEmpty) {
      _loadActivities();
      return;
    }

    // 根据选中的标签过滤活动
    _loadActivities().then((_) {
      setState(() {
        _activities =
            _activities.where((activity) {
              return activity.tags.any((tag) => _selectedTags.contains(tag));
            }).toList();
        _sortActivities();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活动时间线'),
        actions: [
          // 标签管理按钮
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: _showTagManagerDialog,
            tooltip: '标签管理',
          ),
          // 排序下拉菜单
          PopupMenuButton<int>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            initialValue: _sortMode,
            onSelected: (int index) {
              setState(() {
                _sortMode = index;
                _sortActivities();
              });
            },
            itemBuilder:
                (context) => [
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
                        Text('按活动时长排序'),
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
        ],
      ),
      body: Column(
        children: [
          // 日期选择器
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    _onDateChanged(
                      _selectedDate.subtract(const Duration(days: 1)),
                    );
                  },
                ),
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _onDateChanged(picked);
                    }
                  },
                  child: Text(
                    '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    _onDateChanged(_selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
          ),
          // 活动时间线
          Expanded(
            child: ActivityTimeline(
              activities: _activities,
              onActivityTap: (activity) {
                showDialog(
                  context: context,
                  builder:
                      (context) => ActivityForm(
                        activity: activity,
                        onSave: (ActivityRecord updatedActivity) async {
                          await _activityService.updateActivity(
                            activity,
                            updatedActivity,
                          );
                          _loadActivities();
                        },
                        selectedDate: _selectedDate,
                      ),
                );
              },
              onUnrecordedTimeTap: (start, end) {
                showDialog(
                  context: context,
                  builder:
                      (context) => ActivityForm(
                        selectedDate: _selectedDate,
                        initialStartTime: start,
                        initialEndTime: end,
                        onSave: (ActivityRecord activity) async {
                          await _activityService.saveActivity(activity);
                          _loadActivities();
                        },
                      ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
