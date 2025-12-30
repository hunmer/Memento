import 'package:flutter/material.dart';
import 'package:Memento/widgets/form_fields/form_field_wrapper.dart';

/// 事件选项
class EventOption {
  final String eventName;
  final String category;
  final String description;

  const EventOption({
    required this.eventName,
    required this.category,
    required this.description,
  });
}

/// 事件多选字段
///
/// 功能特性：
/// - 显示事件多选对话框
/// - 显示已选事件数量
/// - 支持自定义可用事件列表
class EventMultiSelectField extends FormFieldWrapper {
  /// 可用事件列表
  final List<EventOption> availableEvents;

  /// 对话框标题
  final String? dialogTitle;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 值变化回调
  final ValueChanged<dynamic>? onChanged;

  const EventMultiSelectField({
    super.key,
    required super.name,
    required this.availableEvents,
    this.dialogTitle,
    super.initialValue,
    this.prefixIcon,
    this.onChanged,
    super.enabled = true,
  });

  @override
  State<EventMultiSelectField> createState() => _EventMultiSelectFieldState();
}

class _EventMultiSelectFieldState
    extends FormFieldWrapperState<EventMultiSelectField> {
  late List<String> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedEvents = List<String>.from(widget.initialValue ?? []);
  }

  String get _selectedEventsText {
    if (_selectedEvents.isEmpty) return '未选择';
    return '已选择 ${_selectedEvents.length} 个事件';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Colors.deepPurple)
            : const Icon(Icons.event, color: Colors.deepPurple),
        title: const Text('监听的事件'),
        subtitle: Text(_selectedEventsText),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.enabled ? _showEventSelector : null,
      ),
    );
  }

  Future<void> _showEventSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _EventSelectorDialog(
        availableEvents: widget.availableEvents,
        initialSelectedEvents: _selectedEvents,
        dialogTitle: widget.dialogTitle ?? '选择事件',
      ),
    );

    if (result != null) {
      setState(() {
        _selectedEvents = result;
      });
      widget.onChanged?.call(_selectedEvents);
    }
  }

  @override
  dynamic getValue() => _selectedEvents;
}

/// 事件选择器对话框
class _EventSelectorDialog extends StatefulWidget {
  final List<EventOption> availableEvents;
  final List<String> initialSelectedEvents;
  final String dialogTitle;

  const _EventSelectorDialog({
    required this.availableEvents,
    required this.initialSelectedEvents,
    required this.dialogTitle,
  });

  @override
  State<_EventSelectorDialog> createState() => _EventSelectorDialogState();
}

class _EventSelectorDialogState extends State<_EventSelectorDialog> {
  late Set<String> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedEvents = widget.initialSelectedEvents.toSet();
  }

  @override
  Widget build(BuildContext context) {
    // 按分类分组事件
    final groupedEvents = <String, List<EventOption>>{};
    for (final event in widget.availableEvents) {
      groupedEvents.putIfAbsent(event.category, () => []).add(event);
    }

    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView(
          children: groupedEvents.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...entry.value.map((event) {
                  final isSelected = _selectedEvents.contains(event.eventName);
                  return CheckboxListTile(
                    title: Text(event.eventName),
                    subtitle: Text(event.description),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedEvents.add(event.eventName);
                        } else {
                          _selectedEvents.remove(event.eventName);
                        }
                      });
                    },
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _selectedEvents.toList());
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
