/// 动作表单模型
/// 定义动态表单的字段配置和验证规则
library;

import 'package:flutter/material.dart';

/// 表单字段类型枚举
enum FormFieldType {
  text,           // 文本输入
  textarea,       // 多行文本
  select,         // 下拉单选
  multiSelect,    // 下拉多选
  checkbox,       // 复选框
  switchField,    // 开关
  slider,         // 滑块
  number,         // 数字输入
  date,           // 日期选择
  time,           // 时间选择
  dateTime,       // 日期时间选择
  pluginSelector, // 插件选择器（特殊类型）
  pluginActionSelector, // 插件动作选择器
  colorPicker,    // 颜色选择器
  iconSelector,   // 图标选择器
}

/// 表单字段配置
class FormFieldConfig {
  /// 字段类型
  final FormFieldType type;

  /// 字段标签
  final String label;

  /// 字段提示文字
  final String? hint;

  /// 默认值
  final dynamic defaultValue;

  /// 是否必填
  final bool required;

  /// 占位符
  final String? placeholder;

  /// 选择项（用于 select, multiSelect 等）
  final List<FormFieldOption>? options;

  /// 验证规则
  final List<FormFieldValidator>? validators;

  /// 额外参数
  final Map<String, dynamic>? extraParams;

  /// 字段依赖关系
  final List<String>? dependsOn;

  /// 显示顺序
  final int order;

  /// 是否隐藏
  final bool hidden;

  /// 只读
  final bool readOnly;

  /// 自定义组件
  final Widget? customWidget;

  const FormFieldConfig({
    required this.type,
    required this.label,
    this.hint,
    this.defaultValue,
    this.required = false,
    this.placeholder,
    this.options,
    this.validators,
    this.extraParams,
    this.dependsOn,
    this.order = 0,
    this.hidden = false,
    this.readOnly = false,
    this.customWidget,
  });

  /// 验证字段值
  List<String> validate(dynamic value) {
    final errors = <String>[];

    // 必填验证
    if (required && (value == null || value.toString().isEmpty)) {
      errors.add('$label是必填项');
    }

    // 自定义验证
    if (validators != null) {
      for (final validator in validators!) {
        final error = validator.validate(value);
        if (error != null) {
          errors.add(error);
        }
      }
    }

    return errors;
  }

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      'hint': hint,
      'defaultValue': _encodeValue(defaultValue),
      'required': required,
      'placeholder': placeholder,
      'options': options?.map((o) => o.toJson()).toList(),
      'validators': validators?.map((v) => v.toJson()).toList(),
      'extraParams': extraParams,
      'dependsOn': dependsOn,
      'order': order,
      'hidden': hidden,
      'readOnly': readOnly,
    };
  }

  /// 从JSON反序列化
  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      type: FormFieldType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FormFieldType.text,
      ),
      label: json['label'] as String,
      hint: json['hint'] as String?,
      defaultValue: _decodeValue(json['defaultValue']),
      required: json['required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      options: json['options'] != null
          ? (json['options'] as List)
              .map((o) => FormFieldOption.fromJson(o as Map<String, dynamic>))
              .toList()
          : null,
      validators: json['validators'] != null
          ? (json['validators'] as List)
              .map((v) => FormFieldValidator.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
      extraParams: json['extraParams'] as Map<String, dynamic>?,
      dependsOn: (json['dependsOn'] as List<dynamic>?)
          ?.map((d) => d as String)
          .toList(),
      order: json['order'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      readOnly: json['readOnly'] as bool? ?? false,
    );
  }

  /// 复制并修改属性
  FormFieldConfig copyWith({
    FormFieldType? type,
    String? label,
    String? hint,
    dynamic defaultValue,
    bool? required,
    String? placeholder,
    List<FormFieldOption>? options,
    List<FormFieldValidator>? validators,
    Map<String, dynamic>? extraParams,
    List<String>? dependsOn,
    int? order,
    bool? hidden,
    bool? readOnly,
    Widget? customWidget,
  }) {
    return FormFieldConfig(
      type: type ?? this.type,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      defaultValue: defaultValue ?? this.defaultValue,
      required: required ?? this.required,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? this.options,
      validators: validators ?? this.validators,
      extraParams: extraParams ?? this.extraParams,
      dependsOn: dependsOn ?? this.dependsOn,
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
      readOnly: readOnly ?? this.readOnly,
      customWidget: customWidget ?? this.customWidget,
    );
  }

  static dynamic _encodeValue(dynamic value) {
    if (value is IconData) {
      return {
        'codePoint': value.codePoint,
        'fontFamily': value.fontFamily,
      };
    }
    return value;
  }

  static dynamic _decodeValue(dynamic value) {
    if (value is Map && value.containsKey('codePoint')) {
      return IconData(
        value['codePoint'] as int,
        fontFamily: value['fontFamily'] as String?,
      );
    }
    return value;
  }
}

/// 表单字段选项
class FormFieldOption {
  final String value;
  final String label;
  final String? description;
  final IconData? icon;
  final bool disabled;

  const FormFieldOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.disabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'disabled': disabled,
    };
  }

  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      icon: json['iconCodePoint'] != null
          ? IconData(
              json['iconCodePoint'] as int,
              fontFamily: json['iconFontFamily'] as String?,
            )
          : null,
      disabled: json['disabled'] as bool? ?? false,
    );
  }
}

/// 表单字段验证器
class FormFieldValidator {
  final String type;
  final dynamic value;
  final String? message;

  const FormFieldValidator({
    required this.type,
    this.value,
    this.message,
  });

