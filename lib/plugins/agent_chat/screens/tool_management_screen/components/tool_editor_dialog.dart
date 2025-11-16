import 'package:flutter/material.dart';
import '../../../models/tool_config.dart';

/// 工具编辑对话框
class ToolEditorDialog extends StatefulWidget {
  final String pluginId;
  final String? toolId;
  final ToolConfig? config;
  final bool isNew;

  const ToolEditorDialog({
    super.key,
    required this.pluginId,
    this.toolId,
    this.config,
    this.isNew = false,
  });

  @override
  State<ToolEditorDialog> createState() => _ToolEditorDialogState();
}

class _ToolEditorDialogState extends State<ToolEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  // 表单字段控制器
  late TextEditingController _toolIdController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _returnsTypeController;
  late TextEditingController _returnsDescController;
  late TextEditingController _notesController;

  // 参数列表
  List<_ParameterData> _parameters = [];

  // 示例列表
  List<_ExampleData> _examples = [];

  // 启用状态
  bool _enabled = true;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    _toolIdController = TextEditingController(text: widget.toolId ?? '');
    _titleController = TextEditingController(text: widget.config?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.config?.description ?? '');
    _returnsTypeController =
        TextEditingController(text: widget.config?.returns.type ?? 'string');
    _returnsDescController =
        TextEditingController(text: widget.config?.returns.description ?? '');
    _notesController = TextEditingController(text: widget.config?.notes ?? '');

    _enabled = widget.config?.enabled ?? true;

    // 加载现有参数
    if (widget.config != null) {
      _parameters = widget.config!.parameters
          .map((p) => _ParameterData(
                nameController: TextEditingController(text: p.name),
                typeController: TextEditingController(text: p.type),
                descController: TextEditingController(text: p.description),
                optional: p.optional,
              ))
          .toList();

      _examples = widget.config!.examples
          .map((e) => _ExampleData(
                codeController: TextEditingController(text: e.code),
                commentController: TextEditingController(text: e.comment),
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _toolIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _returnsTypeController.dispose();
    _returnsDescController.dispose();
    _notesController.dispose();

    for (var param in _parameters) {
      param.dispose();
    }
    for (var example in _examples) {
      example.dispose();
    }

    super.dispose();
  }

  /// 添加参数
  void _addParameter() {
    setState(() {
      _parameters.add(_ParameterData(
        nameController: TextEditingController(),
        typeController: TextEditingController(text: 'string'),
        descController: TextEditingController(),
        optional: false,
      ));
    });
  }

  /// 移除参数
  void _removeParameter(int index) {
    setState(() {
      _parameters[index].dispose();
      _parameters.removeAt(index);
    });
  }

  /// 添加示例
  void _addExample() {
    setState(() {
      _examples.add(_ExampleData(
        codeController: TextEditingController(),
        commentController: TextEditingController(),
      ));
    });
  }

  /// 移除示例
  void _removeExample(int index) {
    setState(() {
      _examples[index].dispose();
      _examples.removeAt(index);
    });
  }

  /// 保存工具配置
  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 构建参数列表
    final parameters = _parameters
        .map((p) => ToolParameter(
              name: p.nameController.text.trim(),
              type: p.typeController.text.trim(),
              description: p.descController.text.trim(),
              optional: p.optional,
            ))
        .toList();

    // 构建示例列表
    final examples = _examples
        .where((e) =>
            e.codeController.text.trim().isNotEmpty ||
            e.commentController.text.trim().isNotEmpty)
        .map((e) => ToolExample(
              code: e.codeController.text.trim(),
              comment: e.commentController.text.trim(),
            ))
        .toList();

    // 构建返回值
    final returns = ToolReturns(
      type: _returnsTypeController.text.trim(),
      description: _returnsDescController.text.trim(),
    );

    // 构建工具配置
    final config = ToolConfig(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      parameters: parameters,
      returns: returns,
      examples: examples,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      enabled: _enabled,
    );

    // 返回结果
    Navigator.pop(context, {
      'toolId': widget.isNew
          ? _toolIdController.text.trim()
          : widget.toolId,
      'config': config,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题栏
            Row(
              children: [
                Text(
                  widget.isNew ? '添加工具' : '编辑工具',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // 表单内容
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 工具 ID
                    TextFormField(
                      controller: _toolIdController,
                      decoration: const InputDecoration(
                        labelText: '工具 ID',
                        hintText: '例如: todo_getTasks',
                      ),
                      enabled: widget.isNew,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入工具 ID';
                        }
                        if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value)) {
                          return '工具 ID 只能包含小写字母、数字和下划线';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 插件 ID（只读）
                    TextFormField(
                      initialValue: widget.pluginId,
                      decoration: const InputDecoration(
                        labelText: '插件 ID',
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // 工具标题
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '工具标题',
                        hintText: '工具的简短标题',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入工具标题';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 工具描述
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '工具描述',
                        hintText: '详细描述工具的功能',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入工具描述';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 参数列表
                    _buildParametersSection(),
                    const SizedBox(height: 24),

                    // 返回值配置
                    _buildReturnsSection(),
                    const SizedBox(height: 24),

                    // 示例列表
                    _buildExamplesSection(),
                    const SizedBox(height: 24),

                    // 注意事项
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: '注意事项（可选）',
                        hintText: '使用工具时的注意事项',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // 启用工具
                    SwitchListTile(
                      title: const Text('启用工具'),
                      value: _enabled,
                      onChanged: (value) {
                        setState(() {
                          _enabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建参数列表部分
  Widget _buildParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '参数列表',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addParameter,
              tooltip: '添加参数',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_parameters.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无参数，点击 + 添加'),
            ),
          )
        else
          ..._parameters.asMap().entries.map((entry) {
            final index = entry.key;
            final param = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '参数 ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          iconSize: 20,
                          color: Colors.red,
                          onPressed: () => _removeParameter(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: param.nameController,
                      decoration: const InputDecoration(
                        labelText: '参数名',
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入参数名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: param.typeController,
                      decoration: const InputDecoration(
                        labelText: '参数类型',
                        hintText: 'string, number, boolean, object, array',
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入参数类型';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: param.descController,
                      decoration: const InputDecoration(
                        labelText: '参数描述',
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入参数描述';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('可选参数'),
                      value: param.optional,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          param.optional = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  /// 构建返回值部分
  Widget _buildReturnsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '返回值',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _returnsTypeController,
          decoration: const InputDecoration(
            labelText: '返回值类型',
            hintText: 'string, object, array, etc.',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入返回值类型';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _returnsDescController,
          decoration: const InputDecoration(
            labelText: '返回值描述',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入返回值描述';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 构建示例列表部分
  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '示例代码',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addExample,
              tooltip: '添加示例',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_examples.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无示例，点击 + 添加'),
            ),
          )
        else
          ..._examples.asMap().entries.map((entry) {
            final index = entry.key;
            final example = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '示例 ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          iconSize: 20,
                          color: Colors.red,
                          onPressed: () => _removeExample(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: example.commentController,
                      decoration: const InputDecoration(
                        labelText: '示例说明',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: example.codeController,
                      decoration: const InputDecoration(
                        labelText: '示例代码',
                        hintText: 'const result = await Memento.todo.getTasks();',
                        isDense: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

/// 参数数据辅助类
class _ParameterData {
  final TextEditingController nameController;
  final TextEditingController typeController;
  final TextEditingController descController;
  bool optional;

  _ParameterData({
    required this.nameController,
    required this.typeController,
    required this.descController,
    required this.optional,
  });

  void dispose() {
    nameController.dispose();
    typeController.dispose();
    descController.dispose();
  }
}

/// 示例数据辅助类
class _ExampleData {
  final TextEditingController codeController;
  final TextEditingController commentController;

  _ExampleData({
    required this.codeController,
    required this.commentController,
  });

  void dispose() {
    codeController.dispose();
    commentController.dispose();
  }
}
