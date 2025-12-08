/// 动作组编辑器
/// 用于创建和编辑动作组
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/action/models/action_instance.dart';
import 'package:Memento/core/action/models/action_group.dart';
import 'action_selector_dialog.dart';
import 'package:Memento/core/l10n/core_localizations.dart';

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
      Toast.show(CoreLocalizations.of(context)!.pleaseAddAtLeastOneAction);
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
                      widget.group != null ? CoreLocalizations.of(context)!.editActionGroup : CoreLocalizations.of(context)!.createActionGroupTitle,
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
                        CoreLocalizations.of(context)!.basicInfo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: CoreLocalizations.of(context)!.groupTitle,
                          hintText: CoreLocalizations.of(context)!.enterActionGroupTitle,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return CoreLocalizations.of(context)!.pleaseEnterGroupTitle;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: CoreLocalizations.of(context)!.groupDescription,
                          hintText: CoreLocalizations.of(context)!.enterActionGroupDescription,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),

                      // 执行配置
                      Text(
                        CoreLocalizations.of(context)!.executionConfig,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<GroupOperator>(
                        value: _operator,
                        decoration: InputDecoration(
                          labelText: CoreLocalizations.of(context)!.operator,
                          hintText: CoreLocalizations.of(context)!.selectExecutionMethod,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: GroupOperator.sequence,
                            child: Text(CoreLocalizations.of(context)!.sequentialExecution),
                          ),
                          DropdownMenuItem(
                            value: GroupOperator.parallel,
                            child: Text(CoreLocalizations.of(context)!.parallelExecution),
                          ),
                          DropdownMenuItem(
                            value: GroupOperator.condition,
                            child: Text(CoreLocalizations.of(context)!.conditionalExecution),
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
                        decoration: InputDecoration(
                          labelText: CoreLocalizations.of(context)!.executionMode,
                          hintText: CoreLocalizations.of(context)!.selectExecutionMode,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: GroupExecutionMode.all,
                            child: Text(CoreLocalizations.of(context)!.executeAllActions),
                          ),
                          DropdownMenuItem(
                            value: GroupExecutionMode.any,
                            child: Text(CoreLocalizations.of(context)!.executeAnyAction),
                          ),
                          DropdownMenuItem(
                            value: GroupExecutionMode.first,
                            child: Text(CoreLocalizations.of(context)!.executeFirstOnly),
                          ),
                          DropdownMenuItem(
                            value: GroupExecutionMode.last,
                            child: Text(CoreLocalizations.of(context)!.executeLastOnly),
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
                        decoration: InputDecoration(
                          labelText: CoreLocalizations.of(context)!.priority,
                          hintText: CoreLocalizations.of(context)!.priorityDescription,
                          border: const OutlineInputBorder(),
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
                            CoreLocalizations.of(context)!.actionList,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _onAddAction,
                            icon: const Icon(Icons.add),
                            label: Text(CoreLocalizations.of(context)!.addAction),
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
                                  CoreLocalizations.of(context)!.noActionsAdded,
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
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(CoreLocalizations.of(context)!.edit),
                                        ),
                                        if (index > 0)
                                          PopupMenuItem(
                                            value: 'moveUp',
                                            child: Text(CoreLocalizations.of(context)!.moveUp),
                                          ),
                                        if (index < _actions.length - 1)
                                          PopupMenuItem(
                                            value: 'moveDown',
                                            child: Text(CoreLocalizations.of(context)!.moveDown),
                                          ),
                                        PopupMenuItem(
                                          value: 'remove',
                                          child: Text(CoreLocalizations.of(context)!.delete),
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
                    child: Text(CoreLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.save),
                    label: Text(CoreLocalizations.of(context)!.save),
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
