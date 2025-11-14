import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../main.dart';
import '../models/home_item.dart';
import '../models/home_widget_item.dart';
import '../models/home_folder_item.dart';
import '../models/layout_config.dart';

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
        debugPrint('初始化：活动布局ID = $_activeLayoutId');
      }
    } catch (e) {
      debugPrint('加载活动布局ID失败: $e');
    }

    await loadLayout();
    _initialized = true;
  }

  /// 从配置加载布局
  Future<void> loadLayout() async {
    try {
      final config = await globalConfigManager.getPluginConfig(_configKey);

      if (config != null) {
        // 加载项目列表
        if (config['items'] != null) {
          final itemsList = config['items'] as List;
          _items = itemsList
              .map((json) => HomeItem.fromJson(json as Map<String, dynamic>))
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
    }
  }

  /// 保存布局到配置
  Future<void> saveLayout() async {
    try {
      await globalConfigManager.savePluginConfig(_configKey, {
        'items': _items.map((item) => item.toJson()).toList(),
        'gridCrossAxisCount': _gridCrossAxisCount,
        'gridAlignment': _gridAlignment,
      });
      _isDirty = false;
      debugPrint('Home layout saved: ${_items.length} items, grid: $_gridCrossAxisCount, alignment: $_gridAlignment');
    } catch (e) {
      debugPrint('Error saving home layout: $e');
    }
  }

  /// 标记为脏数据并延迟保存
  void _markDirty() {
    _isDirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      if (_isDirty) {
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
      _items[index] = newItem;
      _markDirty();
      notifyListeners();
    }
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
      debugPrint('Folder not found: $folderId');
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
      debugPrint('Grid cross axis count must be between 1 and 10');
      return;
    }
    _gridCrossAxisCount = count;
    _markDirty();
    notifyListeners();
  }

  /// 设置网格显示位置
  void setGridAlignment(String alignment) {
    if (alignment != 'top' && alignment != 'center') {
      debugPrint('Grid alignment must be "top" or "center"');
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

  /// 获取所有小组件项（递归，包括文件夹内的）
  List<HomeWidgetItem> getAllWidgetItems() {
    final List<HomeWidgetItem> widgets = [];

    void collectWidgets(List<HomeItem> items) {
      for (var item in items) {
        if (item is HomeWidgetItem) {
          widgets.add(item);
        } else if (item is HomeFolderItem) {
          collectWidgets(item.children);
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

      debugPrint('Layout saved: $name');
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

      // 更新当前活动的布局ID
      _activeLayoutId = layoutId;
      await globalConfigManager.savePluginConfig(_activeLayoutIdKey, {
        'activeLayoutId': layoutId,
      });

      // 同时更新默认布局（保持向后兼容）
      await saveLayout();

      _isDirty = false;
      notifyListeners();

      debugPrint('Layout loaded: ${config.name}');
    } catch (e) {
      debugPrint('Error loading layout config: $e');
      rethrow;
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

      debugPrint('Layout deleted: $layoutId');
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

      debugPrint('Layout renamed: $newName');
    } catch (e) {
      debugPrint('Error renaming layout: $e');
      rethrow;
    }
  }

  /// 更新当前活动布局的配置（覆盖保存）
  Future<void> updateCurrentLayout() async {
    if (_activeLayoutId == null) {
      debugPrint('No active layout to update');
      return;
    }

    try {
      final layouts = await getSavedLayouts();
      final index = layouts.indexWhere((l) => l.id == _activeLayoutId);

      if (index == -1) {
        debugPrint('Active layout not found, saving as new');
        return;
      }

      // 更新布局配置
      layouts[index] = layouts[index].copyWith(
        items: _items.map((item) => item.toJson()).toList(),
        gridCrossAxisCount: _gridCrossAxisCount,
        updatedAt: DateTime.now(),
      );

      // 保存更新后的布局列表
      await globalConfigManager.savePluginConfig(_layoutConfigsKey, {
        'layouts': layouts.map((l) => l.toJson()).toList(),
      });

      // 同时更新默认布局
      await saveLayout();

      debugPrint('Layout updated: $_activeLayoutId');
    } catch (e) {
      debugPrint('Error updating layout: $e');
      rethrow;
    }
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
      notifyListeners();
      debugPrint('Global background config saved');
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
      debugPrint('Layout configs saved: ${layouts.length} layouts');
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
