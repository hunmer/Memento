import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../config.dart';
import '../types.dart';

/// 构建文本输入框
Widget buildTextField(FormFieldConfig config, GlobalKey fieldKey, BuildContext context) {
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
                if (config.prefixButtons != null)
                  ...config.prefixButtons!.map((btn) => IconButton(
                        icon: Icon(btn.icon),
                        tooltip: btn.tooltip,
                        onPressed: btn.onPressed,
                      )),
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
                    autofocus: false,
                    onChanged: (v) {
                      fieldState.didChange(v);
                      config.onChanged?.call(v);
                    },
                  ),
                ),
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
    autofocus: false,
    onChanged: config.onChanged,
  );
}

/// 构建多行文本输入框
Widget buildTextAreaField(FormFieldConfig config, GlobalKey fieldKey) {
  final extra = config.extra ?? {};

  return FormBuilderTextField(
    key: fieldKey,
    name: config.name,
    initialValue: config.initialValue?.toString() ?? '',
    decoration: InputDecoration(
      labelText: config.labelText,
      hintText: config.hintText,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
    minLines: (extra['minLines'] as int?) ?? 3,
    maxLines: (extra['maxLines'] as int?) ?? 6,
    keyboardType: TextInputType.multiline,
    enabled: config.enabled,
    autofocus: false,
    onChanged: config.onChanged,
  );
}

/// 构建下拉选择框
Widget buildSelectField(FormFieldConfig config, GlobalKey fieldKey) {
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
