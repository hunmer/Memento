import 'package:get/get.dart' hide Node;
import 'package:flutter/material.dart';
import 'package:Memento/plugins/nodes/models/node.dart';
import 'package:Memento/plugins/nodes/screens/node_edit_screen/dialogs/add_custom_field_dialog.dart';

class CustomFieldsSection extends StatefulWidget {
  final List<CustomField> initialFields;
  final Function(List<CustomField>) onFieldsChanged;

  const CustomFieldsSection({
    super.key,
    required this.initialFields,
    required this.onFieldsChanged,
  });

  @override
  State<CustomFieldsSection> createState() => _CustomFieldsSectionState();
}

class _CustomFieldsSectionState extends State<CustomFieldsSection> {
  // 内部管理的自定义字段列表
  late List<CustomField> _customFields;
  // 使用 Map 存储每个字段的控制器和编辑状态
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _isEditing = {};

  @override
  void initState() {
    super.initState();
    _customFields = List.from(widget.initialFields);
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < _customFields.length; i++) {
      _controllers[i] = TextEditingController(text: _customFields[i].value);
      _isEditing[i] = false;
    }
  }

  @override
  void dispose() {
    // 释放所有控制器
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomFieldsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果外部传入的初始值发生变化，更新内部状态
    if (oldWidget.initialFields != widget.initialFields) {
      setState(() {
        _customFields = List.from(widget.initialFields);
        _controllers.clear();
        _isEditing.clear();
        _initializeControllers();
      });
      widget.onFieldsChanged(_customFields);
    }
  }

  void _toggleEdit(int index) async {
    final currentEditing = _isEditing[index] ?? false;

    setState(() {
      _isEditing[index] = !currentEditing;
      if (currentEditing) {
        // 退出编辑模式时，更新值
        final value = _controllers[index]?.text ?? '';
        _customFields[index] = CustomField(
          key: _customFields[index].key,
          value: value,
        );
      }
    });

    // 通知外部数据已变更
    widget.onFieldsChanged(_customFields);

    // 如果进入编辑模式，延迟聚焦
    if (!currentEditing) {
      await Future.microtask(() {});
      if (mounted) {
        _controllers[index]?.selection = TextSelection.fromPosition(
          TextPosition(offset: _controllers[index]?.text.length ?? 0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'nodes_customFields'.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (_customFields.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '暂无自定义字段',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 14,
              ),
            ),
          )
        else
          ..._customFields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;
            final controller = _controllers[index];
            final isEditing = _isEditing[index] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 字段名和操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.key,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          size: 20,
                        ),
                        onPressed: () => _toggleEdit(index),
                        tooltip: isEditing ? '保存' : '编辑',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _removeField(index),
                        tooltip: '删除',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 字段值
                  if (isEditing)
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      maxLines: null,
                    )
                  else
                    InkWell(
                      onTap: () => _toggleEdit(index),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          field.value.isEmpty ? '点击编辑' : field.value,
                          style: TextStyle(
                            color: field.value.isEmpty
                                ? Theme.of(context).disabledColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text('nodes_addCustomField'.tr),
            onPressed: () => _showAddCustomFieldDialog(context),
          ),
        ),
      ],
    );
  }

  void _showAddCustomFieldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddCustomFieldDialog(
        onCustomFieldAdded: (field) {
          setState(() {
            _customFields.add(field);
            final newIndex = _customFields.length - 1;
            _controllers[newIndex] = TextEditingController(text: field.value);
            _isEditing[newIndex] = false;
          });
          widget.onFieldsChanged(_customFields);
        },
      ),
    );
  }

  void _removeField(int index) {
    setState(() {
      // 释放控制器
      _controllers[index]?.dispose();
      _controllers.remove(index);
      _isEditing.remove(index);

      // 删除字段
      _customFields.removeAt(index);

      // 重新整理控制器索引
      _rebuildControllers();
    });
    widget.onFieldsChanged(_customFields);
  }

  void _rebuildControllers() {
    // 清空并重新创建控制器
    _controllers.clear();
    _isEditing.clear();
    _initializeControllers();
  }
}
