import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../models/tool_config.dart';
import '../../../../../core/js_bridge/js_bridge_manager.dart';

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

class _ToolEditorDialogState extends State<ToolEditorDialog>
    with SingleTickerProviderStateMixin {
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

  // Tab 控制器
  late TabController _tabController;

  // UI 处理器注册状态
  bool _uiHandlersRegistered = false;

  @override
  void initState() {
    super.initState();

    // 在第一帧渲染后注册 UI 处理器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_uiHandlersRegistered && mounted) {
        JSBridgeManager.instance.registerUIHandlers(context);
        _uiHandlersRegistered = true;
        debugPrint('✓ ToolEditorDialog: UI 处理器已注册');
      }
    });

    // 初始化 Tab 控制器（4个Tab：基本信息、参数列表、返回值、示例代码）
    // 默认激活"示例代码"tab以方便调试
    _tabController = TabController(length: 4, vsync: this, initialIndex: 3);

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
    _tabController.dispose();
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
                child: Column(
                  children: [
                    // Tab 栏
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: '基本信息'),
                        Tab(text: '参数列表'),
                        Tab(text: '返回值'),
                        Tab(text: '示例代码'),
                      ],
                    ),

                    // Tab 内容
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 基本信息
                          _buildBasicInfoTab(),
                          // 参数列表
                          _buildParametersTab(),
                          // 返回值
                          _buildReturnsTab(),
                          // 示例代码
                          _buildExamplesTab(),
                        ],
                      ),
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

  /// 构建基本信息 Tab
  Widget _buildBasicInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 工具 ID
        TextFormField(
          controller: _toolIdController,
          decoration: const InputDecoration(
            labelText: '工具 ID',
            hintText: '例如: todo_getTasks',
            helperText: '工具的唯一标识符，只能包含小写字母、数字和下划线',
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
            helperText: '该工具所属的插件',
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
            helperText: '显示给用户的工具名称',
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
            helperText: '向AI解释该工具的用途和功能',
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入工具描述';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 注意事项
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: '注意事项（可选）',
            hintText: '使用工具时的注意事项',
            helperText: '额外的使用说明或限制条件',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // 启用工具
        Card(
          child: SwitchListTile(
            title: const Text('启用工具'),
            subtitle: const Text('禁用后该工具将不会提供给AI使用'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 构建参数列表 Tab
  Widget _buildParametersTab() {
    return Column(
      children: [
        // 添加按钮
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加参数'),
                onPressed: _addParameter,
              ),
            ],
          ),
        ),

        // 参数列表
        Expanded(
          child: _parameters.isEmpty
              ? const Center(
                  child: Text('暂无参数，点击上方按钮添加'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _parameters.length,
                  itemBuilder: (context, index) {
                    final param = _parameters[index];
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
                                hintText:
                                    'string, number, boolean, object, array',
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
                  },
                ),
        ),
      ],
    );
  }

  /// 构建返回值 Tab
  Widget _buildReturnsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        const SizedBox(height: 16),
        TextFormField(
          controller: _returnsDescController,
          decoration: const InputDecoration(
            labelText: '返回值描述',
          ),
          maxLines: 5,
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

  /// 构建示例代码 Tab
  Widget _buildExamplesTab() {
    return Column(
      children: [
        // 添加按钮
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加示例'),
                onPressed: _addExample,
              ),
            ],
          ),
        ),

        // 示例列表
        Expanded(
          child: _examples.isEmpty
              ? const Center(
                  child: Text('暂无示例，点击上方按钮添加'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _examples.length,
                  itemBuilder: (context, index) {
                    final example = _examples[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '示例 ${index + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                // 测试按钮
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('测试'),
                                  onPressed: () =>
                                      _testExample(example.codeController.text),
                                ),
                                const SizedBox(width: 8),
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
                                hintText:
                                    'const result = await Memento.todo.getTasks();',
                                isDense: true,
                              ),
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 测试示例代码
  Future<void> _testExample(String code) async {
    if (code.trim().isEmpty) {
      _showTestResult('错误', '示例代码不能为空');
      return;
    }

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在执行 JS 代码...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 执行 JS 代码
      final result = await JSBridgeManager.instance.evaluate(code);

      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
      }

      // 显示结果
      if (result.success) {
        // 将结果转换为字符串
        String resultString;
        final resultData = result.result;

        if (resultData == null) {
          resultString = 'null';
        } else if (resultData is String) {
          resultString = resultData;
        } else {
          // 对象类型，序列化为 JSON
          try {
            resultString = jsonEncode(resultData);
          } catch (e) {
            resultString = resultData.toString();
          }
        }

        _showTestResult('执行成功', resultString);
      } else {
        _showTestResult('执行失败', result.error ?? '未知错误');
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
      }
      _showTestResult('执行异常', e.toString());
    }
  }

  /// 显示测试结果对话框
  void _showTestResult(String title, String message) {
    // 尝试格式化 JSON
    String formattedMessage = message;
    try {
      // 尝试解析 JSON
      final decoded = jsonDecode(message);
      // 使用缩进格式化 JSON
      const encoder = JsonEncoder.withIndent('  ');
      formattedMessage = encoder.convert(decoded);
    } catch (e) {
      // 不是有效的 JSON，使用原始消息
      formattedMessage = message;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: TextEditingController(text: formattedMessage),
            readOnly: true,
            maxLines: null,
            minLines: 10,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
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
