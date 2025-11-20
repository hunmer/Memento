import 'package:flutter/material.dart';
import '../../services/tool_template_service.dart';
import '../../models/saved_tool_template.dart';
import '../chat_screen/components/save_tool_dialog.dart';
import 'components/template_execution_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 工具模板管理界面
class ToolTemplateScreen extends StatefulWidget {
  final ToolTemplateService templateService;
  final Function(SavedToolTemplate)? onUseTemplate;

  const ToolTemplateScreen({
    super.key,
    required this.templateService,
    this.onUseTemplate,
  });

  @override
  State<ToolTemplateScreen> createState() => _ToolTemplateScreenState();
}

class _ToolTemplateScreenState extends State<ToolTemplateScreen> {
  String _searchQuery = '';
  Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    widget.templateService.addListener(_onTemplatesChanged);
  }

  @override
  void dispose() {
    widget.templateService.removeListener(_onTemplatesChanged);
    super.dispose();
  }

  void _onTemplatesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 应用搜索和标签过滤
    var templates = widget.templateService.templates;

    if (_searchQuery.isNotEmpty) {
      templates = widget.templateService.searchTemplates(_searchQuery);
    }

    // 多标签过滤:只要模板包含任一选中标签就显示
    if (_selectedTags.isNotEmpty) {
      templates =
          templates
              .where((t) => t.tags.any((tag) => _selectedTags.contains(tag)))
              .toList();
    }

    final allTags = widget.templateService.getAllTags();

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具模板'),
        actions: [
          // 标签过滤按钮
          if (allTags.isNotEmpty)
            IconButton(
              icon: Badge(
                isLabelVisible: _selectedTags.isNotEmpty,
                label: Text(_selectedTags.length.toString()),
                child: Icon(
                  Icons.filter_list,
                  color: _selectedTags.isNotEmpty ? Colors.blue : null,
                ),
              ),
              tooltip: '按标签过滤',
              onPressed: () => _showTagFilterDialog(allTags),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_selectedTags.isNotEmpty ? 100 : 60),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索工具模板...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              // 当前选中的标签
              if (_selectedTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: Row(
                    children: [
                      const Text(
                        '当前过滤：',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              _selectedTags.map((tag) {
                                return Chip(
                                  avatar: const Icon(Icons.label, size: 16),
                                  label: Text(tag),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedTags.remove(tag);
                                    });
                                  },
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                        ),
                      ),
                      if (_selectedTags.length > 1)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedTags.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text(
                            '清空',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: templates.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _buildTemplateCard(template);
              },
            ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无保存的工具模板' : '未找到匹配的模板',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '在AI工具调用消息中点击"保存工具"即可保存',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建模板卡片
  Widget _buildTemplateCard(SavedToolTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 执行按钮
                  IconButton(
                    onPressed: () => _executeTemplate(template),
                    icon: const Icon(Icons.play_circle_outline),
                    tooltip: '执行测试',
                    color: Colors.green,
                  ),
                  // 使用按钮
                  if (widget.onUseTemplate != null)
                    FilledButton.icon(
                      onPressed: () {
                        widget.onUseTemplate!(template);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('使用'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // 更多菜单
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editTemplate(template);
                          break;
                        case 'delete':
                          _deleteTemplate(template);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('编辑', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 描述
              if (template.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  template.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // 统计信息
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.construction,
                    '${template.steps.length} 个步骤',
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.access_time,
                    _formatTime(template.createdAt),
                    Colors.grey,
                  ),
                  if (template.usageCount > 0)
                    _buildInfoChip(
                      Icons.trending_up,
                      '使用 ${template.usageCount} 次',
                      Colors.green,
                    ),
                  if (template.declaredTools.isNotEmpty)
                    _buildInfoChip(
                      Icons.build_circle,
                      '${template.declaredTools.length} 个工具',
                      Colors.orange,
                    ),
                ],
              ),

              // 标签
              if (template.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: template.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label,
                            size: 12,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return timeago.format(dateTime, locale: 'zh');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// 编辑模板
  Future<void> _editTemplate(SavedToolTemplate template) async {
    final result = await showEditToolDialog(
      context,
      template,
      widget.templateService,
    );

    if (result == true && mounted) {
      // 编辑成功，界面会自动更新（通过监听器）
      setState(() {});
    }
  }

  /// 删除模板
  Future<void> _deleteTemplate(SavedToolTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除工具模板"${template.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.templateService.deleteTemplate(template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 执行模板测试
  Future<void> _executeTemplate(SavedToolTemplate template) async {
    // 克隆步骤以避免修改原始模板
    final steps = widget.templateService.cloneTemplateSteps(template);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TemplateExecutionDialog(
        templateName: template.name,
        steps: steps,
      ),
    );
  }

  /// 显示标签过滤对话框
  Future<void> _showTagFilterDialog(List<String> allTags) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder:
          (context) => _TagFilterDialog(
            allTags: allTags,
            selectedTags: Set.from(_selectedTags),
            templateService: widget.templateService,
          ),
    );

    if (result != null) {
      setState(() {
        _selectedTags = result;
      });
    }
  }
}

/// 标签过滤对话框
class _TagFilterDialog extends StatefulWidget {
  final List<String> allTags;
  final Set<String> selectedTags;
  final ToolTemplateService templateService;

  const _TagFilterDialog({
    required this.allTags,
    required this.selectedTags,
    required this.templateService,
  });

  @override
  State<_TagFilterDialog> createState() => _TagFilterDialogState();
}

class _TagFilterDialogState extends State<_TagFilterDialog> {
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = Set.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.filter_list, size: 24),
          const SizedBox(width: 8),
          const Text('选择标签过滤'),
          const Spacer(),
          if (_selectedTags.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
              child: const Text('清空'),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allTags.length,
          itemBuilder: (context, index) {
            final tag = widget.allTags[index];
            final count =
                widget.templateService.templates
                    .where((t) => t.tags.contains(tag))
                    .length;
            final isSelected = _selectedTags.contains(tag);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              title: Row(
                children: [
                  Icon(
                    Icons.label,
                    size: 18,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tag)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.blue.shade50 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.blue.shade200
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _selectedTags),
          icon:
              _selectedTags.isEmpty
                  ? const Icon(Icons.check)
                  : Badge(
                    label: Text(_selectedTags.length.toString()),
                    child: const Icon(Icons.check),
                  ),
          label: const Text('确定'),
        ),
      ],
    );
  }
}
