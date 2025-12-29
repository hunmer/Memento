import 'dart:io';
import 'dart:ui';
import 'package:Memento/core/app_initializer.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/layout_config.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/app_drawer.dart';
import 'package:Memento/core/floating_ball/floating_ball_service.dart';
import 'package:Memento/core/global_flags.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'managers/home_layout_manager.dart';
import 'widgets/home_grid.dart';
import 'widgets/add_widget_dialog.dart';
import 'widgets/create_folder_dialog.dart';
import 'widgets/layout_manager_dialog.dart';
import 'widgets/background_settings_page.dart';
import 'widgets/widget_settings_dialog.dart';

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

  // 编辑模式标志（拖拽排序）
  bool _isEditMode = false;

  // 批量编辑模式标志
  bool _isBatchMode = false;

  // 批量选中的项目ID列表
  final Set<String> _selectedItemIds = {};

  // 是否是首次加载，使用静态变量确保在热重载时保持状态
  static bool _hasInitialized = false;
  // 是否正在打开插件
  bool _isOpeningPlugin = false;
  // 是否已经尝试过打开插件（无论成功与否）
  bool _triedToOpenPlugin = false;

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

  // 是否通过参数启动（如小组件、URL scheme等）
  bool _launchedWithParameters = false;

  @override
  void initState() {
    super.initState();
    _initializeLayout();

    // 监听布局管理器的变化（包括透明度设置）
    _layoutManager.addListener(_onLayoutChanged);

    // 监听启动状态变化
    AppStartupState.instance.addListener(_onStartupStateChanged);

    // 延迟初始化，确保在布局完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 显示悬浮球（如果启用的话）
        FloatingBallService().show(context);
        // 首次加载时打开最后使用的插件（仅在无参数启动且插件已加载时）
        if (!_triedToOpenPlugin && !_launchedWithParameters) {
          _tryOpenLastUsedPlugin();
        }
      }
    });
  }

  /// 尝试打开最后使用的插件（等待插件加载完成）
  void _tryOpenLastUsedPlugin() {
    _triedToOpenPlugin = true;  // 标记为已尝试

    if (AppStartupState.instance.pluginsReady) {
      _openLastUsedPlugin();
    } else {
      // 如果插件还没加载完，会通过 _onStartupStateChanged 监听器处理
    }
  }

  /// 标记为已初始化
  void _markInitialized() {
    _hasInitialized = true;
  }

  /// 启动状态变化回调
  void _onStartupStateChanged() {
    if (mounted) {
      setState(() {});

      // 当插件加载完成时，尝试打开最后使用的插件
      if (AppStartupState.instance.pluginsReady &&
          !_hasInitialized &&
          !_launchedWithParameters &&
          _triedToOpenPlugin) {
        _openLastUsedPlugin();
      }
    }
  }

  @override
  void dispose() {
    _layoutManager.removeListener(_onLayoutChanged);
    AppStartupState.instance.removeListener(_onStartupStateChanged);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 将检查启动参数的逻辑移到这里，确保 context 已完全初始化
    if (!_launchedWithParameters) {
      _checkLaunchParameters();
    }

    // 检查完成后，重置全局标志
    if (isLaunchedFromWidget) {
      isLaunchedFromWidget = false;
    }
  }

  /// 布局管理器变化时的回调（包括透明度设置）
  void _onLayoutChanged() {
    if (mounted) {
      setState(() {
        // 触发界面重新构建，应用新的透明度设置
      });
    }
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
    final registry = HomeWidgetRegistry();
    final allWidgets = registry.getAllWidgets();

    if (allWidgets.isEmpty) {
      debugPrint('没有注册任何小组件,跳过创建默认布局');
      return;
    }

    // 优先创建的插件顺序
    final priorityPlugins = [
      'chat',
      'openai',
      'diary',
      'activity',
      'notes',
      'todo',
      'calendar',
      'bill',
    ];

    // 收集要添加的默认小组件(每个插件选择一个图标组件)
    final defaultWidgets = <HomeWidget>[];

    for (final pluginId in priorityPlugins) {
      final pluginWidgets = registry.getWidgetsByPlugin(pluginId);
      if (pluginWidgets.isEmpty) continue;

      // 优先选择 small 尺寸的图标组件
      final iconWidget = pluginWidgets.firstWhere(
        (w) => w.defaultSize == HomeWidgetSize.small,
        orElse: () => pluginWidgets.first,
      );

      defaultWidgets.add(iconWidget);
    }

    // 如果优先插件都没有,从所有注册的小组件中选择前8个
    if (defaultWidgets.isEmpty) {
      defaultWidgets.addAll(allWidgets.take(8));
    }

    // 创建小组件实例并添加到布局
    for (final widget in defaultWidgets) {
      final item = HomeWidgetItem(
        id: _layoutManager.generateId(),
        widgetId: widget.id,
        size: widget.defaultSize,
        config: {},
      );
      _layoutManager.addItem(item);
    }

    debugPrint('创建了 ${defaultWidgets.length} 个默认小组件');
  }

  /// 检查启动参数，判断是否通过特定方式启动应用
  void _checkLaunchParameters() {
    // 检查是否从小组件启动
    if (isLaunchedFromWidget) {
      _launchedWithParameters = true;
      debugPrint('应用通过桌面小组件启动');
      // 注意：不立即重置标志，在 didChangeDependencies() 中统一重置
      return;
    }

    // 检查路由设置，看是否有参数
    final routeSettings = ModalRoute.of(context)?.settings;

    if (routeSettings != null && routeSettings.arguments != null) {
      // 如果有路由参数，说明是通过特定方式启动的
      _launchedWithParameters = true;
      debugPrint('应用通过路由参数启动: ${routeSettings.arguments}');
      return;
    }

    // 可以在这里添加更多的参数检测逻辑
    // 例如：检查是否通过 Intent、URI Scheme 等方式启动
    // 目前主要检查路由参数，后续可根据需要扩展
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
      _markInitialized();
      _isOpeningPlugin = false;
      return;
    }

    // 检查是否通过参数启动
    if (_launchedWithParameters) {
      _markInitialized();
      _isOpeningPlugin = false;
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

    // 无论是否打开插件，都标记为已初始化
    _markInitialized();
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
    SmoothBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
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
                Toast.info(
                  _isEditMode ? '长按拖拽可调整顺序' : '已退出编辑模式',
                  duration: const Duration(seconds: 1),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box_outline_blank),
              title: const Text('批量编辑'),
              onTap: () {
                Navigator.pop(context);
                _toggleBatchMode();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: Text('screens_createNewFolder'.tr),
              onTap: () {
                Navigator.pop(context);
                _showCreateFolderDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: Text('screens_addWidget'.tr),
              onTap: () {
                Navigator.pop(context);
                _showAddWidgetDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save),
              title: Text('screens_saveCurrentLayout'.tr),
              onTap: () {
                Navigator.pop(context);
                _showSaveLayoutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: Text('screens_manageLayouts'.tr),
              onTap: () {
                Navigator.pop(context);
                _showLayoutManagerDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text('screens_themeSettings'.tr),
              onTap: () {
                Navigator.pop(context);
                _showThemeSettings();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: Text('screens_gridSettings'.tr),
              subtitle: Text(
                '${_layoutManager.gridCrossAxisCount} 列 · ${_layoutManager.gridAlignment == "top" ? 'screens_topDisplay'.tr : 'screens_centerDisplay'.tr}',
              ),
              onTap: () {
                Navigator.pop(context);
                _showGridSizeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: Text('screens_clearLayout'.tr),
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
            title: Text('screens_confirmClear'.tr),
            content: Text('screens_confirmClearAllWidgets'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _layoutManager.clear();
              });
                  Toast.success(
                    'screens_allWidgetsCleared'.tr,
                  );
            },
                child: Text('screens_confirm'.tr),
          ),
        ],
      ),
    );
  }

  /// 快速创建布局
  Future<void> _createQuickLayout(Map<String, String> data) async {
    final name = data['name']!;
    final type = data['type']!;

    try {
      // 清空当前布局
      _layoutManager.clear();

      // 根据选择的类型添加小组件
      if (type == '1x1') {
        await _addAllWidgetsOfSize(HomeWidgetSize.small);
      } else if (type == '2x2') {
        await _addAllWidgetsOfSize(HomeWidgetSize.large);
      }
      // 空白布局不添加任何内容

      // 保存布局
      await _layoutManager.saveCurrentLayoutAs(name);

      Toast.success('布局"$name"已创建');
    } catch (e) {
      Toast.error('创建失败：$e');
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

  /// 显示保存布局对话框
  void _showSaveLayoutDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('screens_saveCurrentLayout'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
                labelText: 'screens_layoutName'.tr,
                hintText: 'screens_layoutNameHint'.tr,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                    Toast.error(
                      'screens_pleaseEnterLayoutName'.tr,
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
                      Toast.success(
                        'screens_layoutSaved'.trParams({'name': name}),
                      );
                }
              } catch (e) {
                if (mounted) {
                      Toast.error(
                        '${'screens_saveFailed'.tr}: $e',
                      );
                }
              }
            },
                child: Text('screens_save'.tr),
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
    await NavigationHelper.push(context, const BackgroundSettingsPage(),
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
    SmoothBottomSheet.show(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item is HomeWidgetItem)
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(
                    'screens_widgetSettings'.tr,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showWidgetSettings(item);
                  },
                ),
              if (item is HomeWidgetItem)
                ListTile(
                  leading: const Icon(Icons.aspect_ratio),
                  title: Text('screens_adjustSize'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _showSizeAdjuster(item);
                  },
                ),
              if (item is HomeWidgetItem && _isSelectorWidget(item))
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: Text('screens_reselectData'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _reselectWidgetData(item);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'screens_delete'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteItem(item);
                },
              ),
            ],
          ),
    );
  }

  /// 检查小组件是否为选择器小组件
  bool _isSelectorWidget(HomeWidgetItem item) {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);
    return widget?.selectorId != null;
  }

  /// 重新选择小组件数据
  void _reselectWidgetData(HomeWidgetItem item) async {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null || widget.selectorId == null) {
      Toast.error('未找到小组件定义');
      return;
    }

    // 先删除已有的选择器配置，让组件变为"未配置"状态
    final updatedConfig = Map<String, dynamic>.from(item.config);
    updatedConfig.remove('selectorWidgetConfig');
    // 删除选择器可能产生的其他配置字段（如 bill 插件的 accountId、periodLabel 等）
    final keysToRemove = widget.dataSelector != null ? _getSelectorDataKeys(widget) : [];
    for (final key in keysToRemove) {
      updatedConfig.remove(key);
    }
    final clearedItem = item.copyWith(config: updatedConfig);
    _layoutManager.updateItem(item.id, clearedItem);

    // 显示数据选择器
    final result = await pluginDataSelectorService.showSelector(
      context,
      widget.selectorId!,
    );

    if (result == null || result.cancelled) {
      // 如果取消，恢复原来的配置
      _layoutManager.updateItem(item.id, item);
      return;
    }

    // 处理选择结果并保存
    final newConfig = _processSelectorResult(widget, result);
    final finalConfig = Map<String, dynamic>.from(item.config);
    finalConfig.addAll(newConfig);

    final finalItem = item.copyWith(config: finalConfig);
    _layoutManager.updateItem(item.id, finalItem);
    await _layoutManager.saveLayout();
    setState(() {});

    Toast.success('数据已更新');
  }

  /// 获取选择器可能产生的配置字段名
  List<String> _getSelectorDataKeys(HomeWidget widget) {
    // 这些是常见的选择器数据字段，具体取决于 dataSelector 的实现
    // bill 插件: accountId, accountTitle, accountIcon, periodId, periodLabel, periodStart, periodEnd
    return ['accountId', 'accountTitle', 'accountIcon', 'periodId', 'periodLabel', 'periodStart', 'periodEnd'];
  }

  /// 处理选择器结果，生成新的配置
  Map<String, dynamic> _processSelectorResult(HomeWidget widget, SelectorResult result) {
    // 将 SelectorResult 保存为 SelectorWidgetConfig
    final selectorConfig = SelectorWidgetConfig.fromSelectorResult(result);

    final newConfig = <String, dynamic>{
      'selectorWidgetConfig': selectorConfig.toJson(),
    };

    // 如果有 dataSelector，也执行它来处理数据
    if (widget.dataSelector != null && result.data is List) {
      final dataArray = result.data as List<dynamic>;
      final extractedData = widget.dataSelector!(dataArray);
      newConfig.addAll(extractedData);
    }

    return newConfig;
  }

  /// 显示小组件设置对话框
  void _showWidgetSettings(HomeWidgetItem item) async {
    // 导入所需的类
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null) {
      Toast.error('未找到小组件定义');
      return;
    }

    // 检查是否提供了统计项
    if (widget.availableStatsProvider == null) {
      Toast.warning('该小组件不支持自定义设置');
      return;
    }

    // 获取可用的统计项
    final availableItems = widget.availableStatsProvider!(context);

    if (availableItems.isEmpty) {
      Toast.warning('该小组件没有可配置的项目');
      return;
    }

    // 从 config 解析现有配置
    PluginWidgetConfig currentConfig;
    try {
      if (item.config.containsKey('pluginWidgetConfig')) {
        currentConfig = PluginWidgetConfig.fromJson(
          item.config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        currentConfig = PluginWidgetConfig();
      }
    } catch (e) {
      currentConfig = PluginWidgetConfig();
    }

    // 显示设置对话框
    final result = await showDialog<PluginWidgetConfig>(
      context: context,
      builder:
          (context) => WidgetSettingsDialog(
            initialConfig: currentConfig,
            availableItems: availableItems,
          ),
    );

    if (result != null) {
      // 更新配置
      final updatedConfig = Map<String, dynamic>.from(item.config);
      updatedConfig['pluginWidgetConfig'] = result.toJson();

      debugPrint('[Home Screen] 保存配置：');
      debugPrint('[Home Screen] - widgetId: ${item.widgetId}');
      debugPrint('[Home Screen] - displayStyle: ${result.displayStyle}');
      debugPrint('[Home Screen] - config JSON: ${result.toJson()}');
      debugPrint('[Home Screen] - updatedConfig: $updatedConfig');

      final updatedItem = item.copyWith(config: updatedConfig);

      // 保存到布局
      _layoutManager.updateItem(item.id, updatedItem);
      await _layoutManager.saveLayout();
      setState(() {});

      Toast.success('设置已保存');
    }
  }

  /// 显示大小调整器
  void _showSizeAdjuster(HomeWidgetItem item) {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);

    if (widget == null) {
      Toast.error('未找到小组件定义');
      return;
    }

    final supportedSizes = widget.supportedSizes;

    if (supportedSizes.length <= 1) {
      Toast.warning('该小组件不支持调整大小');
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('screens_selectWidgetSize'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  supportedSizes.map((size) {
                    final isSelected = size == item.size;
                    final sizeLabel = _getSizeLabel(size);

                    return RadioListTile<HomeWidgetSize>(
                      title: Text(sizeLabel),
                      subtitle: Text(
                        'screens_widgetSize'.trParams({
                          'width': size.width.toString(),
                          'height': size.height.toString(),
                        }),
                      ),
                      value: size,
                      groupValue: item.size,
                      selected: isSelected,
                      onChanged: (HomeWidgetSize? newSize) {
                        if (newSize != null) {
                          Navigator.pop(context);
                          _saveWidgetSize(item, newSize);
                        }
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
              ),
            ],
          ),
    );
  }

  /// 获取尺寸标签
  String _getSizeLabel(HomeWidgetSize size) {
    switch (size) {
      case HomeWidgetSize.small:
        return 'screens_smallSize'.tr;
      case HomeWidgetSize.medium:
        return 'screens_mediumSize'.tr;
      case HomeWidgetSize.large:
        return 'screens_largeSize'.tr;
      case HomeWidgetSize.large3:
        return 'screens_large3Size'.tr;
      case HomeWidgetSize.wide:
        return 'screens_wideSize'.tr;
      case HomeWidgetSize.wide2:
        return 'screens_wide2Size'.tr;
      case HomeWidgetSize.wide3:
        return 'screens_wide3Size'.tr;
    }
  }

  /// 保存组件大小
  Future<void> _saveWidgetSize(
    HomeWidgetItem item,
    HomeWidgetSize newSize,
  ) async {
    final updatedItem = item.copyWith(size: newSize);

    _layoutManager.updateItem(item.id, updatedItem);
    await _layoutManager.saveLayout();
    setState(() {});
    ToastService.instance.showToast('组件大小已更新');
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
            title: Text('screens_confirmDelete'.tr),
            content: Text(
              'screens_confirmDeleteItem'.trParams({'itemName': itemName}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _layoutManager.removeItem(item.id);
                  ToastService.instance.showToast(
                    '"$itemName" ${'screens_deleted'.tr}',
                  );
                },
                child: Text(
                  'screens_delete'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  /// 切换批量编辑模式
  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      if (!_isBatchMode) {
        _selectedItemIds.clear();
      }
      // 退出拖拽编辑模式
      if (_isBatchMode) {
        _isEditMode = false;
      }
    });
  }

  /// 退出批量编辑模式
  void _exitBatchMode() {
    setState(() {
      _isBatchMode = false;
      _selectedItemIds.clear();
    });
  }

  /// 切换项目选中状态
  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  /// 批量删除
  void _confirmBatchDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('screens_confirmDelete'.tr),
            content: Text(
              'screens_confirmDeleteSelectedItems'.trParams({
                'count': _selectedItemIds.length.toString(),
              }),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 删除所有选中的项目
              for (final itemId in _selectedItemIds) {
                _layoutManager.removeItem(itemId);
              }
                  Toast.success(
                    'screens_itemsDeleted'.trParams({
                      'count': _selectedItemIds.length.toString(),
                    }),
                  );
              _exitBatchMode();
            },
                child: Text(
                  'screens_delete'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
          ),
        ],
      ),
    );
  }

  /// 显示移动到文件夹对话框
  void _showMoveToFolderDialog() {
    // 获取所有文件夹
    final folders = _layoutManager.items
        .whereType<HomeFolderItem>()
        .where((folder) => !_selectedItemIds.contains(folder.id))
        .toList();

    if (folders.isEmpty) {
      Toast.warning('screens_noAvailableFolders'.tr);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text('screens_moveToFolder'.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: Icon(folder.icon, color: folder.color),
                title: Text(folder.name),
                    subtitle: Text(
                      'screens_itemCount'.trParams({
                        'count': folder.children.length.toString(),
                      }),
                    ),
                onTap: () {
                  Navigator.pop(context);
                  _moveSelectedItemsToFolder(folder.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                child: Text('screens_cancel'.tr),
          ),
        ],
      ),
    );
  }

  /// 将选中的项目移动到文件夹
  void _moveSelectedItemsToFolder(String folderId) {
    for (final itemId in _selectedItemIds) {
      _layoutManager.moveToFolder(itemId, folderId);
    }
    Toast.success(
      'screens_itemsMovedToFolder'.trParams({
        'count': _selectedItemIds.length.toString(),
      }),
    );
    _exitBatchMode();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEditMode, // 编辑模式下不允许直接返回
      onPopInvokedWithResult: (didPop, result) {
        // 如果处于编辑模式，先退出编辑模式
        if (_isEditMode && !didPop) {
          setState(() {
            _isEditMode = false;
          });
          Toast.info(
            '已退出编辑模式',
            duration: const Duration(seconds: 1),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          _currentLayoutName.isEmpty
              ? 'app_home'.tr
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
          // 批量编辑模式下的操作按钮
          if (_isBatchMode) ...[
            if (_selectedItemIds.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.drive_file_move),
                onPressed: _showMoveToFolderDialog,
                tooltip: '移动到',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _confirmBatchDelete,
                tooltip: '删除',
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitBatchMode,
              tooltip: '退出选择',
            ),
          ] else ...[
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
              isBatchMode: _isBatchMode,
              selectedItemIds: _selectedItemIds,
              alignment: alignment,
              onReorder: (oldIndex, newIndex) {
                _layoutManager.reorder(oldIndex, newIndex);
              },
              onAddToFolder: (itemId, folderId) {
                _layoutManager.moveToFolder(itemId, folderId);
                Toast.success('已添加到文件夹');
              },
              onItemTap: _isBatchMode
                  ? (item) => _toggleItemSelection(item.id)
                  : null,
              onItemLongPress: _handleCardLongPress,
              onQuickCreateLayout: _createQuickLayout,
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
        Toast.error('切换布局失败：$e');
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
      title: Text('screens_gridSettings'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 网格大小设置
            Text(
              'screens_gridSize'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'screens_gridSizeDescription'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'screens_gridColumns'.trParams({
                    'count': _currentSize.toString(),
                  }),
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
              'screens_displayPosition'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'screens_displayPositionDescription'.tr,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment<String>(
                  value: 'top',
                  label: Text('screens_topDisplay'.tr),
                  icon: const Icon(Icons.vertical_align_top),
                ),
                ButtonSegment<String>(
                  value: 'center',
                  label: Text('screens_centerDisplay'.tr),
                  icon: const Icon(Icons.vertical_align_center),
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
          child: Text('screens_complete'.tr),
        ),
      ],
    );
  }
}
