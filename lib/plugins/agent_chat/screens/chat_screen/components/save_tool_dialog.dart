import 'package:flutter/material.dart';
import '../../../models/chat_message.dart';
import '../../../services/tool_template_service.dart';

/// 保存工具对话框
///
/// 用于输入工具模板名称和描述
class SaveToolDialog extends StatefulWidget {
  final ChatMessage message;
  final ToolTemplateService templateService;

  const SaveToolDialog({
    super.key,
    required this.message,
    required this.templateService,
  });

  @override
  State<SaveToolDialog> createState() => _SaveToolDialogState();
}

class _SaveToolDialogState extends State<SaveToolDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.save, color: Colors.blue),
          SizedBox(width: 8),
          Text('保存工具'),
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
                        '将保存 ${widget.message.toolCall?.steps.length ?? 0} 个工具调用步骤',
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

  /// 保存工具
  Future<void> _saveTool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final steps = widget.message.toolCall?.steps ?? [];

      if (steps.isEmpty) {
        throw Exception('没有可保存的工具步骤');
      }

      await widget.templateService.createTemplate(
        name: name,
        description: description.isEmpty ? null : description,
        steps: steps,
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
  ToolTemplateService templateService,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SaveToolDialog(
      message: message,
      templateService: templateService,
    ),
  );
}
