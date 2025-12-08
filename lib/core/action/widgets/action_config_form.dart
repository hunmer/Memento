/// 动作配置表单组件
/// 动态生成动作参数配置表单
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/action/models/action_definition.dart';
import 'package:Memento/core/action/models/action_form.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/l10n/core_localizations.dart';

/// 表单值改变回调
typedef OnFormChanged = void Function(Map<String, dynamic> values);

/// 动作配置表单
class ActionConfigForm extends StatefulWidget {
  final ActionDefinition actionDefinition;
  final OnFormChanged? onChanged;
  final Map<String, dynamic>? initialData;
  final bool readOnly;

  const ActionConfigForm({
    super.key,
    required this.actionDefinition,
    this.onChanged,
    this.initialData,
    this.readOnly = false,
  });

  @override
  State<ActionConfigForm> createState() => _ActionConfigFormState();
}

class _ActionConfigFormState extends State<ActionConfigForm> {
  // 表单键
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 表单数据
  final Map<String, dynamic> _formData = {};

  // 错误信息
  final Map<String, List<String>> _errors = {};

  @override
  void initState() {
    super.initState();

    // 初始化表单数据
    if (widget.initialData != null) {
      _formData.addAll(widget.initialData!);
    } else if (widget.actionDefinition.form != null) {
      for (final entry in widget.actionDefinition.form!.fields.entries) {
        final field = entry.value;
        if (field.defaultValue != null) {
          _formData[entry.key] = field.defaultValue;
        }
      }
    }

    // 延迟触发初始变化回调，避免在构建过程中调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitChange();
    });
  }

  void _emitChange() {
    widget.onChanged?.call(Map.from(_formData));
  }

  void _updateField(String fieldName, dynamic value) {
    setState(() {
      _formData[fieldName] = value;
    });
    _emitChange();
  }

  void _setError(String fieldName, List<String> errors) {
    setState(() {
      _errors[fieldName] = errors;
    });
  }

  void _clearError(String fieldName) {
    setState(() {
      _errors.remove(fieldName);
    });
  }

  List<Widget> _buildFormFields() {
    final widgets = <Widget>[];

    if (widget.actionDefinition.form == null) {
      // 没有表单配置，显示默认字段
      return _buildDefaultFields();
    }

    final form = widget.actionDefinition.form!;
    final sortedFields = form.getSortedFields();

    for (final entry in sortedFields) {
      final fieldName = entry.key;
      final fieldConfig = entry.value;

      // 跳过隐藏字段
      if (fieldConfig.hidden) continue;

      widgets.add(_buildFormField(fieldName, fieldConfig));
    }

    return widgets;
  }

  List<Widget> _buildDefaultFields() {
    // 为 openPlugin 动作显示插件选择器
    if (widget.actionDefinition.id == BuiltInActions.openPlugin) {
      return [
        _buildPluginSelectorField(
          'plugin',
          '插件名称',
          '选择要打开的插件',
          _formData['plugin'] as String?,
        ),
      ];
    }

    // 为 js_custom_executor 动作显示JavaScript代码输入框
    if (widget.actionDefinition.id == 'js_custom_executor') {
      return [
        _buildJavaScriptCodeField(),
      ];
    }

    // 默认显示空提示
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '此动作无需额外配置',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ];
  }

  /// 构建JavaScript代码输入字段
  Widget _buildJavaScriptCodeField() {
    final scriptController = TextEditingController(
      text: _formData['script'] as String? ?? '',
    );

    scriptController.addListener(() {
      _updateField('script', scriptController.text);
    });

    final inputDataController = TextEditingController(
      text: _formData['inputData'] as String? ?? '',
    );

    inputDataController.addListener(() {
      _updateField('inputData', inputDataController.text);
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JavaScript代码',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: scriptController,
            decoration: const InputDecoration(
              hintText: '在这里输入您的JavaScript代码',
              border: OutlineInputBorder(),
              helperText: '使用 inputData 访问输入数据，返回格式：{ success: true, ... }',
              helperMaxLines: 2,
            ),
            maxLines: 10,
            minLines: 5,
          ),
          const SizedBox(height: 16),
          const Text(
            '输入数据（JSON格式，可选）',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: inputDataController,
            decoration: const InputDecoration(
              hintText: '{"key": "value"}',
              border: OutlineInputBorder(),
              helperText: '可选：输入要传递给JavaScript的数据',
              helperMaxLines: 2,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String fieldName, FormFieldConfig config) {
    final hasError = _errors.containsKey(fieldName);
    final errorText = hasError ? _errors[fieldName]!.join('\n') : null;

    Widget fieldWidget;

    switch (config.type) {
      case FormFieldType.text:
        fieldWidget = _buildTextField(fieldName, config);
        break;
      case FormFieldType.textarea:
        fieldWidget = _buildTextArea(fieldName, config);
        break;
      case FormFieldType.select:
        fieldWidget = _buildSelectField(fieldName, config);
        break;
      case FormFieldType.multiSelect:
        fieldWidget = _buildMultiSelectField(fieldName, config);
        break;
      case FormFieldType.checkbox:
        fieldWidget = _buildCheckboxField(fieldName, config);
        break;
      case FormFieldType.switchField:
        fieldWidget = _buildSwitchField(fieldName, config);
        break;
      case FormFieldType.slider:
        fieldWidget = _buildSliderField(fieldName, config);
        break;
      case FormFieldType.number:
        fieldWidget = _buildNumberField(fieldName, config);
        break;
      case FormFieldType.date:
        fieldWidget = _buildDateField(fieldName, config);
        break;
      case FormFieldType.time:
        fieldWidget = _buildTimeField(fieldName, config);
        break;
      case FormFieldType.dateTime:
        fieldWidget = _buildDateTimeField(fieldName, config);
        break;
      case FormFieldType.pluginSelector:
        fieldWidget = _buildPluginSelectorField(
          fieldName,
          config.label,
          config.hint,
          _formData[fieldName] as String?,
        );
        break;
      case FormFieldType.colorPicker:
        fieldWidget = _buildColorPickerField(fieldName, config);
        break;
      case FormFieldType.iconSelector:
        fieldWidget = _buildIconSelectorField(fieldName, config);
        break;
      default:
        fieldWidget = _buildTextField(fieldName, config);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldWidget,
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as String? ?? '';

    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: config.label,
        hintText: config.hint,
        border: const OutlineInputBorder(),
        errorMaxLines: 3,
      ),
      enabled: !(widget.readOnly || config.readOnly),
      onChanged: (value) => _updateField(fieldName, value),
      validator: (value) {
        final errors = config.validate(value);
        if (errors.isNotEmpty) {
          _setError(fieldName, errors);
          return errors.first;
        }
        _clearError(fieldName);
        return null;
      },
    );
  }

  Widget _buildTextArea(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as String? ?? '';

    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: config.label,
        hintText: config.hint,
        border: const OutlineInputBorder(),
        errorMaxLines: 3,
      ),
      maxLines: 3,
      enabled: !(widget.readOnly || config.readOnly),
      onChanged: (value) => _updateField(fieldName, value),
      validator: (value) {
        final errors = config.validate(value);
        if (errors.isNotEmpty) {
          _setError(fieldName, errors);
          return errors.first;
        }
        _clearError(fieldName);
        return null;
      },
    );
  }

  Widget _buildSelectField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName];

    return DropdownButtonFormField<String>(
      value: value as String?,
      decoration: InputDecoration(
        labelText: config.label,
        hintText: config.hint,
        border: const OutlineInputBorder(),
        errorMaxLines: 3,
      ),
      items: [
        if (!config.required)
          const DropdownMenuItem<String>(
            value: null,
            child: Text(CoreLocalizations.of(context)!.notSelected),
          ),
        ...?config.options?.map(
          (option) => DropdownMenuItem<String>(
            value: option.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option.label),
                if (option.description != null)
                  Text(
                    option.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      onChanged: widget.readOnly || config.readOnly ? null : (value) => _updateField(fieldName, value),
      validator: (value) {
        final errors = config.validate(value);
        if (errors.isNotEmpty) {
          _setError(fieldName, errors);
          return errors.first;
        }
        _clearError(fieldName);
        return null;
      },
    );
  }

  Widget _buildMultiSelectField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...?config.options?.map(
              (option) {
                final isSelected = value.contains(option.value);
                return FilterChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: widget.readOnly || config.readOnly
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              value.add(option.value);
                            } else {
                              value.remove(option.value);
                            }
                            _updateField(fieldName, value);
                          });
                        },
                );
              },
            ),
          ],
        ),
        if (config.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              config.hint!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as bool? ?? false;

    return CheckboxListTile(
      title: Text(config.label),
      subtitle: config.hint != null ? Text(config.hint!) : null,
      value: value,
      onChanged: widget.readOnly || config.readOnly
          ? null
          : (value) => _updateField(fieldName, value),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSwitchField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as bool? ?? false;

    return SwitchListTile(
      title: Text(config.label),
      subtitle: config.hint != null ? Text(config.hint!) : null,
      value: value,
      onChanged: widget.readOnly || config.readOnly
          ? null
          : (value) => _updateField(fieldName, value),
    );
  }

  Widget _buildSliderField(String fieldName, FormFieldConfig config) {
    final value = (_formData[fieldName] as num?)?.toDouble() ??
        (config.defaultValue as num?)?.toDouble() ??
        0.0;

    final min = (config.extraParams?['min'] as num?)?.toDouble() ?? 0.0;
    final max = (config.extraParams?['max'] as num?)?.toDouble() ?? 100.0;
    final divisions = config.extraParams?['divisions'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${config.label}: ${value.round()}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: widget.readOnly || config.readOnly
              ? null
              : (value) => _updateField(fieldName, value),
        ),
      ],
    );
  }

  Widget _buildNumberField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as num?;

    return TextFormField(
      initialValue: value?.toString(),
      decoration: InputDecoration(
        labelText: config.label,
        hintText: config.hint,
        border: const OutlineInputBorder(),
        errorMaxLines: 3,
      ),
      keyboardType: TextInputType.number,
      readOnly: widget.readOnly || config.readOnly,
      onChanged: (value) => _updateField(
        fieldName,
        value.isEmpty ? null : num.tryParse(value),
      ),
      validator: (value) {
        final errors = config.validate(value);
        if (errors.isNotEmpty) {
          _setError(fieldName, errors);
          return errors.first;
        }
        _clearError(fieldName);
        return null;
      },
    );
  }

  Widget _buildDateField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as DateTime?;

    return ListTile(
      title: Text(config.label),
      subtitle: Text(
        value != null
            ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
            : config.hint ?? '选择日期',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: widget.readOnly || config.readOnly
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                _updateField(fieldName, date);
              }
            },
    );
  }

  Widget _buildTimeField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as TimeOfDay?;

    return ListTile(
      title: Text(config.label),
      subtitle: Text(
        value != null
            ? value.format(context)
            : config.hint ?? '选择时间',
      ),
      trailing: const Icon(Icons.access_time),
      onTap: widget.readOnly || config.readOnly
          ? null
          : () async {
              final time = await showTimePicker(
                context: context,
                initialTime: value ?? TimeOfDay.now(),
              );
              if (time != null) {
                _updateField(fieldName, time);
              }
            },
    );
  }

  Widget _buildDateTimeField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as DateTime?;

    return ListTile(
      title: Text(config.label),
      subtitle: Text(
        value != null
            ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
            : config.hint ?? '选择日期时间',
      ),
      trailing: const Icon(Icons.event),
      onTap: widget.readOnly || config.readOnly
          ? null
          : () async {
              final date = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: value != null
                      ? TimeOfDay.fromDateTime(value)
                      : TimeOfDay.now(),
                );
                if (time != null) {
                  final dateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  _updateField(fieldName, dateTime);
                }
              }
            },
    );
  }

  Widget _buildPluginSelectorField(
    String fieldName,
    String label,
    String? hint,
    String? currentValue,
  ) {
    // 获取所有真实插件
    final plugins = globalPluginManager.allPlugins;

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(CoreLocalizations.of(context)!.notSelected),
        ),
        ...plugins.map(
          (plugin) => DropdownMenuItem<String>(
            value: plugin.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  plugin.icon ?? Icons.extension,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    plugin.getPluginName(context) ?? plugin.id,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: (value) => _updateField(fieldName, value),
    );
  }

  Widget _buildColorPickerField(String fieldName, FormFieldConfig config) {
    final value = _formData[fieldName] as Color?;

    return ListTile(
      title: Text(config.label),
      subtitle: Text(
        value != null
            ? '#${value.value.toRadixString(16).padLeft(8, '0')}'
            : config.hint ?? '选择颜色',
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ?? Colors.transparent,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onTap: widget.readOnly || config.readOnly
          ? null
          : () async {
              // 预设颜色列表
              final presetColors = [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
                Colors.black,
              ];

              final color = await showDialog<Color>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(CoreLocalizations.of(context)!.selectColor),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetColors
                          .map(
                            (c) => InkWell(
                              onTap: () => Navigator.pop(context, c),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: c,
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(CoreLocalizations.of(context)!.cancel),
                    ),
                  ],
                ),
              );
              if (color != null) {
                _updateField(fieldName, color);
              }
            },
    );
  }

  Widget _buildIconSelectorField(String fieldName, FormFieldConfig config) {
    // TODO: 实现图标选择器
    return Text(CoreLocalizations.of(context)!.iconSelectorNotImplemented);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildFormFields(),
      ),
    );
  }
}
