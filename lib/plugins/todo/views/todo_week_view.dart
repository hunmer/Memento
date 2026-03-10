import 'package:flutter/material.dart';
import 'package:Memento/plugins/todo/models/task.dart';

/// 周视图 - 展示从周一到周日的待办事项
class TodoWeekView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task, TaskStatus) onTaskStatusChanged;
  final Function(DateTime)? onAddTask;

  const TodoWeekView({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskStatusChanged,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    // 获取本周的日期范围
    final weekDates = _getCurrentWeekDates();
    // 按日期分组任务
    final tasksByDate = _groupTasksByDate(tasks, weekDates);

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          // 顶部周信息
          _buildWeekHeader(context, weekDates),
          const SizedBox(height: 8),
          // 七天的卡片布局
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.all(4),
              children: List.generate(7, (index) {
                return _buildDayCard(
                  context,
                  dayIndex: index,
                  date: weekDates[index],
                  dayTasks: tasksByDate[index] ?? [],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建周标题
  Widget _buildWeekHeader(BuildContext context, List<DateTime> weekDates) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startDate = weekDates.first;
    final endDate = weekDates.last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_view_week,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${startDate.month}月${startDate.day}日 - ${endDate.month}月${endDate.day}日',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            '本周任务',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单日卡片
  Widget _buildDayCard(
    BuildContext context, {
    required int dayIndex,
    required DateTime date,
    required List<Task> dayTasks,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dayName = dayNames[dayIndex];
    final isToday = _isSameDay(date, DateTime.now());
    final isPast = date.isBefore(DateTime.now());

    // 排除已完成的任务
    final activeTasks =
        dayTasks.where((t) => t.status != TaskStatus.done).toList();

    // 根据任务状态设置卡片颜色
    Color cardColor;

    if (activeTasks.isEmpty) {
      // 无任务
      cardColor = Colors.grey;
    } else if (isToday) {
      // 今天有任务
      cardColor = Colors.blue;
    } else if (isPast) {
      // 过期未完成
      cardColor = Colors.orange;
    } else {
      // 未来
      cardColor = Colors.green;
    }

    final headerBgColor = cardColor.withOpacity(0.1);
    final headerBorderColor = cardColor.withOpacity(0.3);
    final titleColor = isDark ? cardColor.withOpacity(0.8) : cardColor;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: headerBorderColor, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 卡片标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerBgColor,
              border: Border(bottom: BorderSide(color: headerBorderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeTasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeTasks.length}',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (onAddTask != null)
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: 18,
                      color: titleColor,
                    ),
                    onPressed: () => onAddTask!(date),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
              ],
            ),
          ),
          // 任务列表
          Expanded(
            child:
                activeTasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 32,
                            color: Colors.green.withOpacity(0.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '无待办',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).disabledColor.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      itemCount: activeTasks.length,
                      itemBuilder: (context, index) {
                        final task = activeTasks[index];
                        return InkWell(
                          onTap: () => onTaskTap(task),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Checkbox(
                                    value: task.status == TaskStatus.done,
                                    onChanged: (val) {
                                      onTaskStatusChanged(
                                        task,
                                        val == true
                                            ? TaskStatus.done
                                            : TaskStatus.todo,
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 1.5,
                                    ),
                                    activeColor: Theme.of(context).primaryColor,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // 优先级指示器
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: task.priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  /// 获取本周的日期列表（周一到周日）
  List<DateTime> _getCurrentWeekDates() {
    final now = DateTime.now();
    // 找到本周一
    final monday = now.subtract(Duration(days: now.weekday - 1));
    // 重置时间部分为 00:00:00
    final normalizedMonday = DateTime(monday.year, monday.month, monday.day);

    // 生成周一到周日的日期
    return List.generate(7, (index) {
      return normalizedMonday.add(Duration(days: index));
    });
  }

  /// 按日期分组任务
  Map<int, List<Task>> _groupTasksByDate(
    List<Task> allTasks,
    List<DateTime> weekDates,
  ) {
    final Map<int, List<Task>> grouped = {};

    for (int i = 0; i < 7; i++) {
      grouped[i] = [];
    }

    for (final task in allTasks) {
      if (task.status == TaskStatus.done) continue;

      // 检查任务的开始日期或截止日期是否在本周的某一天
      final taskDate = task.startDate ?? task.dueDate;
      if (taskDate == null) continue;

      for (int i = 0; i < 7; i++) {
        if (_isSameDay(taskDate, weekDates[i])) {
          grouped[i]!.add(task);
          break;
        }
      }
    }

    return grouped;
  }

  /// 判断两个日期是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
