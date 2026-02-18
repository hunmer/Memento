import 'dart:async';
import 'package:Memento/core/app_initializer.dart';
import 'package:flutter/foundation.dart';
import 'package:Memento/screens/home_screen/models/home_item.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/models/home_folder_item.dart';
import 'package:Memento/screens/home_screen/models/home_stack_item.dart';
import 'package:Memento/screens/home_screen/models/layout_config.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 主页布局管理器
///
/// 管理主页上的所有项目（小组件和文件夹）的布局和配置
/// 提供增删改查、拖拽排序、文件夹管理等功能
class HomeLayoutManager extends ChangeNotifier {
  // 单例模式
  static final HomeLayoutManager _instance = HomeLayoutManager._internal();
  factory HomeLayoutManager() => _instance;
  HomeLayoutManager._internal();

  /// 主页项目列表
  List<HomeItem> _items = [];
  List<HomeItem> get items => List.unmodifiable(_items);

  /// 网格列数（默认为4）
  int _gridCrossAxisCount = 4;
  int get gridCrossAxisCount => _gridCrossAxisCount;

  /// 网格显示位置（'top' 顶部显示, 'center' 居中显示）
  String _gridAlignment = 'top';
  String get gridAlignment => _gridAlignment;

  /// 全局小组件透明度（0.0-1.0，默认1.0不透明）
  /// 影响整个小组件包括文字内容
  double _globalWidgetOpacity = 1.0;
  double get globalWidgetOpacity => _globalWidgetOpacity;

  /// 全局小组件背景颜色透明度（0.0-1.0，默认1.0不透明）
  /// 仅影响背景颜色，不影响文字内容
  double _globalWidgetBackgroundOpacity = 1.0;
  double get globalWidgetBackgroundOpacity => _globalWidgetBackgroundOpacity;

  /// 配置键名
  static const String _configKey = 'home_layout';

  /// 布局配置列表的键名
  static const String _layoutConfigsKey = 'home_layout_configs';

  /// 当前活动的布局配置ID
  static const String _activeLayoutIdKey = 'home_active_layout_id';

  /// 全局背景图配置键名
  static const String _globalBackgroundKey = 'home_global_background';

  /// 是否已初始化
  bool _initialized = false;
  bool get initialized => _initialized;

  /// 当前活动的布局ID
  String? _activeLayoutId;

  /// 是否有未保存的更改
  bool _isDirty = false;

  /// 自动保存定时器
  Timer? _saveTimer;

  /// 是否处于加载状态（加载时禁用自动保存）
  bool _isLoading = false;

  /// 初始化布局管理器
  ///
  /// 从配置文件加载布局，如果不存在则初始化默认布局
  Future<void> initialize() async {
    if (_initialized) return;

    // 加载活动布局ID
    try {
      final activeConfig = await globalConfigManager.getPluginConfig(_activeLayoutIdKey);
      if (activeConfig != null && activeConfig['activeLayoutId'] != null) {
        _activeLayoutId = activeConfig['activeLayoutId'] as String;
      }
    } catch (e) {
      debugPrint('加载活动布局ID失败: $e');
    }

    // 加载全局背景配置（包含透明度）
    try {
      final globalConfig = await getGlobalBackgroundConfig();
      _globalWidgetOpacity = (globalConfig['widgetOpacity'] as num?)?.toDouble() ?? 1.0;
      _globalWidgetBackgroundOpacity = (globalConfig['widgetBackgroundOpacity'] as num?)?.toDouble() ?? 1.0;
    } catch (e) {
      debugPrint('加载全局背景配置失败: $e');
    }

    await loadLayout();
    _initialized = true;
  }

  /// 从配置加载布局
  Future<void> loadLayout() async {
    _isLoading = true; // 开始加载，禁用自动保存
    try {
      final config = await globalConfigManager.getPluginConfig(_configKey);

      if (config != null) {
        // 加载项目列表
        if (config['items'] != null) {
          final itemsList = config['items'] as List;
          _items = itemsList
              .map((json) {
                final item = HomeItem.fromJson(json as Map<String, dynamic>);
                return item;
              })
              .toList();
        } else {
          // 没有配置，初始化空布局
          _items = [];
        }

        // 加载网格列数配置
        if (config['gridCrossAxisCount'] != null) {
          _gridCrossAxisCount = config['gridCrossAxisCount'] as int;
          // 确保在1-10范围内
          if (_gridCrossAxisCount < 1) _gridCrossAxisCount = 1;
          if (_gridCrossAxisCount > 10) _gridCrossAxisCount = 10;
        }

        // 加载网格显示位置配置
        if (config['gridAlignment'] != null) {
          _gridAlignment = config['gridAlignment'] as String;
          // 确保值有效
          if (_gridAlignment != 'top' && _gridAlignment != 'center') {
            _gridAlignment = 'top';
          }
        }
      } else {
        // 没有配置，初始化空布局
        _items = [];
      }

      _isDirty = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading home layout: $e');
      _items = [];
    } finally {
      // 延迟解除加载状态，给小组件足够的时间初始化
      Future.delayed(const Duration(milliseconds: 500), () {
        _isLoading = false;
      });
    }
  }

