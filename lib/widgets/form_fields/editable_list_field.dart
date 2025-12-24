import 'package:flutter/material.dart';

/// 可编辑的列表组件
///
/// 功能特性：
/// - 显示带序号的列表项
/// - 支持添加、编辑、删除
/// - 点击编辑按钮将内容填入输入框，完成编辑后替换原项
/// - 统一的样式和主题适配
class EditableListField extends StatefulWidget {
  /// 列表项数据
  final List<String> items;

  /// 输入控制器
  final TextEditingController controller;

  /// 添加项的回调
  final VoidCallback onAdd;

  /// 删除项的回调
  final Function(int index) onRemove;

  /// 编辑项的回调（将内容填入输入框）
  final Function(int index, String content)? onEdit;

  /// 更新项的回调（替换指定索引的内容）
  final Function(int index, String newContent) onUpdate;

  /// 添加按钮的文本
  final String addButtonText;

  /// 输入框标签
  final String inputLabel;

  /// 输入框提示
  final String inputHint;

  /// 标题文本
  final String? titleText;

  /// 输入框最大行数
  final int maxLines;

  /// 主题色
  final Color primaryColor;

  const EditableListField({
    super.key,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    this.onEdit,
    required this.addButtonText,
    required this.inputLabel,
    required this.inputHint,
    this.titleText,
    this.maxLines = 2,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  State<EditableListField> createState() => _EditableListFieldState();
}

class _EditableListFieldState extends State<EditableListField> {
  /// 当前正在编辑的项的索引（null 表示不在编辑状态）
  int? _editingIndex;

  /// 开始编辑
  void _startEditing(int index, String content) {
    setState(() {
      _editingIndex = index;
      widget.controller.text = content;
    });
    // 调用外部的 onEdit 回调（如果提供）
    widget.onEdit?.call(index, content);
  }

  /// 取消编辑
  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      widget.controller.clear();
    });
  }

  /// 处理添加或更新
  void _handleAddOrUpdate() {
    if (_editingIndex != null) {
      // 更新模式
      final newContent = widget.controller.text.trim();
      if (newContent.isNotEmpty) {
        widget.onUpdate(_editingIndex!, newContent);
        setState(() {
          _editingIndex = null;
          widget.controller.clear();
        });
      }
    } else {
      // 添加模式
      widget.onAdd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        if (widget.titleText != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.titleText!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 添加/编辑输入框
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    labelText: widget.inputLabel,
                    hintText: widget.inputHint,
                    border: const OutlineInputBorder(),
                    // 编辑模式下显示不同的样式
                    filled: _editingIndex != null,
                    fillColor: _editingIndex != null
                        ? widget.primaryColor.withOpacity(0.1)
                        : null,
                  ),
                  maxLines: widget.maxLines,
                ),
              ),
              // 如果在编辑模式，显示取消按钮
              if (_editingIndex != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                  tooltip: '取消编辑',
                ),
              // 添加/更新按钮
              IconButton(
                icon: Icon(_editingIndex != null ? Icons.check : Icons.add),
                onPressed: _handleAddOrUpdate,
                tooltip: _editingIndex != null ? '更新' : '添加',
                color: _editingIndex != null ? Colors.green : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 列表项
        if (widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isEditing = _editingIndex == index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isEditing ? 4 : 1,
                  color: isEditing
                      ? widget.primaryColor.withOpacity(0.1)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: widget.primaryColor,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontWeight: isEditing ? FontWeight.bold : null,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _startEditing(index, item),
                          tooltip: '编辑',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => widget.onRemove(index),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
