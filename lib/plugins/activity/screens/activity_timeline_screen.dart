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

  // 标签组
  late List<TagGroup> _tagGroups;
  // 最近使用的标签
  final List<String> _recentTags = [];

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
    // 初始化标签组
    _tagGroups = [
      TagGroup(name: '最近使用', tags: []),
      TagGroup(name: '工作', tags: ['会议', '编程', '写作', '阅读', '学习']),
      TagGroup(name: '生活', tags: ['运动', '购物', '休息', '娱乐', '社交']),
      TagGroup(name: '健康', tags: ['锻炼', '冥想', '饮食', '睡眠']),
    ];
    // 初始化服务
    _initializeService();
  }

  Future<void> _initializeService() async {
    final storage = StorageManager();
    await storage.initialize();
    _activityService = ActivityService(storage, 'activity');

    // 加载保存的标签组
    await _loadTagGroups();

    // 加载活动
    _loadActivities();
  }

  // 加载保存的标签组
  Future<void> _loadTagGroups() async {
    try {
      final savedGroups = await _activityService.getTagGroups();
      if (savedGroups.isNotEmpty) {
        setState(() {
          _tagGroups = savedGroups;
          // 确保最近使用标签组总是存在
          if (!_tagGroups.any((group) => group.name == '最近使用')) {
            _tagGroups.insert(0, TagGroup(name: '最近使用', tags: []));
          }
        });
      }

      // 加载最近使用的标签
      final recentTags = await _activityService.getRecentTags();
      if (recentTags.isNotEmpty) {
        setState(() {
          _recentTags.clear();
          _recentTags.addAll(recentTags);

          // 更新最近使用标签组
          final recentGroupIndex = _tagGroups.indexWhere(
            (g) => g.name == '最近使用',
          );
          if (recentGroupIndex != -1) {
            _tagGroups[recentGroupIndex] = TagGroup(
              name: '最近使用',
              tags: recentTags,
            );
          }
        });
      }
    } catch (e) {
      // 处理错误
      debugPrint('加载标签组失败: $e');
    }
  }

  // 保存标签组
  Future<void> _saveTagGroups() async {
    try {
      await _activityService.saveTagGroups(_tagGroups);
    } catch (e) {
      debugPrint('保存标签组失败: $e');
    }
  }

  // 更新最近使用的标签
  Future<void> _updateRecentTags(List<String> tags) async {
    if (tags.isEmpty) return;

    // 更新最近使用标签列表
    for (final tag in tags) {
      _recentTags.remove(tag); // 如果已存在，先移除
      _recentTags.insert(0, tag); // 添加到最前面
    }

    // 限制最近使用标签数量
    if (_recentTags.length > 10) {
      _recentTags.removeRange(10, _recentTags.length);
    }

    // 更新最近使用标签组
    final recentGroupIndex = _tagGroups.indexWhere((g) => g.name == '最近使用');
    if (recentGroupIndex != -1) {
      _tagGroups[recentGroupIndex] = TagGroup(
        name: '最近使用',
        tags: List.from(_recentTags),
      );
    }

    // 保存最近使用的标签
    await _activityService.saveRecentTags(_recentTags);

    // 保存标签组
    await _saveTagGroups();
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

  // 删除活动的方法
  Future<void> _deleteActivity(ActivityRecord activity) async {
    await _activityService.deleteActivity(activity);
    _loadActivities();
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

              // 更新最近使用的标签
              if (activity.tags.isNotEmpty) {
                await _updateRecentTags(activity.tags);
              }

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
          (context) => TagManagerDialog(
            groups: _tagGroups,
            selectedTags: _selectedTags,
            onGroupsChanged: (updatedGroups) {
              // 保存更新后的标签组
              setState(() {
                _tagGroups = updatedGroups;
              });
              _saveTagGroups();
            },
          ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
      });
      // 更新最近使用的标签
      await _updateRecentTags(result);
      // 根据选中的标签过滤活动
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
              onDeleteActivity: _deleteActivity,
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

                          // 更新最近使用的标签
                          if (updatedActivity.tags.isNotEmpty) {
                            await _updateRecentTags(updatedActivity.tags);
                          }

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
