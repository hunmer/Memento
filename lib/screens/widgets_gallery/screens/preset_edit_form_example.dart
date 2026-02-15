import 'package:flutter/material.dart';

/// 预设编辑表单示例
class PresetEditFormExample extends StatefulWidget {
  const PresetEditFormExample({super.key});

  @override
  State<PresetEditFormExample> createState() => _PresetEditFormExampleState();
}

class _PresetEditFormExampleState extends State<PresetEditFormExample> {
  // 尺寸模式
  String _sizeMode = 'small';

  // 模拟预设数据
  final Map<String, dynamic> _samplePreset = {
    'id': 'preset_001',
    'name': '每日任务模板',
    'description': '用于创建每日待办事项的预设模板',
    'fields': [
      {'id': 'field_1', 'type': 'text', 'label': '任务标题', 'required': true},
      {'id': 'field_2', 'type': 'select', 'label': '优先级', 'options': ['高', '中', '低']},
      {'id': 'field_3', 'type': 'date', 'label': '截止日期', 'required': false},
      {'id': 'field_4', 'type': 'textarea', 'label': '详细描述', 'required': false},
    ],
    'tags': ['工作', '日常'],
  };

  /// 获取宽度
  double _getWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (_sizeMode) {
      case 'small':
        return 360;
      case 'medium':
        return 440;
      case 'mediumWide':
        return screenWidth - 32;
      case 'large':
        return 520;
      case 'largeWide':
        return screenWidth - 32;
      default:
        return 360;
    }
  }

  /// 是否占满宽度
  bool _isFullWidth() {
    return _sizeMode == 'mediumWide' || _sizeMode == 'largeWide';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('预设编辑表单'),
      ),
      body: Column(
        children: [
          // 尺寸切换按钮
          _buildSizeSelector(theme),
          const Divider(height: 1),
          // 内容
          Expanded(
            child: _isFullWidth()
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PresetEditForm',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        const Text('这是一个预设编辑表单组件。'),
                        const SizedBox(height: 24),
                        Text(
                          '功能特性',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('- 表单验证'),
                        const Text('- 动态字段'),
                        const Text('- 预设模板'),
                        const Text('- 数据持久化'),
                        const SizedBox(height: 24),

                        // 预设表单示例
                        Card(
                          elevation: 0,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '预设表单示例',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildFormExample(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 使用说明
                        Card(
                          elevation: 0,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '使用说明',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildUsageGuide(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: SizedBox(
                      width: _getWidth(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PresetEditForm',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            const Text('这是一个预设编辑表单组件。'),
                            const SizedBox(height: 24),
                            Text(
                              '功能特性',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text('- 表单验证'),
                            const Text('- 动态字段'),
                            const Text('- 预设模板'),
                            const Text('- 数据持久化'),
                            const SizedBox(height: 24),

                            // 预设表单示例
                            Card(
                              elevation: 0,
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '预设表单示例',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormExample(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 使用说明
                            Card(
                              elevation: 0,
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '使用说明',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildUsageGuide(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 尺寸选择器
  Widget _buildSizeSelector(ThemeData theme) {
    final sizes = [
      {'value': 'small', 'label': '小尺寸'},
      {'value': 'medium', 'label': '中尺寸'},
      {'value': 'mediumWide', 'label': '中宽'},
      {'value': 'large', 'label': '大尺寸'},
      {'value': 'largeWide', 'label': '大宽'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: sizes.map((size) {
          final isSelected = _sizeMode == size['value'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(size['label']!),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _sizeMode = size['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建表单示例
  Widget _buildFormExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 预设名称
        TextField(
          decoration: const InputDecoration(
            labelText: '预设名称',
            hintText: '输入预设名称',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: _samplePreset['name']),
        ),
        const SizedBox(height: 12),

        // 预设描述
        TextField(
          decoration: const InputDecoration(
            labelText: '预设描述',
            hintText: '输入预设描述',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          controller: TextEditingController(text: _samplePreset['description']),
        ),
        const SizedBox(height: 12),

        // 标签选择
        Wrap(
          spacing: 8,
          children: ['工作', '生活', '学习', '健康'].map((tag) {
            final isSelected = (_samplePreset['tags'] as List).contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) {},
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // 字段列表标题
        Row(
          children: [
            Text(
              '预设字段',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加字段'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 字段列表
        ...(_samplePreset['fields'] as List<dynamic>).map<Widget>((field) {
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(_getFieldIcon(field['type'])),
              title: Text(field['label']),
              subtitle: Text('类型: ${field['type']}${field['required'] ? ' (必填)' : ''}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 获取字段图标
  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'textarea':
        return Icons.notes;
      case 'select':
        return Icons.arrow_drop_down_circle;
      case 'date':
        return Icons.calendar_today;
      case 'number':
        return Icons.numbers;
      case 'checkbox':
        return Icons.check_box;
      default:
        return Icons.input;
    }
  }

  /// 构建使用说明
  Widget _buildUsageGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('1. 创建预设模板，定义字段结构'),
        SizedBox(height: 4),
        Text('2. 配置字段类型和验证规则'),
        SizedBox(height: 4),
        Text('3. 使用预设快速创建表单'),
        SizedBox(height: 4),
        Text('4. 支持数据导入导出'),
        SizedBox(height: 4),
        Text('5. 可与数据选择器集成'),
      ],
    );
  }
}
