import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../services/todo_service.dart';
import '../../plugin_widget.dart';

class TaskEditDialog extends StatelessWidget {
  final TaskItem? task; // 如果为null，表示新建任务；否则表示编辑任务
  final String? parentTaskId; // 如果不为null，表示创建子任务

  const TaskEditDialog({super.key, this.task, this.parentTaskId});

  @override
  Widget build(BuildContext context) {
    // 根据是否有parentTaskId来决定标题
    final String dialogTitle =
        parentTaskId != null ? "新建子任务" : (task != null ? "编辑任务" : "新建任务");

    // 设置对话框宽度为屏幕宽度的80%
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 24.0,
      ),
      // 使对话框高度自适应内容
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
            child: Row(
              children: [
                Text(
                  dialogTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: TaskEditDialogContent(
                  task: task,
                  parentTaskId: parentTaskId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskEditDialogContent extends StatefulWidget {
  final TaskItem? task;
  final String? parentTaskId;

  const TaskEditDialogContent({super.key, this.task, this.parentTaskId});

  @override
  State<TaskEditDialogContent> createState() => TaskEditDialogState();
}

class TaskEditDialogState extends State<TaskEditDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _notesController = TextEditingController();

  late String group;
  late Priority priority;
  late List<String> selectedTags;
  DateTime? _startDate;
  DateTime? _dueDate;
  String? _parentTaskId;

  late final TodoService _todoService;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 在 initState 中不要访问 context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // 获取插件实例
      final pluginWidget = PluginWidget.of(context);
      if (pluginWidget == null) {
        throw Exception('TaskEditDialog must be a child of a PluginWidget');
      }
      _todoService = TodoService.getInstance(pluginWidget.plugin.storage);
      _isInitialized = true;
    }

    // 初始化父任务ID
    _parentTaskId = widget.task?.parentTaskId ?? widget.parentTaskId;

    // 如果是编辑任务，填充现有数据
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _subtitleController.text = widget.task!.subtitle ?? '';
      _notesController.text = widget.task!.notes ?? '';
      group = widget.task!.group;
      priority = widget.task!.priority;
      selectedTags = List.from(widget.task!.tags);
      _startDate = widget.task!.startDate;
      _dueDate = widget.task!.dueDate;
    } else {
      // 新建任务，设置默认值
      final defaultGroup =
          _todoService.groups.isNotEmpty ? _todoService.groups.first : '';
      group =
          widget.parentTaskId != null
              ? _todoService.tasks
                      .where((t) => t.id == widget.parentTaskId)
                      .map((t) => t.group)
                      .firstOrNull ??
                  defaultGroup
              : defaultGroup;
      priority = Priority.notImportantNotUrgent;
      selectedTags = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewTask = widget.task == null;
    final isSubTask = widget.parentTaskId != null;
    final title = isNewTask ? (isSubTask ? '新建子任务' : '新建任务') : '编辑任务';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '任务标题',
                  prefixIcon: Icon(Icons.task_alt),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: '副标题（可选）',
                  prefixIcon: Icon(Icons.short_text),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 父任务选择器
              _buildParentTaskSelector(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: group,
                decoration: const InputDecoration(
                  labelText: '分组',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                items: [
                  ..._todoService.groups.map(
                    (group) =>
                        DropdownMenuItem(value: group, child: Text(group)),
                  ),
                  if (!_todoService.groups.contains(''))
                    const DropdownMenuItem(value: '', child: Text('无分组')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      group = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                value: priority,
                decoration: const InputDecoration(
                  labelText: '优先级',
                  prefixIcon: Icon(Icons.priority_high),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                items:
                    Priority.values.map((priority) {
                      String label;
                      switch (priority) {
                        case Priority.importantUrgent:
                          label = '重要且紧急';
                          break;
                        case Priority.importantNotUrgent:
                          label = '重要不紧急';
                          break;
                        case Priority.notImportantUrgent:
                          label = '紧急不重要';
                          break;
                        case Priority.notImportantNotUrgent:
                          label = '不重要不紧急';
                          break;
                      }
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(label),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTagsSelector(),
              const SizedBox(height: 16),
              _buildDateSelectors(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                maxLines: 21,
              ),
              const SizedBox(height: 16),
              // 底部按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: Text(isNewTask ? '创建' : '保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建父任务选择器
  Widget _buildParentTaskSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showParentTaskSelectionDialog,
          child: InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.account_tree),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _parentTaskId != null
                        ? _todoService.tasks
                                .where((t) => t.id == _parentTaskId)
                                .map((t) => t.title)
                                .firstOrNull ??
                            '父任务不存在'
                        : '无父任务',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 显示父任务选择对话框
  void _showParentTaskSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: const Row(
              children: [
                Icon(Icons.account_tree),
                SizedBox(width: 8),
                Text('选择父任务'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 300,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _buildTaskTreeView(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _parentTaskId = null;
                  });
                },
                child: const Text('清除选择'),
              ),
            ],
          ),
    );
  }

  // 构建任务树视图
  Widget _buildTaskTreeView() {
    // 获取所有顶级任务（没有父任务的任务）
    final rootTasks =
        _todoService.tasks.where((task) {
          // 排除当前正在编辑的任务（如果有）以及其所有子任务
          if (widget.task != null && task.id == widget.task!.id) {
            return false;
          }

          // 检查任务是否是其他任务的子任务
          bool isSubTask = false;
          for (var t in _todoService.tasks) {
            if (t.subTaskIds.contains(task.id)) {
              isSubTask = true;
              break;
            }
          }
          return !isSubTask;
        }).toList();

    return ListView.builder(
      itemCount: rootTasks.length,
      itemBuilder: (context, index) {
        return _buildTaskTreeItem(rootTasks[index], 0);
      },
    );
  }

  // 构建任务树项
  Widget _buildTaskTreeItem(TaskItem task, int depth) {
    final hasChildren = task.subTaskIds.isNotEmpty;

    // 获取子任务列表
    final children =
        hasChildren
            ? task.subTaskIds
                .map((id) => _todoService.tasks.firstWhere((t) => t.id == id))
                .toList()
            : <TaskItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _parentTaskId = task.id;
              Navigator.of(context).pop();
            });
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 * depth,
              top: 8.0,
              bottom: 8.0,
              right: 16.0,
            ),
            decoration: BoxDecoration(
              color:
                  _parentTaskId == task.id
                      ? Theme.of(context).primaryColor.withAlpha(30)
                      : null,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  hasChildren ? Icons.arrow_drop_down : Icons.circle,
                  size: hasChildren ? 24 : 8,
                  color:
                      hasChildren
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight:
                          _parentTaskId == task.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          _parentTaskId == task.id
                              ? Theme.of(context).primaryColor
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren) ...[
          const SizedBox(height: 4),
          ...children.map((child) => _buildTaskTreeItem(child, depth + 1)),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 添加标签标题和图标
        const Row(
          children: [
            Icon(Icons.label, size: 20),
            SizedBox(width: 8),
            Text('标签', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        // 创建带有边框的容器来包装标签选择器
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标签选择器
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _todoService.tags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        avatar:
                            isSelected
                                ? const Icon(Icons.check, size: 16)
                                : null,
                        showCheckmark: false,
                        selectedColor: Theme.of(
                          context,
                        ).primaryColor.withAlpha(51), // 0.2 * 255 ≈ 51
                        backgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _selectDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                            : '开始日期',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _selectDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.event_busy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.year}-${_dueDate!.month}-${_dueDate!.day}'
                            : '截止日期',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _dueDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // 如果开始日期晚于截止日期，更新截止日期
          if (_dueDate != null && _startDate!.isAfter(_dueDate!)) {
            _dueDate = _startDate;
          }
        } else {
          _dueDate = pickedDate;
          // 如果截止日期早于开始日期，更新开始日期
          if (_startDate != null && _dueDate!.isBefore(_startDate!)) {
            _startDate = _dueDate;
          }
        }
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final subtitle = _subtitleController.text.trim();
      final notes = _notesController.text.trim();

      TaskItem task;
      if (widget.task != null && widget.task!.id.isNotEmpty) {
        // 编辑现有任务（只有当ID不为空时）
        task = widget.task!.copyWith(
          title: title,
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          notes: notes.isNotEmpty ? notes : null,
          group: group,
          priority: priority,
          tags: selectedTags,
          startDate: _startDate,
          dueDate: _dueDate,
          parentTaskId: _parentTaskId, // 确保更新父任务ID
        );

        // 如果父任务ID发生变化，需要处理旧的和新的父任务关系
        if (widget.task!.parentTaskId != _parentTaskId) {
          // 如果有旧的父任务，从其子任务列表中移除当前任务
          if (widget.task!.parentTaskId != null) {
            final oldParentTask = _todoService.tasks.firstWhere(
              (t) => t.id == widget.task!.parentTaskId,
              orElse: () => task,
            );
            if (oldParentTask.id != task.id) {
              oldParentTask.subTaskIds.remove(task.id);
              _todoService.updateTask(oldParentTask);
            }
          }

          // 如果有新的父任务，将当前任务添加到其子任务列表中
          if (_parentTaskId != null) {
            final newParentTask = _todoService.tasks.firstWhere(
              (t) => t.id == _parentTaskId,
              orElse: () => task,
            );
            if (newParentTask.id != task.id &&
                !newParentTask.subTaskIds.contains(task.id)) {
              newParentTask.subTaskIds.add(task.id);
              _todoService.updateTask(newParentTask);
            }
          }
        }

        _todoService.updateTask(task);
      } else {
        // 创建新任务（当task为null或者id为空时）
        final newId = const Uuid().v4();
        task = TaskItem(
          id: newId,
          title: title,
          createdAt: DateTime.now(),
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          notes: notes.isNotEmpty ? notes : null,
          group: group,
          priority: priority,
          tags: selectedTags,
          startDate: _startDate,
          dueDate: _dueDate,
          parentTaskId: _parentTaskId ?? widget.parentTaskId, // 设置父任务ID
        );

        // 如果有父任务，将新任务添加到父任务的子任务列表中
        if (task.parentTaskId != null) {
          final parentTask = _todoService.tasks.firstWhere(
            (t) => t.id == task.parentTaskId,
            orElse: () => task,
          );
          if (parentTask.id != task.id) {
            parentTask.subTaskIds.add(task.id);
            _todoService.updateTask(parentTask);
          }
        }

        // 添加新任务
        _todoService.addTask(task);
      }

      Navigator.of(context).pop(task);
    }
  }
}
