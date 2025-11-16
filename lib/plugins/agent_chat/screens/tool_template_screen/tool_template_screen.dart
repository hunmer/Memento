import 'package:flutter/material.dart';
import '../../services/tool_template_service.dart';
import '../../models/saved_tool_template.dart';
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
    final templates = _searchQuery.isEmpty
        ? widget.templateService.templates
        : widget.templateService.searchTemplates(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具模板'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
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
        onTap: () => _showTemplateDetail(template),
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
                  // 使用按钮
                  if (widget.onUseTemplate != null)
                    FilledButton.icon(
                      onPressed: () {
                        widget.onUseTemplate!(template);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
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
                        case 'delete':
                          _deleteTemplate(template);
                          break;
                        case 'detail':
                          _showTemplateDetail(template);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18),
                            SizedBox(width: 8),
                            Text('查看详情'),
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
                ],
              ),
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

  /// 显示模板详情
  void _showTemplateDetail(SavedToolTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (template.description != null) ...[
                Text(
                  template.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],
              const SizedBox(height: 8),
              Text(
                '工具步骤 (${template.steps.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...template.steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${step.title}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (step.desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            step.desc,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          if (widget.onUseTemplate != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onUseTemplate!(template);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('使用'),
            ),
        ],
      ),
    );
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
}
