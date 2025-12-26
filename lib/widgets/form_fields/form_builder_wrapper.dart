import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'form_field_wrapper.dart';
import 'config.dart';
import 'types.dart';
import 'builders/index.dart';

/// 公共表单包装器
///
/// 提供基于配置的动态表单生成功能，支持：
/// - 通过 List[FormFieldConfig] 配置生成字段
/// - 状态完全由内部管理
/// - 自动验证和值收集
/// - 灵活的提交和重置回调
/// - 与现有表单字段组件无缝集成
class FormBuilderWrapper extends StatefulWidget {
  /// 表单配置
  final FormConfig config;

  /// 表单 key（用于 FormBuilder）
  final GlobalKey<FormBuilderState>? formKey;

  /// 状态就绪回调（用于外部访问 wrapper 状态）
  final void Function(FormBuilderWrapperState state)? onStateReady;

  /// 自定义按钮构建器
  final Widget Function(BuildContext context, VoidCallback onSubmit, VoidCallback onReset)? buttonBuilder;

  /// 表单内容构建器（可用于包裹额外内容）
  final Widget Function(BuildContext context, List<Widget> fields)? contentBuilder;

  const FormBuilderWrapper({
    super.key,
    required this.config,
    this.formKey,
    this.onStateReady,
    this.buttonBuilder,
    this.contentBuilder,
  });

  @override
  State<FormBuilderWrapper> createState() => FormBuilderWrapperState();
}

