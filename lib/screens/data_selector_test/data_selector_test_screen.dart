import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';

/// 插件数据选择器测试页面
class DataSelectorTestScreen extends StatefulWidget {
  const DataSelectorTestScreen({super.key});

  @override
  State<DataSelectorTestScreen> createState() => _DataSelectorTestScreenState();
}

class _DataSelectorTestScreenState extends State<DataSelectorTestScreen> {
  String _resultText = '点击按钮测试选择器';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registeredSelectors = pluginDataSelectorService.getAllSelectorIds();

    return Scaffold(
      appBar: AppBar(
        title: const Text('插件数据选择器测试'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 结果展示卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择结果',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _resultText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 已注册的选择器
          Text(
            '已注册的选择器 (${registeredSelectors.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (registeredSelectors.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无注册的选择器',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请确保相关插件已初始化',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...registeredSelectors.map((selectorId) {
              final definition =
                  pluginDataSelectorService.getSelectorDefinition(selectorId);
              if (definition == null) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        (definition.color ?? theme.colorScheme.primary)
                            .withOpacity(0.15),
                    child: Icon(
                      definition.icon ?? Icons.folder,
                      color: definition.color ?? theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(definition.name),
                  subtitle: Text(
                    'ID: ${definition.id}\n'
                    '插件: ${definition.pluginId} | '
                    '步骤: ${definition.steps.length} | '
                    '模式: ${definition.selectionMode == SelectionMode.single ? "单选" : "多选"}',
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => _testSelector(selectorId),
                    child: const Text('测试'),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // 快捷测试按钮
          Text(
            '快捷测试',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickTestButton(
                context,
                'Chat 频道',
                'chat.channel',
                Icons.chat,
                Colors.blue,
              ),
              _buildQuickTestButton(
                context,
                'Chat 消息',
                'chat.message',
                Icons.message,
                Colors.blue,
              ),
              _buildQuickTestButton(
                context,
                'OpenAI Agent',
                'openai.agent',
                Icons.smart_toy,
                Colors.green,
              ),
              _buildQuickTestButton(
                context,
                'OpenAI Prompt',
                'openai.prompt',
                Icons.text_snippet,
                Colors.green,
              ),
              _buildQuickTestButton(
                context,
                'Diary 日记',
                'diary.entry',
                Icons.book,
                Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestButton(
    BuildContext context,
    String label,
    String selectorId,
    IconData icon,
    Color color,
  ) {
    final isRegistered =
        pluginDataSelectorService.getSelectorDefinition(selectorId) != null;

    return ElevatedButton.icon(
      onPressed: isRegistered ? () => _testSelector(selectorId) : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isRegistered ? color : null,
      ),
    );
  }

  Future<void> _testSelector(String selectorId) async {
    setState(() {
      _resultText = '正在打开选择器: $selectorId...';
    });

    try {
      final result = await pluginDataSelectorService.showSelector(
        context,
        selectorId,
      );

      if (result == null) {
        setState(() {
          _resultText = '选择器返回 null（可能是关闭了对话框）';
        });
        return;
      }

      if (result.cancelled) {
        setState(() {
          _resultText = '用户取消了选择';
        });
        return;
      }

      // 格式化结果
      final buffer = StringBuffer();
      buffer.writeln('✅ 选择成功！');
      buffer.writeln();
      buffer.writeln('插件: ${result.pluginId}');
      buffer.writeln('选择器: ${result.selectorId}');
      buffer.writeln();

      if (result.path.isNotEmpty) {
        buffer.writeln('选择路径:');
        for (final pathItem in result.path) {
          buffer.writeln('  → ${pathItem.stepTitle}: ${pathItem.selectedItem.title}');
        }
        buffer.writeln();
      }

      buffer.writeln('最终数据类型: ${result.data?.runtimeType}');

      if (result is MultiSelectorResult) {
        buffer.writeln('选中数量: ${result.selectionCount}');
        buffer.writeln('选中项:');
        for (final item in result.selectedItems) {
          buffer.writeln('  • ${item.title}');
        }
      } else {
        buffer.writeln('数据: ${_formatData(result.data)}');
      }

      buffer.writeln();
      buffer.writeln('--- toMap() 输出 ---');
      buffer.writeln(_formatMap(result.toMap()));

      setState(() {
        _resultText = buffer.toString();
      });
    } catch (e, stack) {
      setState(() {
        _resultText = '❌ 发生错误:\n$e\n\n$stack';
      });
    }
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';
    if (data is String) return '"$data"';
    if (data is num || data is bool) return data.toString();
    if (data is List) {
      return '[${data.length} items]';
    }
    if (data is Map) {
      return '{${data.length} entries}';
    }
    return '${data.runtimeType}: $data';
  }

  String _formatMap(Map<String, dynamic> map, [int indent = 0]) {
    final buffer = StringBuffer();
    final prefix = '  ' * indent;

    buffer.writeln('{');
    map.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.write('$prefix  "$key": ');
        buffer.write(_formatMap(value, indent + 1));
      } else if (value is List) {
        buffer.writeln('$prefix  "$key": [');
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            buffer.write('$prefix    ');
            buffer.write(_formatMap(item, indent + 2));
          } else {
            buffer.writeln('$prefix    $item,');
          }
        }
        buffer.writeln('$prefix  ],');
      } else {
        buffer.writeln('$prefix  "$key": $value,');
      }
    });
    buffer.write('$prefix}');
    if (indent > 0) buffer.writeln(',');

    return buffer.toString();
  }
}
