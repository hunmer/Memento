import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/models/saved_tool_template.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 保存/编辑工具对话框
///
/// 用于输入工具模板名称和描述，支持创建和编辑两种模式
class SaveToolDialog extends StatefulWidget {
  final ChatMessage? message;
  final ToolTemplateService templateService;
  final List<Map<String, String>> declaredTools;
  final SavedToolTemplate? editingTemplate;

  const SaveToolDialog({
    super.key,
    this.message,
    required this.templateService,
    this.declaredTools = const [],
    this.editingTemplate,
  });

  /// 是否为编辑模式
  bool get isEditMode => editingTemplate != null;

  @override
  State<SaveToolDialog> createState() => _SaveToolDialogState();
}

class _SaveToolDialogState extends State<SaveToolDialog>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;
  final List<String> _tags = [];
  final List<ToolCallStep> _steps = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 如果是编辑模式，回显数据
    if (widget.isEditMode) {
      final template = widget.editingTemplate!;
      _nameController.text = template.name;
      _descriptionController.text = template.description ?? '';
      _tags.addAll(template.tags);
      // 深拷贝步骤
      _steps.addAll(template.steps.map((s) => ToolCallStep(
            method: s.method,
            title: s.title,
            desc: s.desc,
            data: s.data,
          )));
    } else if (widget.message?.toolCall?.steps != null) {
      // 创建模式：从消息中获取步骤
      _steps.addAll(widget.message!.toolCall!.steps.map((s) => ToolCallStep(
            method: s.method,
            title: s.title,
            desc: s.desc,
            data: s.data,
          )));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isEditMode ? Icons.edit : Icons.save,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(widget.isEditMode ? '编辑工具模板' : '保存工具'),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: '基础信息'),
              Tab(icon: Icon(Icons.list), text: '执行步骤'),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 500, // 固定高度以适应 TabBarView
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              // 第一个 Tab: 基础信息
              _buildBasicInfoTab(),
              // 第二个 Tab: 执行步骤
              _buildStepsTab(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text('agent_chat_cancel'.tr),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveTool,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text('agent_chat_save'.tr),
        ),
      ],
    );
  }

  /// 构建基础信息 Tab
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名称输入
          TextFormField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '工具名称 *',
              hintText: '例如:导出数据',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入工具名称';
              }
              if (value.trim().length > 50) {
                return '名称不能超过50个字符';
              }
              // 编辑模式下,允许保留原名称
              if (widget.isEditMode) {
                final originalName = widget.editingTemplate!.name;
                if (value.trim() == originalName) {
                  return null;
                }
              }
              // 检查名称是否已存在
              final exists = widget.templateService.templates.any(
                (t) => t.name == value.trim(),
              );
              if (exists) {
                return '该名称已存在';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 描述输入
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '描述(可选)',
              hintText: '描述这个工具的用途...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            validator: (value) {
              if (value != null && value.trim().length > 200) {
                return '描述不能超过200个字符';
              }
              return null;
            },
          ),

          // 声明的工具(如果有)
          if (_getDeclaredTools().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '声明使用的工具 (${_getDeclaredTools().length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _getDeclaredTools()
                        .where((tool) {
                          final name = tool['name'] ?? tool['id'] ?? '';
                          return name.trim().isNotEmpty;
                        })
                        .map((tool) {
                      return Chip(
                        avatar: const Icon(Icons.build, size: 16),
                        label: Text(
                              tool['name'] ?? tool['id'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                        })
                        .toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 标签输入
          const Text(
            '标签(可选)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: '输入标签后按回车添加',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.label),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                      tooltip: '添加标签',
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    );
                  }).toList(),
            ),
          ],

          // 错误信息
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 12, color: Colors.red[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建执行步骤 Tab
  Widget _buildStepsTab() {
    return Column(
      children: [
        // 步骤标题和添加按钮
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '执行步骤 (${_steps.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _addStep,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: '添加步骤',
                color: Colors.blue,
              ),
            ],
          ),
        ),

        // 步骤列表
        Expanded(
          child:
              _steps.isEmpty
                  ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Text(
                        '暂无步骤,点击上方按钮添加',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                  : ReorderableListView.builder(
                    itemCount: _steps.length,
                    onReorder: _onReorderSteps,
                    itemBuilder: (context, index) {
                      return _buildStepEditor(index);
                    },
                  ),
        ),
      ],
    );
  }

  /// 获取声明的工具列表
  List<Map<String, String>> _getDeclaredTools() {
    if (widget.isEditMode) {
      return widget.editingTemplate!.declaredTools;
    }
    return widget.declaredTools;
  }

  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// 添加步骤
  void _addStep() {
    setState(() {
      _steps.add(ToolCallStep(
        method: 'run_js',
        title: '',
        desc: '',
        data: '',
      ));
    });
  }

  /// 删除步骤
  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  /// 重新排序步骤
  void _onReorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  /// 更新步骤
  void _updateStep(int index, {String? title, String? desc, String? data}) {
    setState(() {
      _steps[index] = ToolCallStep(
        method: _steps[index].method,
        title: title ?? _steps[index].title,
        desc: desc ?? _steps[index].desc,
        data: data ?? _steps[index].data,
      );
    });
  }

  /// 构建步骤编辑器
  Widget _buildStepEditor(int index) {
    final step = _steps[index];

    return Card(
      key: ValueKey(index),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
        title: Text(
          step.title.isNotEmpty ? step.title : '步骤 ${index + 1}',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: step.desc.isNotEmpty
            ? Text(
                step.desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              )
            : null,
        trailing: IconButton(
          onPressed: () => _deleteStep(index),
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Colors.red,
          tooltip: '删除步骤',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题输入
                TextField(
                  decoration: const InputDecoration(
                    labelText: '步骤标题',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(text: step.title),
                  onChanged: (value) => _updateStep(index, title: value),
                ),
                const SizedBox(height: 12),

                // 描述输入
                TextField(
                  decoration: const InputDecoration(
                    labelText: '步骤描述',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(text: step.desc),
                  onChanged: (value) => _updateStep(index, desc: value),
                ),
                const SizedBox(height: 12),

                // 代码输入
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'JavaScript 代码',
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'const result = await Memento.plugins...',
                  ),
                  controller: TextEditingController(text: step.data),
                  maxLines: 8,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  onChanged: (value) => _updateStep(index, data: value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 保存或更新工具
  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      // 验证步骤
      if (_steps.isEmpty) {
        throw Exception('至少需要一个步骤');
      }

      // 验证每个步骤都有代码
      for (var i = 0; i < _steps.length; i++) {
        if (_steps[i].data.trim().isEmpty) {
          throw Exception('步骤 ${i + 1} 的代码不能为空');
        }
      }

      if (widget.isEditMode) {
        // 编辑模式：更新现有模板
        final template = widget.editingTemplate!;
        final updatedTemplate = template.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          tags: _tags,
          steps: _steps,
        );

        await widget.templateService.updateTemplate(updatedTemplate);

        if (mounted) {
          Navigator.pop(context, true);
          toastService.showToast('工具模板 "$name" 更新成功');
        }
      } else {
        // 创建模式：新建模板
        await widget.templateService.createTemplate(
          name: name,
          description: description.isEmpty ? null : description,
          steps: _steps,
          declaredTools: _getDeclaredTools(),
          tags: _tags,
        );

        if (mounted) {
          Navigator.pop(context, true);
          toastService.showToast('工具 "$name" 保存成功');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }
}

/// 显示保存工具对话框
Future<bool?> showSaveToolDialog(
  BuildContext context,
  ChatMessage message,
  ToolTemplateService templateService, {
  List<Map<String, String>> declaredTools = const [],
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SaveToolDialog(
      message: message,
      templateService: templateService,
      declaredTools: declaredTools,
    ),
  );
}

/// 显示编辑工具模板对话框
Future<bool?> showEditToolDialog(
  BuildContext context,
  SavedToolTemplate template,
  ToolTemplateService templateService,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SaveToolDialog(
      templateService: templateService,
      editingTemplate: template,
    ),
  );
}
