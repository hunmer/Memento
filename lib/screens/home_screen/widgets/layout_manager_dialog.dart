import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../managers/home_layout_manager.dart';
import '../managers/home_widget_registry.dart';
import '../models/layout_config.dart';
import '../models/home_widget_item.dart';
import '../models/home_widget_size.dart';

/// 布局管理对话框
///
/// 显示所有保存的布局配置，支持切换、重命名和删除
class LayoutManagerDialog extends StatefulWidget {
  const LayoutManagerDialog({super.key});

  @override
  State<LayoutManagerDialog> createState() => _LayoutManagerDialogState();
}

class _LayoutManagerDialogState extends State<LayoutManagerDialog> {
  final HomeLayoutManager _layoutManager = HomeLayoutManager();
  List<LayoutConfig> _layouts = [];
  bool _isLoading = true;
  String? _currentLayoutId;

  @override
  void initState() {
    super.initState();
    _loadLayouts();
  }

  /// 加载所有布局配置
  Future<void> _loadLayouts() async {
    try {
      final layouts = await _layoutManager.getSavedLayouts();
      final currentLayout = await _layoutManager.getCurrentLayoutConfig();

      if (mounted) {
        setState(() {
          _layouts = layouts;
          _currentLayoutId = currentLayout?.id;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载布局失败：$e')),
        );
      }
    }
  }

  /// 切换到指定布局
  Future<void> _switchLayout(LayoutConfig layout) async {
    try {
      await _layoutManager.loadLayoutConfig(layout.id);
      if (mounted) {
        setState(() {
          _currentLayoutId = layout.id;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换到"${layout.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换失败：$e')),
        );
      }
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(LayoutConfig layout) {
    final TextEditingController controller = TextEditingController(text: layout.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名布局'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '布局名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入布局名称')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _layoutManager.renameLayoutConfig(layout.id, newName);
                await _loadLayouts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('重命名成功')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('重命名失败：$e')),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 确认删除布局
  void _confirmDelete(LayoutConfig layout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除布局"${layout.name}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _layoutManager.deleteLayoutConfig(layout.id);
                await _loadLayouts();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败：$e')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 显示新建布局对话框
  void _showCreateLayoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateLayoutDialog(
        onLayoutCreated: () {
          _loadLayouts();
          Navigator.pop(context); // 关闭布局管理对话框
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('布局管理'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _layouts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '暂无保存的布局',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '点击右上角菜单中的"保存当前布局"来创建第一个布局配置',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _layouts.length,
                    itemBuilder: (context, index) {
                      final layout = _layouts[index];
                      final isActive = layout.id == _currentLayoutId;
                      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

                      return Card(
                        elevation: isActive ? 4 : 1,
                        color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
                        child: ListTile(
                          leading: Icon(
                            isActive ? Icons.check_circle : Icons.layers,
                            color: isActive ? Theme.of(context).colorScheme.primary : null,
                          ),
                          title: Text(
                            layout.name,
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${layout.items.length} 个组件 · ${layout.gridCrossAxisCount} 列网格'),
                              Text(
                                '更新：${dateFormat.format(layout.updatedAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'switch':
                                  _switchLayout(layout);
                                  break;
                                case 'rename':
                                  _showRenameDialog(layout);
                                  break;
                                case 'delete':
                                  _confirmDelete(layout);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isActive)
                                const PopupMenuItem(
                                  value: 'switch',
                                  child: Row(
                                    children: [
                                      Icon(Icons.swap_horiz),
                                      SizedBox(width: 8),
                                      Text('切换到此布局'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('重命名'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('删除', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: isActive ? null : () => _switchLayout(layout),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _showCreateLayoutDialog,
          icon: const Icon(Icons.add),
          label: const Text('新建布局'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

/// 新建布局对话框
class _CreateLayoutDialog extends StatefulWidget {
  final VoidCallback onLayoutCreated;

  const _CreateLayoutDialog({required this.onLayoutCreated});

  @override
  State<_CreateLayoutDialog> createState() => _CreateLayoutDialogState();
}

class _CreateLayoutDialogState extends State<_CreateLayoutDialog> {
  final TextEditingController _nameController = TextEditingController();
  final HomeLayoutManager _layoutManager = HomeLayoutManager();
  String _selectedLayoutType = 'empty';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 创建布局
  Future<void> _createLayout() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入布局名称')),
      );
      return;
    }

    try {
      // 清空当前布局
      _layoutManager.clear();

      // 根据选择的类型添加小组件
      if (_selectedLayoutType == '1x1') {
        await _addAllWidgetsOfSize(HomeWidgetSize.small);
      } else if (_selectedLayoutType == '2x2') {
        await _addAllWidgetsOfSize(HomeWidgetSize.large);
      }
      // 空白布局不添加任何内容

      // 保存布局
      await _layoutManager.saveCurrentLayoutAs(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('布局"$name"已创建')),
        );
        Navigator.pop(context);
        widget.onLayoutCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败：$e')),
        );
      }
    }
  }

  /// 添加所有指定尺寸的小组件
  Future<void> _addAllWidgetsOfSize(HomeWidgetSize size) async {
    final registry = HomeWidgetRegistry();
    final allWidgets = registry.getAllWidgets();

    // 筛选支持指定尺寸的小组件
    final widgets = allWidgets
        .where((widget) => widget.supportedSizes.contains(size))
        .toList();

    // 添加到布局
    for (final widget in widgets) {
      final item = HomeWidgetItem(
        id: _layoutManager.generateId(),
        widgetId: widget.id,
        size: size,
        config: {},
      );
      _layoutManager.addItem(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建布局'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '布局名称',
                hintText: '例如：工作布局、娱乐布局',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Text(
              '布局类型',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('空白布局'),
              subtitle: const Text('不包含任何小组件的空白布局'),
              value: 'empty',
              groupValue: _selectedLayoutType,
              onChanged: (value) {
                setState(() {
                  _selectedLayoutType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('所有 1x1 小组件'),
              subtitle: const Text('添加所有支持 1x1 尺寸的小组件'),
              value: '1x1',
              groupValue: _selectedLayoutType,
              onChanged: (value) {
                setState(() {
                  _selectedLayoutType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('所有 2x2 小组件'),
              subtitle: const Text('添加所有支持 2x2 尺寸的小组件'),
              value: '2x2',
              groupValue: _selectedLayoutType,
              onChanged: (value) {
                setState(() {
                  _selectedLayoutType = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _createLayout,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
