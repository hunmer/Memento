import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 常用的过滤条件构建器
class FilterBuilders {
  /// 构建关键词输入框过滤器
  static Widget buildKeywordFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
    String? placeholder,
  }) {
    final controller = TextEditingController(
      text: currentValue as String? ?? '',
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: placeholder ?? 'core_searchPlaceholder'.tr,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: onChanged,
          ),
        ),
        if (controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () {
              controller.clear();
              onChanged('');
            },
          ),
      ],
    );
  }

  /// 构建标签多选过滤器
  static Widget buildTagsFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
    required List<String> availableTags,
  }) {
    final selectedTags = (currentValue as List<String>?) ?? [];

    return Wrap(
      spacing: 8,
      children: availableTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            final newTags = List<String>.from(selectedTags);
            if (selected) {
              newTags.add(tag);
            } else {
              newTags.remove(tag);
            }
            onChanged(newTags);
          },
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  /// 构建标签单选过滤器
  static Widget buildTagFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
    required List<String> availableTags,
  }) {
    final selectedTag = currentValue as String?;

    return Wrap(
      spacing: 8,
      children: availableTags.map((tag) {
        final isSelected = selectedTag == tag;
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            onChanged(selected ? tag : null);
          },
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  /// 构建优先级选择过滤器
  static Widget buildPriorityFilter<T>({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
    required Map<T, String> priorityLabels,
    required Map<T, Color> priorityColors,
  }) {
    final selectedPriority = currentValue as T?;

    return Wrap(
      spacing: 8,
      children: priorityLabels.entries.map((entry) {
        final priority = entry.key;
        final label = entry.value;
        final color = priorityColors[priority] ?? Colors.grey;
        final isSelected = selectedPriority == priority;

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: color.withOpacity(0.3),
          onSelected: (selected) {
            onChanged(selected ? priority : null);
          },
          visualDensity: VisualDensity.compact,
          avatar: CircleAvatar(
            backgroundColor: color,
            radius: 6,
          ),
        );
      }).toList(),
    );
  }

  /// 构建日期范围选择过滤器
  static Widget buildDateRangeFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
  }) {
    final dateRange = currentValue as DateTimeRange?;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(
            dateRange == null
                ? 'core_selectDateRange'.tr
                : '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}',
            style: const TextStyle(fontSize: 13),
          ),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              initialDateRange: dateRange,
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
        ),
        if (dateRange != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  /// 构建单日期选择过滤器
  static Widget buildDateFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
  }) {
    final date = currentValue as DateTime?;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(
            date == null ? 'core_selectDate'.tr : _formatDate(date),
            style: const TextStyle(fontSize: 13),
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
        ),
        if (date != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  /// 构建复选框过滤器
  static Widget buildCheckboxFilter({
    required BuildContext context,
    required dynamic currentValue,
    required ValueChanged<dynamic> onChanged,
    required Map<String, String> options,
  }) {
    final selectedOptions = (currentValue as Map<String, bool>?) ?? {};

    return Wrap(
      spacing: 16,
      children: options.entries.map((entry) {
        final key = entry.key;
        final label = entry.value;
        final isChecked = selectedOptions[key] ?? false;

        return InkWell(
          onTap: () {
            final newOptions = Map<String, bool>.from(selectedOptions);
            newOptions[key] = !isChecked;
            onChanged(newOptions);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (value) {
                  final newOptions = Map<String, bool>.from(selectedOptions);
                  newOptions[key] = value ?? false;
                  onChanged(newOptions);
                },
                visualDensity: VisualDensity.compact,
              ),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 格式化日期
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 生成标签过滤的 badge 文本
  static String? tagsBadge(dynamic value) {
    if (value is List<String> && value.isNotEmpty) {
      return '${value.length}';
    }
    return null;
  }

  /// 生成单标签过滤的 badge 文本
  static String? tagBadge(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  /// 生成优先级过滤的 badge 文本
  static String? priorityBadge(dynamic value, Map<dynamic, String> labels) {
    if (value != null && labels.containsKey(value)) {
      return labels[value];
    }
    return null;
  }

  /// 生成日期范围过滤的 badge 文本
  static String? dateRangeBadge(dynamic value) {
    if (value is DateTimeRange) {
      return '${_formatDate(value.start)}~${_formatDate(value.end)}';
    }
    return null;
  }

  /// 生成单日期过滤的 badge 文本
  static String? dateBadge(dynamic value) {
    if (value is DateTime) {
      return _formatDate(value);
    }
    return null;
  }

  /// 生成复选框过滤的 badge 文本
  static String? checkboxBadge(dynamic value) {
    if (value is Map<String, bool>) {
      final count = value.values.where((v) => v).length;
      return count > 0 ? '$count' : null;
    }
    return null;
  }

  /// 生成关键词过滤的 badge 文本
  static String? keywordBadge(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value.length > 10 ? '${value.substring(0, 10)}...' : value;
    }
    return null;
  }
}
