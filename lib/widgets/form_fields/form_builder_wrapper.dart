import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'form_field_wrapper.dart';
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
  time,

  // 开关滑块类
  switchField,
  slider,

  // 其他
  color,
  tags,
  iconTitle,
  categorySelector,
  customFields,
  listAdd,

  // Picker 选择器类（新增）
  iconPicker,          // 图标选择器
  avatarPicker,        // 头像选择器
  circleIconPicker,    // 圆形图标选择器
  calendarStripPicker, // 日历条日期选择器
  imagePicker,         // 图片选择器
  locationPicker,      // 位置选择器
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

  /// 标签（用于 tags）
  final List<String>? initialTags;

  /// 自定义字段（用于 customFields）
  final List<dynamic>? initialCustomFields;

  /// 值变化回调
  final ValueChanged? onChanged;

  /// 自定义属性（用于扩展）
  final Map<String, dynamic>? extra;

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
    this.initialTags,
    this.initialCustomFields,
    this.onChanged,
    this.extra,
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

  /// 表单 key（可外部提供以便访问表单状态）
  final GlobalKey<FormBuilderState>? formKey;

  /// 自定义按钮构建器
  final Widget Function(BuildContext context, VoidCallback onSubmit, VoidCallback onReset)? buttonBuilder;

  /// 表单内容构建器（可用于包裹额外内容）
  final Widget Function(BuildContext context, List<Widget> fields)? contentBuilder;

  const FormBuilderWrapper({
    super.key,
    required this.config,
    this.formKey,
    this.buttonBuilder,
    this.contentBuilder,
  });

  @override
  State<FormBuilderWrapper> createState() => _FormBuilderWrapperState();
}

class _FormBuilderWrapperState extends State<FormBuilderWrapper> {
  // 存储每个字段的 state key，用于访问其 getValue 和 reset 方法
  final Map<String, GlobalKey<WrappedFormFieldState>> _fieldKeys = {};

  @override
  void initState() {
    super.initState();
    // 为每个字段创建 key
    for (final field in widget.config.fields) {
      _fieldKeys[field.name] = GlobalKey<WrappedFormFieldState>();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 提交表单
  void _submitForm() {
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
    final fields = widget.config.fields.map((config) => _buildField(config)).toList();

    return Column(
      crossAxisAlignment: widget.config.crossAxisAlignment,
      children: [
        if (widget.contentBuilder != null)
          widget.contentBuilder!(context, fields)
        else
          ...fields.expand((field) => [
            field,
            SizedBox(height: widget.config.fieldSpacing),
          ]).toList()
            ..removeLast(), // 移除最后一个间距
        if (widget.config.showSubmitButton || widget.config.showResetButton)
          _buildButtons(),
      ],
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
    }
  }

  // 构建文本输入框
  Widget _buildTextField(FormFieldConfig config, GlobalKey fieldKey) {
    late TextEditingController controller;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue?.toString() ?? '',
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        // 初始化或重用控制器
        try {
          controller = TextEditingController(text: value.toString());
          controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        } catch (e) {
          controller = TextEditingController(text: value.toString());
        }

        return TextInputField(
          controller: controller,
          labelText: config.labelText ?? '',
          hintText: config.hintText ?? '',
          prefixIcon: config.prefixIcon != null ? Icon(config.prefixIcon) : null,
          obscureText: config.type == FormFieldType.password,
          keyboardType: config.type == FormFieldType.email
              ? TextInputType.emailAddress
              : config.type == FormFieldType.number
                  ? TextInputType.number
                  : TextInputType.text,
          enabled: config.enabled,
        );
      },
      getValue: () => controller.text,
      onReset: () {
        controller.text = config.initialValue?.toString() ?? '';
      },
    );
  }

  // 构建多行文本输入框
  Widget _buildTextAreaField(FormFieldConfig config, GlobalKey fieldKey) {
    late TextEditingController controller;
    final extra = config.extra ?? {};

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue?.toString() ?? '',
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        try {
          controller = TextEditingController(text: value.toString());
          controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        } catch (e) {
          controller = TextEditingController(text: value.toString());
        }

        return TextAreaField(
          controller: controller,
          labelText: config.labelText ?? '',
          hintText: config.hintText ?? '',
          minLines: (extra['minLines'] as int?) ?? 3,
          maxLines: (extra['maxLines'] as int?) ?? 6,
          inline: (extra['inline'] as bool?) ?? false,
          enabled: config.enabled,
        );
      },
      getValue: () => controller.text,
      onReset: () {
        controller.text = config.initialValue?.toString() ?? '';
      },
    );
  }

  // 构建下拉选择框
  Widget _buildSelectField(FormFieldConfig config, GlobalKey fieldKey) {
    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => SelectField<dynamic>(
        value: value,
        labelText: config.labelText ?? '',
        hintText: config.hintText ?? '请选择',
        items: config.items ?? [],
        onChanged: setValue,
      ),
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

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue as bool? ?? false,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) => SwitchField(
        value: value ?? false,
        title: config.labelText ?? '',
        subtitle: config.hintText,
        icon: config.prefixIcon,
        inline: (extra['inline'] as bool?) ?? false,
        onChanged: config.enabled ? setValue : null,
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

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: initialTags,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        final tags = (value as List<dynamic>?)?.cast<String>() ?? initialTags;

        return TagsField(
          tags: tags,
          addButtonText: config.hintText ?? '添加标签',
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
              setValue([...tags, result]);
            }
          },
          onRemoveTag: (tag) {
            setValue(List<String>.from(tags)..remove(tag));
          },
        );
      },
    );
  }

  // 构建图标标题字段
  Widget _buildIconTitleField(FormFieldConfig config, GlobalKey fieldKey) {
    final initialIcon = config.prefixIcon;

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: config.initialValue?.toString() ?? '',
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        late TextEditingController controller;
        try {
          controller = TextEditingController(text: value.toString());
          controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
        } catch (e) {
          controller = TextEditingController(text: value.toString());
        }

        // 需要单独存储图标状态
        IconData currentIcon = initialIcon ?? Icons.folder;

        return IconTitleField(
          controller: controller,
          icon: currentIcon,
          hintText: config.hintText ?? '输入标题',
          onIconTap: () {
            // 简单演示，实际可以弹图标选择器
            currentIcon = currentIcon == Icons.folder ? Icons.folder_open : Icons.folder;
            setState(() {});
            config.onChanged?.call(currentIcon);
          },
        );
      },
      getValue: () {
        // 返回文本值
        return null;
      },
      onReset: () {
        // 重置逻辑
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

    return WrappedFormField(
      key: fieldKey,
      name: config.name,
      initialValue: initialItems,
      enabled: config.enabled,
      onChanged: config.onChanged,
      builder: (context, value, setValue) {
        final items = (value as List<dynamic>?) ?? initialItems;

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
              setValue([...items, controller.text]);
              controller.clear();
            }
          },
          onToggle: (index) {
            wrappedOnToggle(index, items[index]);
          },
          onRemove: (index) {
            setValue(List<dynamic>.from(items)..removeAt(index));
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

  // 构建按钮区域
  Widget _buildButtons() {
    if (widget.buttonBuilder != null) {
      return widget.buttonBuilder!(context, _submitForm, _resetForm);
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
              onPressed: _submitForm,
              child: Text(widget.config.submitButtonText),
            ),
        ],
      ),
    );
  }
}
