import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 待办任务数据模型
class TodoTask {
  final String title;
  final bool isCompleted;

  const TodoTask({
    required this.title,
    required this.isCompleted,
  });

  /// 从 JSON 创建
  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  TodoTask copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return TodoTask(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 提醒信息数据模型
class TodoReminder {
  final String text;
  final String hashtag;
  final String hashtagEmoji;

  const TodoReminder({
    required this.text,
    required this.hashtag,
    required this.hashtagEmoji,
  });

  /// 从 JSON 创建
  factory TodoReminder.fromJson(Map<String, dynamic> json) {
    return TodoReminder(
      text: json['text'] as String? ?? '',
      hashtag: json['hashtag'] as String? ?? '',
      hashtagEmoji: json['hashtagEmoji'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'hashtag': hashtag,
      'hashtagEmoji': hashtagEmoji,
    };
  }
}

/// 每日待办事项小组件
class DailyTodoListWidget extends StatefulWidget {
  final String date;
  final String time;
  final List<TodoTask> tasks;
  final TodoReminder reminder;

  const DailyTodoListWidget({
    super.key,
    required this.date,
    required this.time,
    required this.tasks,
    required this.reminder,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DailyTodoListWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final tasksList = (props['tasks'] as List<dynamic>?)
            ?.map((e) => TodoTask.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final reminderJson = props['reminder'] as Map<String, dynamic>?;
    final reminder = reminderJson != null
        ? TodoReminder.fromJson(reminderJson)
        : const TodoReminder(
            text: '',
            hashtag: '',
            hashtagEmoji: '',
          );

    return DailyTodoListWidget(
      date: props['date'] as String? ?? '',
      time: props['time'] as String? ?? '',
      tasks: tasksList,
      reminder: reminder,
    );
  }

  @override
  State<DailyTodoListWidget> createState() => _DailyTodoListWidgetState();
}

class _DailyTodoListWidgetState extends State<DailyTodoListWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<TodoTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: Container(
              width: 360,
              height: 600,
              constraints: const BoxConstraints(minHeight: 400),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE4E4E7),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部日期区域
                  _HeaderSection(
                    date: widget.date,
                    time: widget.time,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  // 任务列表
                  _TasksSection(
                    tasks: _tasks,
                    onToggle: _toggleTask,
                    animation: _fadeAnimation,
                    isDark: isDark,
                  ),
                  // 底部提醒
                  _ReminderSection(
                    reminder: widget.reminder,
                    animation: _fadeAnimation,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 顶部日期区域
class _HeaderSection extends StatelessWidget {
  final String date;
  final String time;
  final Color primaryColor;
  final bool isDark;

  const _HeaderSection({
    required this.date,
    required this.time,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.black87 : Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black87 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.more_horiz,
                color: isDark ? Colors.black87 : Colors.black87,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'Done',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black87 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 任务列表区域
class _TasksSection extends StatelessWidget {
  final List<TodoTask> tasks;
  final Function(int) onToggle;
  final Animation<double> animation;
  final bool isDark;

  const _TasksSection({
    required this.tasks,
    required this.onToggle,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          // 点阵网格背景
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -20),
              child: Text(
                'Things to do today',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _TaskItem(
                    task: tasks[index],
                    onTap: () => onToggle(index),
                    animation: animation,
                    index: index,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个任务项
class _TaskItem extends StatelessWidget {
  final TodoTask task;
  final VoidCallback onTap;
  final Animation<double> animation;
  final int index;
  final bool isDark;

  const _TaskItem({
    required this.task,
    required this.onTap,
    required this.animation,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.2 + index * 0.1,
        (0.6 + index * 0.1).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  _Checkbox(
                    isChecked: task.isCompleted,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: task.isCompleted
                            ? (isDark
                                ? const Color(0xFF71717A)
                                : const Color(0xFFA1A1AA))
                            : (isDark
                                ? const Color(0xFFE4E4E7)
                                : const Color(0xFF27272A)),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 复选框组件
class _Checkbox extends StatelessWidget {
  final bool isChecked;
  final bool isDark;

  const _Checkbox({
    required this.isChecked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isChecked
            ? (isDark ? Colors.white : const Color(0xFF18181B))
            : (isDark ? const Color(0xFF27272A) : Colors.white),
        border: Border.all(
          color: isChecked
              ? (isDark ? Colors.white : const Color(0xFF18181B))
              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8)),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isChecked
          ? Icon(
              Icons.check,
              size: 16,
              color: isDark ? const Color(0xFF18181B) : Colors.white,
            )
          : null,
    );
  }
}

/// 底部提醒区域
class _ReminderSection extends StatelessWidget {
  final TodoReminder reminder;
  final Animation<double> animation;
  final bool isDark;

  const _ReminderSection({
    required this.reminder,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reminderAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: reminderAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: reminderAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - reminderAnimation.value)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF4F4F5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          reminder.text,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? const Color(0xFFE4E4E7)
                                : const Color(0xFF27272A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF831843).withOpacity(0.4)
                                : const Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reminder.hashtag,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFF472B6)
                                  : const Color(0xFFDB2777),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reminder.hashtagEmoji,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? const Color(0xFFE4E4E7)
                                : const Color(0xFF27272A),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
