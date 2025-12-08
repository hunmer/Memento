import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/plugins/scripts_center/models/script_input.dart';
import 'package:Memento/plugins/scripts_center/l10n/scripts_center_localizations.dart';

/// 脚本输入参数编辑对话框
class ScriptInputEditDialog extends StatefulWidget {
  /// 如果为null则为创建模式，否则为编辑模式
  final ScriptInput? input;

  const ScriptInputEditDialog({super.key, this.input});

  @override
  State<ScriptInputEditDialog> createState() => _ScriptInputEditDialogState();
}

class _ScriptInputEditDialogState extends State<ScriptInputEditDialog> {
  final _formKey = GlobalKey<FormState>();

  // 表单控制器
  late final TextEditingController _labelController;
  late final TextEditingController _keyController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _placeholderController;
  late final TextEditingController _defaultValueController;
  late final TextEditingController _optionsController;

  // 表单值
  String _selectedType = 'string';
  bool _required = false;

  // 可用类型列表
  final List<_TypeOption> _availableTypes = [
    _TypeOption('string', Icons.text_fields, '文本'),
    _TypeOption('number', Icons.numbers, '数字'),
    _TypeOption('boolean', Icons.toggle_on, '布尔值'),
    _TypeOption('select', Icons.list, '选择'),
  ];

  bool get isEditMode => widget.input != null;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    final input = widget.input;
    _labelController = TextEditingController(text: input?.label ?? '');
    _keyController = TextEditingController(text: input?.key ?? '');
    _descriptionController = TextEditingController(
      text: input?.description ?? '',
    );
    _placeholderController = TextEditingController(
      text: input?.placeholder ?? '',
    );
    _defaultValueController = TextEditingController(
      text: input?.defaultValue?.toString() ?? '',
    );
    _optionsController = TextEditingController(
      text: input?.options?.join(', ') ?? '',
    );

    // 初始化下拉选择值
    if (input != null) {
      _selectedType = input.type;
      _required = input.required;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _keyController.dispose();
    _descriptionController.dispose();
    _placeholderController.dispose();
    _defaultValueController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  /// 验证并保存
  void _saveInput() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 处理选项列表（仅用于 select 类型）
    List<String>? options;
    if (_selectedType == 'select') {
      final optionsText = _optionsController.text.trim();
      if (optionsText.isEmpty) {
        Toast.error('选择类型必须提供选项列表');
        return;
      }
      options =
          optionsText
              .replaceAll('，', ',')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    }

    // 处理默认值
    dynamic defaultValue;
    final defaultValueText = _defaultValueController.text.trim();
    if (defaultValueText.isNotEmpty) {
      switch (_selectedType) {
        case 'number':
          defaultValue = double.tryParse(defaultValueText);
          break;
        case 'boolean':
          defaultValue = defaultValueText.toLowerCase() == 'true';
          break;
        default:
          defaultValue = defaultValueText;
      }
    }

    // 返回输入参数对象
    final input = ScriptInput(
      label: _labelController.text.trim(),
      key: _keyController.text.trim(),
      type: _selectedType,
      required: _required,
      defaultValue: defaultValue,
      options: options,
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      placeholder:
          _placeholderController.text.trim().isEmpty
              ? null
              : _placeholderController.text.trim(),
    );

    Navigator.of(context).pop(input);
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
                  Icon(
                    isEditMode ? Icons.edit : Icons.add_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditMode ? '编辑输入参数' : '添加输入参数',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
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
                      // 参数名称
                      TextFormField(
                        controller: _labelController,
                        decoration: const InputDecoration(
                          labelText: '参数名称 *',
                          hintText: '例如：用户名',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入参数名称';
                          }
                          return null;
                        },
                        autofocus: !isEditMode,
                      ),
                      const SizedBox(height: 16),

                      // 变量名
                      TextFormField(
                        controller: _keyController,
                        decoration: const InputDecoration(
                          labelText: '变量名 *',
                          hintText: '例如：username',
                          helperText: '在JS代码中使用的变量名，仅支持字母、数字和下划线',
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入变量名';
                          }
                          if (!RegExp(
                            r'^[a-zA-Z_][a-zA-Z0-9_]*$',
                          ).hasMatch(value)) {
                            return '变量名只能包含字母、数字和下划线，且不能以数字开头';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 数据类型
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: '数据类型',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _availableTypes.map((typeOption) {
                              return DropdownMenuItem(
                                value: typeOption.value,
                                child: Row(
                                  children: [
                                    Icon(typeOption.icon, size: 20),
                                    const SizedBox(width: 8),
                                    Text(typeOption.label),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 选项列表（仅用于 select 类型）
                      if (_selectedType == 'select') ...[
                        TextFormField(
                          controller: _optionsController,
                          decoration: const InputDecoration(
                            labelText: '选项列表 *',
                            hintText: '例如：选项1, 选项2, 选项3',
                            helperText: '多个选项用逗号分隔',
                            prefixIcon: Icon(Icons.list_alt),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '选择类型必须提供选项列表';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 默认值
                      TextFormField(
                        controller: _defaultValueController,
                        decoration: InputDecoration(
                          labelText: '默认值',
                          hintText: _getDefaultValueHint(),
                          prefixIcon: const Icon(Icons.edit_note),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 提示文本
                      TextFormField(
                        controller: _placeholderController,
                        decoration: const InputDecoration(
                          labelText: '提示文本',
                          hintText: '例如：请输入用户名',
                          prefixIcon: Icon(Icons.info_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 参数描述
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '参数描述',
                          hintText: '简短描述这个参数的用途',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // 必填开关
                      SwitchListTile(
                        value: _required,
                        onChanged: (value) {
                          setState(() {
                            _required = value;
                          });
                        },
                        title: Text(ScriptsCenterLocalizations.of(context).requiredParameter),
                        subtitle: Text(_required
                            ? ScriptsCenterLocalizations.of(context).userMustFillThisParameter
                            : ScriptsCenterLocalizations.of(context).thisParameterIsOptional),
                        secondary: Icon(
                          _required
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: _required ? Colors.orange : Colors.grey,
                        ),
                      ),
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
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(ScriptsCenterLocalizations.of(context).cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveInput,
                    icon: Icon(isEditMode ? Icons.save : Icons.add),
                    label: Text(isEditMode ? '保存' : '添加'),
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

  String _getDefaultValueHint() {
    switch (_selectedType) {
      case 'number':
        return '例如：0';
      case 'boolean':
        return '例如：true 或 false';
      case 'select':
        return '例如：选项1';
      default:
        return '例如：默认文本';
    }
  }
}

/// 类型选项
class _TypeOption {
  final String value;
  final IconData icon;
  final String label;

  _TypeOption(this.value, this.icon, this.label);
}
