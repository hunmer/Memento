import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 自定义字段组件
///
/// 功能特性：
/// - 支持添加、编辑、删除键值对字段
/// - 统一的表单字段样式
/// - 支持 inline 模式（label在左，字段列表在右）
class CustomFieldsField extends StatefulWidget {
  /// 自定义字段列表
  final List<CustomField> fields;

  /// 字段变更回调
  final Function(List<CustomField>) onFieldsChanged;

  /// 标签文本
  final String? labelText;

  /// 是否使用inline模式
  final bool inline;

  /// 添加按钮文本
  final String addButtonText;

  /// 添加字段对话框标题
  final String addDialogTitle;

  /// 编辑字段对话框标题
  final String editDialogTitle;

  /// 字段名标签
  final String fieldNameLabel;

  /// 字段名提示
  final String fieldNameHint;

  /// 字段值标签
  final String fieldValueLabel;

  /// 字段值提示
  final String fieldValueHint;

  /// 删除确认对话框标题
  final String deleteConfirmTitle;

  /// 删除确认内容
  final String deleteConfirmContent;

  /// inline模式下label的宽度
  final double labelWidth;

  const CustomFieldsField({
    super.key,
    required this.fields,
    required this.onFieldsChanged,
    this.labelText,
    this.inline = false,
    this.addButtonText = '添加字段',
    this.addDialogTitle = '添加自定义字段',
    this.editDialogTitle = '编辑自定义字段',
    this.fieldNameLabel = '字段名',
    this.fieldNameHint = '请输入字段名',
    this.fieldValueLabel = '字段值',
    this.fieldValueHint = '请输入字段值',
    this.deleteConfirmTitle = '确认删除',
    this.deleteConfirmContent = '确定要删除这个字段吗？',
    this.labelWidth = 100,
  });

  @override
  State<CustomFieldsField> createState() => _CustomFieldsFieldState();
}

class _CustomFieldsFieldState extends State<CustomFieldsField> {
  late List<CustomField> _fields;

  @override
  void initState() {
    super.initState();
    _fields = List<CustomField>.from(widget.fields);
  }

  @override
  void didUpdateWidget(CustomFieldsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fields != oldWidget.fields) {
      _fields = List<CustomField>.from(widget.fields);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // inline 模式
    if (widget.inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.labelText != null) ...[
            SizedBox(
              width: widget.labelWidth,
              child: Text(
                widget.labelText!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                if (_fields.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '暂无自定义字段',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ..._buildFieldsList(),
                _buildAddButton(theme),
              ],
            ),
          ),
        ],
      );
    }

    // 默认模式：独立卡片样式
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              if (_fields.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '暂无自定义字段',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._buildFieldsList(),
              _buildAddButton(theme),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFieldsList() {
    final List<Widget> widgets = [];

    for (int i = 0; i < _fields.length; i++) {
      widgets.add(
        ListTile(
          title: Text(
            _fields[i].key,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _fields[i].value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editField(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _deleteField(i),
              ),
            ],
          ),
          onTap: () => _editField(i),
        ),
      );

      // 在字段之间添加分隔线（除了最后一个）
      if (i < _fields.length - 1) {
        widgets.add(
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildAddButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addField,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.addButtonText,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addField() async {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.addDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: widget.fieldNameLabel,
                  hintText: widget.fieldNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: widget.fieldValueLabel,
                  hintText: widget.fieldValueHint,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('goods_cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  toastService.showToast(
                    'goods_fieldNameAndValueCannotBeEmpty'.tr,
                  );
                }
              },
              child: Text('goods_confirm'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _fields.add(
          CustomField(key: keyController.text, value: valueController.text),
        );
        widget.onFieldsChanged(_fields);
      });
    }
  }

  void _editField(int index) async {
    final field = _fields[index];
    final TextEditingController keyController = TextEditingController(
      text: field.key,
    );
    final TextEditingController valueController = TextEditingController(
      text: field.value,
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.editDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: widget.fieldNameLabel,
                  hintText: widget.fieldNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: widget.fieldValueLabel,
                  hintText: widget.fieldValueHint,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('goods_cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty &&
                    valueController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                } else {
                  toastService.showToast(
                    'goods_fieldNameAndValueCannotBeEmpty'.tr,
                  );
                }
              },
              child: Text('goods_confirm'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _fields[index] = CustomField(
          key: keyController.text,
          value: valueController.text,
        );
        widget.onFieldsChanged(_fields);
      });
    }
  }

  void _deleteField(int index) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.deleteConfirmTitle),
          content: Text(widget.deleteConfirmContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('goods_cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('goods_delete'.tr),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _fields.removeAt(index);
          widget.onFieldsChanged(_fields);
        });
      }
    });
  }
}
