import 'package:flutter/material.dart';
import '../models/analysis_preset.dart';
import '../controllers/analysis_preset_controller.dart';
import '../l10n/openai_localizations.dart';

/// 基础信息对话框
///
/// 用于编辑分析预设的基础信息（标题、描述、标签）
class BasicInfoDialog extends StatefulWidget {
  final AnalysisPreset? preset; // null表示新建，否则为编辑

  const BasicInfoDialog({super.key, this.preset});

  @override
  State<BasicInfoDialog> createState() => _BasicInfoDialogState();
}

class _BasicInfoDialogState extends State<BasicInfoDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  List<String> _tags = [];
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.preset != null;

    // 初始化控制器
    _titleController = TextEditingController(text: widget.preset?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.preset?.description ?? '');
    _tagController = TextEditingController();

    // 初始化标签
    if (widget.preset != null) {
      _tags = List.from(widget.preset!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OpenAILocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              _isEditMode ? localizations.editPreset : localizations.addPreset,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // 预设标题输入
            TextField(
              controller: _titleController,
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
              controller: _descriptionController,
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
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  tooltip: localizations.addTag,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 标签列表
            if (_tags.isEmpty)
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
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
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
              ),

            const SizedBox(height: 24),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(localizations.save),
                ),
              ],
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

    if (_tags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该标签已存在'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _tags.add(tag);
    });

    _tagController.clear();
  }

  /// 移除标签
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  /// 保存
  Future<void> _save() async {
    final localizations = OpenAILocalizations.of(context);

    // 验证输入
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterTitle)),
      );
      return;
    }

    try {
      final controller = AnalysisPresetController();

      final preset = AnalysisPreset(
        id: widget.preset?.id, // 编辑模式使用原ID，新建模式为null
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags,
        agentId: widget.preset?.agentId, // 保留原有的智能体ID
        prompt: widget.preset?.prompt ?? '', // 保留原有的提示词
        updatedAt: DateTime.now(),
      );

      await controller.savePreset(preset);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.presetSaved)),
      );

      Navigator.pop(context, preset); // 返回保存的预设对象
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.saveFailed}: $e')),
      );
    }
  }
}
