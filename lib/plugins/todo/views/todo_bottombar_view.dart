import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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

  // 用于测量底部栏高度
  double _bottomBarHeight = 0.0;
  final GlobalKey _bottomBarKey = GlobalKey();

  // 搜索查询变量
  String _searchQuery = '';

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

  // 测量底部栏高度
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bottomBarKey.currentContext != null) {
        final RenderBox renderBox =
            _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final Size size = renderBox.size;
        if (size.height != _bottomBarHeight) {
          setState(() {
            _bottomBarHeight = size.height;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color unselectedColor = colorScheme.onSurface.withOpacity(0.6);
    final Color bottomAreaColor = colorScheme.surface;

    return BottomBar(
      fit: StackFit.expand,
      icon:
          (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (_tabController.indexIsChanging) return;

                // 滚动到顶部功能
                if (_currentPage != 0) {
                  _tabController.animateTo(0);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _colors[_currentPage],
                size: width,
              ),
            ),
          ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: MediaQuery.of(context).size.width * 0.85,
      barColor: colorScheme.surface,
      start: 2,
      end: 0,
      offset: 12,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _colors[_currentPage].withOpacity(0.3),
          width: 1,
        ),
      ),
      iconDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colors[_currentPage].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      hideOnScroll: true,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body:
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
                    controller: _tabController,
                    dragStartBehavior: DragStartBehavior.down,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildTabPage(0), _buildTabPage(1)],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              ),
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color:
                    _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: const Icon(Icons.check_box_outlined),
                text: 'todo_todoTab'.tr,
              ),
              Tab(icon: const Icon(Icons.history), text: 'todo_historyTab'.tr),
            ],
          ),
          Positioned(
            top: -25,
            child: Builder(
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
                    color:
                        fabColor.computeLuminance() < 0.5
                            ? Colors.white
                            : Colors.black,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建tab页面
  Widget _buildTabPage(int index) {
    switch (index) {
      case 0:
        return _buildTaskListView();
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

    // 应用过滤
    if (filterParams.isEmpty) {
      _plugin.taskController.clearFilter();
    } else {
      _plugin.taskController.applyFilter(filterParams);
    }

    setState(() {});
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
            _plugin.taskController.clearFilter();
          } else {
            _plugin.taskController.applyFilter({'keyword': query});
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
            // 重新应用搜索，使用当前过滤设置
            _plugin.taskController.applyFilter({
              'keyword': currentQuery,
              'searchFilters': filters,
            });
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
          return _plugin.taskController.isGridView
              ? TodoFourQuadrantView(
                tasks: _plugin.taskController.tasks,
                onTaskTap: (task) => _showTaskDetailDialog(context, task),
                onTaskStatusChanged: (task, status) {
                  _plugin.taskController.updateTaskStatus(task.id, status);
                },
              )
              : TaskListView(
                tasks: _plugin.taskController.tasks,
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
        final searchTasks = _plugin.taskController.tasks;

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