  String? validate(dynamic fieldValue) {
    switch (type) {
      case 'required':
        if (fieldValue == null || fieldValue.toString().isEmpty) {
          return message ?? '此字段是必填的';
        }
        return null;

      case 'minLength':
        if (fieldValue is String && fieldValue.length < (value as int)) {
          return message ?? '最少需要$value个字符';
        }
        return null;

      case 'maxLength':
        if (fieldValue is String && fieldValue.length > (value as int)) {
          return message ?? '最多允许$value个字符';
        }
        return null;

      case 'pattern':
        if (fieldValue is String) {
          final regex = RegExp(value as String);
          if (!regex.hasMatch(fieldValue)) {
            return message ?? '格式不正确';
          }
        }
        return null;

      case 'min':
        if (fieldValue is num && fieldValue < (value as num)) {
          return message ?? '不能小于$value';
        }
        return null;

      case 'max':
        if (fieldValue is num && fieldValue > (value as num)) {
          return message ?? '不能大于$value';
        }
        return null;

      case 'email':
        if (fieldValue is String) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(fieldValue)) {
            return message ?? '请输入有效的邮箱地址';
          }
        }
        return null;

      case 'url':
        if (fieldValue is String) {
          final urlRegex = RegExp(
            r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
          );
          if (!urlRegex.hasMatch(fieldValue)) {
            return message ?? '请输入有效的URL地址';
          }
        }
        return null;

      case 'custom':
        // 自定义验证逻辑
        return null;

      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'message': message,
    };
  }

  factory FormFieldValidator.fromJson(Map<String, dynamic> json) {
    return FormFieldValidator(
      type: json['type'] as String,
      value: json['value'],
      message: json['message'] as String?,
    );
  }
}

/// 动作表单
class ActionForm {
  /// 字段配置映射
  final Map<String, FormFieldConfig> fields;

  /// 表单布局类型
  final FormLayoutType layoutType;

  /// 字段间距
  final double fieldSpacing;

  /// 标签宽度占比
  final double labelWidthRatio;

  const ActionForm({
    required this.fields,
    this.layoutType = FormLayoutType.vertical,
    this.fieldSpacing = 16.0,
    this.labelWidthRatio = 0.3,
  });

  /// 验证表单数据
  List<String> validate(Map<String, dynamic> data) {
    final errors = <String>[];

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final fieldConfig = entry.value;
      final fieldValue = data[fieldName];

      // 跳过隐藏字段
      if (fieldConfig.hidden) continue;

      // 验证字段
      final fieldErrors = fieldConfig.validate(fieldValue);
      for (final error in fieldErrors) {
        errors.add('$fieldName: $error');
      }

      // 检查字段依赖
      if (fieldConfig.dependsOn != null) {
        for (final dependency in fieldConfig.dependsOn!) {
          if (data.containsKey(dependency)) {
            final depValue = data[dependency];
            if (depValue != null && depValue.toString().isNotEmpty) {
              // 依赖字段有值，可以继续验证
              final depFieldConfig = fields[dependency];
              if (depFieldConfig != null) {
                final depErrors = depFieldConfig.validate(depValue);
                errors.addAll(depErrors);
              }
            }
          }
        }
      }
    }

    return errors;
  }

  /// 获取排序后的字段列表
  List<MapEntry<String, FormFieldConfig>> getSortedFields() {
    final entries = fields.entries.toList();
    entries.sort((a, b) => a.value.order.compareTo(b.value.order));
    return entries;
  }

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'fields': fields.map((key, value) => MapEntry(key, value.toJson())),
      'layoutType': layoutType.name,
      'fieldSpacing': fieldSpacing,
      'labelWidthRatio': labelWidthRatio,
    };
  }

  /// 从JSON反序列化
  factory ActionForm.fromJson(Map<String, dynamic> json) {
    final fields = <String, FormFieldConfig>{};
    final fieldsJson = json['fields'] as Map<String, dynamic>?;
    if (fieldsJson != null) {
      fieldsJson.forEach((key, value) {
        fields[key] = FormFieldConfig.fromJson(value as Map<String, dynamic>);
      });
    }

    return ActionForm(
      fields: fields,
      layoutType: FormLayoutType.values.firstWhere(
        (e) => e.name == json['layoutType'],
        orElse: () => FormLayoutType.vertical,
      ),
      fieldSpacing: json['fieldSpacing'] as double? ?? 16.0,
      labelWidthRatio: json['labelWidthRatio'] as double? ?? 0.3,
    );
  }

  /// 复制并修改属性
  ActionForm copyWith({
    Map<String, FormFieldConfig>? fields,
    FormLayoutType? layoutType,
    double? fieldSpacing,
    double? labelWidthRatio,
  }) {
    return ActionForm(
      fields: fields ?? this.fields,
      layoutType: layoutType ?? this.layoutType,
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      labelWidthRatio: labelWidthRatio ?? this.labelWidthRatio,
    );
  }

  /// 添加字段
  ActionForm addField(String name, FormFieldConfig config) {
    return copyWith(fields: {...fields, name: config});
  }

  /// 移除字段
  ActionForm removeField(String name) {
    final newFields = Map<String, FormFieldConfig>.from(fields);
    newFields.remove(name);
    return copyWith(fields: newFields);
  }

  /// 更新字段
  ActionForm updateField(String name, FormFieldConfig config) {
    return copyWith(fields: {...fields, name: config});
  }

  /// 获取字段配置
  FormFieldConfig? getFieldConfig(String name) => fields[name];

  /// 检查字段是否存在
  bool hasField(String name) => fields.containsKey(name);

  /// 字段数量
  int get fieldCount => fields.length;

  /// 显示字段数量（排除隐藏字段）
  int get visibleFieldCount =>
      fields.values.where((f) => !f.hidden).length;
}

/// 表单布局类型
enum FormLayoutType {
  vertical,   // 垂直布局
  horizontal, // 水平布局
  grid,       // 网格布局
}
