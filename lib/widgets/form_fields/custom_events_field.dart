import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/contact/models/custom_activity_event_model.dart';

/// 自定义活动事件字段
///
/// 功能特性：
/// - 支持添加、删除自定义活动事件
/// - 每个事件包含颜色和标题
/// - 支持颜色选择器
/// - 统一的 Material Design 3 样式
class CustomEventsField extends StatefulWidget {
  /// 活动事件列表
  final List<CustomActivityEvent> events;

  /// 事件变更回调
  final Function(List<CustomActivityEvent>) onEventsChanged;

  /// 标签文本
  final String? labelText;

  /// 添加按钮文本
  final String addButtonText;

  /// 是否启用
  final bool enabled;

  const CustomEventsField({
    super.key,
    required this.events,
    required this.onEventsChanged,
    this.labelText,
    this.addButtonText = '添加事件',
    this.enabled = true,
  });

  @override
  State<CustomEventsField> createState() => _CustomEventsFieldState();
}

class _CustomEventsFieldState extends State<CustomEventsField> {
  late List<CustomActivityEvent> _events;
  late Map<int, TextEditingController> _titleControllers;

  @override
  void initState() {
    super.initState();
    _events = List<CustomActivityEvent>.from(widget.events);
    _titleControllers = {};
    for (int i = 0; i < _events.length; i++) {
      _titleControllers[i] = TextEditingController(text: _events[i].title);
    }
  }

  @override
  void didUpdateWidget(CustomEventsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events) {
      _events = List<CustomActivityEvent>.from(widget.events);
      _titleControllers.clear();
      for (int i = 0; i < _events.length; i++) {
        _titleControllers[i] = TextEditingController(text: _events[i].title);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        ..._events.asMap().entries.map((entry) {
          int idx = entry.key;
          var event = entry.value;
          return _buildEventItem(context, idx, event, theme);
        }),
        const SizedBox(height: 8),
        _buildAddButton(theme),
      ],
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    int index,
    CustomActivityEvent event,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _buildColorPickerButton(index, event.color),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _titleControllers[index],
              decoration: InputDecoration(
                hintText: 'Event Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              enabled: widget.enabled,
              onChanged: (value) {
                setState(() {
                  _events[index] = CustomActivityEvent(
                    id: event.id,
                    color: event.color,
                    title: value,
                  );
                });
                widget.onEventsChanged(_events);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle, color: theme.colorScheme.error),
            onPressed: widget.enabled
                ? () {
                    setState(() {
                      _titleControllers[index]?.dispose();
                      _titleControllers.remove(index);
                      _events.removeAt(index);
                      // 重新索引控制器
                      final newControllers = <int, TextEditingController>{};
                      for (int i = 0; i < _events.length; i++) {
                        final oldController = _titleControllers[i > index ? i + 1 : i];
                        if (oldController != null) {
                          newControllers[i] = oldController;
                        } else {
                          // 如果控制器不存在，创建新的
                          newControllers[i] = TextEditingController(
                            text: _events[i].title,
                          );
                        }
                      }
                      _titleControllers = newControllers;
                    });
                    widget.onEventsChanged(_events);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerButton(int index, Color color) {
    return GestureDetector(
      onTap: widget.enabled
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                    'contact_pickColor'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: color,
                      onColorChanged: (newColor) {
                        setState(() {
                          _events[index] = CustomActivityEvent(
                            id: _events[index].id,
                            color: newColor,
                            title: _events[index].title,
                          );
                        });
                        widget.onEventsChanged(_events);
                      },
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'contact_done'.tr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return TextButton.icon(
      icon: Icon(Icons.add_circle, color: theme.colorScheme.primary),
      label: Text(widget.addButtonText),
      onPressed: widget.enabled
          ? () {
              setState(() {
                final newIndex = _events.length;
                _events.add(
                  CustomActivityEvent(
                    color: theme.colorScheme.primary,
                    title: '',
                  ),
                );
                _titleControllers[newIndex] = TextEditingController();
              });
              widget.onEventsChanged(_events);
            }
          : null,
    );
  }
}
