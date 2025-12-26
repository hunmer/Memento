import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../form_field_wrapper.dart';
import '../config.dart';
import '../switch_field.dart';
import '../slider_field.dart';
import '../color_selector_field.dart';

/// 构建开关
Widget buildSwitchField(FormFieldConfig config, GlobalKey fieldKey) {
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
      onChanged: config.enabled
          ? (v) {
              fieldState.didChange(v);
              config.onChanged?.call(v);
            }
          : null,
    ),
  );
}

/// 构建滑块
Widget buildSliderField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建颜色选择器
Widget buildColorField(FormFieldConfig config, GlobalKey fieldKey) {
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
