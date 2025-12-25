import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/plugins/timer/views/add_timer_item_dialog.dart';
import 'package:Memento/plugins/contact/models/custom_activity_event_model.dart';
import 'form_field_wrapper.dart';
import '../picker/icon_picker_dialog.dart';
import 'index.dart';

/// 表单字段类型枚举
enum FormFieldType {
  // 文本输入类
  text,
  textArea,
  password,
  email,
  number,

  // 选择器类
  select,
  date,
  dateRange,           // 日期范围选择器
  time,

  // 开关滑块类
  switchField,
  slider,

  // 其他
  color,
  tags,
  iconTitle,
  categorySelector,
  optionSelector,
  customFields,
  listAdd,

  // Picker 选择器类（新增）
  iconPicker,          // 图标选择器
  avatarPicker,        // 头像选择器
  circleIconPicker,    // 圆形图标选择器
  calendarStripPicker, // 日历条日期选择器
  imagePicker,         // 图片选择器
  locationPicker,      // 位置选择器

  // 自定义复合字段
  promptEditor,        // 提示词编辑器
  iconAvatarRow,       // 图标头像行

  // 账单专用字段
  expenseTypeSelector, // 收支类型选择器
  amountInput,         // 金额输入框

  // 待办任务专用字段
  reminders,           // 提醒时间列表

  // 计时器专用字段
  timerItems,          // 子计时器列表
  timerIconGrid,       // 图标网格选择器

  // 联系人专用字段
  genderSelector,      // 性别选择器
  customEvents,        // 自定义活动事件列表
  avatarNameSection,   // 头像名称区域（头像+姓名组合）

  // 日记相册专用字段
  chipSelector,        // Chip 选择器（心情、天气等）

  // 订阅专用字段
  subscriptionCycle,   // 订阅周期选择器（月度/季度/年度）
}

/// 表单字段配置
class FormFieldConfig {
  /// 字段唯一标识
  final String name;

  /// 字段类型
  final FormFieldType type;

  /// 字段标签
  final String? labelText;

  /// 占位提示
  final String? hintText;

  /// 初始值
  final dynamic initialValue;

  /// 是否必填
  final bool required;

  /// 验证错误消息
  final String? validationMessage;

  /// 是否启用
  final bool enabled;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 下拉选项（用于 select 类型）
  final List<DropdownMenuItem>? items;

  /// 滑块最小值
  final double? min;

  /// 滑块最大值
  final double? max;

  /// 滑块分段数
  final int? divisions;

  /// 快捷值（用于滑块）
  final List<double>? quickValues;

  /// 类别选项（用于 categorySelector）
  final List<String>? categories;

  /// 类别图标（用于 categorySelector）
  final Map<String, IconData>? categoryIcons;

  /// 选项列表（用于 optionSelector）
  final List<OptionItem>? options;

  /// 是否使用水平滚动（用于 optionSelector）
  final bool useHorizontalScroll;

  /// 选项卡片宽度（用于 optionSelector）
  final double? optionWidth;

  /// 选项卡片高度（用于 optionSelector）
  final double? optionHeight;

  /// 网格列数（用于 optionSelector）
  final int? gridColumns;

  /// 主题色（用于 optionSelector）
  final Color? primaryColor;

  /// 标签（用于 tags）
  final List<String>? initialTags;

  /// 自定义字段（用于 customFields）
  final List<dynamic>? initialCustomFields;

  /// 值变化回调
  final ValueChanged? onChanged;

  /// 自定义属性（用于扩展）
  final Map<String, dynamic>? extra;

  /// 显示条件（返回 true 时显示字段）
  final bool Function(Map<String, dynamic> formValues)? visible;

  /// 输入框前缀按钮（用于 text/number/email 等输入类型）
  final List<InputGroupButton>? prefixButtons;

  /// 输入框后缀按钮（用于 text/number/email 等输入类型）
  final List<InputGroupButton>? suffixButtons;

  const FormFieldConfig({
    required this.name,
    required this.type,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.required = false,
    this.validationMessage,
    this.enabled = true,
    this.prefixIcon,
    this.items,
    this.min,
    this.max,
    this.divisions,
    this.quickValues,
    this.categories,
    this.categoryIcons,
    this.options,
    this.useHorizontalScroll = true,
    this.optionWidth,
    this.optionHeight,
    this.gridColumns,
    this.primaryColor,
    this.initialTags,
    this.initialCustomFields,
    this.onChanged,
    this.extra,
    this.visible,
    this.prefixButtons,
    this.suffixButtons,
  });
}

/// 输入框组按钮
class InputGroupButton {
  /// 按钮图标
  final IconData icon;

  /// 按钮提示文本
  final String? tooltip;

  /// 点击回调
  final VoidCallback onPressed;

  const InputGroupButton({
    required this.icon,
    this.tooltip,
    required this.onPressed,
  });
}

/// 表单配置
class FormConfig {
  /// 字段配置列表
  final List<FormFieldConfig> fields;

  /// 表单提交回调
  final void Function(Map<String, dynamic> values) onSubmit;

  /// 表单重置回调
  final VoidCallback? onReset;

  /// 验证失败回调
  final void Function(Map<String, dynamic> errors)? onValidationFailed;

  /// 提交按钮文本
  final String submitButtonText;

  /// 重置按钮文本
  final String resetButtonText;

  /// 是否显示提交按钮
  final bool showSubmitButton;

  /// 是否显示重置按钮
  final bool showResetButton;

  /// 自定义提交按钮 widget（替代内置按钮）
  final Widget? submitButtonWidget;

