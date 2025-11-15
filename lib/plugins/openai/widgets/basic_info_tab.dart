import 'package:flutter/material.dart';
import '../l10n/openai_localizations.dart';

/// 基础信息Tab组件
///
/// 用于在插件分析对话框中输入预设的基础信息（标题、描述、标签）
class BasicInfoTab extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final List<String> tags;
  final Function(List<String>) onTagsChanged;

  const BasicInfoTab({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<BasicInfoTab> {
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OpenAILocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: widget.titleController,
              decoration: InputDecoration(
                labelText: localizations.presetTitle,
                hintText: '例如: 日记情感分析',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 16),

            // 描述输入
            TextField(
              controller: widget.descriptionController,
              decoration: InputDecoration(
                labelText: localizations.presetDescription,
                hintText: '简要说明这个预设的用途',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              minLines: 3,
            ),

            const SizedBox(height: 16),

            // 标签部分
            Text(
              localizations.presetTags,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 标签输入框和添加按钮
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: localizations.enterTagName,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.label),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  label: Text(localizations.addTag),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 标签列表
            if (widget.tags.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    '暂无标签',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      backgroundColor: theme.primaryColor.withAlpha(30),
                      labelStyle: TextStyle(color: theme.primaryColor),
                      deleteIconColor: theme.primaryColor,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();

    if (tag.isEmpty) return;

    if (widget.tags.contains(tag)) {
      // 标签已存在，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该标签已存在'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 添加标签
    final newTags = List<String>.from(widget.tags)..add(tag);
    widget.onTagsChanged(newTags);

    // 清空输入框
    _tagController.clear();
  }

  /// 移除标签
  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.tags)..remove(tag);
    widget.onTagsChanged(newTags);
  }
}
