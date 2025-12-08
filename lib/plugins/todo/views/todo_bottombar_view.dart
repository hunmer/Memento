import 'dart:async';
import 'dart:io';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';
import 'package:Memento/plugins/todo/widgets/task_list_view.dart';
import 'package:Memento/plugins/todo/widgets/task_form.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/todo/views/todo_four_quadrant_view.dart';
import 'package:Memento/plugins/todo/widgets/filter_dialog.dart';
import 'package:Memento/plugins/todo/widgets/history_completed_view.dart';
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
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
    final Color unselectedColor =
        _colors[_currentPage].computeLuminance() < 0.5
            ? Colors.black.withOpacity(0.6)
            : Colors.white.withOpacity(0.6);
    final Color bottomAreaColor = Theme.of(context).scaffoldBackgroundColor;

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
      barColor:
          _colors[_currentPage].computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
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
              Tab(icon: const Icon(Icons.check_box_outlined), text: '待办'),
              Tab(icon: const Icon(Icons.history), text: '历史'),
            ],
          ),
          Positioned(
            top: -25,
            child: FloatingActionButton(
              backgroundColor: _colors[_currentPage],
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(Icons.add, color: Colors.white, size: 32),
              onPressed: () {
                NavigationHelper.push(
                  context,
                  TaskForm(
                    taskController: _plugin.taskController,
                    reminderController: _plugin.reminderController,
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

  // 构建任务列表视图（第一个tab）
  Widget _buildTaskListView() {
    return SuperCupertinoNavigationWrapper(
      title: const Text('待办事项'),
      largeTitle: '待办事项',
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      enableSearchBar: true,
      searchPlaceholder: '搜索任务标题、备注、标签...',
      enableSearchFilter: true,
      filterLabels: const {
        'title': '标题',
        'description': '备注',
        'tag': '标签',
        'subtask': '子任务',
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
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: _showFilterDialog,
        ),
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
                  child: Text(TodoLocalizations.of(context).sortByDueDate),
                ),
                PopupMenuItem(
                  value: SortBy.priority,
                  child: Text(TodoLocalizations.of(context).sortByPriority),
                ),
                PopupMenuItem(
                  value: SortBy.custom,
                  child: Text(TodoLocalizations.of(context).customSort),
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
                onTaskDismissed: (task) {
                  _plugin.taskController.deleteTask(task.id);
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
      title: const Text('历史记录'),
      largeTitle: '历史记录',
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('清空历史记录'),
                    content: const Text('确定要清空所有历史记录吗？此操作不可撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          '清空',
                          style: TextStyle(color: Colors.red),
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

  // 显示过滤器对话框
  void _showFilterDialog() async {
    final tags =
        _plugin.taskController.tasks
            .expand((task) => task.tags)
            .toSet()
            .toList();
    final filter = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => FilterDialog(
            onFilter: (filter) => Navigator.pop(context, filter),
            availableTags: tags,
          ),
    );
    if (filter != null) {
      _plugin.taskController.applyFilter(filter);
    }
  }

  // 显示任务详情对话框
  void _showTaskDetailDialog(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TodoItemDetail(
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
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '输入关键词开始搜索',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '支持搜索：标题、备注、标签、子任务',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
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
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '未找到匹配的任务',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '尝试使用其他关键词',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
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
          onTaskDismissed: (task) {
            _plugin.taskController.deleteTask(task.id);
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
