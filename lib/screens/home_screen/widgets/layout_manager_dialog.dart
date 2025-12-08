import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/layout_config.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/l10n/screens_localizations.dart';
import '../../../../core/services/toast_service.dart';
import 'layout_type_selector.dart';

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
        final l10n = ScreensLocalizations.of(context)!;
        toastService.showToast('${l10n.loadLayoutFailed}：$e');
      }
    }
  }

  /// 切换到指定布局
  Future<void> _switchLayout(LayoutConfig layout) async {
    final l10n = ScreensLocalizations.of(context)!;
    try {
      await _layoutManager.loadLayoutConfig(layout.id);
      if (mounted) {
        setState(() {
          _currentLayoutId = layout.id;
        });
        Navigator.pop(context);
        toastService.showToast('${l10n.switchedToLayout}"${layout.name}"');
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('${l10n.switchFailed}：$e');
      }
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(LayoutConfig layout) {
    final l10n = ScreensLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController(text: layout.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameLayout),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.layoutName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                toastService.showToast(l10n.pleaseEnterLayoutName);
                return;
              }

              Navigator.pop(context);

              try {
                await _layoutManager.renameLayoutConfig(layout.id, newName);
                await _loadLayouts();
                if (mounted) {
                  toastService.showToast(l10n.renameSuccess);
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast(l10n.saveFailed);
                }
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 确认删除布局
  void _confirmDelete(LayoutConfig layout) {
    final l10n = ScreensLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteLayout(layout.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _layoutManager.deleteLayoutConfig(layout.id);
                await _loadLayouts();
                if (mounted) {
                  toastService.showToast(l10n.deleteSuccess);
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast(l10n.saveFailed);
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
    final l10n = ScreensLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.layoutManagement),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _layouts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noSavedLayouts,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.saveFirstLayoutHint,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                PopupMenuItem(
                                  value: 'switch',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.swap_horiz),
                                      const SizedBox(width: 8),
                                      Text(l10n.switchToThisLayout),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit),
                                    const SizedBox(width: 8),
                                    Text(l10n.rename),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
          label: Text(l10n.newLayout),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
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
    final l10n = ScreensLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      toastService.showToast(l10n.pleaseEnterLayoutName);
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
        toastService.showToast(l10n.layoutSaved(name));
        Navigator.pop(context);
        widget.onLayoutCreated();
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast(l10n.saveFailed);
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
    final l10n = ScreensLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.newLayout),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.layoutName,
                hintText: l10n.layoutNameHint,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            LayoutTypeSelector(
              initialType: _selectedLayoutType,
              onTypeChanged: (value) {
                setState(() {
                  _selectedLayoutType = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _createLayout,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