  /// 按钮布局方式
  final MainAxisAlignment buttonAlignment;

  /// 表单间距
  final double fieldSpacing;

  /// 是否自动验证
  final bool autovalidateMode;

  /// 跨度方向
  final CrossAxisAlignment crossAxisAlignment;

  const FormConfig({
    required this.fields,
    required this.onSubmit,
    this.onReset,
    this.onValidationFailed,
    this.submitButtonText = '提交',
    this.resetButtonText = '重置',
    this.showSubmitButton = true,
    this.showResetButton = false,
    this.submitButtonWidget,
    this.buttonAlignment = MainAxisAlignment.end,
    this.fieldSpacing = 16,
    this.autovalidateMode = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });
}

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
  // 存储每个字段的 state key，用于访问其 getValue 和 reset 方法
  final Map<String, GlobalKey<WrappedFormFieldState>> _fieldKeys = {};

  // 用于 FormBuilder 的 key（用于监听表单值变化）
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

  // 用于监听表单变化的 ValueNotifier
  final ValueNotifier<int> _formChangeNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // 为每个字段创建 key
    for (final field in widget.config.fields) {
      _fieldKeys[field.name] = GlobalKey<WrappedFormFieldState>();
    }
    // 回调通知状态已准备就绪
    widget.onStateReady?.call(this);
  }

  @override
  void dispose() {
    super.dispose();
    _formChangeNotifier.dispose();
  }

  // 获取当前表单值
  Map<String, dynamic> get _currentValues {
    return _fbKey.currentState?.value ?? {};
  }

  // 公共提交方法（可从外部调用）
  void submitForm() => _submitFormInternal();

  // 获取当前表单值（公共方法）
  Map<String, dynamic> get currentValues => _currentValues;

  /// 保存并验证所有字段
  /// 先调用 FormBuilder 的 saveAndValidate，然后保存所有 WrappedField 的值
  bool saveAndValidate() {
    // 先调用 FormBuilder 的 saveAndValidate
    final fbState = _fbKey.currentState;
    if (fbState != null) {
      fbState.save();
      // 触发所有 WrappedField 的 save()
      for (final fieldKey in _fieldKeys.values) {
        fieldKey.currentState?.save();
      }
      return fbState.validate();
    }
    return false;
  }

  // 更新指定字段的值（公共方法）
  void patchValue(Map<String, dynamic> values) {
    _fbKey.currentState?.patchValue(values);
  }

  // 内部提交表单方法
  void _submitFormInternal() {
    // 从所有字段包装器中获取值
    final values = <String, dynamic>{};

    for (final entry in _fieldKeys.entries) {
      final fieldName = entry.key;
      final fieldKey = entry.value;
      final value = fieldKey.currentState?.getValue();
      if (value != null) {
        values[fieldName] = value;
      }
    }

    // 验证必填字段
    bool isValid = true;
    final errors = <String, dynamic>{};

    for (final field in widget.config.fields) {
      if (field.required && (values[field.name] == null || values[field.name].toString().isEmpty)) {
        isValid = false;
        errors[field.name] = field.validationMessage ?? '${field.labelText ?? field.name}不能为空';
      }
    }

    if (isValid) {
      widget.config.onSubmit(values);
    } else if (widget.config.onValidationFailed != null) {
      widget.config.onValidationFailed!(errors);
    }
  }

  // 重置表单
  void _resetForm() {
    for (final fieldKey in _fieldKeys.values) {
      fieldKey.currentState?.reset();
    }
    widget.config.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: widget.formKey ?? _fbKey,
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
              ..removeLast(), // 移除最后一个间距
          if (widget.config.showSubmitButton || widget.config.showResetButton)
            _buildButtons(),
        ],
      ),
    );
  }

  // 包装字段，支持条件显示
  Widget _buildFieldWrapper(FormFieldConfig config) {
    // 如果没有 visible 条件，直接返回字段
    if (config.visible == null) {
      return _buildField(config);
    }

    // 使用 ValueListenableBuilder 监听表单值变化
    return ValueListenableBuilder(
      valueListenable: _formChangeNotifier,
      builder: (context, _, __) {
        final shouldShow = config.visible!(_currentValues);
        return shouldShow ? _buildField(config) : const SizedBox.shrink();
      },
    );
  }

  // 构建单个字段
  Widget _buildField(FormFieldConfig config) {
    final fieldKey = _fieldKeys[config.name];

    switch (config.type) {
      // 文本输入类
      case FormFieldType.text:
      case FormFieldType.password:
      case FormFieldType.email:
      case FormFieldType.number:
        return _buildTextField(config, fieldKey!);

      case FormFieldType.textArea:
        return _buildTextAreaField(config, fieldKey!);

      // 选择器类
      case FormFieldType.select:
        return _buildSelectField(config, fieldKey!);

      case FormFieldType.date:
        return _buildDateField(config, fieldKey!);

      case FormFieldType.dateRange:
        return _buildDateRangeField(config, fieldKey!);

      case FormFieldType.time:
        return _buildTimeField(config, fieldKey!);

      // 开关滑块类
      case FormFieldType.switchField:
        return _buildSwitchField(config, fieldKey!);

      case FormFieldType.slider:
        return _buildSliderField(config, fieldKey!);

      // 其他类型
      case FormFieldType.color:
        return _buildColorField(config, fieldKey!);

      case FormFieldType.tags:
        return _buildTagsField(config, fieldKey!);

      case FormFieldType.iconTitle:
        return _buildIconTitleField(config, fieldKey!);

      case FormFieldType.categorySelector:
        return _buildCategorySelectorField(config, fieldKey!);

      case FormFieldType.optionSelector:
        return _buildOptionSelectorField(config, fieldKey!);

      case FormFieldType.customFields:
        return _buildCustomFieldsField(config, fieldKey!);

      case FormFieldType.listAdd:
        return _buildListAddField(config, fieldKey!);

      // Picker 选择器类（新增）
      case FormFieldType.iconPicker:
        return _buildIconPickerField(config, fieldKey!);

      case FormFieldType.avatarPicker:
        return _buildAvatarPickerField(config, fieldKey!);

      case FormFieldType.circleIconPicker:
        return _buildCircleIconPickerField(config, fieldKey!);

      case FormFieldType.calendarStripPicker:
        return _buildCalendarStripPickerField(config, fieldKey!);

      case FormFieldType.imagePicker:
        return _buildImagePickerField(config, fieldKey!);

      case FormFieldType.locationPicker:
        return _buildLocationPickerField(config, fieldKey!);

      // 自定义复合字段
      case FormFieldType.promptEditor:
        return _buildPromptEditorField(config, fieldKey!);

      case FormFieldType.iconAvatarRow:
        return _buildIconAvatarRowField(config, fieldKey!);

      // 账单专用字段
      case FormFieldType.expenseTypeSelector:
        return _buildExpenseTypeSelectorField(config, fieldKey!);

      case FormFieldType.amountInput:
        return _buildAmountInputField(config, fieldKey!);

      // 待办任务专用字段
      case FormFieldType.reminders:
        return _buildRemindersField(config, fieldKey!);

      // 计时器专用字段
      case FormFieldType.timerItems:
        return _buildTimerItemsField(config, fieldKey!);

      case FormFieldType.timerIconGrid:
        return _buildTimerIconGridField(config, fieldKey!);

      // 联系人专用字段
      case FormFieldType.genderSelector:
        return _buildGenderSelectorField(config, fieldKey!);

      case FormFieldType.customEvents:
        return _buildCustomEventsField(config, fieldKey!);

      case FormFieldType.avatarNameSection:
        return _buildAvatarNameSectionField(config, fieldKey!);

      // 日记相册专用字段
      case FormFieldType.chipSelector:
        return _buildChipSelectorField(config, fieldKey!);

      // 订阅专用字段
      case FormFieldType.subscriptionCycle:
        return _buildSubscriptionCycleField(config, fieldKey!);
    }
  }

  // 构建文本输入框
  Widget _buildTextField(FormFieldConfig config, GlobalKey fieldKey) {
    // 如果有前缀或后缀按钮，使用 FormBuilderField + TextField
    if (config.prefixButtons != null || config.suffixButtons != null) {
      return FormBuilderField<String>(
        key: fieldKey,
        name: config.name,
        initialValue: config.initialValue?.toString() ?? '',
        enabled: config.enabled,
        builder: (fieldState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (config.labelText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    config.labelText!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              Row(
                children: [
                  // 前缀按钮
                  if (config.prefixButtons != null)
                    ...config.prefixButtons!.map((btn) => IconButton(
                          icon: Icon(btn.icon),
                          tooltip: btn.tooltip,
                          onPressed: btn.onPressed,
                        )),
                  // 输入框
                  Expanded(
                    child: TextField(
                      controller: TextEditingController.fromValue(
                        TextEditingValue(text: fieldState.value ?? ''),
                      ),
                      decoration: InputDecoration(
                        hintText: config.hintText,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      obscureText: config.type == FormFieldType.password,
                      keyboardType: config.type == FormFieldType.email
                          ? TextInputType.emailAddress
                          : config.type == FormFieldType.number
                              ? TextInputType.number
                              : TextInputType.text,
                      enabled: config.enabled,
                      onChanged: (v) {
                        fieldState.didChange(v);
                        config.onChanged?.call(v);
                      },
                    ),
                  ),
                  // 后缀按钮
                  if (config.suffixButtons != null)
                    ...config.suffixButtons!.map((btn) => IconButton(
                          icon: Icon(btn.icon),
                          tooltip: btn.tooltip,
                          onPressed: btn.onPressed,
                        )),
                ],
              ),
            ],
          );
        },
      );
    }

    // 默认使用 FormBuilderTextField
    return FormBuilderTextField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue?.toString() ?? '',
      decoration: InputDecoration(
        labelText: config.labelText,
        hintText: config.hintText,
        prefixIcon: config.prefixIcon != null ? Icon(config.prefixIcon) : null,
      ),
      obscureText: config.type == FormFieldType.password,
      keyboardType: config.type == FormFieldType.email
          ? TextInputType.emailAddress
          : config.type == FormFieldType.number
              ? TextInputType.number
              : TextInputType.text,
      enabled: config.enabled,
      onChanged: config.onChanged,
    );
  }

  // 构建多行文本输入框
  Widget _buildTextAreaField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};

    return FormBuilderTextField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue?.toString() ?? '',
      decoration: InputDecoration(
        labelText: config.labelText,
        hintText: config.hintText,
        border: const OutlineInputBorder(),
      ),
      minLines: (extra['minLines'] as int?) ?? 3,
      maxLines: (extra['maxLines'] as int?) ?? 6,
      keyboardType: TextInputType.multiline,
      enabled: config.enabled,
      onChanged: config.onChanged,
    );
  }

  // 构建下拉选择框
  Widget _buildSelectField(FormFieldConfig config, GlobalKey fieldKey) {
    return FormBuilderDropdown<dynamic>(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue,
      decoration: InputDecoration(
        labelText: config.labelText,
        hintText: config.hintText ?? '请选择',
      ),
      enabled: config.enabled,
      items: config.items ?? [],
      onChanged: config.onChanged,
    );
  }

  // 构建日期选择框
  Widget _buildDateField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as DateTime?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        return DatePickerField(
          date: value,
          formattedDate: value != null
              ? (extra['format'] != null
                  ? DateFormat(extra['format'] as String).format(value)
                  : DateFormat('yyyy-MM-dd').format(value))
              : '',
          placeholder: config.hintText ?? '选择日期',
          labelText: config.labelText,
          inline: (extra['inline'] as bool?) ?? false,
          onTap: config.enabled
              ? () async {
                  final initialDate = value ?? DateTime.now();
                  final firstDate = extra['firstDate'] as DateTime? ?? DateTime(2000);
                  final lastDate = extra['lastDate'] as DateTime? ?? DateTime(2100);

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (picked != null) {
                    setValue(picked);
                  }
                }
              : () {},
        );
      },
    );
  }

  // 构建时间选择框
  Widget _buildTimeField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as TimeOfDay?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => TimePickerField(
        label: config.labelText ?? '选择时间',
        time: value ?? TimeOfDay.now(),
        onTimeChanged: setValue,
      ),
    );
  }

  // 构建开关
  Widget _buildSwitchField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};

    return FormBuilderField<bool>(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as bool? ?? false,
      enabled: config.enabled,
      builder: (fieldState) => SwitchField(
        value: fieldState.value ?? false,
        title: config.labelText ?? '',
        subtitle: config.hintText,
        icon: config.prefixIcon,
        inline: (extra['inline'] as bool?) ?? false,
        onChanged: config.enabled ? (v) {
          fieldState.didChange(v);
          config.onChanged?.call(v);
        } : null,
      ),
    );
  }

  // 构建滑块
  Widget _buildSliderField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final quickValueLabelFn = extra['quickValueLabel'] as String Function(double)?;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as double? ?? 0.0,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        final displayValue = (extra['valueText'] as String?) ?? '${(value ?? 0).toInt()}';

        return SliderField(
          label: config.labelText ?? '',
          valueText: displayValue,
          min: config.min ?? 0,
          max: config.max ?? 100,
          value: value ?? 0,
          divisions: config.divisions,
          onChanged: config.enabled ? setValue : null,
          quickValues: config.quickValues,
          quickValueLabel: quickValueLabelFn,
          onQuickValueTap: config.enabled
              ? (v) {
                  setValue(v);
                }
              : null,
        );
      },
    );
  }

  // 构建颜色选择器
  Widget _buildColorField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as Color? ?? Colors.blue,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => ColorSelectorField(
        labelText: config.labelText ?? '选择颜色',
        selectedColor: value ?? Colors.blue,
        onColorChanged: config.enabled ? setValue : (color) {},
      ),
    );
  }

  // 构建标签字段
  Widget _buildTagsField(FormFieldConfig config, GlobalKey fieldKey) {
    final initialTags = config.initialTags ?? [];
    final extra = config.extra ?? {};
    final quickSelectTags = extra['quickSelectTags'] as List<String>?;

    return FormBuilderField<List<String>>(
      key: fieldKey,
      name: config.name,
      initialValue: initialTags.cast<String>(),
      enabled: config.enabled,
      builder: (fieldState) {
        final tags = fieldState.value ?? initialTags.cast<String>();

        return TagsField(
          tags: tags,
          addButtonText: config.hintText ?? '添加标签',
          primaryColor: (extra['primaryColor'] as Color?) ?? const Color(0xFF607AFB),
          quickSelectTags: quickSelectTags,
          onQuickSelectTag: (tag) {
            if (!tags.contains(tag)) {
              final newTags = [...tags, tag];
              fieldState.didChange(newTags);
              config.onChanged?.call(newTags);
            }
          },
          onAddTag: () async {
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(config.labelText ?? '添加标签'),
                content: TextField(
                  decoration: const InputDecoration(hintText: '标签名称'),
                  onSubmitted: (value) => Navigator.pop(context, value),
                ),
              ),
            );
            if (result != null && result.isNotEmpty) {
              final newTags = [...tags, result];
              fieldState.didChange(newTags);
              config.onChanged?.call(newTags);
            }
          },
          onRemoveTag: (tag) {
            final newTags = List<String>.from(tags)..remove(tag);
            fieldState.didChange(newTags);
            config.onChanged?.call(newTags);
          },
        );
      },
    );
  }

  // 构建图标标题字段
  Widget _buildIconTitleField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue,
      enabled: config.enabled,
      onChanged: config.onChanged,
      onSaved: (value) {
        // 获取当前状态的值并同步到 FormBuilder
        final state = (fieldKey as GlobalKey<WrappedFormFieldState>).currentState;
        if (state != null) {
          // 直接使用 getValue() 获取当前值
          final currentValue = state.getValue();
          state.setValue(currentValue);
        }
      },
      builder: (context, value, setValue) {
        // 从当前值中提取标题和图标
        String currentTitle = '';
        IconData? currentIcon;

        if (value is Map) {
          currentTitle = value['title']?.toString() ?? '';
          currentIcon = value['icon'] as IconData?;
        } else if (value is String) {
          currentTitle = value;
        }

        // 使用 StatefulWidget 来管理图标状态和 controller
        return _IconTitleFieldWrapper(
          initialTitle: currentTitle,
          initialIcon: currentIcon ?? config.prefixIcon ?? Icons.assignment,
          hintText: config.hintText ?? '输入标题',
          onValueChanged: setValue,
        );
      },
      getValue: () {
        // 直接从当前 state 获取值
        return (fieldKey as GlobalKey<WrappedFormFieldState>).currentState?.getValue();
      },
      onReset: () {
        // 重置为初始值
        (fieldKey as GlobalKey<WrappedFormFieldState>).currentState?.reset();
      },
    );
  }

  // 构建类别选择器
  Widget _buildCategorySelectorField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as String?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => CategorySelectorField(
        categories: config.categories ?? [],
        selectedCategory: value,
        categoryIcons: config.categoryIcons ?? {},
        onCategoryChanged: config.enabled ? setValue : (category) {},
      ),
    );
  }

  // 构建选项选择器
  Widget _buildOptionSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as String?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        // 需要包装在 FormFieldGroup 中以匹配原始样式
        return FormFieldGroup(
          padding: const EdgeInsets.all(16),
          children: [
            OptionSelectorField(
              options: config.options ?? [],
              selectedId: value,
              labelText: config.labelText,
              useHorizontalScroll: config.useHorizontalScroll,
              optionWidth: config.optionWidth ?? 80,
              optionHeight: config.optionHeight ?? 80,
              gridColumns: config.gridColumns ?? 4,
              primaryColor: config.primaryColor ?? const Color(0xFF607AFB),
              onSelectionChanged: config.enabled ? setValue : (id) {},
            ),
          ],
        );
      },
    );
  }

  // 构建自定义字段
  Widget _buildCustomFieldsField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: List<CustomField>.from(config.initialCustomFields ?? []),
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => CustomFieldsField(
        fields: (value as List<dynamic>?)?.cast<CustomField>() ?? [],
        labelText: config.labelText ?? '自定义字段',
        addButtonText: config.hintText ?? '添加字段',
        onFieldsChanged: (fields) => setValue(fields),
      ),
    );
  }

  // 构建列表添加字段
  Widget _buildListAddField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final initialItems = extra['initialItems'] as List<dynamic>? ?? [];

    return FormBuilderField<List<dynamic>>(
      key: fieldKey,
      name: config.name,
      initialValue: initialItems,
      enabled: config.enabled,
      builder: (fieldState) {
        final items = fieldState.value ?? initialItems;

        // 使用 Function 类型避免类型转换问题
        final getTitleRaw = extra['getTitle'];
        final getIsCompletedRaw = extra['getIsCompleted'];
        final onToggleRaw = extra['onToggle'];

        // 包装函数，处理不同类型的参数
        String wrappedGetTitle(dynamic item) {
          if (getTitleRaw == null) return item.toString();
          return getTitleRaw(item);
        }

        bool wrappedGetIsCompleted(dynamic item) {
          if (getIsCompletedRaw == null) return false;
          return getIsCompletedRaw(item);
        }

        void wrappedOnToggle(int index, dynamic item) {
          if (onToggleRaw != null) {
            onToggleRaw(index, item);
          }
        }

        late TextEditingController controller;

        try {
          controller = TextEditingController(text: '');
          controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        } catch (e) {
          controller = TextEditingController(text: '');
        }

        return ListAddField<dynamic>(
          items: items,
          controller: controller,
          addButtonText: config.hintText ?? '添加',
          onAdd: () {
            if (controller.text.isNotEmpty) {
              final newItems = [...items, controller.text];
              fieldState.didChange(newItems);
              config.onChanged?.call(newItems);
              controller.clear();
            }
          },
          onToggle: (index) {
            wrappedOnToggle(index, items[index]);
          },
          onRemove: (index) {
            final newItems = List<dynamic>.from(items)..removeAt(index);
            fieldState.didChange(newItems);
            config.onChanged?.call(newItems);
          },
          getTitle: wrappedGetTitle,
          getIsCompleted: wrappedGetIsCompleted,
        );
      },
    );
  }

  // ============ Picker 选择器类（新增）============

  // 构建图标选择器字段
  Widget _buildIconPickerField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final enableIconToImage = extra['enableIconToImage'] as bool? ?? false;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as IconData? ?? Icons.help,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => IconPickerField(
        currentIcon: value as IconData? ?? Icons.help,
        labelText: config.labelText,
        enabled: config.enabled,
        enableIconToImage: enableIconToImage,
        onIconChanged: setValue,
      ),
    );
  }

  // 构建头像选择器字段
  Widget _buildAvatarPickerField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final username = extra['username'] as String? ?? 'User';
    final size = extra['size'] as double? ?? 80.0;
    final saveDirectory = extra['saveDirectory'] as String? ?? 'avatars';

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as String?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => AvatarPickerField(
        username: username,
        currentAvatarPath: value as String?,
        size: size,
        saveDirectory: saveDirectory,
        enabled: config.enabled,
        onAvatarChanged: setValue,
      ),
    );
  }

  // 构建圆形图标选择器字段
  Widget _buildCircleIconPickerField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final initialBackgroundColor = extra['initialBackgroundColor'] as Color? ?? Colors.blue;
    final showLabel = extra['showLabel'] as bool? ?? false;
    final labelText = extra['labelText'] as String? ?? config.labelText;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue is Map
          ? config.initialValue as Map<String, dynamic>
          : {'icon': config.initialValue as IconData? ?? Icons.star, 'color': initialBackgroundColor},
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        final data = value is Map<String, dynamic>
            ? value
            : {'icon': Icons.star, 'color': initialBackgroundColor};

        return CircleIconPickerField(
          currentIcon: data['icon'] as IconData? ?? Icons.star,
          currentBackgroundColor: data['color'] as Color? ?? Colors.blue,
          enabled: config.enabled,
          showLabel: showLabel,
          labelText: labelText,
          onValueChanged: setValue,
        );
      },
    );
  }

  // 构建日历条日期选择器字段
  Widget _buildCalendarStripPickerField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final allowFutureDates = extra['allowFutureDates'] as bool? ?? false;
    final useShortWeekDay = extra['useShortWeekDay'] as bool? ?? false;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as DateTime? ?? DateTime.now(),
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => CalendarStripPickerField(
        selectedDate: value as DateTime? ?? DateTime.now(),
        enabled: config.enabled,
        allowFutureDates: allowFutureDates,
        useShortWeekDay: useShortWeekDay,
        onDateChanged: setValue,
      ),
    );
  }

  // 构建图片选择器字段
  Widget _buildImagePickerField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final enableCrop = extra['enableCrop'] as bool? ?? false;
    final cropAspectRatio = extra['cropAspectRatio'] as double?;
    final multiple = extra['multiple'] as bool? ?? false;
    final saveDirectory = extra['saveDirectory'] as String? ?? 'app_images';
    final enableCompression = extra['enableCompression'] as bool? ?? false;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => ImagePickerField(
        currentImage: value,
        labelText: config.labelText,
        hintText: config.hintText,
        enabled: config.enabled,
        saveDirectory: saveDirectory,
        enableCrop: enableCrop,
        cropAspectRatio: cropAspectRatio,
        multiple: multiple,
        enableCompression: enableCompression,
        onImageChanged: setValue,
      ),
    );
  }

  // 构建位置选择器字段
  Widget _buildLocationPickerField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as String?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => LocationPickerField(
        currentLocation: value as String?,
        labelText: config.labelText,
        hintText: config.hintText,
        enabled: config.enabled,
        isMobile: true,
        onLocationChanged: setValue,
      ),
    );
  }

  // 构建提示词编辑器字段
  Widget _buildPromptEditorField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final labelText = extra['labelText'] as String? ?? config.labelText;

    return FormBuilderField<List<Prompt>>(
      key: fieldKey,
      name: config.name,
      initialValue: (config.initialValue as List<dynamic>? ?? []).cast<Prompt>(),
      enabled: config.enabled,
      builder: (fieldState) => PromptEditorField(
        name: config.name,
        initialValue: fieldState.value ?? [],
        enabled: config.enabled,
        labelText: labelText,
        onChanged: (v) {
          fieldState.didChange(v);
          config.onChanged?.call(v);
        },
      ),
    );
  }

  // 构建图标头像行字段
  Widget _buildIconAvatarRowField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final avatarSaveDirectory = extra['avatarSaveDirectory'] as String? ?? 'openai/agent_avatars';

    final initialValue = config.initialValue as Map<String, dynamic>? ?? {
      'icon': Icons.smart_toy,
      'iconColor': Colors.blue,
      'avatarUrl': null,
    };

    return FormBuilderField<Map<String, dynamic>>(
      key: fieldKey,
      name: config.name,
      initialValue: initialValue,
      enabled: config.enabled,
      builder: (fieldState) {
        final value = fieldState.value ?? initialValue;
        return IconAvatarRowField(
          name: config.name,
          initialIcon: value['icon'] as IconData?,
          initialIconColor: value['iconColor'] as Color?,
          initialAvatarUrl: value['avatarUrl'] as String?,
          enabled: config.enabled,
          avatarSaveDirectory: avatarSaveDirectory,
          onChanged: (v) {
            fieldState.didChange(v);
            config.onChanged?.call(v);
          },
        );
      },
    );
  }

  // 构建收支类型选择器字段
  Widget _buildExpenseTypeSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final expenseColor = extra['expenseColor'] as Color? ?? const Color(0xFFE74C3C);
    final incomeColor = extra['incomeColor'] as Color? ?? const Color(0xFF2ECC71);

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as bool? ?? true,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => ExpenseTypeSelectorField(
        isExpense: value as bool? ?? true,
        onTypeChanged: config.enabled ? setValue : (isExpense) {},
        expenseColor: expenseColor,
        incomeColor: incomeColor,
      ),
    );
  }

  // 构建金额输入框字段
  Widget _buildAmountInputField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final currencySymbol = extra['currencySymbol'] as String? ?? '¥';
    final fontSize = extra['fontSize'] as double? ?? 40.0;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as double?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => AmountInputField(
        amount: value as double?,
        onAmountChanged: setValue,
        currencySymbol: currencySymbol,
        fontSize: fontSize,
        enabled: config.enabled,
        validator: config.required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return config.validationMessage ?? '请输入金额';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效的金额';
                }
                return null;
              }
            : null,
      ),
    );
  }

  // 构建提醒时间列表字段
  Widget _buildRemindersField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final primaryColor = extra['primaryColor'] as Color? ?? const Color(0xFF607AFB);

    return FormBuilderField<List<DateTime>>(
      key: fieldKey,
      name: config.name,
      initialValue: (config.initialValue as List<dynamic>? ?? []).cast<DateTime>(),
      enabled: config.enabled,
      builder: (fieldState) {
        final reminders = fieldState.value ?? <DateTime>[];

        return RemindersField(
          reminders: reminders,
          labelText: config.labelText,
          hintText: config.hintText ?? '无',
          primaryColor: primaryColor,
          onRemoveReminder: (index) {
            final newReminders = List<DateTime>.from(reminders)..removeAt(index);
            fieldState.didChange(newReminders);
            config.onChanged?.call(newReminders);
          },
          onReminderAdded: (newReminders) {
            fieldState.didChange(newReminders);
            config.onChanged?.call(newReminders);
          },
        );
      },
    );
  }

  // 构建日期范围选择器字段
  Widget _buildDateRangeField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};

    // 从 initialValue 中提取开始和结束日期
    DateTime? startDate;
    DateTime? endDate;

    if (config.initialValue is DateTimeRange) {
      final range = config.initialValue as DateTimeRange;
      startDate = range.start;
      endDate = range.end;
    } else if (config.initialValue is Map) {
      final data = config.initialValue as Map<String, dynamic>;
      startDate = data['startDate'] as DateTime?;
      endDate = data['endDate'] as DateTime?;
    }

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: {
        'startDate': startDate,
        'endDate': endDate,
      },
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        final currentStartDate = value?['startDate'] as DateTime?;
        final currentEndDate = value?['endDate'] as DateTime?;

        return DateRangeField(
          startDate: currentStartDate,
          endDate: currentEndDate,
          enabled: config.enabled,
          placeholder: config.hintText,
          rangeLabelText: extra['rangeLabelText'] as String?,
          firstDate: extra['firstDate'] as DateTime?,
          lastDate: extra['lastDate'] as DateTime?,
          onDateRangeChanged: (range) {
            if (range != null) {
              setValue({
                'startDate': range.start,
                'endDate': range.end,
              });
            } else {
              // 清除选择
              setValue({'startDate': null, 'endDate': null});
            }
          },
        );
      },
    );
  }

  // 构建子计时器列表字段
  Widget _buildTimerItemsField(FormFieldConfig config, GlobalKey fieldKey) {
    return FormBuilderField<List<dynamic>>(
      key: fieldKey,
      name: config.name,
      initialValue: (config.initialValue as List<dynamic>? ?? []).cast(),
      enabled: config.enabled,
      builder: (fieldState) {
        final items = (fieldState.value ?? []).cast<dynamic>();
        // 转换为 TimerItem 列表
        final timerItems = items.cast<TimerItem>();

        return TimerItemsField(
          timerItems: timerItems,
          enabled: config.enabled,
          onAdd: () {
            // 打开添加计时器对话框
            final context = fieldState.context;
            if (context != null) {
              _showAddTimerDialog(context, fieldState);
            }
          },
          onEdit: (index, item) {
            final newItems = List<dynamic>.from(items);
            newItems[index] = item;
            fieldState.didChange(newItems);
            config.onChanged?.call(newItems);
          },
          onRemove: (index) {
            final newItems = List<dynamic>.from(items)..removeAt(index);
            fieldState.didChange(newItems);
            config.onChanged?.call(newItems);
          },
        );
      },
    );
  }

  /// 显示添加计时器对话框
  void _showAddTimerDialog(BuildContext context, dynamic fieldState) {
    showDialog(
      context: context,
      builder: (context) => const AddTimerItemDialog(),
    ).then((newTimer) {
      if (newTimer != null) {
        final currentItems = fieldState.value ?? [];
        final newItems = List<dynamic>.from(currentItems)..add(newTimer);
        fieldState.didChange(newItems);
      }
    });
  }

  // 构建图标网格选择器字段
  Widget _buildTimerIconGridField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};
    final presetIcons = extra['presetIcons'] as List<IconData>?;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as IconData? ?? Icons.psychology,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        return TimerIconGridField(
          selectedIcon: value as IconData? ?? Icons.psychology,
          presetIcons: presetIcons ?? const [
            Icons.psychology,
            Icons.auto_stories,
            Icons.code,
            Icons.fitness_center,
            Icons.edit,
            Icons.more_horiz,
          ],
          enabled: config.enabled,
          primaryColor: config.primaryColor,
          onIconChanged: setValue,
        );
      },
    );
  }

  // ============ 联系人专用字段（新增）============

  // 构建性别选择器字段
  Widget _buildGenderSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => GenderSelectorField(
        selectedGender: value,
        onGenderChanged: setValue,
        enabled: config.enabled,
      ),
    );
  }

  // 构建自定义活动事件字段
  Widget _buildCustomEventsField(FormFieldConfig config, GlobalKey fieldKey) {
    final initialEvents = config.initialValue as List<dynamic>? ?? [];

    return FormBuilderField<List<CustomActivityEvent>>(
      key: fieldKey,
      name: config.name,
      initialValue: initialEvents.cast<CustomActivityEvent>(),
      enabled: config.enabled,
      builder: (fieldState) {
        final events = fieldState.value ?? initialEvents.cast<CustomActivityEvent>();

        return CustomEventsField(
          events: events,
          labelText: config.labelText,
          addButtonText: config.hintText ?? '添加事件',
          enabled: config.enabled,
          onEventsChanged: (newEvents) {
            fieldState.didChange(newEvents);
            config.onChanged?.call(newEvents);
          },
        );
      },
    );
  }

  // 构建头像名称区域字段
  Widget _buildAvatarNameSectionField(FormFieldConfig config, GlobalKey fieldKey) {
    final initialValue = config.initialValue as Map<String, dynamic>? ?? {};

    return FormBuilderField<Map<String, dynamic>>(
      key: fieldKey,
      name: config.name,
      initialValue: initialValue,
      enabled: config.enabled,
      builder: (fieldState) {
        final value = fieldState.value ?? initialValue;

        return AvatarNameSection(
          avatarUrl: value['avatarUrl'] as String?,
          firstName: value['firstName'] as String? ?? '',
          lastName: value['lastName'] as String? ?? '',
          enabled: config.enabled,
          onAvatarChanged: (url) {
            final newValue = Map<String, dynamic>.from(value);
            newValue['avatarUrl'] = url;
            fieldState.didChange(newValue);
            config.onChanged?.call(newValue);
          },
          onFirstNameChanged: (name) {
            final newValue = Map<String, dynamic>.from(value);
            newValue['firstName'] = name;
            fieldState.didChange(newValue);
            config.onChanged?.call(newValue);
          },
          onLastNameChanged: (name) {
            final newValue = Map<String, dynamic>.from(value);
            newValue['lastName'] = name;
            fieldState.didChange(newValue);
            config.onChanged?.call(newValue);
          },
        );
      },
    );
  }

  // ============ 订阅专用字段（新增）============

  // 构建订阅周期选择器字段
  Widget _buildSubscriptionCycleField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};

    return FormBuilderField<int>(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as int? ?? 30,
      enabled: config.enabled,
      builder: (fieldState) {
        final currentDays = fieldState.value ?? 30;

        return SubscriptionCycleField(
          currentDays: currentDays,
          enabled: config.enabled,
          monthlyLabel: extra['monthlyLabel'] as String? ?? '月度',
          quarterlyLabel: extra['quarterlyLabel'] as String? ?? '季度',
          yearlyLabel: extra['yearlyLabel'] as String? ?? '年度',
          onDaysChanged: (days) {
            fieldState.didChange(days);
            config.onChanged?.call(days);
          },
        );
      },
    );
  }

  // ============ 日记相册专用字段（新增）============

  // 构建 Chip 选择器字段
  Widget _buildChipSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
    final extra = config.extra ?? {};

    // 从 extra 中获取选项列表
    final optionsRaw = extra['options'] as List<dynamic>?;
    final options = optionsRaw?.map((e) {
      if (e is ChipOption) return e;
      if (e is Map<String, dynamic>) {
        return ChipOption(
          id: e['id'] as String,
          label: e['label'] as String,
          icon: e['icon'] as IconData?,
          color: e['color'] as Color?,
        );
      }
      return ChipOption(id: e.toString(), label: e.toString());
    }).toList() ?? <ChipOption>[];

    final hintText = extra['hintText'] as String? ?? config.hintText ?? '选择';
    final selectorTitle = extra['selectorTitle'] as String? ?? '选择';
    final selectedBackgroundColor = extra['selectedBackgroundColor'] as Color?;
    final selectedForegroundColor = extra['selectedForegroundColor'] as Color?;
    final icon = extra['icon'] as IconData?;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as String?,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => ChipSelectorField(
        options: options,
        selectedId: value as String?,
        hintText: hintText,
        selectorTitle: selectorTitle,
        enabled: config.enabled,
        selectedBackgroundColor: selectedBackgroundColor,
        selectedForegroundColor: selectedForegroundColor,
        icon: icon,
        onValueChanged: setValue,
      ),
    );
  }

  // 构建按钮区域
  Widget _buildButtons() {
    // 如果有自定义按钮构建器，使用它
    if (widget.buttonBuilder != null) {
      return widget.buttonBuilder!(context, submitForm, _resetForm);
    }

    // 如果有自定义提交按钮 widget，使用它
    if (widget.config.submitButtonWidget != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: InkWell(
          onTap: () async {
            // 同时调用 FormBuilder 的 saveAndValidate 和我们的 _submitFormInternal
            final fbState = widget.formKey?.currentState;
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

    // 默认按钮
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
                // 同时调用 FormBuilder 的 saveAndValidate 和我们的 _submitFormInternal
                final fbState = widget.formKey?.currentState;
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

/// 图标标题字段包装器 - StatefulWidget 来管理图标状态
class _IconTitleFieldWrapper extends StatefulWidget {
  final String initialTitle;
  final IconData initialIcon;
  final String hintText;
  final ValueChanged<Map<String, dynamic>> onValueChanged;

  const _IconTitleFieldWrapper({
    required this.initialTitle,
    required this.initialIcon,
    required this.hintText,
    required this.onValueChanged,
  });

  @override
  State<_IconTitleFieldWrapper> createState() => _IconTitleFieldWrapperState();
}

class _IconTitleFieldWrapperState extends State<_IconTitleFieldWrapper> {
  late TextEditingController _controller;
  late IconData _currentIcon;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
    _currentIcon = widget.initialIcon;
    // 初始化时设置值
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateValue();
    });
  }

  @override
  void didUpdateWidget(_IconTitleFieldWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果初始图标变化，更新图标
    if (oldWidget.initialIcon != widget.initialIcon) {
      _currentIcon = widget.initialIcon;
      _updateValue();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateValue() {
    widget.onValueChanged({
      'title': _controller.text,
      'icon': _currentIcon,
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTitleField(
      controller: _controller,
      icon: _currentIcon,
      hintText: widget.hintText,
      onChanged: (text) => _updateValue(),
      onIconTap: () async {
        final selectedIcon = await showIconPickerDialog(
          context,
          _currentIcon,
        );
        if (selectedIcon != null) {
          setState(() {
            _currentIcon = selectedIcon;
          });
          _updateValue();
        }
      },
    );
  }
}
