import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../models/saved_tool_template.dart';
import '../../../services/tool_template_service.dart';

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

class _SaveToolDialogState extends State<SaveToolDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // 如果是编辑模式，回显数据
    if (widget.isEditMode) {
      final template = widget.editingTemplate!;
      _nameController.text = template.name;
      _descriptionController.text = template.description ?? '';
      _tags.addAll(template.tags);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepsCount = widget.isEditMode
        ? widget.editingTemplate!.steps.length
        : (widget.message?.toolCall?.steps.length ?? 0);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isEditMode ? Icons.edit : Icons.save,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(widget.isEditMode ? '编辑工具模板' : '保存工具'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 提示信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isEditMode
                            ? '编辑模板信息 (包含 $stepsCount 个工具调用步骤)'
                            : '将保存 $stepsCount 个工具调用步骤',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 名称输入
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '工具名称 *',
                  hintText: '例如：导出数据',
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
                  // 编辑模式下，允许保留原名称
                  if (widget.isEditMode) {
                    final originalName = widget.editingTemplate!.name;
                    if (value.trim() == originalName) {
                      return null;
                    }
                  }
                  // 检查名称是否已存在
                  final exists = widget.templateService.templates
                      .any((t) => t.name == value.trim());
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
                  labelText: '描述（可选）',
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

              // 声明的工具（如果有）
              if (_getDeclaredTools().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '声明使用的工具 (${_getDeclaredTools().length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getDeclaredTools().map((tool) {
                      return Chip(
                        avatar: const Icon(Icons.build, size: 16),
                        label: Text(
                          tool['toolName'] ?? tool['toolId'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 标签输入
              Text(
                '标签（可选）',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
                  children: _tags.map((tag) {
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
                const SizedBox(height: 12),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveTool,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存'),
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

      if (widget.isEditMode) {
        // 编辑模式：更新现有模板
        final template = widget.editingTemplate!;
        final updatedTemplate = template.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          tags: _tags,
        );

        await widget.templateService.updateTemplate(updatedTemplate);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('工具模板 "$name" 更新成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 创建模式：新建模板
        final steps = widget.message?.toolCall?.steps ?? [];

        if (steps.isEmpty) {
          throw Exception('没有可保存的工具步骤');
        }

        await widget.templateService.createTemplate(
          name: name,
          description: description.isEmpty ? null : description,
          steps: steps,
          declaredTools: _getDeclaredTools(),
          tags: _tags,
        );

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('工具 "$name" 保存成功'),
              backgroundColor: Colors.green,
            ),
          );
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
