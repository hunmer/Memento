import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/layout_config.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../../../../core/services/toast_service.dart';
import 'layout_type_selector.dart';

/// 布局管理对话框
///
/// 显示所有保存的布局配置，支持切换、重命名和删除
class LayoutManagerDialog extends StatefulWidget {
  final VoidCallback? onLayoutChanged;

  const LayoutManagerDialog({super.key, this.onLayoutChanged});

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
        });        toastService.showToast('${'screens_loadLayoutFailed'.tr}：$e');
      }
    }
  }

  /// 切换到指定布局
  Future<void> _switchLayout(LayoutConfig layout) async {    try {
      await _layoutManager.loadLayoutConfig(layout.id);
      if (mounted) {
        setState(() {
          _currentLayoutId = layout.id;
        });
        Navigator.pop(context);
        toastService.showToast('${'screens_switchedToLayout'.tr}"${layout.name}"');
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('${'screens_switchFailed'.tr}：$e');
      }
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(LayoutConfig layout) {    final TextEditingController controller = TextEditingController(text: layout.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('screens_renameLayout'.tr),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'screens_layoutName'.tr,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('screens_cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                toastService.showToast('screens_pleaseEnterLayoutName'.tr);
                return;
              }

              Navigator.pop(context);

              try {
                await _layoutManager.renameLayoutConfig(layout.id, newName);
                await _loadLayouts();
                if (mounted) {
                  toastService.showToast('screens_renameSuccess'.tr);
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast('screens_saveFailed'.tr);
                }
              }
            },
            child: Text('screens_confirm'.tr),
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
        title: Text('screens_confirmDelete'.tr),
        content: Text('screens_confirmDeleteLayout'.trParams({'layoutName': layout.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('screens_cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _layoutManager.deleteLayoutConfig(layout.id);
                await _loadLayouts();
                    // 通知外部重新加载布局列表
                    widget.onLayoutChanged?.call();
                if (mounted) {
                  toastService.showToast('screens_deleteSuccess'.tr);
                }
              } catch (e) {
                if (mounted) {
                  toastService.showToast('screens_saveFailed'.tr);
                }
              }
            },
            child: Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
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
        onLayoutCreated: (newLayoutId) {
          _loadLayouts();
          // 通知外部切换到新布局
          widget.onLayoutChanged?.call();
          Navigator.pop(context); // 关闭布局管理对话框
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {    return AlertDialog(
      title: Text('screens_layoutManagement'.tr),
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
                            'screens_noSavedLayouts'.tr,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'screens_saveFirstLayoutHint'.tr,
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
                                      Text('screens_switchToThisLayout'.tr),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit),
                                    const SizedBox(width: 8),
                                    Text('screens_rename'.tr),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text('screens_delete'.tr, style: const TextStyle(color: Colors.red)),
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
          label: Text('screens_newLayout'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('screens_close'.tr),
        ),
      ],
    );
  }
}

/// 新建布局对话框
class _CreateLayoutDialog extends StatefulWidget {
  final ValueChanged<String> onLayoutCreated;

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
      toastService.showToast('screens_pleaseEnterLayoutName'.tr);
      return;
    }

    try {
      // 创建临时的 items 列表(不修改当前布局状态)
      final List<HomeItem> newItems = [];

      // 根据选择的类型添加小组件
      if (_selectedLayoutType == '1x1') {
        newItems.addAll(await _getAllWidgetsOfSize(HomeWidgetSize.small));
      } else if (_selectedLayoutType == '2x2') {
        newItems.addAll(await _getAllWidgetsOfSize(HomeWidgetSize.large));
      }
      // 空白布局不添加任何内容

      // 保存新布局(不修改当前布局状态)
      final newLayoutId = await _layoutManager.saveLayoutAs(
        name,
        newItems,
        _layoutManager.gridCrossAxisCount,
      );

      if (mounted) {
        toastService.showToast('screens_layoutSaved'.trParams({'name': name}));
        Navigator.pop(context);
        widget.onLayoutCreated(newLayoutId);
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('screens_saveFailed'.tr);
      }
    }
  }

  /// 获取所有指定尺寸的小组件(返回列表,不添加到 layoutManager)
  Future<List<HomeItem>> _getAllWidgetsOfSize(HomeWidgetSize size) async {
    final registry = HomeWidgetRegistry();
    final allWidgets = registry.getAllWidgets();

    // 筛选支持指定尺寸的小组件
    final widgets = allWidgets
        .where((widget) => widget.supportedSizes.contains(size))
        .toList();

    // 创建小组件项列表
    final items = <HomeItem>[];
    for (final widget in widgets) {
      final item = HomeWidgetItem(
        id: _layoutManager.generateId(),
        widgetId: widget.id,
        size: size,
        config: {},
      );
      items.add(item);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {    return AlertDialog(
      title: Text('screens_newLayout'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'screens_layoutName'.tr,
                hintText: 'screens_layoutNameHint'.tr,
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
          child: Text('screens_cancel'.tr),
        ),
        TextButton(
          onPressed: _createLayout,
          child: Text('screens_create'.tr),
        ),
      ],
    );
  }
}
