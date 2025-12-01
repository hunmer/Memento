import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../todo_plugin.dart';
import '../models/task.dart';

/// 待办列表小组件配置界面
class TodoListSelectorScreen extends StatefulWidget {
  /// 小组件ID（Android appWidgetId）
  final int? widgetId;

  const TodoListSelectorScreen({
    super.key,
    this.widgetId,
  });

  @override
  State<TodoListSelectorScreen> createState() => _TodoListSelectorScreenState();
}

class _TodoListSelectorScreenState extends State<TodoListSelectorScreen> {
  final TodoPlugin _todoPlugin = TodoPlugin.instance;
  final TextEditingController _titleController = TextEditingController();

  /// 时间范围选项
  static const Map<String, String> _timeRangeOptions = {
    'today': '今日',
    'week': '本周',
    'month': '本月',
    'all': '所有',
  };

  String _selectedTimeRange = 'today';

  @override
  void initState() {
    super.initState();
    // 默认标题为空，显示时间范围对应的默认标题
    _titleController.text = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// 根据时间范围筛选任务
  List<Task> _getFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tasks = _todoPlugin.taskController.tasks;

    switch (_selectedTimeRange) {
      case 'today':
        return tasks.where((task) {
          if (task.status == TaskStatus.done) return false;
          if (task.startDate == null && task.dueDate == null) return true;

          final startDay = task.startDate != null
              ? DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day)
              : null;
          final dueDay = task.dueDate != null
              ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
              : null;

          if (startDay != null && dueDay != null) {
            return !startDay.isAfter(today) && !dueDay.isBefore(today);
          } else if (startDay != null) {
            return !startDay.isAfter(today);
          } else if (dueDay != null) {
            return !dueDay.isBefore(today);
          }
          return true;
        }).toList();

      case 'week':
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return tasks.where((task) {
          if (task.status == TaskStatus.done) return false;
          if (task.startDate == null && task.dueDate == null) return true;

          final startDay = task.startDate != null
              ? DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day)
              : null;
          final dueDay = task.dueDate != null
              ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
              : null;

          if (startDay != null && dueDay != null) {
            return !(dueDay.isBefore(weekStart) || startDay.isAfter(weekEnd));
          } else if (startDay != null) {
            return !startDay.isAfter(weekEnd);
          } else if (dueDay != null) {
            return !dueDay.isBefore(weekStart);
          }
          return true;
        }).toList();

      case 'month':
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return tasks.where((task) {
          if (task.status == TaskStatus.done) return false;
          if (task.startDate == null && task.dueDate == null) return true;

          final startDay = task.startDate != null
              ? DateTime(task.startDate!.year, task.startDate!.month, task.startDate!.day)
              : null;
          final dueDay = task.dueDate != null
              ? DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day)
              : null;

          if (startDay != null && dueDay != null) {
            return !(dueDay.isBefore(monthStart) || startDay.isAfter(monthEnd));
          } else if (startDay != null) {
            return !startDay.isAfter(monthEnd);
          } else if (dueDay != null) {
            return !dueDay.isBefore(monthStart);
          }
          return true;
        }).toList();

      case 'all':
      default:
        return tasks.where((task) => task.status != TaskStatus.done).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置待办列表小组件'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 标题设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.title, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '小组件标题',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '留空则使用默认标题（${_timeRangeOptions[_selectedTimeRange]}）',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 时间范围选择
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '时间范围',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeRangeOptions.entries.map((entry) {
                      final isSelected = _selectedTimeRange == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTimeRange = entry.key;
                            });
                          }
                        },
                        selectedColor: const Color(0xFF2dd4bf).withAlpha(50),
                        checkmarkColor: const Color(0xFF2dd4bf),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF2dd4bf)
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 预览
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '预览（${filteredTasks.length} 个任务）',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 模拟小组件样式
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题栏
                        Row(
                          children: [
                            Text(
                              _titleController.text.isEmpty
                                  ? _timeRangeOptions[_selectedTimeRange]!
                                  : _titleController.text,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2dd4bf),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredTasks.length}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5eeada),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.add,
                              color: Color(0xFF2dd4bf),
                              size: 32,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 任务列表（最多显示4个）
                        ...filteredTasks.take(4).map((task) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),

                        if (filteredTasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                '暂无待办任务',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveAndFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2dd4bf),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '确认配置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// 保存配置并关闭界面
  Future<void> _saveAndFinish() async {
    if (widget.widgetId == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      // 保存时间范围配置
      await HomeWidget.saveWidgetData<String>(
        'todo_list_range_${widget.widgetId}',
        _selectedTimeRange,
      );

      // 保存标题配置
      await HomeWidget.saveWidgetData<String>(
        'todo_list_title_${widget.widgetId}',
        _titleController.text,
      );

      // 同步任务数据到小组件
      await _syncTasksToWidget();

      // 更新小组件
      await HomeWidget.updateWidget(
        name: 'TodoListWidgetProvider',
        iOSName: 'TodoListWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.TodoListWidgetProvider',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '已配置「${_titleController.text.isEmpty ? _timeRangeOptions[_selectedTimeRange] : _titleController.text}」'),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 同步任务数据到小组件
  /// 同步所有未完成任务（包含日期信息），让 Android 端按时间范围过滤
  Future<void> _syncTasksToWidget() async {
    try {
      // 获取所有未完成任务（不按时间范围过滤，让 Android 端过滤）
      final allTasks = _todoPlugin.taskController.tasks
          .where((task) => task.status != TaskStatus.done)
          .toList();

      // 构建任务数据（包含日期字段，供 Android 端过滤使用）
      final taskList = allTasks.map((task) {
        return {
          'id': task.id,
          'title': task.title,
          'completed': task.status == TaskStatus.done,
          'startDate': task.startDate?.toIso8601String(),
          'dueDate': task.dueDate?.toIso8601String(),
        };
      }).toList();

      // 构建小组件数据
      final widgetData = jsonEncode({
        'tasks': taskList,
        'total': taskList.length,
      });

      // 保存到 SharedPreferences
      await HomeWidget.saveWidgetData<String>(
        'todo_list_widget_data',
        widgetData,
      );

      debugPrint('待办列表数据已同步: ${taskList.length} 个任务');
    } catch (e) {
      debugPrint('同步待办列表数据失败: $e');
    }
  }
}
