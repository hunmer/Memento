import 'package:get/get.dart';
import 'dart:async';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';
import 'package:Memento/plugins/todo/widgets/task_list_view.dart';
import 'package:Memento/plugins/todo/widgets/task_form.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
import 'package:Memento/plugins/todo/views/todo_four_quadrant_view.dart';
import 'package:Memento/plugins/todo/widgets/history_completed_view.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'todo_item_detail.dart';

class TodoBottomBarView extends StatefulWidget {
  const TodoBottomBarView({super.key});

  @override
  State<TodoBottomBarView> createState() => _TodoBottomBarViewState();
}

class _TodoBottomBarViewState extends State<TodoBottomBarView>
    with SingleTickerProviderStateMixin {
  late TodoPlugin _plugin;
  late TabController _tabController;
  Timer? _timer;
  int _currentPage = 0;

  final GlobalKey _bottomBarKey = GlobalKey();

  // 搜索查询变量
  String _searchQuery = '';

  // 过滤条件状态（由 View 自己管理）
  Map<String, dynamic>? _currentFilter;

  // 获取页面颜色
  List<Color> get _colors => [
    Colors.blue, // 第一个tab的颜色
    Colors.green, // 第二个tab的颜色
  ];

  @override
  void initState() {
    super.initState();
    _plugin = TodoPlugin.instance;
    _tabController = TabController(length: 2, vsync: this);

    // 监听tab切换
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentPage = _tabController.index;
        });
        // 更新路由上下文
        _updateRouteContext();
      }
    });

    // 定时器用于更新计时器显示
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool hasActiveTimer = false;
      for (final task in _plugin.taskController.tasks) {
        if (task.status == TaskStatus.inProgress && task.startTime != null) {
          hasActiveTimer = true;
          break;
        }
      }

      if (hasActiveTimer) {
        setState(() {});
      }
    });

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();

      // 检查是否有 action: create 参数，用于从小组件打开新建任务表单
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['action'] == 'create') {
        _openTaskForm();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前页面状态
  void _updateRouteContext() {
    String pageId;
    String title;
    Map<String, dynamic> params = {};

    if (_currentPage == 0) {
      // 待办列表页
      final taskCount = _plugin.taskController.tasks.length;

      if (_searchQuery.isNotEmpty) {
        pageId = '/todo_list_search';
        title = '待办事项 - 搜索: $_searchQuery';
        params['searchQuery'] = _searchQuery;
        params['resultCount'] = taskCount;
      } else {
        pageId = '/todo_list';
        title = '待办事项';
        params['taskCount'] = taskCount;
      }

      params['viewMode'] = _plugin.taskController.isGridView ? 'grid' : 'list';
      params['sortBy'] = _plugin.taskController.sortBy.toString();
    } else {
      // 历史记录页
      pageId = '/todo_history';
      title = '待办历史记录';
      params['completedCount'] = _plugin.taskController.completedTasks.length;
    }

    RouteHistoryManager.updateCurrentContext(
      pageId: pageId,
      title: title,
      params: params,
    );
  }

  /// 打开新建任务表单
  void _openTaskForm() {
    NavigationHelper.openContainerWithHero(
      context,
      (context) => TaskForm(
        taskController: _plugin.taskController,
        reminderController: _plugin.reminderController,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// 构建 FAB
  Widget _buildFab() {
    return Builder(
      builder: (context) {
        final fabColor = _colors[_currentPage];
        return FloatingActionButton(
          backgroundColor: fabColor,
          elevation: 4,
          shape: const CircleBorder(),
          onPressed: () {
            NavigationHelper.openContainerWithHero(
              context,
              (context) => TaskForm(
                taskController: _plugin.taskController,
                reminderController: _plugin.reminderController,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            );
          },
          child: Icon(
            Icons.add,
            color: fabColor.computeLuminance() < 0.5
                ? Colors.white
                : Colors.black,
            size: 32,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildTabPage(0), _buildTabPage(1)],
      ),
      fab: _buildFab(),
      children: [
        Tab(
          icon: const Icon(Icons.check_box_outlined),
          text: 'todo_todoTab'.tr,
        ),
        Tab(icon: const Icon(Icons.history), text: 'todo_historyTab'.tr),
      ],
    );
  }

  // 构建tab页面
  Widget _buildTabPage(int index) {
    switch (index) {
      case 0:
        // 使用 EventListenerContainer 监听任务事件来触发 UI 更新
        // AnimatedBuilder 会监听 taskController 的变化并重建 UI
        return EventListenerContainer(
          events: [
            'task_added',
            'task_updated',
            'task_deleted',
            'task_completed',
          ],
          onEvent: () {}, // AnimatedBuilder 会处理更新
          child: _buildTaskListView(),
        );
      case 1:
        return _buildHistoryView();
      default:
        return _buildTaskListView();
    }
  }

  /// 构建过滤条件列表
  List<FilterItem> _buildFilterItems() {
    // 获取所有可用标签
    final availableTags = _plugin.taskController.getAllTags();

    return [
      // 1. 标签多选过滤
      if (availableTags.isNotEmpty)
        FilterItem(
          id: 'tags',
          title: 'todo_tags'.tr,
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            return FilterBuilders.buildTagsFilter(
              context: context,
              currentValue: currentValue,
              onChanged: onChanged,
              availableTags: availableTags,
            );
          },
          getBadge: FilterBuilders.tagsBadge,
        ),

      // 2. 优先级过滤
      FilterItem(
        id: 'priority',
        title: 'todo_priority'.tr,
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildPriorityFilter<TaskPriority>(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            priorityLabels: {
              TaskPriority.low: 'todo_low'.tr,
              TaskPriority.medium: 'todo_medium'.tr,
              TaskPriority.high: 'todo_high'.tr,
            },
            priorityColors: const {
              TaskPriority.low: Colors.green,
              TaskPriority.medium: Colors.orange,
              TaskPriority.high: Colors.red,
            },
          );
        },
        getBadge:
            (value) => FilterBuilders.priorityBadge(value, {
              TaskPriority.low: 'todo_low'.tr,
              TaskPriority.medium: 'todo_medium'.tr,
              TaskPriority.high: 'todo_high'.tr,
            }),
      ),

      // 3. 日期范围过滤
      FilterItem(
        id: 'dateRange',
        title: 'todo_dateRange'.tr,
        type: FilterType.dateRange,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildDateRangeFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: FilterBuilders.dateRangeBadge,
      ),

      // 4. 完成状态过滤
      FilterItem(
        id: 'status',
        title: 'todo_status'.tr,
        type: FilterType.checkbox,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildCheckboxFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            options: {
              'showCompleted': 'todo_showCompleted'.tr,
              'showIncomplete': 'todo_showIncomplete'.tr,
            },
          );
        },
        getBadge: FilterBuilders.checkboxBadge,
        initialValue: const {'showCompleted': true, 'showIncomplete': true},
      ),
    ];
  }

  /// 应用多条件过滤
  void _applyMultiFilters(Map<String, dynamic> filters) {
    // 构建过滤参数
    final filterParams = <String, dynamic>{};

    // 标签过滤
    if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
      filterParams['tags'] = filters['tags'];
    }

    // 优先级过滤
    if (filters['priority'] != null) {
      filterParams['priority'] = filters['priority'];
    }

    // 日期范围过滤
    if (filters['dateRange'] != null) {
      final range = filters['dateRange'] as DateTimeRange;
      filterParams['startDate'] = range.start;
      filterParams['endDate'] = range.end;
    }

    // 完成状态过滤
    if (filters['status'] != null) {
      final status = filters['status'] as Map<String, bool>;
      filterParams['showCompleted'] = status['showCompleted'] ?? true;
      filterParams['showIncomplete'] = status['showIncomplete'] ?? true;
    }

    // 保存过滤状态到 View 层
    _currentFilter = filterParams.isEmpty ? null : filterParams;

    // 延迟setState到当前帧结束后,避免在构建期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // 构建任务列表视图（第一个tab）
  Widget _buildTaskListView() {
    return SuperCupertinoNavigationWrapper(
      title: Text('todo_todoTasks'.tr),
      largeTitle: 'todo_todoTasks'.tr,

      enableSearchBar: true,
      searchPlaceholder: 'todo_searchTasksHint'.tr,
      enableSearchFilter: true,
      filterLabels: {
        'title': 'todo_searchTitle'.tr,
        'description': 'todo_searchDescription'.tr,
        'tag': 'todo_searchTag'.tr,
        'subtask': 'todo_searchSubtask'.tr,
      },
      onSearchChanged: (query) {
        // 实时搜索功能
        setState(() {
          _searchQuery = query;
          if (query.isEmpty) {
            _currentFilter = null;
          } else {
            _currentFilter = {'keyword': query};
          }
        });
        // 更新路由上下文
        _updateRouteContext();
      },
      onSearchFilterChanged: (filters) {
        // 处理搜索过滤器变化
        setState(() {
          final currentQuery = _searchQuery;
          if (currentQuery.isNotEmpty) {
            // 保存搜索过滤设置
            _currentFilter = {
              'keyword': currentQuery,
              'searchFilters': filters,
            };
          }
        });
      },
      searchBody: _buildSearchResults(),

      // 启用多条件过滤
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _applyMultiFilters,

      actions: [
        IconButton(
          icon: Icon(
            _plugin.taskController.isGridView
                ? Icons.view_list
                : Icons.dashboard,
          ),
          onPressed: _plugin.taskController.toggleViewMode,
        ),
        PopupMenuButton<SortBy>(
          icon: const Icon(Icons.sort),
          onSelected: _plugin.taskController.setSortBy,
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: SortBy.dueDate,
                  child: Text('todo_sortByDueDate'.tr),
                ),
                PopupMenuItem(
                  value: SortBy.priority,
                  child: Text('todo_sortByPriority'.tr),
                ),
                PopupMenuItem(
                  value: SortBy.custom,
                  child: Text('todo_customSort'.tr),
                ),
              ],
        ),
      ],
      body: AnimatedBuilder(
        animation: _plugin.taskController,
        builder: (context, _) {
          // 根据 View 的过滤状态决定使用过滤后的结果还是原始数据
          final tasks = _currentFilter != null
              ? _plugin.taskController.filterTasks(_currentFilter!)
              : _plugin.taskController.tasks;

          return _plugin.taskController.isGridView
              ? TodoFourQuadrantView(
                tasks: tasks,
                onTaskTap: (task) => _showTaskDetailDialog(context, task),
                onTaskStatusChanged: (task, status) {
                  _plugin.taskController.updateTaskStatus(task.id, status);
                },
              )
              : TaskListView(
                tasks: tasks,
                onTaskTap: (task) => _showTaskDetailDialog(context, task),
                onTaskStatusChanged: (task, status) {
                  _plugin.taskController.updateTaskStatus(task.id, status);
                },
                onTaskDismissed: (task) async {
                  await _plugin.taskController.deleteTask(task.id);
                },
                onTaskEdit: (task) {
                  NavigationHelper.push(
                    context,
                    TaskForm(
                      task: task,
                      taskController: _plugin.taskController,
                      reminderController: _plugin.reminderController,
                    ),
                  );
                },
                onSubtaskStatusChanged: (taskId, subtaskId, isCompleted) {
                  _plugin.taskController.updateSubtaskStatus(
                    taskId,
                    subtaskId,
                    isCompleted,
                  );
                },
              );
        },
      ),
    );
  }

  // 构建历史记录视图（第二个tab）
  Widget _buildHistoryView() {
    return SuperCupertinoNavigationWrapper(
      title: Text('todo_historyTitle'.tr),
      largeTitle: 'todo_historyTitle'.tr,

      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('todo_clearHistoryTitle'.tr),
                    content: Text('todo_clearHistoryMessage'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('todo_cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'todo_clearHistoryAction'.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );

            if (confirmed == true) {
              _plugin.taskController.clearHistory();
              setState(() {});
            }
          },
        ),
      ],
      body: HistoryCompletedView(
        completedTasks: _plugin.taskController.completedTasks,
        taskController: _plugin.taskController,
      ),
    );
  }

  // 显示任务详情对话框
  void _showTaskDetailDialog(BuildContext context, Task task) {
    SmoothBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => TodoItemDetail(
            task: task,
            taskController: _plugin.taskController,
          ),
    );
  }

  // 构建搜索结果视图
  Widget _buildSearchResults() {
    return AnimatedBuilder(
      animation: _plugin.taskController,
      builder: (context, _) {
        // 搜索结果使用 View 的过滤状态
        final searchTasks = _currentFilter != null
            ? _plugin.taskController.filterTasks(_currentFilter!)
            : _plugin.taskController.tasks;

        if (_searchQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'todo_searchInputHint'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'todo_searchSupportHint'.tr,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        if (searchTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'todo_noMatchingTasks'.tr,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'todo_tryOtherKeywords'.tr,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return TaskListView(
          tasks: searchTasks,
          onTaskTap: (task) => _showTaskDetailDialog(context, task),
          onTaskStatusChanged: (task, status) {
            _plugin.taskController.updateTaskStatus(task.id, status);
          },
          onTaskDismissed: (task) async {
            await _plugin.taskController.deleteTask(task.id);
          },
          onTaskEdit: (task) {
            NavigationHelper.push(
              context,
              TaskForm(
                task: task,
                taskController: _plugin.taskController,
                reminderController: _plugin.reminderController,
              ),
            );
          },
          onSubtaskStatusChanged: (taskId, subtaskId, isCompleted) {
            _plugin.taskController.updateSubtaskStatus(
              taskId,
              subtaskId,
              isCompleted,
            );
          },
        );
      },
    );
  }
}
