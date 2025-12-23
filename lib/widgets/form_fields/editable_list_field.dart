import 'package:flutter/material.dart';

/// 可编辑的列表组件
///
/// 功能特性：
/// - 显示带序号的列表项
/// - 支持添加、编辑、删除
/// - 点击编辑按钮将内容填入输入框
/// - 统一的样式和主题适配
class EditableListField extends StatelessWidget {
  /// 列表项数据
  final List<String> items;

  /// 输入控制器
  final TextEditingController controller;

  /// 添加项的回调
  final VoidCallback onAdd;

  /// 删除项的回调
  final Function(int index) onRemove;

  /// 编辑项的回调（将内容填入输入框并删除原项）
  final Function(int index, String content) onEdit;

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
    required this.onEdit,
    required this.addButtonText,
    required this.inputLabel,
    required this.inputHint,
    this.titleText,
    this.maxLines = 2,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        if (titleText != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              titleText!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 添加输入框
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: inputLabel,
                    hintText: inputHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: maxLines,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 列表项
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(item),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onEdit(index, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => onRemove(index),
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