class FormBuilderWrapperState extends State<FormBuilderWrapper> {
  final Map<String, GlobalKey<WrappedFormFieldState>> _fieldKeys = {};
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final ValueNotifier<int> _formChangeNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    for (final field in widget.config.fields) {
      _fieldKeys[field.name] = GlobalKey<WrappedFormFieldState>();
    }
    widget.onStateReady?.call(this);
  }

  @override
  void dispose() {
    super.dispose();
    _formChangeNotifier.dispose();
  }

  /// 获取实际使用的 FormBuilder key
  GlobalKey<FormBuilderState> get _actualFormKey => widget.formKey ?? _fbKey;

  Map<String, dynamic> get _currentValues {
    final formValues = _actualFormKey.currentState?.value ?? {};
    final values = Map<String, dynamic>.from(formValues);
    // 合并 WrappedFormField 的值（这些字段不会自动注册到 FormBuilder）
    for (final entry in _fieldKeys.entries) {
      final fieldState = entry.value.currentState;
      if (fieldState != null) {
        values[entry.key] = fieldState.getValue();
      }
    }
    return values;
  }

  void submitForm() => _submitFormInternal();

  Map<String, dynamic> get currentValues => _currentValues;

  bool saveAndValidate() {
    final fbState = _actualFormKey.currentState;
    if (fbState != null) {
      fbState.save();
      for (final fieldKey in _fieldKeys.values) {
        fieldKey.currentState?.save();
      }
      // 执行自定义验证逻辑
      return _validateAllFields();
    }
    return false;
  }

  /// 验证所有字段（包括自定义验证规则）
  bool _validateAllFields() {
    // 获取当前值
    final formValues = _actualFormKey.currentState?.value ?? {};
    final values = Map<String, dynamic>.from(formValues);
    for (final entry in _fieldKeys.entries) {
      final fieldState = entry.value.currentState;
      if (fieldState != null) {
        values[entry.key] = fieldState.getValue();
      }
    }

    // 验证所有必填字段
    for (final field in widget.config.fields) {
      if (field.required) {
        final value = values[field.name];
        bool isEmpty = false;

        if (value == null) {
          isEmpty = true;
        } else if (value is Map) {
          // 对于 iconTitle 等 Map 类型字段，检查 'title' 键
          isEmpty = (value['title']?.toString().trim() ?? '').isEmpty;
        } else if (value is String) {
          isEmpty = value.trim().isEmpty;
        } else if (value is List && value.isEmpty) {
          isEmpty = true;
        }

        if (isEmpty) {
          _showValidationError(field.validationMessage ?? '${field.labelText ?? field.name}不能为空');
          return false;
        }
      }
    }
    return true;
  }

  void patchValue(Map<String, dynamic> values) {
    _actualFormKey.currentState?.patchValue(values);
  }

  void _submitFormInternal() {
    final fbState = _actualFormKey.currentState;

    // 先保存表单，确保所有字段值同步
    fbState?.save();
    for (final fieldKey in _fieldKeys.values) {
      fieldKey.currentState?.save();
    }

    // 从 FormBuilder 获取值
    final formValues = fbState?.value ?? {};

    // 合并 WrappedFormField 的值（这些字段不会自动注册到 FormBuilder）
    final values = Map<String, dynamic>.from(formValues);
    for (final entry in _fieldKeys.entries) {
      final fieldState = entry.value.currentState;
      if (fieldState != null) {
        values[entry.key] = fieldState.getValue();
      }
    }

    bool isValid = true;
    final errors = <String, dynamic>{};

    for (final field in widget.config.fields) {
      final value = values[field.name];
      if (field.required && (value == null || value.toString().isEmpty)) {
        isValid = false;
        errors[field.name] = field.validationMessage ?? '${field.labelText ?? field.name}不能为空';
      }
    }

    if (isValid) {
      widget.config.onSubmit(values);
    } else if (widget.config.onValidationFailed != null) {
      widget.config.onValidationFailed!(errors);
    } else {
      // 默认验证失败行为：显示错误消息
      final errorMessages = errors.values.join('\n');
      _showValidationError(errorMessages);
    }
  }

  /// 显示验证错误提示
  void _showValidationError(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '知道了',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () => scaffoldMessenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _resetForm() {
    for (final fieldKey in _fieldKeys.values) {
      fieldKey.currentState?.reset();
    }
    widget.config.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _actualFormKey,
      child: Column(
        crossAxisAlignment: widget.config.crossAxisAlignment,
        children: [
          if (widget.contentBuilder != null)
            widget.contentBuilder!(context, widget.config.fields.map((config) => _buildFieldWrapper(config)).toList())
          else
            ...widget.config.fields.map((config) => _buildFieldWrapper(config)).expand((field) => [
              field,
              SizedBox(height: widget.config.fieldSpacing),
            ]).toList()
              ..removeLast(),
          if (widget.config.showSubmitButton || widget.config.showResetButton)
            _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildFieldWrapper(FormFieldConfig config) {
    if (config.visible == null) {
      return _buildField(config);
    }

    return ValueListenableBuilder(
      valueListenable: _formChangeNotifier,
      builder: (context, _, __) {
        final shouldShow = config.visible!(_currentValues);
        return shouldShow ? _buildField(config) : const SizedBox.shrink();
      },
    );
  }

  Widget _buildField(FormFieldConfig config) {
    final fieldKey = _fieldKeys[config.name]!;

    switch (config.type) {
      case FormFieldType.text:
      case FormFieldType.password:
      case FormFieldType.email:
      case FormFieldType.number:
        return buildTextField(config, fieldKey, context);

      case FormFieldType.textArea:
        return buildTextAreaField(config, fieldKey, context);

      case FormFieldType.select:
        return buildSelectField(config, fieldKey, context);

      case FormFieldType.date:
        return buildDateField(config, fieldKey, context);

      case FormFieldType.dateRange:
        return buildDateRangeField(config, fieldKey);

      case FormFieldType.time:
        return buildTimeField(config, fieldKey);

      case FormFieldType.switchField:
        return buildSwitchField(config, fieldKey);

      case FormFieldType.slider:
        return buildSliderField(config, fieldKey);

      case FormFieldType.color:
        return buildColorField(config, fieldKey);

      case FormFieldType.tags:
        return buildTagsField(config, fieldKey, context);

      case FormFieldType.iconTitle:
        return buildIconTitleField(config, fieldKey);

      case FormFieldType.categorySelector:
        return buildCategorySelectorField(config, fieldKey);

      case FormFieldType.optionSelector:
        return buildOptionSelectorField(config, fieldKey);

      case FormFieldType.customFields:
        return buildCustomFieldsField(config, fieldKey);

      case FormFieldType.listAdd:
        return buildListAddField(config, fieldKey);

      case FormFieldType.iconPicker:
        return buildIconPickerField(config, fieldKey);

      case FormFieldType.avatarPicker:
        return buildAvatarPickerField(config, fieldKey);

      case FormFieldType.circleIconPicker:
        return buildCircleIconPickerField(config, fieldKey);

      case FormFieldType.calendarStripPicker:
        return buildCalendarStripPickerField(config, fieldKey);

      case FormFieldType.imagePicker:
        return buildImagePickerField(config, fieldKey);

      case FormFieldType.locationPicker:
        return buildLocationPickerField(config, fieldKey);

      case FormFieldType.promptEditor:
        return buildPromptEditorField(config, fieldKey);

      case FormFieldType.iconAvatarRow:
        return buildIconAvatarRowField(config, fieldKey);

      case FormFieldType.expenseTypeSelector:
        return buildExpenseTypeSelectorField(config, fieldKey);

      case FormFieldType.amountInput:
        return buildAmountInputField(config, fieldKey);

      case FormFieldType.reminders:
        return buildRemindersField(config, fieldKey);

      case FormFieldType.timerItems:
        return buildTimerItemsField(config, fieldKey, context);

      case FormFieldType.timerIconGrid:
        return buildTimerIconGridField(config, fieldKey);

      case FormFieldType.genderSelector:
        return buildGenderSelectorField(config, fieldKey);

      case FormFieldType.customEvents:
        return buildCustomEventsField(config, fieldKey);

      case FormFieldType.avatarNameSection:
        return buildAvatarNameSectionField(config, fieldKey);

      case FormFieldType.chipSelector:
        return buildChipSelectorField(config, fieldKey);

      case FormFieldType.subscriptionCycle:
        return buildSubscriptionCycleField(config, fieldKey);

      case FormFieldType.reminderDate:
        return buildReminderDateField(config, fieldKey);
    }
  }

  Widget _buildButtons() {
    if (widget.buttonBuilder != null) {
      return widget.buttonBuilder!(context, submitForm, _resetForm);
    }

    if (widget.config.submitButtonWidget != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: InkWell(
          onTap: () async {
            final fbState = _actualFormKey.currentState;
            if (fbState != null) {
              final isValid = fbState.saveAndValidate();
              if (isValid) {
                _submitFormInternal();
              }
            } else {
              _submitFormInternal();
            }
          },
          child: widget.config.submitButtonWidget,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: widget.config.buttonAlignment,
        children: [
          if (widget.config.showResetButton)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _resetForm,
                child: Text(widget.config.resetButtonText),
              ),
            ),
          if (widget.config.showSubmitButton)
            FilledButton(
              onPressed: () async {
                final fbState = _actualFormKey.currentState;
                if (fbState != null) {
                  final isValid = fbState.saveAndValidate();
                  if (isValid) {
                    _submitFormInternal();
                  }
                } else {
                  _submitFormInternal();
                }
              },
              child: Text(widget.config.submitButtonText),
            ),
        ],
      ),
    );
  }
}
