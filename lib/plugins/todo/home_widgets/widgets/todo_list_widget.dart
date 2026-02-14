/// 待办列表小组件（2x2）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../providers.dart';
import '../utils.dart';

/// 2x2 待办列表小组件
class TodoListWidget extends StatelessWidget {
  const TodoListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
    return StatefulBuilder(
      builder: (context, setState) {
        return EventListenerContainer(
          events: const ['task_added', 'task_deleted', 'task_completed'],
          onEvent: () => setState(() {}),
          child: const _TodoListWidgetContent(),
        );
      },
    );
  }
}

/// 待办列表小组件内容
class _TodoListWidgetContent extends StatelessWidget {
  const _TodoListWidgetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = getTodoTasks(5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题
              Row(
                children: [
                  Icon(Icons.checklist, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'todo_name'.tr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 任务列表
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tasks.isNotEmpty)
                        ...tasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTaskItem(context, task, theme),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'empty_todo'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Map<String, dynamic> task,
    ThemeData theme,
  ) {
    final status = task['status'] as int;
    final priority = task['priority'] as int;

    return Row(
      children: [
        Icon(
          getStatusIcon(status),
          size: 14,
          color:
              theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            task['title'] as String,
            style: theme.textTheme.bodySmall?.copyWith(
              color: status == 2
                  ? theme.colorScheme.onPrimaryContainer.withOpacity(0.5)
                  : theme.colorScheme.onPrimaryContainer,
              decoration:
                  status == 2 ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: getPriorityColor(priority),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
