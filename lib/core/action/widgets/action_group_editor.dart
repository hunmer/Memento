/// 动作组编辑器
/// 用于创建和编辑动作组
library action_group_editor;

import 'package:flutter/material.dart';
import '../action_manager.dart';
import '../models/action_definition.dart';
import '../models/action_instance.dart';
import '../models/action_group.dart';
import 'action_selector_dialog.dart';

/// 动作组编辑器
class ActionGroupEditor extends StatefulWidget {
  final ActionGroup? group;

  const ActionGroupEditor({
    super.key,
    this.group,
  });

  @override
  State<ActionGroupEditor> createState() => _ActionGroupEditorState();
}

class _ActionGroupEditorState extends State<ActionGroupEditor> {
  // 表单控制器
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 标题和描述控制器
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // 操作符
  GroupOperator _operator = GroupOperator.sequence;

  // 执行模式
  GroupExecutionMode _executionMode = GroupExecutionMode.all;

  // 动作列表
  final List<ActionInstance> _actions = [];

  // 优先级
  int _priority = 0;

  @override
  void initState() {
    super.initState();

    if (widget.group != null) {
      final group = widget.group!;
      _titleController.text = group.title;
      _descriptionController.text = group.description ?? '';
      _operator = group.operator;
      _executionMode = group.executionMode;
      _actions.addAll(group.actions);
      _priority = group.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAddAction() async {
    final result = await showDialog<ActionSelectorResult>(
      context: context,
      builder: (context) => const ActionSelectorDialog(
        showGroupEditor: false,
      ),
    );

    if (result != null && result.singleAction != null) {
      setState(() {
        _actions.add(result.singleAction!);
      });
    }
  }

  void _onEditAction(int index) async {
    final action = _actions[index];
    final result = await showDialog<ActionSelectorResult>(
      context: context,
      builder: (context) => ActionSelectorDialog(
        showGroupEditor: false,
        initialValue: ActionSelectorResult(
          singleAction: action,
        ),
      ),
    );

    if (result != null && result.singleAction != null) {
      setState(() {
        _actions[index] = result.singleAction!;
      });
    }
  }

  void _onRemoveAction(int index) {
    setState(() {
      _actions.removeAt(index);
    });
  }

  void _onMoveUp(int index) {
    if (index > 0) {
      setState(() {
        final temp = _actions[index - 1];
        _actions[index - 1] = _actions[index];
        _actions[index] = temp;
      });
    }
  }

  void _onMoveDown(int index) {
    if (index < _actions.length - 1) {
      setState(() {
        final temp = _actions[index + 1];
        _actions[index + 1] = _actions[index];
        _actions[index] = temp;
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少添加一个动作'),
        ),
      );
      return;
    }

    final groupId = widget.group?.id ?? 'group_${DateTime.now().millisecondsSinceEpoch}';

    final group = ActionGroup(
      id: groupId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      operator: _operator,
      executionMode: _executionMode,
      actions: List.from(_actions),
      priority: _priority,
    );

    Navigator.pop(context, group);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_shared,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.group != null ? '编辑动作组' : '创建动作组',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            // 表单内容
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本信息
                      Text(
                        '基本信息',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '组标题',
                          hintText: '输入动作组标题',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入组标题';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '组描述',
                          hintText: '输入动作组描述（可选）',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),

                      // 执行配置
                      Text(
                        '执行配置',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GroupOperator>(
                        value: _operator,
                        decoration: const InputDecoration(
                          labelText: '操作符',
                          hintText: '选择执行方式',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GroupOperator.sequence,
                            child: Text('顺序执行'),
                          ),
                          DropdownMenuItem(
                            value: GroupOperator.parallel,
                            child: Text('并行执行'),
                          ),
                          DropdownMenuItem(
                            value: GroupOperator.condition,
                            child: Text('条件执行'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _operator = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GroupExecutionMode>(
                        value: _executionMode,
                        decoration: const InputDecoration(
                          labelText: '执行模式',
                          hintText: '选择执行模式',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GroupExecutionMode.all,
                            child: Text('执行所有动作'),
                          ),
                          DropdownMenuItem(
                            value: GroupExecutionMode.any,
                            child: Text('执行任一动作'),
                          ),
                          DropdownMenuItem(
                            value: GroupExecutionMode.first,
                            child: Text('只执行第一个'),
                          ),
                          DropdownMenuItem(
                            value: GroupExecutionMode.last,
                            child: Text('只执行最后一个'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _executionMode = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _priority.toString(),
                        decoration: const InputDecoration(
                          labelText: '优先级',
                          hintText: '数字越大优先级越高',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _priority = int.tryParse(value) ?? 0;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // 动作列表
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '动作列表',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _onAddAction,
                            icon: const Icon(Icons.add),
                            label: const Text('添加动作'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 动作列表
                      _actions.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '暂无动作，点击上方按钮添加',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _actions.length,
                              itemBuilder: (context, index) {
                                final action = _actions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.grey[300],
                                      child: Icon(
                                        action.displayIcon ??
                                            Icons.code,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(action.displayTitle),
                                    subtitle: Text(
                                      action.displayDescription ??
                                          action.actionId,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _onEditAction(index);
                                            break;
                                          case 'moveUp':
                                            _onMoveUp(index);
                                            break;
                                          case 'moveDown':
                                            _onMoveDown(index);
                                            break;
                                          case 'remove':
                                            _onRemoveAction(index);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('编辑'),
                                        ),
                                        if (index > 0)
                                          const PopupMenuItem(
                                            value: 'moveUp',
                                            child: Text('上移'),
                                          ),
                                        if (index < _actions.length - 1)
                                          const PopupMenuItem(
                                            value: 'moveDown',
                                            child: Text('下移'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Text('删除'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.save),
                    label: const Text('保存'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
