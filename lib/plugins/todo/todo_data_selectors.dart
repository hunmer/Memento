part of 'todo_plugin.dart';

// ==================== 数据选择器注册 ====================
void _registerDataSelectors() {
  // 注册任务选择器
  PluginDataSelectorService.instance.registerSelector(SelectorDefinition(
    id: 'todo.task',
    pluginId: TodoPlugin.instance.id,
    name: '选择任务',
    icon: TodoPlugin.instance.icon,
    color: TodoPlugin.instance.color,
    searchable: true,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'task',
        title: '选择任务',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (_) async {
          return TodoPlugin.instance.taskController.tasks.map((task) {
            // 构建副标题：状态 + 优先级 + 日期
            final statusText = task.status == TaskStatus.todo
                ? '待办'
                : task.status == TaskStatus.inProgress
                    ? '进行中'
                    : '已完成';
            final priorityText = task.priority == TaskPriority.low
                ? '低优先级'
                : task.priority == TaskPriority.medium
                    ? '中优先级'
                    : '高优先级';
            final dueDateText = task.dueDate != null
                ? ' | ${task.dueDate!.month}/${task.dueDate!.day}'
                : '';

            return SelectableItem(
              id: task.id,
              title: task.title,
              subtitle: '$statusText | $priorityText$dueDateText',
              icon: task.statusIcon,
              rawData: task,
            );
          }).toList();
        },
        searchFilter: (items, query) {
          if (query.isEmpty) return items;
          final lowerQuery = query.toLowerCase();
          return items.where((item) {
            final titleMatch = item.title.toLowerCase().contains(lowerQuery);
            final task = item.rawData as Task;
            final descriptionMatch = task.description?.toLowerCase().contains(lowerQuery) ?? false;
            final tagsMatch = task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
            return titleMatch || descriptionMatch || tagsMatch;
          }).toList();
        },
      ),
    ],
  ));

  // 注册公共小组件选择器
  _registerCommonWidgetsSelector();
}

/// 注册公共小组件选择器
void _registerCommonWidgetsSelector() {
  // 定义可用的公共小组件
  final widgets = [
    SelectableItem(
      id: 'roundedTaskProgress',
      title: '圆角任务进度',
      subtitle: '显示任务进度、待办列表',
      icon: Icons.task_alt,
      rawData: {'widgetId': 'roundedTaskProgress', 'widgetName': '圆角任务进度'},
    ),
    SelectableItem(
      id: 'taskListCard',
      title: '任务列表卡片',
      subtitle: '显示任务列表和计数信息',
      icon: Icons.format_list_bulleted,
      rawData: {'widgetId': 'taskListCard', 'widgetName': '任务列表卡片'},
    ),
    SelectableItem(
      id: 'colorTagTaskCard',
      title: '彩色标签任务列表',
      subtitle: '带彩色标签的任务列表',
      icon: Icons.label,
      rawData: {'widgetId': 'colorTagTaskCard', 'widgetName': '彩色标签任务列表'},
    ),
    SelectableItem(
      id: 'upcomingTasks',
      title: '即将到来的任务',
      subtitle: '显示即将到期的任务',
      icon: Icons.upcoming,
      rawData: {'widgetId': 'upcomingTasks', 'widgetName': '即将到来的任务'},
    ),
    SelectableItem(
      id: 'dailyTodoList',
      title: '每日待办列表',
      subtitle: '显示日期时间和待办任务',
      icon: Icons.today,
      rawData: {'widgetId': 'dailyTodoList', 'widgetName': '每日待办列表'},
    ),
    SelectableItem(
      id: 'roundedReminders',
      title: '圆角提醒事项列表',
      subtitle: '显示提醒事项列表',
      icon: Icons.notification_important_rounded,
      rawData: {'widgetId': 'roundedReminders', 'widgetName': '圆角提醒事项列表'},
    ),
  ];

  PluginDataSelectorService.instance.registerSelector(
    SelectorDefinition(
      id: 'todo_common_widgets',
      pluginId: TodoPlugin.instance.id,
      name: '选择小组件样式',
      icon: Icons.widgets_outlined,
      color: Colors.blue,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'widget',
          title: '选择小组件样式',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async => widgets,
        ),
      ],
    ),
  );
}
