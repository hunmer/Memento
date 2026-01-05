import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:Memento/widgets/form_fields/form_field_wrapper.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/types.dart';
import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/plugins/database/controllers/field_controller.dart';
import 'package:Memento/plugins/database/models/field_model.dart';

/// 字段类型选择器字段
///
/// 功能特性：
/// - 显示字段类型选择对话框
/// - 支持单选和多选模式
/// - 显示已选类型数量
/// - 支持配置模式（双 Tab）
class FieldTypeSelectorField extends FormFieldWrapper {
  /// 是否支持多选
  final bool multiSelect;

  /// 对话框标题
  final String? dialogTitle;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 是否显示配置 Tab（启用后对话框会有两个 Tab）
  final bool showConfigTab;

  /// 初始字段模型（配置模式下使用）
  final FieldModel? initialField;

  /// 值变化回调
  @override
  final ValueChanged<dynamic>? onChanged;

  const FieldTypeSelectorField({
    super.key,
    required super.name,
    super.initialValue,
    this.multiSelect = true,
    this.dialogTitle,
    this.prefixIcon,
    this.showConfigTab = false,
    this.initialField,
    this.onChanged,
    super.enabled = true,
  });

  @override
  State<FieldTypeSelectorField> createState() => _FieldTypeSelectorFieldState();
}

class _FieldTypeSelectorFieldState extends FormFieldWrapperState<FieldTypeSelectorField> {
  late dynamic _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue ?? (widget.multiSelect ? <String>[] : null);
  }

  String get _selectedText {
    if (widget.multiSelect) {
      final selectedList = _selectedValue as List<String>?;
      if (selectedList == null || selectedList.isEmpty) return '未选择';
      return '已选择 ${selectedList.length} 个字段类型';
    } else {
      return _selectedValue?.toString() ?? '未选择';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Colors.deepPurple)
            : const Icon(Icons.dashboard, color: Colors.deepPurple),
        title: Text(widget.dialogTitle ?? '选择字段类型'),
        subtitle: Text(_selectedText),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.enabled ? _showFieldTypeSelector : null,
      ),
    );
  }

  Future<void> _showFieldTypeSelector() async {
    if (widget.showConfigTab && !widget.multiSelect) {
      // 配置模式：单选 + 双 Tab
      final result = await showDialog<FieldModel>(
        context: context,
        builder: (context) => FieldTypeSelectorDialog(
          initialSelectedTypes: _selectedValue != null ? [_selectedValue as String] : [],
          dialogTitle: widget.dialogTitle ?? '选择字段类型',
          multiSelect: false,
          showConfigTab: true,
          initialField: widget.initialField,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedValue = result.type;
        });
        widget.onChanged?.call(_selectedValue);
      }
    } else if (widget.multiSelect) {
      // 多选模式
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => FieldTypeSelectorDialog(
          initialSelectedTypes: _selectedValue as List<String>? ?? [],
          dialogTitle: widget.dialogTitle ?? '选择字段类型',
          multiSelect: true,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedValue = result;
        });
        widget.onChanged?.call(_selectedValue);
      }
    } else {
      // 单选模式（无配置）
      final result = await showDialog<String>(
        context: context,
        builder: (context) => FieldTypeSelectorDialog(
          initialSelectedTypes: _selectedValue != null ? [_selectedValue as String] : [],
          dialogTitle: widget.dialogTitle ?? '选择字段类型',
          multiSelect: false,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedValue = result;
        });
        widget.onChanged?.call(_selectedValue);
      }
    }
  }

  @override
  dynamic getValue() => _selectedValue;
}

/// 字段类型选择器对话框
class FieldTypeSelectorDialog extends StatefulWidget {
  /// 初始选中的字段类型列表
  final List<String> initialSelectedTypes;

  /// 对话框标题
  final String dialogTitle;

  /// 是否支持多选
  final bool multiSelect;

  /// 是否显示配置 Tab
  final bool showConfigTab;

  /// 初始字段模型（配置模式下使用）
  final FieldModel? initialField;

  const FieldTypeSelectorDialog({
    super.key,
    required this.initialSelectedTypes,
    required this.dialogTitle,
    this.multiSelect = true,
    this.showConfigTab = false,
    this.initialField,
  });

  @override
  State<FieldTypeSelectorDialog> createState() => FieldTypeSelectorDialogState();
}

