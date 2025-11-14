import 'dart:io';
import 'dart:ui';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/layout_config.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../main.dart';
import '../../core/floating_ball/floating_ball_service.dart';
import 'managers/home_layout_manager.dart';
import 'widgets/home_grid.dart';
import 'widgets/add_widget_dialog.dart';
import 'widgets/create_folder_dialog.dart';
import 'widgets/layout_manager_dialog.dart';
import 'widgets/background_settings_page.dart';

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

  // 编辑模式标志
  bool _isEditMode = false;

  // 是否是首次加载，使用静态变量确保在热重载时保持状态
  static bool _hasInitialized = false;
  // 是否正在打开插件
  bool _isOpeningPlugin = false;

  // 当前布局名称
  String _currentLayoutName = '';

  // 所有保存的布局列表
  List<LayoutConfig> _savedLayouts = [];

  // PageView 控制器
  PageController? _pageController;

  // 当前页索引
  int _currentPageIndex = 0;

  // 当前背景图配置
  String? _currentBackgroundPath;
  BoxFit _currentBackgroundFit = BoxFit.cover;
  double _currentBackgroundBlur = 0.0;

  // 全局小组件透明度
  double _globalWidgetOpacity = 1.0;

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

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// 初始化布局
  Future<void> _initializeLayout() async {
    try {
      await _layoutManager.initialize();

      // 加载所有保存的布局
      await _loadSavedLayouts();

      // 如果有保存的布局，尝试加载最后活动的布局
      if (_savedLayouts.isNotEmpty) {
        final currentConfig = await _layoutManager.getCurrentLayoutConfig();
        if (currentConfig != null) {
          // 加载活动布局
          await _layoutManager.loadLayoutConfig(currentConfig.id);
          debugPrint('首次加载布局: ${currentConfig.name}');
        }
      }

      // 如果是空布局，创建默认小组件
      if (_layoutManager.items.isEmpty) {
        await _createDefaultWidgets();
      }

      // 获取当前活动布局名称
      await _updateCurrentLayoutName();

      // 加载当前背景图
      await _loadCurrentBackground();
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

  /// 加载所有保存的布局
  Future<void> _loadSavedLayouts() async {
    try {
      final layouts = await _layoutManager.getSavedLayouts();
      final currentConfig = await _layoutManager.getCurrentLayoutConfig();

      if (mounted) {
        setState(() {
          _savedLayouts = layouts;
          // 初始化 PageController
          if (layouts.isNotEmpty && currentConfig != null) {
            // 找到当前活动布局的索引
            _currentPageIndex = layouts.indexWhere(
              (layout) => layout.id == currentConfig.id,
            );
            if (_currentPageIndex == -1) {
              _currentPageIndex = 0;
            }
            _pageController = PageController(initialPage: _currentPageIndex);
          }
        });
      }
    } catch (e) {
      debugPrint('加载保存的布局失败: $e');
    }
  }

  /// 更新当前布局名称
  Future<void> _updateCurrentLayoutName() async {
    try {
      final currentConfig = await _layoutManager.getCurrentLayoutConfig();
      if (mounted) {
        setState(() {
          _currentLayoutName = currentConfig?.name ?? '';
        });
      }
    } catch (e) {
      debugPrint('获取当前布局名称失败: $e');
    }
  }

  /// 加载当前背景图配置
  Future<void> _loadCurrentBackground() async {
    try {
      // 先加载全局配置
      final globalConfig = await _layoutManager.getGlobalBackgroundConfig();

      String? backgroundPath = globalConfig['backgroundImagePath'] as String?;
      BoxFit backgroundFit = LayoutConfig.boxFitFromString(
        globalConfig['backgroundFit'] as String?,
      );
      double backgroundBlur =
          (globalConfig['backgroundBlur'] as num?)?.toDouble() ?? 0.0;
      final widgetOpacity =
          (globalConfig['widgetOpacity'] as num?)?.toDouble() ?? 1.0;

      // 如果有当前布局配置且设置了独立背景，则覆盖全局背景
      final currentConfig = await _layoutManager.getCurrentLayoutConfig();
      if (currentConfig?.backgroundImagePath != null) {
        backgroundPath = currentConfig!.backgroundImagePath;
        backgroundFit = currentConfig.backgroundFit;
        backgroundBlur = currentConfig.backgroundBlur;
      }

      if (mounted) {
        setState(() {
          _currentBackgroundPath = backgroundPath;
          _currentBackgroundFit = backgroundFit;
          _currentBackgroundBlur = backgroundBlur;
          _globalWidgetOpacity = widgetOpacity;
        });

        // 强制刷新一次，确保 AnimatedSwitcher 正确触发
        // 在下一帧再次 setState，触发重建
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }

      debugPrint('背景图加载完成: path=$backgroundPath, opacity=$widgetOpacity');
    } catch (e) {
      debugPrint('加载背景图失败: $e');
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
                  leading: Icon(_isEditMode ? Icons.check : Icons.edit),
                  title: Text(_isEditMode ? '完成排序' : '自定义排序'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isEditMode ? '长按拖拽可调整顺序' : '已退出编辑模式'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('保存当前布局'),
              onTap: () {
                Navigator.pop(context);
                _showSaveLayoutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('管理布局'),
              onTap: () {
                Navigator.pop(context);
                _showLayoutManagerDialog();
              },
            ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('主题设置'),
                  onTap: () {
                    Navigator.pop(context);
                    _showThemeSettings();
                  },
                ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.grid_view),
                  title: const Text('网格设置'),
                  subtitle: Text(
                    '${_layoutManager.gridCrossAxisCount} 列 · ${_layoutManager.gridAlignment == "top" ? "顶部显示" : "居中显示"}',
                  ),
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
  void _showGridSizeDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _GridSizeDialog(layoutManager: _layoutManager),
    );

    // 对话框关闭后强制刷新界面，确保显示位置设置生效
    if (mounted) {
      setState(() {});
    }
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

  /// 显示保存布局对话框
  void _showSaveLayoutDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存当前布局'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '布局名称',
            hintText: '例如：工作布局、娱乐布局',
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入布局名称')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _layoutManager.saveCurrentLayoutAs(name);
                // 刷新布局列表和名称
                await _loadSavedLayouts();
                await _updateCurrentLayoutName();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('布局"$name"已保存')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('保存失败：$e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示布局管理对话框
  void _showLayoutManagerDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const LayoutManagerDialog(),
    );

    // 对话框关闭后刷新布局列表和名称
    await _loadSavedLayouts();
    await _updateCurrentLayoutName();
  }

  /// 显示主题设置页面
  void _showThemeSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackgroundSettingsPage()),
    );

    // 返回后刷新背景图和透明度
    await _loadCurrentBackground();
  }

  @override
  void didPopNext() {
    // 当从其他页面返回到HomeScreen时触发
    super.didPopNext();
    setState(() {
      // 刷新布局
    });
  }

  /// 处理卡片长按事件
  void _handleCardLongPress(HomeItem item) {
    if (_isEditMode) {
      // 编辑模式下不显示菜单，由拖拽处理
      return;
    }

    // 非编辑模式下显示操作菜单
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('设置背景颜色'),
                  onTap: () {
                    Navigator.pop(context);
                    _showColorPicker(item);
                  },
                ),
                if (item is HomeWidgetItem)
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('设置背景图'),
                    onTap: () {
                      Navigator.pop(context);
                      _showBackgroundImagePicker(item);
                    },
                  ),
                if (item is HomeWidgetItem)
                  ListTile(
                    leading: const Icon(Icons.aspect_ratio),
                    title: const Text('调整大小'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSizeAdjuster(item);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteItem(item);
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// 显示颜色选择器
  void _showColorPicker(HomeItem item) {
    // TODO: 实现背景颜色选择功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('背景颜色功能开发中...')));
  }

  /// 显示背景图选择器
  void _showBackgroundImagePicker(HomeWidgetItem item) {
    // TODO: 实现背景图选择功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('背景图功能开发中...')));
  }

  /// 显示大小调整器
  void _showSizeAdjuster(HomeWidgetItem item) {
    // TODO: 实现组件大小调整功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('大小调整功能开发中...')));
  }

  /// 确认删除项目
  void _confirmDeleteItem(HomeItem item) {
    final itemName =
        item is HomeWidgetItem
            ? HomeWidgetRegistry().getWidget(item.widgetId)?.name ?? '组件'
            : (item as HomeFolderItem).name;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除 "$itemName" 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _layoutManager.removeItem(item.id);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('"$itemName" 已删除')));
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLayoutName.isEmpty
              ? AppLocalizations.of(context)!.home
              : _currentLayoutName,
        ),
        centerTitle: true,
        backgroundColor:
            _currentBackgroundPath != null ? Colors.transparent : null,
        elevation: _currentBackgroundPath != null ? 0 : null,
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
      extendBodyBehindAppBar: _currentBackgroundPath != null,
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图（带淡入淡出动画）
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child:
                _currentBackgroundPath != null
                    ? _buildBackgroundImage()
                    : const SizedBox.expand(key: ValueKey('no_background')),
          ),

          // 主内容
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _savedLayouts.isEmpty
              ? _buildHomeContent()
              : Stack(
                children: [
                  // 使用 ScrollConfiguration 让桌面端支持鼠标拖拽
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _savedLayouts.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        // 使用当前布局ID作为key，确保只在布局切换时触发动画
                        final layoutId =
                            index < _savedLayouts.length
                                ? _savedLayouts[index].id
                                : 'default';

                        // 使用 AnimatedSwitcher 为小组件添加淡入淡出动画
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child: _buildHomeContent(key: ValueKey(layoutId)),
                        );
                      },
                    ),
                  ),
                    // 底部圆点指示器
                    if (_savedLayouts.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _savedLayouts.length,
                                (index) => GestureDetector(
                                  onTap: () {
                                    _pageController?.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: index == _currentPageIndex ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: index == _currentPageIndex
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
        ],
      ),
    );
  }

  /// 构建背景图
  Widget _buildBackgroundImage() {
    // 使用背景图路径作为key，确保切换背景时触发动画
    return Stack(
      key: ValueKey(_currentBackgroundPath),
      fit: StackFit.expand,
      children: [
        // 背景图片
        Image.file(File(_currentBackgroundPath!), fit: _currentBackgroundFit),
        // 模糊效果
        if (_currentBackgroundBlur > 0)
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _currentBackgroundBlur,
              sigmaY: _currentBackgroundBlur,
            ),
            child: Container(color: Colors.transparent),
          ),
      ],
    );
  }

  /// 构建主页内容
  Widget _buildHomeContent({Key? key}) {
    return Opacity(
      key: key,
      opacity: _globalWidgetOpacity,
      child: ListenableBuilder(
        listenable: _layoutManager,
        builder: (context, child) {
          // 在 ListenableBuilder 内部计算，确保配置改变时会重新计算
          final isCenter = _layoutManager.gridAlignment == 'center';
          final alignment = isCenter ? Alignment.center : Alignment.topCenter;

          return Padding(
            // 当有背景图且顶部对齐时，添加顶部padding避免小组件被AppBar遮挡
            // 居中对齐时不需要顶部padding
            padding: EdgeInsets.only(
              top:
                  !isCenter && _currentBackgroundPath != null
                      ? MediaQuery.of(context).padding.top
                      : 0,
            ),
            child: HomeGrid(
              items: _layoutManager.items,
              crossAxisCount: _layoutManager.gridCrossAxisCount,
              isEditMode: _isEditMode,
              alignment: alignment,
              onReorder: (oldIndex, newIndex) {
                _layoutManager.reorder(oldIndex, newIndex);
              },
              onItemLongPress: _handleCardLongPress,
            ),
          );
        },
      ),
    );
  }

  /// 页面切换回调
  void _onPageChanged(int index) async {
    if (index < 0 || index >= _savedLayouts.length) {
      return;
    }

    final layout = _savedLayouts[index];
    setState(() {
      _currentPageIndex = index;
      _currentLayoutName = layout.name;
    });

    // 加载对应的布局配置
    try {
      await _layoutManager.loadLayoutConfig(layout.id);
      // 加载对应的背景图
      await _loadCurrentBackground();
    } catch (e) {
      debugPrint('切换布局失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换布局失败：$e')),
        );
      }
    }
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
  late String _currentAlignment;

  @override
  void initState() {
    super.initState();
    _currentSize = widget.layoutManager.gridCrossAxisCount;
    _currentAlignment = widget.layoutManager.gridAlignment;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('网格设置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 网格大小设置
            Text(
              '网格大小',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '选择主页网格的列数 (1-10)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '$_currentSize 列',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                      _currentSize > 1
                          ? () {
                            setState(() {
                              _currentSize--;
                              widget.layoutManager.setGridCrossAxisCount(
                                _currentSize,
                              );
                            });
                          }
                          : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed:
                      _currentSize < 10
                          ? () {
                            setState(() {
                              _currentSize++;
                              widget.layoutManager.setGridCrossAxisCount(
                                _currentSize,
                              );
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
            const SizedBox(height: 8),
            Text(
              '提示：数字越大，每行显示的组件越多',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 显示位置设置
            Text(
              '显示位置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '选择小组件在屏幕上的对齐方式',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'top',
                  label: Text('顶部显示'),
                  icon: Icon(Icons.vertical_align_top),
                ),
                ButtonSegment<String>(
                  value: 'center',
                  label: Text('居中显示'),
                  icon: Icon(Icons.vertical_align_center),
                ),
              ],
              selected: {_currentAlignment},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _currentAlignment = newSelection.first;
                  widget.layoutManager.setGridAlignment(_currentAlignment);
                });
              },
            ),
          ],
        ),
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
