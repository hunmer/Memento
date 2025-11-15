import 'package:flutter/material.dart';
import '../models/script_info.dart';
import '../models/script_input.dart';

/// 脚本运行参数输入对话框
///
/// 用于在执行 module 类型脚本时收集用户输入
class ScriptRunDialog extends StatefulWidget {
  /// 要执行的脚本信息
  final ScriptInfo script;

  const ScriptRunDialog({
    super.key,
    required this.script,
  });

  @override
  State<ScriptRunDialog> createState() => _ScriptRunDialogState();
}

class _ScriptRunDialogState extends State<ScriptRunDialog> {
  final _formKey = GlobalKey<FormState>();

  /// 文本输入控制器映射 (key -> controller)
  final Map<String, TextEditingController> _textControllers = {};

  /// 布尔值状态映射 (key -> value)
  final Map<String, bool> _boolValues = {};

  /// 下拉选择值映射 (key -> value)
  final Map<String, String?> _selectValues = {};

  @override
  void initState() {
    super.initState();

    // 初始化控制器和默认值
    for (final input in widget.script.inputs) {
      switch (input.type) {
        case 'string':
        case 'number':
          _textControllers[input.key] = TextEditingController(
            text: input.defaultValue?.toString() ?? '',
          );
          break;
        case 'boolean':
          _boolValues[input.key] = input.defaultValue as bool? ?? false;
          break;
        case 'select':
          _selectValues[input.key] = input.defaultValue?.toString();
          break;
      }
    }
  }

  @override
  void dispose() {
    // 释放所有文本控制器
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 收集并验证所有输入
  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 收集所有输入值
    final Map<String, dynamic> values = {};

    for (final input in widget.script.inputs) {
      dynamic value;

      switch (input.type) {
        case 'string':
          value = _textControllers[input.key]!.text.trim();
          break;
        case 'number':
          final text = _textControllers[input.key]!.text.trim();
          value = text.isEmpty ? null : double.tryParse(text);
          break;
        case 'boolean':
          value = _boolValues[input.key];
          break;
        case 'select':
          value = _selectValues[input.key];
          break;
      }

      // 使用格式化后的值
      values[input.key] = input.getFormattedValue(value);
    }

    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '运行脚本: ${widget.script.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.script.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.script.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 表单内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 提示信息
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '请填写以下参数以运行脚本',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 动态生成输入字段
                      ...widget.script.inputs.map((input) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildInputField(input),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('运行'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据输入类型构建对应的表单字段
  Widget _buildInputField(ScriptInput input) {
    switch (input.type) {
      case 'string':
        return _buildTextInput(input);
      case 'number':
        return _buildNumberInput(input);
      case 'boolean':
        return _buildBooleanInput(input);
      case 'select':
        return _buildSelectInput(input);
      default:
        return _buildTextInput(input);
    }
  }

  /// 构建文本输入字段
  Widget _buildTextInput(ScriptInput input) {
    return TextFormField(
      controller: _textControllers[input.key],
      decoration: InputDecoration(
        labelText: input.label + (input.required ? ' *' : ''),
        hintText: input.placeholder ?? '',
        helperText: input.description,
        prefixIcon: const Icon(Icons.text_fields),
        border: const OutlineInputBorder(),
      ),
      validator: (value) => input.validate(value),
      maxLines: input.description != null && input.description!.length > 50 ? 3 : 1,
    );
  }

  /// 构建数字输入字段
  Widget _buildNumberInput(ScriptInput input) {
    return TextFormField(
      controller: _textControllers[input.key],
      decoration: InputDecoration(
        labelText: input.label + (input.required ? ' *' : ''),
        hintText: input.placeholder ?? '',
        helperText: input.description,
        prefixIcon: const Icon(Icons.numbers),
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => input.validate(value),
    );
  }

  /// 构建布尔值输入字段
  Widget _buildBooleanInput(ScriptInput input) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        value: _boolValues[input.key]!,
        onChanged: (value) {
          setState(() {
            _boolValues[input.key] = value;
          });
        },
        title: Text(input.label + (input.required ? ' *' : '')),
        subtitle: input.description != null
            ? Text(
                input.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              )
            : null,
        secondary: Icon(
          _boolValues[input.key]! ? Icons.check_circle : Icons.cancel,
          color: _boolValues[input.key]! ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  /// 构建下拉选择字段
  Widget _buildSelectInput(ScriptInput input) {
    return DropdownButtonFormField<String>(
      value: _selectValues[input.key],
      decoration: InputDecoration(
        labelText: input.label + (input.required ? ' *' : ''),
        helperText: input.description,
        prefixIcon: const Icon(Icons.list),
        border: const OutlineInputBorder(),
      ),
      hint: Text(input.placeholder ?? '请选择'),
      items: input.options?.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectValues[input.key] = value;
        });
      },
      validator: (value) => input.validate(value),
    );
  }
}
