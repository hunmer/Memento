import 'dart:async';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/event/event.dart';
import 'package:Memento/core/global_flags.dart';
import 'package:flutter/material.dart';
import 'managers/home_layout_manager.dart';
import 'managers/home_widget_registry.dart';
import 'models/home_folder_item.dart';
import 'models/home_item.dart';
import 'models/home_widget_item.dart';
import 'models/home_stack_item.dart';
import 'models/home_widget_size.dart';
import 'models/layout_config.dart';

/// 主屏幕控制器 - 负责状态管理和业务逻辑
class HomeScreenController extends ChangeNotifier {
  final HomeLayoutManager _layoutManager = HomeLayoutManager();
  bool _isLoading = true;

  // 编辑模式标志（拖拽排序）
  bool _isEditMode = false;

  // 批量编辑模式标志
  bool _isBatchMode = false;

  // 批量选中的项目ID列表
  final Set<String> _selectedItemIds = {};
  String? _draggingLayoutId;
  String? _draggingItemId;
  HomeItem? _draggingItemSnapshot;

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

  // TabBarView 控制器
  TabController? _tabController;

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

  // 记录已加载过的布局ID，避免重复加载
  final Set<String> _loadedLayoutIds = {};

  // 缓存每个布局的 items，避免切换 tab 时重复加载
  final Map<String, List<HomeItem>> _layoutItemsCache = {};

  // 缓存每个布局的结构（用于骨架屏），避免重复加载
  final Map<String, ({List<HomeWidgetSize> structure, int crossAxisCount})>
  _layoutStructureCache = {};

  // UI 状态变化回调
  VoidCallback? _stateChangedCallback;

  // Getters
  HomeLayoutManager get layoutManager => _layoutManager;
  bool get isLoading => _isLoading;
  bool get isEditMode => _isEditMode;
  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedItemIds => _selectedItemIds;
  bool get isDraggingItem => _draggingItemId != null;
  String get currentLayoutName => _currentLayoutName;
  List<LayoutConfig> get savedLayouts => _savedLayouts;
  PageController? get pageController => _pageController;
  TabController? get tabController => _tabController;
  int get currentPageIndex => _currentPageIndex;
  String? get currentBackgroundPath => _currentBackgroundPath;
  BoxFit get currentBackgroundFit => _currentBackgroundFit;
  double get currentBackgroundBlur => _currentBackgroundBlur;
  double get globalWidgetOpacity => _globalWidgetOpacity;
  bool get launchedWithParameters => _launchedWithParameters;
  bool get triedToOpenPlugin => _triedToOpenPlugin;

  /// 获取指定布局的 items（从缓存或当前 layoutManager）
  List<HomeItem> getItemsForLayout(String layoutId) {
    if (_currentLayoutId == layoutId) {
      return _layoutManager.items;
    }
    if (_layoutItemsCache.containsKey(layoutId)) {
      return _layoutItemsCache[layoutId]!;
    }
    return [];
  }

  /// 初始化
  VoidCallback? _layoutChangedListener;

  void init(VoidCallback onStateChanged) {
    _stateChangedCallback = onStateChanged;
    initializeLayout();
    // 创建包装器，先同步缓存再通知 UI
    _layoutChangedListener = () {
      onLayoutChanged(onStateChanged);
    };
    _layoutManager.addListener(_layoutChangedListener!);
    AppStartupState.instance.addListener(onStateChanged);
  }

  /// 标记为已初始化
  void markInitialized() {
    _hasInitialized = true;
  }

  /// 布局管理器变化时的回调
  void onLayoutChanged(VoidCallback onStateChanged) {
    // 同步更新当前布局的缓存
    if (_currentPageIndex < _savedLayouts.length) {
      final currentLayoutId = _savedLayouts[_currentPageIndex].id;
      _layoutItemsCache[currentLayoutId] = List<HomeItem>.from(_layoutManager.items);
    }
    onStateChanged();
  }

