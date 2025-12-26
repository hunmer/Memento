import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../form_field_wrapper.dart';
import '../config.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/plugins/timer/views/add_timer_item_dialog.dart';
import 'package:Memento/plugins/contact/models/custom_activity_event_model.dart';
import '../prompt_editor_field.dart';
import '../icon_avatar_row_field.dart';
import '../expense_type_selector_field.dart';
import '../amount_input_field.dart';
import '../reminders_field.dart';
import '../timer_items_field.dart';
import '../timer_icon_grid_field.dart';
import '../gender_selector_field.dart';
import '../custom_events_field.dart';
import '../avatar_name_section.dart';
import '../chip_selector_field.dart';
import '../subscription_cycle_field.dart';

/// 构建提示词编辑器字段
Widget buildPromptEditorField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建图标头像行字段
Widget buildIconAvatarRowField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建收支类型选择器字段
Widget buildExpenseTypeSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建金额输入框字段
Widget buildAmountInputField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建提醒时间列表字段
Widget buildRemindersField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建子计时器列表字段
Widget buildTimerItemsField(FormFieldConfig config, GlobalKey fieldKey, BuildContext context) {
  return FormBuilderField<List<dynamic>>(
    key: fieldKey,
    name: config.name,
    initialValue: (config.initialValue as List<dynamic>? ?? []).cast(),
    enabled: config.enabled,
    builder: (fieldState) {
      final items = (fieldState.value ?? []).cast<dynamic>();
      final timerItems = items.cast<TimerItem>();

      return TimerItemsField(
        timerItems: timerItems,
        enabled: config.enabled,
        onAdd: () {
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

/// 构建图标网格选择器字段
Widget buildTimerIconGridField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建性别选择器字段
Widget buildGenderSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建自定义活动事件字段
Widget buildCustomEventsField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建头像名称区域字段
Widget buildAvatarNameSectionField(FormFieldConfig config, GlobalKey fieldKey) {
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

/// 构建 Chip 选择器字段
Widget buildChipSelectorField(FormFieldConfig config, GlobalKey fieldKey) {
  final extra = config.extra ?? {};

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

/// 构建订阅周期选择器字段
Widget buildSubscriptionCycleField(FormFieldConfig config, GlobalKey fieldKey) {
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
