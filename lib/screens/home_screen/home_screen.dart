import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../main.dart';
import '../../core/floating_ball/floating_ball_service.dart';
import 'managers/home_layout_manager.dart';
import 'widgets/home_grid.dart';
import 'widgets/add_widget_dialog.dart';
import 'widgets/create_folder_dialog.dart';

/// 重构后的主屏幕
///
/// 使用新的 HomeLayoutManager 和组件系统
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final HomeLayoutManager _layoutManager = HomeLayoutManager();
  bool _isLoading = true;

  // 是否是首次加载，使用静态变量确保在热重载时保持状态
  static bool _hasInitialized = false;
  // 是否正在打开插件
  bool _isOpeningPlugin = false;

  @override
  void initState() {
    super.initState();
    _initializeLayout();

    // 延迟初始化，确保在布局完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 显示悬浮球（如果启用的话）
        FloatingBallService().show(context);
        // 首次加载时打开最后使用的插件
        if (!_hasInitialized) {
          _openLastUsedPlugin();
          _hasInitialized = true;
        }
      }
    });
  }

  /// 初始化布局
  Future<void> _initializeLayout() async {
    try {
      await _layoutManager.initialize();

      // 如果是空布局，创建默认小组件
      if (_layoutManager.items.isEmpty) {
        await _createDefaultWidgets();
      }
    } catch (e) {
      debugPrint('初始化布局失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 创建默认小组件（从已注册的小组件中选择）
  Future<void> _createDefaultWidgets() async {
    // TODO: 根据用户配置或插件优先级创建默认小组件
    // 暂时留空，用户可以通过"添加组件"按钮手动添加
  }

  /// 打开最后使用的插件
  void _openLastUsedPlugin() async {
    // 防止重复打开
    if (_isOpeningPlugin) {
      return;
    }
    _isOpeningPlugin = true;

    // 检查是否启用了自动打开功能
    if (!globalPluginManager.autoOpenLastPlugin) {
      return;
    }

    // 获取最后一次使用的插件
    final lastPlugin = globalPluginManager.getLastOpenedPlugin();
    if (lastPlugin != null) {
      // 使用延迟确保不会与初始动画冲突
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        globalPluginManager.openPlugin(context, lastPlugin);
      }
    }
    _isOpeningPlugin = false;
  }

  /// 显示添加组件对话框
  void _showAddWidgetDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddWidgetDialog(),
    );
  }

  /// 显示操作菜单
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('新建文件夹'),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('添加组件'),
              onTap: () {
                Navigator.pop(context);
                _showAddWidgetDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('网格大小'),
              subtitle: Text('当前：${_layoutManager.gridCrossAxisCount} 列'),
              onTap: () {
                Navigator.pop(context);
                _showGridSizeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('清空布局'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearLayout();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示创建文件夹对话框
  void _showCreateFolderDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );
  }

  /// 显示网格大小调节对话框
  void _showGridSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => _GridSizeDialog(layoutManager: _layoutManager),
    );
  }

  /// 确认清空布局
  void _confirmClearLayout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有小组件吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _layoutManager.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('布局已清空')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void didPopNext() {
    // 当从其他页面返回到HomeScreen时触发
    super.didPopNext();
    setState(() {
      // 刷新布局
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWidgetDialog,
            tooltip: '添加组件',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
            tooltip: '更多选项',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _layoutManager,
              builder: (context, child) {
                return HomeGrid(
                  items: _layoutManager.items,
                  crossAxisCount: _layoutManager.gridCrossAxisCount,
                  onReorder: (oldIndex, newIndex) {
                    _layoutManager.reorder(oldIndex, newIndex);
                  },
                );
              },
            ),
    );
  }
}

/// 网格大小调节对话框
class _GridSizeDialog extends StatefulWidget {
  final HomeLayoutManager layoutManager;

  const _GridSizeDialog({required this.layoutManager});

  @override
  State<_GridSizeDialog> createState() => _GridSizeDialogState();
}

class _GridSizeDialogState extends State<_GridSizeDialog> {
  late int _currentSize;

  @override
  void initState() {
    super.initState();
    _currentSize = widget.layoutManager.gridCrossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('网格大小'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '选择主页网格的列数 (1-10)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('$_currentSize 列', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _currentSize > 1
                    ? () {
                        setState(() {
                          _currentSize--;
                          widget.layoutManager.setGridCrossAxisCount(_currentSize);
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _currentSize < 10
                    ? () {
                        setState(() {
                          _currentSize++;
                          widget.layoutManager.setGridCrossAxisCount(_currentSize);
                        });
                      }
                    : null,
              ),
            ],
          ),
          Slider(
            value: _currentSize.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_currentSize',
            onChanged: (value) {
              setState(() {
                _currentSize = value.round();
                widget.layoutManager.setGridCrossAxisCount(_currentSize);
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            '提示：数字越大，每行显示的组件越多',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
    );
  }
}
