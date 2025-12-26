import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../config.dart';
import '../types.dart';

/// ========== 公共样式生成函数 ==========

/// 创建统一的圆角背景色 InputDecoration
/// 用于 TextField、TextArea 等输入组件
InputDecoration createRoundedInputDecoration({
  required BuildContext context,
  required String? labelText,
  required String? hintText,
  IconData? prefixIcon,
  EdgeInsets? contentPadding,
}) {
  final theme = Theme.of(context);

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: theme.colorScheme.onSurfaceVariant, size: 20)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerLow,
    isDense: true,
    contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

/// 创建统一的圆角背景色 BoxDecoration
/// 用于 Container、Row 等非 Input 组件
BoxDecoration createRoundedContainerDecoration(BuildContext context, {double radius = 12}) {
  final theme = Theme.of(context);

  return BoxDecoration(
    color: theme.colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: theme.colorScheme.outline.withOpacity(0.2),
    ),
  );
}

/// ========== 构建函数 ==========

/// 构建文本输入框 - 使用圆角背景色卡片样式
Widget buildTextField(FormFieldConfig config, GlobalKey fieldKey, BuildContext context) {
  return FormBuilderTextField(
    key: fieldKey,
    name: config.name,
    initialValue: config.initialValue?.toString() ?? '',
    enabled: config.enabled,
    obscureText: config.type == FormFieldType.password,
    keyboardType: config.type == FormFieldType.email
        ? TextInputType.emailAddress
        : config.type == FormFieldType.number
            ? TextInputType.number
            : TextInputType.text,
    onChanged: config.onChanged,
    decoration: createRoundedInputDecoration(
      context: context,
      labelText: config.labelText,
      hintText: config.hintText,
      prefixIcon: config.prefixIcon,
    ),
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 16,
    ),
  );
}

/// 构建多行文本输入框 - 使用圆角背景色卡片样式
Widget buildTextAreaField(FormFieldConfig config, GlobalKey fieldKey, BuildContext context) {
  final extra = config.extra ?? {};

  return FormBuilderTextField(
    key: fieldKey,
    name: config.name,
    initialValue: config.initialValue?.toString() ?? '',
    enabled: config.enabled,
    minLines: (extra['minLines'] as int?) ?? 3,
    maxLines: (extra['maxLines'] as int?) ?? 6,
    keyboardType: TextInputType.multiline,
    onChanged: config.onChanged,
    decoration: createRoundedInputDecoration(
      context: context,
      labelText: config.labelText,
      hintText: config.hintText,
      contentPadding: const EdgeInsets.all(12),
    ),
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 16,
    ),
  );
}

/// 构建下拉选择框 - 使用圆角背景色卡片样式
Widget buildSelectField(FormFieldConfig config, GlobalKey fieldKey, BuildContext context) {
  final theme = Theme.of(context);

  return FormBuilderField<dynamic>(
    key: fieldKey,
    name: config.name,
    initialValue: config.initialValue,
    enabled: config.enabled,
    builder: (fieldState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                config.labelText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: createRoundedContainerDecoration(context),
            child: Row(
              children: [
                if (config.prefixIcon != null) ...[
                  Icon(config.prefixIcon, color: theme.colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: DropdownButton<dynamic>(
                    value: fieldState.value,
                    hint: config.hintText != null
                        ? Text(
                            config.hintText!,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          )
                        : null,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: theme.colorScheme.surfaceContainerLow,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                    items: (config.items ?? []).map((item) {
                      return DropdownMenuItem<dynamic>(
                        value: item.value,
                        child: item.child,
                      );
                    }).toList(),
                    onChanged: config.enabled ? (value) {
                      fieldState.didChange(value);
                      config.onChanged?.call(value);
                    } : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
