import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../form_field_wrapper.dart';
import '../config.dart';
import '../../picker/icon_picker_dialog.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import '../tags_field.dart';
import '../icon_title_field.dart';
import '../category_selector_field.dart';
import '../option_selector_field.dart';
import '../form_field_group.dart';
import '../custom_fields_field.dart';
import '../list_add_field.dart';

/// 构建标签字段
Widget buildTagsField(FormFieldConfig config, GlobalKey fieldKey, BuildContext context) {
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

/// 构建图标标题字段
Widget buildIconTitleField(FormFieldConfig config, GlobalKey fieldKey) {
  return WrappedFormField(
    key: fieldKey,
    name: config.name,
    initialValue: config.initialValue,
    enabled: config.enabled,
    onChanged: config.onChanged,
    onSaved: (value) {
      final state = (fieldKey as GlobalKey<WrappedFormFieldState>).currentState;
      if (state != null) {
        final currentValue = state.getValue();
        state.setValue(currentValue);
      }
    },
    builder: (context, value, setValue) {
      String currentTitle = '';
      IconData? currentIcon;

      if (value is Map) {
        currentTitle = value['title']?.toString() ?? '';
        currentIcon = value['icon'] as IconData?;
      } else if (value is String) {
        currentTitle = value;
      }

      return _IconTitleFieldWrapper(
        initialTitle: currentTitle,
        initialIcon: currentIcon ?? config.prefixIcon ?? Icons.assignment,
        hintText: config.hintText ?? '输入标题',
        onValueChanged: setValue,
      );
    },
    getValue: () {
      return (fieldKey as GlobalKey<WrappedFormFieldState>).currentState?.getValue();
    },
    onReset: () {
      (fieldKey as GlobalKey<WrappedFormFieldState>).currentState?.reset();
    },
  );
}

/// 图标标题字段包装器
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateValue();
    });
  }

  @override
  void didUpdateWidget(_IconTitleFieldWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
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

/// 构建类别选择器
Widget buildCategorySelectorField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建选项选择器
Widget buildOptionSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
  return WrappedFormField(
    key: fieldKey,
    name: config.name,
    initialValue: config.initialValue as String?,
    enabled: config.enabled,
    onChanged: config.onChanged,
    builder: (context, value, setValue) {
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

/// 构建自定义字段
Widget buildCustomFieldsField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建列表添加字段
Widget buildListAddField(FormFieldConfig config, GlobalKey fieldKey) {
  final extra = config.extra ?? {};
  final initialItems = extra['initialItems'] as List<dynamic>? ?? [];

  return FormBuilderField<List<dynamic>>(
    key: fieldKey,
    name: config.name,
    initialValue: initialItems,
    enabled: config.enabled,
    builder: (fieldState) {
      final items = fieldState.value ?? initialItems;

      final getTitleRaw = extra['getTitle'];
      final getIsCompletedRaw = extra['getIsCompleted'];
      final onToggleRaw = extra['onToggle'];

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