  /// 保存布局到配置
  Future<void> saveLayout() async {
    final serializedItems = _items.map((item) => item.toJson()).toList();
    try {
      await globalConfigManager.savePluginConfig(_configKey, {
        'items': serializedItems,
        'gridCrossAxisCount': _gridCrossAxisCount,
        'gridAlignment': _gridAlignment,
      });
      await _syncActiveLayout(serializedItems);
      _isDirty = false;
    } catch (e) {
      debugPrint('Error saving home layout: $e');
    }
  }

  Future<void> _syncActiveLayout(
    List<Map<String, dynamic>> serializedItems,
  ) async {
    if (_activeLayoutId == null) {
      return;
    }

    try {
      final layouts = await getSavedLayouts();
      final index = layouts.indexWhere((l) => l.id == _activeLayoutId);

      if (index == -1) {
        return;
      }

      layouts[index] = layouts[index].copyWith(
        items: serializedItems,
        gridCrossAxisCount: _gridCrossAxisCount,
        updatedAt: DateTime.now(),
      );

      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error syncing active layout: $e');
    }
  }

  /// 标记为脏数据并延迟保存
  void _markDirty() {
    // 如果正在加载，不触发自动保存
    if (_isLoading) {
      return;
    }

    _isDirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      if (_isDirty && !_isLoading) {
        saveLayout();
      }
    });
  }

  // ==================== 项目管理 ====================

  /// 添加项目到主页
  void addItem(HomeItem item) {
    _items.add(item);
    _markDirty();
    notifyListeners();
  }

  /// 在指定位置插入项目
  void insertItem(int index, HomeItem item) {
    _items.insert(index, item);
    _markDirty();
    notifyListeners();
  }

  /// 移除项目
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    _markDirty();
    notifyListeners();
  }

  /// 移除指定索引的项目
  void removeItemAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _markDirty();
      notifyListeners();
    }
  }

  /// 更新项目
  void updateItem(String itemId, HomeItem newItem) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final oldItem = _items[index];

      // 只有当项目真的改变时才更新和保存
      // 使用 runtimeType 和 JSON 对比判断是否有变化
      final oldJson = oldItem.toJson();
      final newJson = newItem.toJson();

      // 改进的比较逻辑:使用 JSON 编码后的字符串比较(更稳定)
      bool hasChanged = false;
      if (oldItem.runtimeType != newItem.runtimeType) {
        hasChanged = true;
      } else {
        // 比较关键字段
        if (oldJson['type'] != newJson['type']) {
          hasChanged = true;
        } else if (oldItem is HomeWidgetItem && newItem is HomeWidgetItem) {
          // 对于小组件,比较 widgetId、size 和 config
          // 注意：size 没有实现 == 运算符，所以需要比较 width 和 height
          final sizeChanged = oldItem.size.width != newItem.size.width ||
              oldItem.size.height != newItem.size.height;
          if (oldItem.widgetId != newItem.widgetId ||
              sizeChanged ||
              !_mapsAreEqual(oldItem.config, newItem.config)) {
            hasChanged = true;
          }
        } else if (oldItem is HomeFolderItem && newItem is HomeFolderItem) {
          // ?????,???????????????
          if (oldItem.name != newItem.name ||
              oldItem.icon != newItem.icon ||
              oldItem.color != newItem.color ||
              oldItem.children.length != newItem.children.length) {
            hasChanged = true;
          }
        } else if (oldItem is HomeStackItem && newItem is HomeStackItem) {
          if (oldItem.direction != newItem.direction ||
              oldItem.size != newItem.size ||
              oldItem.activeIndex != newItem.activeIndex ||
              oldItem.children.length != newItem.children.length) {
            hasChanged = true;
          } else {
            for (var i = 0; i < oldItem.children.length; i++) {
              final oldChild = oldItem.children[i];
              final newChild = newItem.children[i];
              if (oldChild.widgetId != newChild.widgetId ||
                  oldChild.size != newChild.size ||
                  !_mapsAreEqual(oldChild.config, newChild.config)) {
                hasChanged = true;
                break;
              }
            }
          }
        } else {
          // 其他情况,总是更新
          hasChanged = true;
        }
      }

      if (hasChanged) {
        _items[index] = newItem;
        _markDirty();
        notifyListeners();
      }
    }
  }

  /// 比较两个 Map 是否相等(浅比较)
  bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  /// 根据ID查找项目
  HomeItem? findItem(String itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// 重新排序
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    _markDirty();
    notifyListeners();
  }

  // ==================== 折叠组件管理 ====================

  bool canMergeIntoStack(HomeItem target, HomeItem dragged) {
    final reference = _resolveStackReference(target);
    if (reference == null) {
      return false;
    }
    final draggedWidgets = _flattenWidgets(dragged);
    if (draggedWidgets.isEmpty) {
      return false;
    }
    return draggedWidgets.every(
      (widget) => _hasSameDimensions(reference, widget),
    );
  }

  HomeStackItem? mergeIntoStack({
    required String targetItemId,
    required String draggedItemId,
    HomeStackDirection? direction,
  }) {
    final targetIndex = _items.indexWhere((item) => item.id == targetItemId);
    final draggedIndex = _items.indexWhere((item) => item.id == draggedItemId);
    if (targetIndex == -1 || draggedIndex == -1) {
      return null;
    }

    final targetItem = _items[targetIndex];
    if (targetItem is HomeFolderItem) {
      return null;
    }

    final draggedItem = _items[draggedIndex];
    final draggedWidgets = _flattenWidgets(draggedItem);
    if (draggedWidgets.isEmpty) {
      return null;
    }

    final reference = _resolveStackReference(targetItem);
    if (reference == null) {
      return null;
    }

    if (!draggedWidgets.every(
      (widget) => _hasSameDimensions(reference, widget),
    )) {
      return null;
    }

    // 先移除被拖拽项，避免索引错位
    _items.removeAt(draggedIndex);
    var effectiveTargetIndex = targetIndex;
    if (draggedIndex < targetIndex) {
      effectiveTargetIndex -= 1;
    }

    HomeStackItem updatedStack;
    if (targetItem is HomeStackItem) {
      updatedStack = targetItem.copyWith(
        children: [...targetItem.children, ...draggedWidgets],
      );
      _items[effectiveTargetIndex] = updatedStack;
    } else if (targetItem is HomeWidgetItem) {
      if (direction == null) {
        // 新建折叠需要方向
        _items.insert(draggedIndex, draggedItem);
        return null;
      }
      updatedStack = HomeStackItem(
        id: targetItem.id,
        children: [targetItem, ...draggedWidgets],
        size: targetItem.size,
        direction: direction,
      );
      _items[effectiveTargetIndex] = updatedStack;
    } else {
      // 目标不是可折叠项，撤回移除操作
      _items.insert(
        draggedIndex > _items.length ? _items.length : draggedIndex,
        draggedItem,
      );
      return null;
    }

    _markDirty();
    notifyListeners();
    return updatedStack;
  }

  void updateStackActiveIndex(String stackId, int newIndex) {
    final index = _items.indexWhere((item) => item.id == stackId);
    if (index == -1) {
      return;
    }
    final stack = _items[index];
    if (stack is! HomeStackItem) {
      return;
    }
    if (newIndex < 0 || newIndex >= stack.children.length) {
      return;
    }
    if (stack.activeIndex == newIndex) {
      return;
    }
    _items[index] = stack.copyWith(activeIndex: newIndex);
    _markDirty();
  }

  /// 拆散折叠组件中的所有小组件
  ///
  /// 将 HomeStackItem 中的所有 HomeWidgetItem 拆散并插入到原位置
  void unstackAllItems(String stackId) {
    final index = _items.indexWhere((item) => item.id == stackId);
    if (index == -1) {
      return;
    }
    final stack = _items[index];
    if (stack is! HomeStackItem) {
      return;
    }

    // 移除折叠组件
    _items.removeAt(index);

    // 将所有子组件插入到原位置
    for (int i = 0; i < stack.children.length; i++) {
      _items.insert(index + i, stack.children[i]);
    }

    _markDirty();
    notifyListeners();
  }

  /// 拆散折叠组件中的指定小组件
  ///
  /// 将 HomeStackItem 中的指定 HomeWidgetItem 拆散并插入到折叠组件之前
  void unstackItem(String stackId, String widgetItemId) {
    final index = _items.indexWhere((item) => item.id == stackId);
    if (index == -1) {
      return;
    }
    final stack = _items[index];
    if (stack is! HomeStackItem) {
      return;
    }

    final childIndex = stack.children.indexWhere((child) => child.id == widgetItemId);
    if (childIndex == -1) {
      return;
    }

    // 从折叠组件中移除该小组件
    final child = stack.children[childIndex];
    final updatedChildren = List<HomeWidgetItem>.from(stack.children)..removeAt(childIndex);

    if (updatedChildren.isEmpty) {
      // 没有子组件了，将小组件替换原来的折叠组件
      _items[index] = child;
    } else if (updatedChildren.length == 1) {
      // 剩下一个子组件，将它替换为普通小组件，并删除折叠组件
      final remainingChild = updatedChildren.first;
      // 将拆散的小组件插入到原位置之前
      _items[index] = remainingChild;
      _items.insert(index, child);
    } else {
      // 还有多个子组件，更新折叠组件的子组件列表
      _items[index] = stack.copyWith(children: updatedChildren);

      // 将拆散的小组件插入到折叠组件之前
      _items.insert(index, child);
    }

    _markDirty();
    notifyListeners();
  }

  HomeWidgetItem? _resolveStackReference(HomeItem item) {
    if (item is HomeWidgetItem) {
      return item;
    }
    if (item is HomeStackItem && item.children.isNotEmpty) {
      return item.children.first;
    }
    return null;
  }

  List<HomeWidgetItem> _flattenWidgets(HomeItem item) {
    if (item is HomeWidgetItem) {
      return [item];
    }
    if (item is HomeStackItem) {
      return List<HomeWidgetItem>.from(item.children);
    }
    return [];
  }

  bool _hasSameDimensions(HomeWidgetItem a, HomeWidgetItem b) {
    if (a.size != b.size) {
      return false;
    }
    // 如果不是 CustomSize，直接返回 true
    if (a.size is! CustomSize) {
      return true;
    }
    // 对于 CustomSize，需要检查配置中的宽高
    final aw = (a.config['customWidth'] as int?) ?? a.size.width;
    final ah = (a.config['customHeight'] as int?) ?? a.size.height;
    final bw = (b.config['customWidth'] as int?) ?? b.size.width;
    final bh = (b.config['customHeight'] as int?) ?? b.size.height;
    return aw == bw && ah == bh;
  }

  // ==================== 文件夹管理 ====================

  /// 将项目移动到文件夹
  void moveToFolder(String itemId, String folderId) {
    // 找到项目和文件夹
    final item = findItem(itemId);
    final folder = findItem(folderId);

    if (item == null || folder is! HomeFolderItem) {
      return;
    }

    // 从主列表中移除项目
    _items.removeWhere((i) => i.id == itemId);

    // 添加到文件夹
    final updatedFolder = folder.copyWith(
      children: [...folder.children, item],
    );
    updateItem(folderId, updatedFolder);

    _markDirty();
    notifyListeners();
  }

  /// 直接添加项目到文件夹
  void addItemToFolder(HomeItem item, String folderId) {
    final folder = findItem(folderId);
    if (folder is! HomeFolderItem) {
      return;
    }

    // 添加到文件夹
    final updatedFolder = folder.copyWith(
      children: [...folder.children, item],
    );
    updateItem(folderId, updatedFolder);

    _markDirty();
    notifyListeners();
  }

  /// 从文件夹中移出项目
  void removeFromFolder(String itemId, String folderId) {
    final folder = findItem(folderId);
    if (folder is! HomeFolderItem) {
      return;
    }

    // 找到要移出的项目
    HomeItem? item;
    try {
      item = folder.children.firstWhere((child) => child.id == itemId);
    } catch (e) {
      return;
    }

    if (item == null) return;

    // 从文件夹移除
    final updatedFolder = folder.copyWith(
      children: folder.children.where((child) => child.id != itemId).toList(),
    );
    updateItem(folderId, updatedFolder);

    // 添加到主列表
    _items.add(item);

    _markDirty();
    notifyListeners();
  }

  /// 重新排序文件夹内的项目
  void reorderInFolder(String folderId, int oldIndex, int newIndex) {
    final folder = findItem(folderId);
    if (folder is! HomeFolderItem) {
      return;
    }

    final children = List<HomeItem>.from(folder.children);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = children.removeAt(oldIndex);
    children.insert(newIndex, item);

    final updatedFolder = folder.copyWith(children: children);
    updateItem(folderId, updatedFolder);

    _markDirty();
    notifyListeners();
  }

  // ==================== 网格配置管理 ====================

  /// 设置网格列数
  void setGridCrossAxisCount(int count) {
    if (count < 1 || count > 10) {
      return;
    }
    _gridCrossAxisCount = count;
    _markDirty();
    notifyListeners();
  }

  /// 设置网格显示位置
  void setGridAlignment(String alignment) {
    if (alignment != 'top' && alignment != 'center') {
      return;
    }
    _gridAlignment = alignment;
    _markDirty();
    notifyListeners();
  }

  // ==================== 工具方法 ====================

  /// 生成唯一ID
  String generateId() {
    return 'item_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 清空所有项目
  void clear() {
    _items.clear();
    _markDirty();
    notifyListeners();
  }

  /// 直接设置 items 列表（用于缓存恢复）
  void setItems(List<HomeItem> newItems) {
    _items.clear();
    _items.addAll(newItems);
    notifyListeners();
  }

  /// 获取所有小组件项（递归，包括文件夹内的）
  List<HomeWidgetItem> getAllWidgetItems() {
    final List<HomeWidgetItem> widgets = [];

    void collectWidgets(List<HomeItem> items) {
      for (var item in items) {
        if (item is HomeWidgetItem) {
          widgets.add(item);
        } else if (item is HomeFolderItem) {
          collectWidgets(item.children);
        } else if (item is HomeStackItem) {
          widgets.addAll(item.children);
        }
      }
    }

    collectWidgets(_items);
    return widgets;
  }

  /// 获取项目总数（包括文件夹内的）
  int get totalItemCount {
    int count = _items.length;
    for (var item in _items) {
      if (item is HomeFolderItem) {
        count += item.itemCount;
      } else if (item is HomeStackItem) {
        count += item.children.length;
      }
    }
    return count;
  }

  // ==================== 多布局管理 ====================

  /// 获取所有保存的布局配置
  Future<List<LayoutConfig>> getSavedLayouts() async {
    try {
      final configs = await globalConfigManager.getPluginConfig(_layoutConfigsKey);
      if (configs == null || configs['layouts'] == null) {
        return [];
      }

      final layoutsList = configs['layouts'] as List;
      return layoutsList
          .map((json) => LayoutConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading saved layouts: $e');
      return [];
    }
  }

  /// 保存当前布局为新的配置
  Future<void> saveCurrentLayoutAs(String name) async {
    try {
      // 生成新的布局ID
      final layoutId = 'layout_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      // 创建布局配置
      final config = LayoutConfig(
        id: layoutId,
        name: name,
        items: _items.map((item) => item.toJson()).toList(),
        gridCrossAxisCount: _gridCrossAxisCount,
        createdAt: now,
        updatedAt: now,
      );

      // 获取现有的布局列表
      final layouts = await getSavedLayouts();
      layouts.add(config);

      // 保存布局列表
      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });

      // 设置为当前活动的布局
      _activeLayoutId = layoutId;
      await globalConfigManager.savePluginConfig(_activeLayoutIdKey, {
        'activeLayoutId': layoutId,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving layout: $e');
      rethrow;
    }
  }

  /// 保存指定的布局配置(不修改当前布局状态)
  /// 用于创建新布局时避免影响当前显示的布局
  /// 返回新创建的布局ID
  Future<String> saveLayoutAs(String name, List<HomeItem> items, int crossAxisCount) async {
    try {
      final layoutId = 'layout_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final config = LayoutConfig(
        id: layoutId,
        name: name,
        items: items.map((item) => item.toJson()).toList(),
        gridCrossAxisCount: crossAxisCount,
        createdAt: now,
        updatedAt: now,
      );

      final layouts = await getSavedLayouts();
      layouts.add(config);

      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });

      // 设置为当前活动的布局
      _activeLayoutId = layoutId;
      await globalConfigManager.savePluginConfig(_activeLayoutIdKey, {
        'activeLayoutId': layoutId,
      });

      notifyListeners();
      return layoutId;
    } catch (e) {
      debugPrint('Error saving layout: $e');
      rethrow;
    }
  }

  /// 加载指定的布局配置
  Future<void> loadLayoutConfig(String layoutId) async {
    try {
      final layouts = await getSavedLayouts();
      final config = layouts.firstWhere(
        (l) => l.id == layoutId,
        orElse: () => throw Exception('Layout not found: $layoutId'),
      );

      // 应用布局配置
      _items = config.items
          .map((json) => HomeItem.fromJson(json))
          .toList();
      _gridCrossAxisCount = config.gridCrossAxisCount;

      // 更新当前活动的布局ID（仅在内存中）
      _activeLayoutId = layoutId;

      _isDirty = false;
      notifyListeners();

    } catch (e) {
      debugPrint('Error loading layout config: $e');
      rethrow;
    }
  }

  /// 设置当前活动的布局并保存
  Future<void> setActiveLayout(String layoutId) async {
    await globalConfigManager.savePluginConfig(_activeLayoutIdKey, {
      'activeLayoutId': layoutId,
    });
    _activeLayoutId = layoutId;
  }

  /// 读取指定布局的结构（不修改当前状态）
  /// 用于骨架屏占位
  Future<LayoutConfig?> readLayoutConfig(String layoutId) async {
    try {
      final layouts = await getSavedLayouts();
      debugPrint('getSavedLayouts returned ${layouts.length} layouts:');
      for (var i = 0; i < layouts.length; i++) {
        debugPrint('  [$i] id=${layouts[i].id}, name=${layouts[i].name}');
      }
      final config = layouts.firstWhere(
        (l) => l.id == layoutId,
        orElse: () => throw Exception('Layout not found: $layoutId'),
      );
      debugPrint(
        'readLayoutConfig: $layoutId, name=${config.name}, items=${config.items.length}',
      );
      return config;
    } catch (e) {
      debugPrint('Error reading layout config: $e');
      return null;
    }
  }

  /// 删除指定的布局配置
  Future<void> deleteLayoutConfig(String layoutId) async {
    try {
      final layouts = await getSavedLayouts();
      layouts.removeWhere((l) => l.id == layoutId);

      // 保存更新后的布局列表
      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });

      // 如果删除的是当前活动的布局，清除活动布局ID
      if (_activeLayoutId == layoutId) {
        _activeLayoutId = null;
        await globalConfigManager.savePluginConfig(_activeLayoutIdKey, {
          'activeLayoutId': null,
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting layout: $e');
      rethrow;
    }
  }

  /// 重命名布局配置
  Future<void> renameLayoutConfig(String layoutId, String newName) async {
    try {
      final layouts = await getSavedLayouts();
      final index = layouts.indexWhere((l) => l.id == layoutId);

      if (index == -1) {
        throw Exception('Layout not found: $layoutId');
      }

      // 更新布局名称和修改时间
      layouts[index] = layouts[index].copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );

      // 保存更新后的布局列表
      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error renaming layout: $e');
      rethrow;
    }
  }

  /// 更新当前活动布局的配置（覆盖保存）
  Future<void> updateCurrentLayout() async {
    await _syncActiveLayout(_items.map((item) => item.toJson()).toList());
  }

  /// 获取当前活动的布局配置
  Future<LayoutConfig?> getCurrentLayoutConfig() async {
    if (_activeLayoutId == null) {
      return null;
    }

    try {
      final layouts = await getSavedLayouts();
      try {
        return layouts.firstWhere((l) => l.id == _activeLayoutId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting current layout: $e');
      return null;
    }
  }

  // ==================== 背景图管理 ====================

  /// 获取全局背景图配置
  Future<Map<String, dynamic>> getGlobalBackgroundConfig() async {
    try {
      final config = await globalConfigManager.getPluginConfig(_globalBackgroundKey);
      return config ?? {};
    } catch (e) {
      debugPrint('Error getting global background config: $e');
      return {};
    }
  }

  /// 保存全局背景图配置
  Future<void> saveGlobalBackgroundConfig(Map<String, dynamic> config) async {
    try {
      await globalConfigManager.savePluginConfig(_globalBackgroundKey, config);
      // 更新缓存的透明度值
      _globalWidgetOpacity = (config['widgetOpacity'] as num?)?.toDouble() ?? 1.0;
      _globalWidgetBackgroundOpacity = (config['widgetBackgroundOpacity'] as num?)?.toDouble() ?? 1.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving global background config: $e');
      rethrow;
    }
  }

  /// 保存布局配置列表
  Future<void> saveLayoutConfigs(List<LayoutConfig> layouts) async {
    try {
      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving layout configs: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
