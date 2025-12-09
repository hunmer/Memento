import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/widgets/widget_config_editor/index.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/todo/l10n/todo_localizations.dart';

/// 待办列表小组件配置界面
///
/// 提供实时预览、双色配置和透明度调节功能。
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
  late WidgetConfig _widgetConfig;
  bool _isLoading = true;

  String _selectedTimeRange = 'today';

  @override
  void initState() {
    super.initState();
    // 初始化双色配置
    _widgetConfig = WidgetConfig(
      colors: [
        const ColorConfig(
          key: 'primary',
          label: 'Primary Color',
          defaultValue: Color(0xFF2dd4bf),
          currentValue: Color(0xFF2dd4bf),
        ),
        const ColorConfig(
          key: 'accent',
          label: 'Accent Color',
          defaultValue: Color(0xFF5eeada),
          currentValue: Color(0xFF5eeada),
        ),
      ],
      opacity: 1.0,
    );
    _loadSavedConfig();
  }

  /// 获取时间范围选项
  Map<String, String> _getTimeRangeOptions(BuildContext context) {
    final l10n = TodoLocalizations.of(context);
    return {
      'today': l10n.today,
      'week': l10n.thisWeek,
      'month': l10n.thisMonth,
      'all': l10n.all,
    };
  }

  /// 加载已保存的配置
  Future<void> _loadSavedConfig() async {
    if (widget.widgetId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 加载时间范围
      final savedRange = await HomeWidget.getWidgetData<String>(
        'todo_list_range_${widget.widgetId}',
      );
      final timeRangeOptions = _getTimeRangeOptions(context);
      if (savedRange != null && timeRangeOptions.containsKey(savedRange)) {
        _selectedTimeRange = savedRange;
      }

      // 加载标题
      final savedTitle = await HomeWidget.getWidgetData<String>(
        'todo_list_title_${widget.widgetId}',
      );
      if (savedTitle != null) {
        _titleController.text = savedTitle;
      }

      // 加载主色调
      final savedPrimaryColor = await HomeWidget.getWidgetData<int>(
        'todo_widget_primary_color_${widget.widgetId}',
      );
      if (savedPrimaryColor != null) {
        _widgetConfig = _widgetConfig.updateColor('primary', Color(savedPrimaryColor));
      }

      // 加载强调色
      final savedAccentColor = await HomeWidget.getWidgetData<int>(
        'todo_widget_accent_color_${widget.widgetId}',
      );
      if (savedAccentColor != null) {
        _widgetConfig = _widgetConfig.updateColor('accent', Color(savedAccentColor));
      }

      // 加载透明度
      final savedOpacity = await HomeWidget.getWidgetData<double>(
        'todo_widget_opacity_${widget.widgetId}',
      );
      if (savedOpacity != null) {
        _widgetConfig = _widgetConfig.copyWith(opacity: savedOpacity);
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
    }

    setState(() => _isLoading = false);
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
    final l10n = TodoLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _getTimeRangeOptions(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.configureTodoListWidget),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WidgetConfigEditor(
        widgetSize: WidgetSize.large,
        initialConfig: _widgetConfig,
        previewTitle: l10n.todoTasks,
        onConfigChanged: (config) {
          setState(() => _widgetConfig = config);
        },
        previewBuilder: _buildPreview,
        customConfigWidgets: [
          _buildTitleConfig(),
          const SizedBox(height: 16),
          _buildTimeRangeConfig(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveAndFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: _widgetConfig.getColor('primary') ?? const Color(0xFF2dd4bf),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.confirmConfiguration,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建预览
  Widget _buildPreview(BuildContext context, WidgetConfig config) {
    final l10n = TodoLocalizations.of(context);
    final primaryColor = config.getColor('primary') ?? const Color(0xFF2dd4bf);
    final accentColor = config.getColor('accent') ?? const Color(0xFF5eeada);
    final filteredTasks = _getFilteredTasks();
    final timeRangeOptions = _getTimeRangeOptions(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Expanded(
                child: Text(
                  _titleController.text.isEmpty
                      ? timeRangeOptions[_selectedTimeRange]!
                      : _titleController.text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filteredTasks.length}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.add,
                color: primaryColor,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 任务列表
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      l10n.noTodoTasks,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTasks.take(4).length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Padding(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建标题配置
  Widget _buildTitleConfig() {
    final theme = Theme.of(context);
    final l10n = TodoLocalizations.of(context);
    final timeRangeOptions = _getTimeRangeOptions(context);

    return Card(
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
                  l10n.widgetTitle,
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
                hintText: '${l10n.leaveEmptyForDefaultTitle}（${timeRangeOptions[_selectedTimeRange]}）',
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
    );
  }

  /// 构建时间范围配置
  Widget _buildTimeRangeConfig() {
    final theme = Theme.of(context);
    final l10n = TodoLocalizations.of(context);
    final primaryColor = _widgetConfig.getColor('primary') ?? const Color(0xFF2dd4bf);
    final timeRangeOptions = _getTimeRangeOptions(context);

    return Card(
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
                  l10n.timeRange,
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
              children: timeRangeOptions.entries.map((entry) {
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
                  selectedColor: primaryColor.withAlpha(50),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存配置并关闭界面
  Future<void> _saveAndFinish() async {
    TodoLocalizations.of(context);
    final timeRangeOptions = _getTimeRangeOptions(context);

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

      // 保存主色调（使用 String 存储，因为 HomeWidget 不支持 int）
      final primaryColor = _widgetConfig.getColor('primary');
      if (primaryColor != null) {
        await HomeWidget.saveWidgetData<String>(
          'todo_widget_primary_color_${widget.widgetId}',
          primaryColor.value.toString(),
        );
      }

      // 保存强调色（使用 String 存储）
      final accentColor = _widgetConfig.getColor('accent');
      if (accentColor != null) {
        await HomeWidget.saveWidgetData<String>(
          'todo_widget_accent_color_${widget.widgetId}',
          accentColor.value.toString(),
        );
      }

      // 保存透明度（使用 String 存储）
      await HomeWidget.saveWidgetData<String>(
        'todo_widget_opacity_${widget.widgetId}',
        _widgetConfig.opacity.toString(),
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
        final title = _titleController.text.isEmpty
            ? timeRangeOptions[_selectedTimeRange]
            : _titleController.text;
        toastService.showToast('Configured "$title"');

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('Configuration failed: $e');
      }
    }
  }

  /// 同步任务数据到小组件
  Future<void> _syncTasksToWidget() async {
    try {
      final allTasks = _todoPlugin.taskController.tasks
          .where((task) => task.status != TaskStatus.done)
          .toList();

      final taskList = allTasks.map((task) {
        return {
          'id': task.id,
          'title': task.title,
          'completed': task.status == TaskStatus.done,
          'startDate': task.startDate?.toIso8601String(),
          'dueDate': task.dueDate?.toIso8601String(),
        };
      }).toList();

      final widgetData = jsonEncode({
        'tasks': taskList,
        'total': taskList.length,
      });

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