  /// 获取当前布局的结构（用于骨架屏占位）
  /// 只保留尺寸信息，不保留实际内容
  List<HomeWidgetSize> getCurrentLayoutStructure() {
    return _layoutManager.items.map((item) {
      if (item is HomeWidgetItem) {
        if (item.size == HomeWidgetSize.custom) {
          return HomeWidgetSize.custom;
        }
        return item.size;
      } else if (item is HomeStackItem) {
        return item.size;
      } else if (item is HomeFolderItem) {
        return HomeWidgetSize.small;
      }
      return HomeWidgetSize.small;
    }).toList();
  }

  /// 获取指定布局的结构（用于骨架屏占位）
  /// 直接读取配置，不修改当前状态
  Future<({List<HomeWidgetSize> structure, int crossAxisCount})> getLayoutStructureById(String layoutId) async {
    // 检查缓存
    if (_layoutStructureCache.containsKey(layoutId)) {
      return _layoutStructureCache[layoutId]!;
    }

    try {
      // 直接读取目标布局配置，不修改当前状态
      final config = await _layoutManager.readLayoutConfig(layoutId);
      if (config == null) {
        debugPrint('getLayoutStructureById: $layoutId, config is null');
        return (structure: <HomeWidgetSize>[], crossAxisCount: 4);
      }

      debugPrint('getLayoutStructureById: $layoutId, config.name=${config.name}, itemsCount=${config.items.length}');

      // 解析结构
      final structure = config.items.map((json) {
        final type = json['type'] ?? 'unknown';
        final item = HomeItem.fromJson(json);
        final HomeWidgetSize size;
        if (item is HomeWidgetItem) {
          size = item.size;
        } else if (item is HomeStackItem) {
          size = item.size;
        } else if (item is HomeFolderItem) {
          size = HomeWidgetSize.small;
        } else {
          size = HomeWidgetSize.small;
        }
        debugPrint('  item: type=$type, size=$size');
        return size;
      }).toList();

      final targetCrossAxisCount = config.gridCrossAxisCount;

      final result = (
        structure: structure,
        crossAxisCount: targetCrossAxisCount,
      );

      // 缓存结果
      _layoutStructureCache[layoutId] = result;

      debugPrint('getLayoutStructureById result: $layoutId, structure: ${structure.length}, crossAxisCount: $targetCrossAxisCount');
      return result;
    } catch (e) {
      debugPrint('获取布局结构失败: $e');
      return (structure: <HomeWidgetSize>[], crossAxisCount: 4);
    }
  }