class FieldTypeSelectorDialogState extends State<FieldTypeSelectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Set<String> _selectedTypes;
  late String _selectedType;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  FormBuilderWrapperState? _wrapperState;

  /// 是否有选中的类型
  bool get _hasSelection => _selectedTypes.isNotEmpty;

  /// 获取所有可用的字段类型
  List<String> get _availableTypes => FieldController.getFieldTypes();

  /// 当前选中的字段类型
  String get currentType => _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.showConfigTab ? 2 : 1, vsync: this);
    _selectedTypes = widget.initialSelectedTypes.toSet();

    // 如果没有初始选中类型，默认选中第一个
    if (_selectedTypes.isEmpty) {
      _selectedType = _availableTypes.first;
      _selectedTypes.add(_selectedType);
    } else {
      _selectedType = widget.initialField?.type ?? _selectedTypes.first;
    }

    // 监听 Tab 变化
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    // 当切换到配置 Tab 时，确保已选择类型
    if (_tabController.index == 1 && _selectedType.isEmpty) {
      _tabController.animateTo(0);
    }
  }

  /// 选择类型后自动跳转到配置 Tab
  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      _selectedTypes.clear();
      _selectedTypes.add(type);
    });

    // 如果是配置模式，延迟跳转到第二个 Tab
    if (widget.showConfigTab) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _tabController.animateTo(1);
        }
      });
    }
  }

  /// 全选或反选
  void _toggleSelectAll() {
    setState(() {
      if (_hasSelection) {
        _selectedTypes.clear();
      } else {
        _selectedTypes = _availableTypes.toSet();
      }
    });
  }

  /// 构建配置表单字段
  List<FormFieldConfig> _buildConfigFields() {
    // 解析已保存的配置
    final savedConfig = _parseDescription(widget.initialField?.description);

    final fields = <FormFieldConfig>[
      // 字段名称（必填）
      FormFieldConfig(
        name: 'name',
        type: FormFieldType.text,
        labelText: '字段名称',
        hintText: '请输入字段名称',
        initialValue: widget.initialField?.name ?? '',
        required: true,
        validationMessage: '字段名称不能为空',
        prefixIcon: Icons.label,
      ),
    ];

    // 根据字段类型添加特定配置
    switch (_selectedType) {
      case 'Text':
      case 'Long Text':
      case 'Password':
        fields.addAll([
          FormFieldConfig(
            name: 'placeholder',
            type: FormFieldType.text,
            labelText: '占位提示',
            hintText: '输入框占位文本',
            initialValue: savedConfig['placeholder']?.toString() ?? '',
            prefixIcon: Icons.help_outline,
          ),
          FormFieldConfig(
            name: 'defaultValue',
            type: _selectedType == 'Long Text' ? FormFieldType.textArea : FormFieldType.text,
            labelText: '默认值',
            hintText: '请输入默认值',
            initialValue: savedConfig['defaultValue']?.toString() ?? '',
            prefixIcon: Icons.data_array,
          ),
          if (_selectedType == 'Long Text')
            FormFieldConfig(
              name: 'maxLines',
              type: FormFieldType.number,
              labelText: '最大行数',
              hintText: '默认 3 行',
              initialValue: int.tryParse(savedConfig['maxLines']?.toString() ?? '') ?? 3,
              prefixIcon: Icons.line_style,
            ),
        ]);
        break;

      case 'Integer':
      case 'Rating':
        fields.addAll([
          FormFieldConfig(
            name: 'minValue',
            type: FormFieldType.number,
            labelText: '最小值',
            hintText: '最小值',
            initialValue: int.tryParse(savedConfig['minValue']?.toString() ?? '') ?? 0,
            prefixIcon: Icons.arrow_downward,
          ),
          FormFieldConfig(
            name: 'maxValue',
            type: FormFieldType.number,
            labelText: '最大值',
            hintText: _selectedType == 'Rating' ? '默认 5' : '最大值',
            initialValue: int.tryParse(savedConfig['maxValue']?.toString() ?? '') ?? (_selectedType == 'Rating' ? 5 : 100),
            prefixIcon: Icons.arrow_upward,
          ),
          FormFieldConfig(
            name: 'defaultValue',
            type: FormFieldType.number,
            labelText: '默认值',
            hintText: '请输入默认值',
            initialValue: int.tryParse(savedConfig['defaultValue']?.toString() ?? '') ?? 0,
            prefixIcon: Icons.data_array,
          ),
        ]);
        break;

      case 'Dropdown':
        fields.add(
          FormFieldConfig(
            name: 'options',
            type: FormFieldType.textArea,
            labelText: '选项列表',
            hintText: '每行一个选项',
            initialValue: savedConfig['options']?.toString() ?? '',
            prefixIcon: Icons.list,
            extra: {'maxLines': 5},
          ),
        );
        break;

      case 'Date':
      case 'Time':
      case 'Date/Time':
        fields.addAll([
          FormFieldConfig(
            name: 'defaultValue',
            type: FormFieldType.text,
            labelText: '默认值',
            hintText: '留空使用当前时间',
            initialValue: savedConfig['defaultValue']?.toString() ?? 'now',
            prefixIcon: Icons.access_time,
          ),
          FormFieldConfig(
            name: 'format',
            type: FormFieldType.text,
            labelText: '日期格式',
            hintText: _selectedType == 'Time' ? 'HH:mm' : 'yyyy-MM-dd',
            initialValue: savedConfig['format']?.toString() ?? (_selectedType == 'Time' ? 'HH:mm' : 'yyyy-MM-dd'),
            prefixIcon: Icons.text_format,
          ),
        ]);
        break;

      case 'Checkbox':
        fields.add(
          FormFieldConfig(
            name: 'defaultValue',
            type: FormFieldType.switchField,
            labelText: '默认选中',
            hintText: '默认状态',
            initialValue: savedConfig['defaultValue'] == true,
          ),
        );
        break;

      case 'URL':
        fields.addAll([
          FormFieldConfig(
            name: 'placeholder',
            type: FormFieldType.text,
            labelText: '占位提示',
            hintText: 'https://example.com',
            initialValue: savedConfig['placeholder']?.toString() ?? '',
            prefixIcon: Icons.link,
          ),
          FormFieldConfig(
            name: 'defaultValue',
            type: FormFieldType.text,
            labelText: '默认 URL',
            hintText: '请输入默认 URL',
            initialValue: savedConfig['defaultValue']?.toString() ?? '',
            prefixIcon: Icons.data_array,
          ),
        ]);
        break;
    }

    return fields;
  }

  /// 解析 description 字符串为 Map
  Map<String, dynamic> _parseDescription(String? description) {
    if (description == null || description.isEmpty) return {};

    // 尝试解析为 JSON
    try {
      if (description.trim().startsWith('{')) {
        // 如果是 JSON 格式
        final parsed = jsonDecode(description) as Map<String, dynamic>;
        return parsed;
      }
    } catch (e) {
      // JSON 解析失败，尝试其他格式
    }

    // 如果是旧格式的纯文本，作为 defaultValue 返回
    return {'defaultValue': description};
  }

  /// 保存并返回配置的字段模型
  FieldModel _buildFieldModel(Map<String, dynamic> values) {
    final name = values['name'] as String? ?? '';
    final description = _buildDescription(values);

    return FieldModel(
      id: widget.initialField?.id ?? '', // 调用者需要设置 ID
      name: name,
      type: _selectedType,
      description: description,
    );
  }

  /// 从表单值构建 description 字段
  String? _buildDescription(Map<String, dynamic> values) {
    final description = <String, dynamic>{};

    // 收集所有非 name 字段
    for (final key in values.keys) {
      if (key != 'name') {
        final value = values[key];
        if (value != null && value.toString().isNotEmpty) {
          description[key] = value;
        }
      }
    }

    return description.isEmpty ? null : jsonEncode(description);
  }

  void _handleConfirm() {
    if (widget.showConfigTab) {
      // 配置模式：验证表单并保存
      _wrapperState?.submitForm();
    } else {
      // 普通模式：直接返回选中的类型
      if (widget.multiSelect) {
        Navigator.pop(context, _selectedTypes.toList());
      } else {
        Navigator.pop(context, _selectedTypes.first);
      }
    }
  }

  void _handleConfigSubmit(Map<String, dynamic> values) {
    final fieldModel = _buildFieldModel(values);
    Navigator.pop(context, fieldModel);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: widget.showConfigTab ? 500 : 400,
        height: widget.showConfigTab ? 500 : 400,
        child: widget.showConfigTab
            ? Column(
                children: [
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: '选择类型'),
                      Tab(text: '配置属性'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTypeSelectionTab(),
                        _buildConfigTab(),
                      ],
                    ),
                  ),
                ],
              )
            : _buildTypeSelectionTab(),
      ),
      actions: [
        // 左侧全选/反选按钮（仅多选模式且非配置模式）
        if (widget.multiSelect && !widget.showConfigTab)
          TextButton.icon(
            onPressed: _toggleSelectAll,
            icon: Icon(_hasSelection ? Icons.deselect : Icons.select_all),
            label: Text(_hasSelection ? '反选' : '全选'),
            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
          ),
        if (widget.multiSelect && !widget.showConfigTab) const SizedBox(width: 8),
        // 右侧取消/确定按钮
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _hasSelection ? _handleConfirm : null,
          child: const Text('确定'),
        ),
      ],
    );
  }

  /// 构建类型选择 Tab
  Widget _buildTypeSelectionTab() {
    return ListView.builder(
      itemCount: _availableTypes.length,
      itemBuilder: (context, index) {
        final type = _availableTypes[index];
        final icon = FieldController.fieldTypes[type];
        final isSelected = _selectedTypes.contains(type);

        if (widget.multiSelect && !widget.showConfigTab) {
          // 多选模式（配置模式下禁用多选）
          return CheckboxListTile(
            secondary: Icon(icon, color: Colors.deepPurple),
            title: Text(type),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedTypes.add(type);
                } else {
                  _selectedTypes.remove(type);
                }
              });
            },
          );
        } else {
          // 单选模式
          return RadioListTile<String>(
            secondary: Icon(icon, color: Colors.deepPurple),
            title: Text(type),
            value: type,
            groupValue: _selectedType,
            onChanged: (value) {
              if (value != null) {
                _onTypeSelected(value);
              }
            },
          );
        }
      },
    );
  }

  /// 构建配置 Tab
  Widget _buildConfigTab() {
    final configFields = _buildConfigFields();

    return FormBuilderWrapper(
      formKey: _formKey,
      onStateReady: (state) => _wrapperState = state,
      config: FormConfig(
        showSubmitButton: false,
        showResetButton: false,
        fieldSpacing: 16,
        fields: configFields,
        onSubmit: _handleConfigSubmit,
      ),
    );
  }
}
