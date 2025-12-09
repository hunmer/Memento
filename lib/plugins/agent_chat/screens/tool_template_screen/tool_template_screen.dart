import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/plugins/agent_chat/models/saved_tool_template.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/components/save_tool_dialog.dart';
import 'components/template_execution_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:Memento/core/services/toast_service.dart';
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
  final ScrollController _tagsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.templateService.addListener(_onTemplatesChanged);
  }

  @override
  void dispose() {
    _tagsScrollController.dispose();
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
        title: Text('agent_chat_toolTemplate'.tr),
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
          // 重置默认模板按钮
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '重置默认模板',
            onPressed: _resetToDefaultTemplates,
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
                        child: Scrollbar(
                          controller: _tagsScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _tagsScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  _selectedTags.map((tag) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Chip(
                                        avatar: const Icon(Icons.label, size: 16),
                                        label: Text(tag),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedTags.remove(tag);
                                          });
                                        },
                                        deleteIcon: const Icon(Icons.close, size: 16),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
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
                          label: Text(
                            'agent_chat_clear'.tr,
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
                      label: Text('agent_chat_use'.tr),
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
                          PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                                const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'agent_chat_edit'.tr,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                                const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'agent_chat_delete'.tr,
                                  style: const TextStyle(color: Colors.red),
                                ),
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
            title: Text('agent_chat_deleteConfirmation'.tr),
            content: Text(
              'agent_chat_confirmDeleteTemplate'.trParams({
                'templateName': template.name,
              }),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
                child: Text('agent_chat_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
                child: Text('agent_chat_delete'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.templateService.deleteTemplate(template.id);
        if (mounted) {
          toastService.showToast('删除成功');
        }
      } catch (e) {
        if (mounted) {
          toastService.showToast('删除失败: $e');
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

  /// 重置为默认模板
  Future<void> _resetToDefaultTemplates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: Row(
          children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text('agent_chat_resetConfirmation'.tr),
          ],
        ),
        content: const Text(
          '此操作将强制恢复所有默认工具模板到初始状态。\n\n'
          '⚠️ 注意：如果您修改过默认模板，这些修改将会被覆盖！\n\n'
          '自定义模板不会受到影响。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
                child: Text('agent_chat_cancel'.tr),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            icon: const Icon(Icons.restore),
                label: Text('agent_chat_reset'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 显示加载指示器
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Center(
            child: Card(
              child: Padding(
                    padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          AgentChatLocalizations.of(
                            context,
                          ).resettingDefaultTemplates,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // 执行重置操作
      await widget.templateService.restoreDefaultTemplates();

      // 关闭加载指示器
      if (mounted) {
        Navigator.pop(context);

        // 显示成功提示
        toastService.showToast('默认模板已成功重置');

        // 刷新界面
        setState(() {});
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) {
        Navigator.pop(context);

        // 显示错误提示
        toastService.showToast('重置失败: $e');
      }
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
          Text('agent_chat_selectTagFilter'.tr),
          const Spacer(),
          if (_selectedTags.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
              child: Text('agent_chat_clear'.tr),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.allTags.map((tag) {
              final count =
                  widget.templateService.templates
                      .where((t) => t.tags.contains(tag))
                      .length;
              final isSelected = _selectedTags.contains(tag);

              return FilterChip(
                avatar: Icon(
                  Icons.label,
                  size: 18,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue.shade100 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                showCheckmark: false,
                selectedColor: Colors.blue.shade50,
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade300 : Colors.grey.shade400,
                  width: 1,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('agent_chat_cancel'.tr),
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
          label: Text('agent_chat_confirm'.tr),
        ),
      ],
    );
  }
}