  /// 初始化布局
  Future<void> initializeLayout() async {
    try {
      await _layoutManager.initialize();
      await _loadSavedLayouts();
      if (_savedLayouts.isNotEmpty) {
        final currentConfig = await _layoutManager.getCurrentLayoutConfig();
        if (currentConfig != null) {
          await _layoutManager.loadLayoutConfig(currentConfig.id);
          _loadedLayoutIds.add(currentConfig.id);
          // 缓存当前布局的 items
          _layoutItemsCache[currentConfig.id] = List<HomeItem>.from(_layoutManager.items);
        }
      }
      // if (_layoutManager.items.isEmpty) {
      //   await _createDefaultWidgets();
      // }
      await _updateCurrentLayoutName();
      await loadCurrentBackground();
    } catch (e) {
      debugPrint('初始化布局失败: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// 加载所有保存的布局
  Future<void> _loadSavedLayouts() async {
    try {
      final layouts = await _layoutManager.getSavedLayouts();
      final currentConfig = await _layoutManager.getCurrentLayoutConfig();
      _savedLayouts = layouts;

      // 清除已删除布局的缓存
      final validLayoutIds = layouts.map((l) => l.id).toSet();
      _layoutItemsCache.removeWhere(
        (layoutId, _) => !validLayoutIds.contains(layoutId),
      );
      _layoutStructureCache.removeWhere(
        (layoutId, _) => !validLayoutIds.contains(layoutId),
      );
      _loadedLayoutIds.removeWhere(
        (layoutId) => !validLayoutIds.contains(layoutId),
      );

      if (layouts.isNotEmpty && currentConfig != null) {
        _currentPageIndex = layouts.indexWhere(
          (layout) => layout.id == currentConfig.id,
        );
        if (_currentPageIndex == -1) _currentPageIndex = 0;
        _pageController = PageController(initialPage: _currentPageIndex);
        // TabController 由 View 层创建（需要 TickerProvider）
      }
    } catch (e) {
      debugPrint('加载保存的布局失败: $e');
    }
  }

  /// 重新加载布局列表（供外部调用）
  Future<void> reloadLayouts() async {
    // 保存当前布局 ID
    final oldLayoutId = _currentPageIndex < _savedLayouts.length
        ? _savedLayouts[_currentPageIndex].id
        : null;

    await _loadSavedLayouts();

    // 检查当前布局是否还存在
    final bool currentLayoutExists = oldLayoutId != null &&
        _savedLayouts.any((layout) => layout.id == oldLayoutId);

    if (_savedLayouts.isEmpty) {
      // 没有布局了，重置 index
      _currentPageIndex = 0;
      _currentLayoutName = '';
    } else if (!currentLayoutExists || _currentPageIndex >= _savedLayouts.length) {
      // 当前布局被删除或 index 越界，切换到第一个布局
      _currentPageIndex = 0;
      final layout = _savedLayouts[_currentPageIndex];
      _currentLayoutName = layout.name;
      await _layoutManager.loadLayoutConfig(layout.id);
      _layoutItemsCache[layout.id] = List<HomeItem>.from(_layoutManager.items);
      await loadCurrentBackground();
    } else {
      // 当前布局仍存在，重新加载以确保数据同步
      final layout = _savedLayouts[_currentPageIndex];
      await _layoutManager.loadLayoutConfig(layout.id);
      _layoutItemsCache[layout.id] = List<HomeItem>.from(_layoutManager.items);
    }

    // 通知监听器更新 UI
    notifyListeners();
  }

  /// 切换到最后一个布局（用于新建布局后）
  Future<void> switchToLastLayout() async {
    if (_savedLayouts.isEmpty) return;

    await _loadSavedLayouts();

    // 切换到最后一个布局
    _currentPageIndex = _savedLayouts.length - 1;
    final layout = _savedLayouts[_currentPageIndex];
    _currentLayoutName = layout.name;
    await _layoutManager.loadLayoutConfig(layout.id);
    _layoutItemsCache[layout.id] = List<HomeItem>.from(_layoutManager.items);
    await loadCurrentBackground();

    // 通知监听器更新 UI
    notifyListeners();
  }

  /// 更新当前布局名称
  Future<void> _updateCurrentLayoutName() async {
    try {
      final currentConfig = await _layoutManager.getCurrentLayoutConfig();
      _currentLayoutName = currentConfig?.name ?? '';
    } catch (e) {
      debugPrint('获取当前布局名称失败: $e');
    }
  }

  /// 加载当前背景图配置
  Future<void> loadCurrentBackground() async {
    try {
      final globalConfig = await _layoutManager.getGlobalBackgroundConfig();
      String? backgroundPath = globalConfig['backgroundImagePath'] as String?;
      BoxFit backgroundFit = LayoutConfig.boxFitFromString(
        globalConfig['backgroundFit'] as String?,
      );
      double backgroundBlur = (globalConfig['backgroundBlur'] as num?)?.toDouble() ?? 0.0;
      double widgetOpacity = (globalConfig['widgetOpacity'] as num?)?.toDouble() ?? 1.0;

      final currentConfig = await _layoutManager.getCurrentLayoutConfig();
      if (currentConfig?.backgroundImagePath != null) {
        backgroundPath = currentConfig!.backgroundImagePath;
        backgroundFit = currentConfig.backgroundFit;
        backgroundBlur = currentConfig.backgroundBlur;
      }

      _currentBackgroundPath = backgroundPath;
      _currentBackgroundFit = backgroundFit;
      _currentBackgroundBlur = backgroundBlur;
      _globalWidgetOpacity = widgetOpacity;
      debugPrint('背景图加载完成: path=$backgroundPath, opacity=$widgetOpacity');
    } catch (e) {
      debugPrint('加载背景图失败: $e');
    }
  }

  /// 创建默认小组件
  Future<void> _createDefaultWidgets() async {
    final registry = HomeWidgetRegistry();
    final allWidgets = registry.getAllWidgets();
    if (allWidgets.isEmpty) {
      debugPrint('没有注册任何小组件,跳过创建默认布局');
      return;
    }

    final priorityPlugins = ['chat', 'openai', 'diary', 'activity', 'notes', 'todo', 'calendar', 'bill'];
    final defaultWidgets = <dynamic>[];

    for (final pluginId in priorityPlugins) {
      final pluginWidgets = registry.getWidgetsByPlugin(pluginId);
      if (pluginWidgets.isEmpty) continue;
      final iconWidget = pluginWidgets.firstWhere(
        (w) => w.defaultSize == HomeWidgetSize.small,
        orElse: () => pluginWidgets.first,
      );
      defaultWidgets.add(iconWidget);
    }

    if (defaultWidgets.isEmpty) {
      defaultWidgets.addAll(allWidgets.take(8));
    }

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

  /// 检查启动参数
  void checkLaunchParameters() {
    if (isLaunchedFromWidget) {
      _launchedWithParameters = true;
      debugPrint('应用通过桌面小组件启动');
      isLaunchedFromWidget = false;
      return;
    }

    // 路由参数检查在 didChangeDependencies 中处理
  }

  /// 设置启动参数状态
  void setLaunchedWithParameters(bool value) {
    _launchedWithParameters = value;
  }

  /// 尝试打开最后使用的插件
  void tryOpenLastUsedPlugin(BuildContext context) {
    _triedToOpenPlugin = true;

    // 获取最后打开的插件ID
    final lastOpenedPluginId = globalPluginManager.getLastOpenedPluginId;
    if (lastOpenedPluginId == null) {
      // 没有最后打开的插件记录
      return;
    }

    // 检查插件是否已加载
    final lastPlugin = globalPluginManager.getPlugin(lastOpenedPluginId);
    if (lastPlugin != null) {
      // 插件已加载，直接打开
      openLastUsedPlugin(context);
    } else {
      // 插件还未加载，使用 once 监听 plugin_loaded 事件
      eventManager.once('plugin_loaded', (args) {
        if (args is Value<String> && args.value == lastOpenedPluginId) {
          // 是等待的插件，打开它
          if (context.mounted) {
            openLastUsedPlugin(context);
          }
        }
      });
    }
  }

  /// 打开最后使用的插件
  void openLastUsedPlugin(BuildContext context) {
    if (_isOpeningPlugin) return;
    _isOpeningPlugin = true;

    if (!globalPluginManager.autoOpenLastPlugin) {
      _markInitialized();
      _isOpeningPlugin = false;
      return;
    }

    if (_launchedWithParameters) {
      _markInitialized();
      _isOpeningPlugin = false;
      return;
    }

    final lastPlugin = globalPluginManager.getLastOpenedPlugin();
    if (lastPlugin != null) {
      globalPluginManager.openPlugin(context, lastPlugin);
    }

    _markInitialized();
    _isOpeningPlugin = false;
  }

  void _markInitialized() {
    _hasInitialized = true;
  }

  /// 切换编辑模式
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    _stateChangedCallback?.call();
  }

  /// 切换批量编辑模式
  void toggleBatchMode() {
    _isBatchMode = !_isBatchMode;
    if (!_isBatchMode) {
      _selectedItemIds.clear();
    }
    if (_isBatchMode) {
      _isEditMode = false;
    }
    _stateChangedCallback?.call();
  }

  /// 退出批量编辑模式
  void exitBatchMode() {
    _isBatchMode = false;
    _selectedItemIds.clear();
    _stateChangedCallback?.call();
  }

  /// 切换项目选中状态
  void toggleItemSelection(String itemId) {
    if (_selectedItemIds.contains(itemId)) {
      _selectedItemIds.remove(itemId);
    } else {
      _selectedItemIds.add(itemId);
    }
    _stateChangedCallback?.call();
  }

  void handleDragStart(String layoutId, HomeItem item) {
    _draggingLayoutId = layoutId;
    _draggingItemId = item.id;
    _draggingItemSnapshot = item;
    debugPrint('HomeScreenController.handleDragStart -> layout=$layoutId, item=${item.id}');
  }

  void handleDragEnded() {
    if (_draggingItemId != null) {
      debugPrint('HomeScreenController.handleDragEnded -> cleared drag state');
    }
    _draggingLayoutId = null;
    _draggingItemId = null;
    _draggingItemSnapshot = null;
  }

  /// 页面切换回调
  void onPageChanged(int index, VoidCallback onStateChanged) async {
    if (index < 0 || index >= _savedLayouts.length) return;

    // 保存当前布局到缓存（如果有内容）
    final currentLayoutId = _currentPageIndex < _savedLayouts.length
        ? _savedLayouts[_currentPageIndex].id
        : null;
    if (currentLayoutId != null && _layoutManager.items.isNotEmpty) {
      _layoutItemsCache[currentLayoutId] = List<HomeItem>.from(_layoutManager.items);
    }

    final layout = _savedLayouts[index];
    final isFirstLoad = !_loadedLayoutIds.contains(layout.id);
    final hasCache = _layoutItemsCache.containsKey(layout.id);

    _currentPageIndex = index;
    _currentLayoutName = layout.name;

    try {
      // 如果有缓存，直接使用缓存数据
      if (hasCache) {
        _layoutManager.setItems(_layoutItemsCache[layout.id]!);
        // 清除结构缓存，确保使用最新的布局数据
        _layoutStructureCache.remove(layout.id);
        onStateChanged();
        return;
      }

      // 加载布局配置
      await _layoutManager.loadLayoutConfig(layout.id);

      // 缓存加载的数据
      _layoutItemsCache[layout.id] = List<HomeItem>.from(_layoutManager.items);

      // 清除结构缓存，确保使用最新的布局数据
      _layoutStructureCache.remove(layout.id);

      // 仅在首次加载时保存活动布局ID和加载背景图
      if (isFirstLoad) {
        await _layoutManager.setActiveLayout(layout.id);
        await loadCurrentBackground();
        _loadedLayoutIds.add(layout.id);
      }

      onStateChanged();
    } catch (e) {
      debugPrint('切换布局失败: $e');
    }
  }

  /// 处理卡片长按事件 - 返回操作菜单数据
  List<dynamic> getCardMenuItems(HomeItem item) {
    final items = <dynamic>[];
    if (item is HomeWidgetItem) {
      items.add({'type': 'settings'});
      items.add({'type': 'size'});
      if (isSelectorWidget(item)) {
        items.add({'type': 'reselect'});
      }
    }
    items.add({'type': 'divider'});
    items.add({'type': 'delete', 'item': item});
    return items;
  }

  /// 检查是否为选择器小组件
  bool isSelectorWidget(HomeWidgetItem item) {
    final registry = HomeWidgetRegistry();
    final widget = registry.getWidget(item.widgetId);
    return widget?.selectorId != null;
  }

  /// 确认删除项目
  String getDeleteConfirmMessage(HomeItem item) {
    final itemName = item is HomeWidgetItem
        ? HomeWidgetRegistry().getWidget(item.widgetId)?.name ?? '组件'
        : (item as HomeFolderItem).name;
    return '确定要删除 "$itemName" 吗？';
  }

  /// 清理资源
  void cleanup(VoidCallback onStateChanged) {
    if (_layoutChangedListener != null) {
      _layoutManager.removeListener(_layoutChangedListener!);
    }
    AppStartupState.instance.removeListener(onStateChanged);
    _pageController?.dispose();
    _tabController?.dispose();
  }

  // ==================== 拖拽跨布局 ====================

  Future<bool> moveDraggedItemToLayout(String draggedItemId, String targetLayoutId, int targetIndex) async {
    final sourceLayoutId = _draggingLayoutId;
    final activeDraggedId = _draggingItemId;
    if (sourceLayoutId == null || activeDraggedId == null) {
      debugPrint('moveDraggedItemToLayout -> skip, no active drag');
      return false;
    }
    if (sourceLayoutId == targetLayoutId) {
      debugPrint('moveDraggedItemToLayout -> skip, same layout');
      return false;
    }
    if (activeDraggedId != draggedItemId) {
      debugPrint('moveDraggedItemToLayout -> mismatch drag id');
      return false;
    }

    final removedItem = await _removeItemFromLayout(sourceLayoutId, activeDraggedId) ?? _draggingItemSnapshot;
    if (removedItem == null) {
      debugPrint('moveDraggedItemToLayout -> failed, cannot locate source item');
      return false;
    }

    final inserted = await _insertItemIntoLayout(targetLayoutId, removedItem, targetIndex);
    if (!inserted) {
      await _insertItemIntoLayout(sourceLayoutId, removedItem, 0);
      return false;
    }

    await _persistLayouts({sourceLayoutId, targetLayoutId});
    return true;
  }

  Future<HomeItem?> _removeItemFromLayout(String layoutId, String itemId) async {
    if (_isActiveLayout(layoutId)) {
      final index = _layoutManager.items.indexWhere((element) => element.id == itemId);
      if (index == -1) {
        return null;
      }
      final item = _layoutManager.items[index];
      _layoutManager.removeItemAt(index);
      return item;
    }

    final items = await _getOrLoadLayoutItems(layoutId);
    final index = items.indexWhere((element) => element.id == itemId);
    if (index == -1) {
      return null;
    }
    final item = items.removeAt(index);
    _layoutItemsCache[layoutId] = items;
    return item;
  }

  Future<bool> _insertItemIntoLayout(String layoutId, HomeItem item, int targetIndex) async {
    if (_isActiveLayout(layoutId)) {
      final maxIndex = _layoutManager.items.length;
      final clampedIndex = targetIndex < 0
          ? 0
          : targetIndex > maxIndex
              ? maxIndex
              : targetIndex;
      _layoutManager.insertItem(clampedIndex, item);
      return true;
    }

    final items = await _getOrLoadLayoutItems(layoutId);
    final maxIndex = items.length;
    final clampedIndex = targetIndex < 0
        ? 0
        : targetIndex > maxIndex
            ? maxIndex
            : targetIndex;
    items.insert(clampedIndex, item);
    _layoutItemsCache[layoutId] = items;
    return true;
  }

  Future<List<HomeItem>> _getOrLoadLayoutItems(String layoutId) async {
    final cached = _layoutItemsCache[layoutId];
    if (cached != null) {
      return cached;
    }

    LayoutConfig? config;
    try {
      config = _savedLayouts.firstWhere((layout) => layout.id == layoutId);
    } catch (_) {
      config = await _layoutManager.readLayoutConfig(layoutId);
    }

    if (config == null) {
      _layoutItemsCache[layoutId] = <HomeItem>[];
      return _layoutItemsCache[layoutId]!;
    }

    final items = config.items.map((json) => HomeItem.fromJson(json)).toList();
    _layoutItemsCache[layoutId] = items;
    return items;
  }

  Future<void> _persistLayouts(Set<String> layoutIds) async {
    if (layoutIds.isEmpty) {
      return;
    }
    bool changed = false;
    final updatedLayouts = List<LayoutConfig>.from(_savedLayouts);
    for (var i = 0; i < updatedLayouts.length; i++) {
      final layout = updatedLayouts[i];
      if (!layoutIds.contains(layout.id)) {
        continue;
      }
      final snapshot = await _getItemsSnapshot(layout.id);
      if (snapshot == null) {
        continue;
      }
      updatedLayouts[i] = layout.copyWith(
        items: snapshot.map((item) => item.toJson()).toList(),
        updatedAt: DateTime.now(),
      );
      changed = true;
    }
    if (changed) {
      _savedLayouts = updatedLayouts;
      await _layoutManager.saveLayoutConfigs(_savedLayouts);
    }
  }

  Future<List<HomeItem>?> _getItemsSnapshot(String layoutId) async {
    if (_isActiveLayout(layoutId)) {
      return List<HomeItem>.from(_layoutManager.items);
    }
    if (_layoutItemsCache.containsKey(layoutId)) {
      return List<HomeItem>.from(_layoutItemsCache[layoutId]!);
    }
    final loaded = await _getOrLoadLayoutItems(layoutId);
    return List<HomeItem>.from(loaded);
  }

  bool _isActiveLayout(String layoutId) {
    final current = _currentLayoutId;
    return current != null && current == layoutId;
  }

  String? get _currentLayoutId {
    if (_savedLayouts.isEmpty || _currentPageIndex >= _savedLayouts.length) {
      return null;
    }
    return _savedLayouts[_currentPageIndex].id;
  }
}
