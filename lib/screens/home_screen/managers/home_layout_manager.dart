import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../main.dart';
import '../models/home_item.dart';
import '../models/home_widget_item.dart';
import '../models/home_folder_item.dart';

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

  /// 配置键名
  static const String _configKey = 'home_layout';

  /// 是否已初始化
  bool _initialized = false;
  bool get initialized => _initialized;

  /// 是否有未保存的更改
  bool _isDirty = false;

  /// 自动保存定时器
  Timer? _saveTimer;

  /// 初始化布局管理器
  ///
  /// 从配置文件加载布局，如果不存在则初始化默认布局
  Future<void> initialize() async {
    if (_initialized) return;

    await loadLayout();
    _initialized = true;
  }

  /// 从配置加载布局
  Future<void> loadLayout() async {
    try {
      final config = await globalConfigManager.getPluginConfig(_configKey);

      if (config != null && config['items'] != null) {
        final itemsList = config['items'] as List;
        _items = itemsList
            .map((json) => HomeItem.fromJson(json as Map<String, dynamic>))
            .toList();
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
      });
      _isDirty = false;
      debugPrint('Home layout saved: ${_items.length} items');
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
    return _items.firstWhere((item) => item.id == itemId, orElse: () => null as HomeItem);
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

  /// 从文件夹中移出项目
  void removeFromFolder(String itemId, String folderId) {
    final folder = findItem(folderId);
    if (folder is! HomeFolderItem) {
      return;
    }

    // 找到要移出的项目
    final item = folder.children.firstWhere(
      (child) => child.id == itemId,
      orElse: () => null as HomeItem,
    );

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

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
