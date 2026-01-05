part of 'todo_plugin.dart';

// ==================== 数据选择器注册 ====================

void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'todo.task',
    pluginId: id,
    name: '选择任务',
    icon: icon,
    color: color,
    searchable: true,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'task',
        title: '选择任务',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (_) async {
          return taskController.tasks.map((task) {
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
}
