import 'package:flutter/material.dart';
import 'types.dart';
import 'option_selector_field.dart';

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

  /// 值变化时通知（用于触发条件字段更新）
  final VoidCallback? onValueChanged;

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
    this.onValueChanged,
    this.extra,
    this.visible,
    this.prefixButtons,
    this.suffixButtons,
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
