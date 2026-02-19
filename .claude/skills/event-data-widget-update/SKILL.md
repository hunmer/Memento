# 事件携带数据更新小组件

将小组件从传统的"事件通知+重新获取数据"模式迁移到"事件携带数据"模式，解决数据更新时序问题和缓存刷新延迟问题。

## 适用场景

- 小组件需要实时响应插件数据变化
- 存在事件触发后数据未及时更新的问题
- 需要优化性能，避免重复的数据获取操作
- 数据变化频繁的小组件（如列表、统计卡片等）

## 问题背景

### 传统模式的问题

```dart
// ❌ 传统模式：事件只通知变化，小组件需要重新获取数据
EventListenerContainer(
  events: const ['item_added', 'item_updated', 'item_deleted'],
  onEvent: () => setState(() {}),  // 只触发重建
  child: FutureBuilder(
    future: _getDataFromPlugin(),  // 重新获取数据，可能存在时序问题
    builder: (context, snapshot) => ...,
  ),
)
```

**问题**：
1. **时序问题**：事件广播时数据可能还没保存完成
2. **性能问题**：每次重建都需要重新获取数据
3. **缓存问题**：FutureBuilder 可能复用旧的缓存结果

### 事件携带数据模式

```dart
// ✅ 事件携带数据模式：直接使用事件中的最新数据
EventListenerContainer(
  events: const ['items_cache_updated'],
  onEventWithData: (args) {
    if (args is ItemsCacheUpdatedEventArgs) {
      setState(() {
        _cachedItems = args.items;  // 直接使用事件数据
      });
    }
  },
  child: _buildWithItems(_cachedItems),
)
```

**优势**：
1. **实时数据**：事件携带的数据是保存后的最新数据
2. **高性能**：无需额外的数据获取操作
3. **无时序问题**：数据在事件中直接传递

## 实现步骤

### 步骤 1：创建事件参数类

在插件的 `controllers/` 或 `models/` 目录下创建携带数据的事件参数类：

```dart
// lib/plugins/<plugin>/controllers/<plugin>_controller.dart

import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/plugins/<plugin>/models/<model>.dart';

/// 缓存更新事件参数 - 携带最新的数据列表
class <Plugin>CacheUpdatedEventArgs extends EventArgs {
  /// 最新的数据列表
  final List<<Model>> items;

  /// 更新时间戳
  final DateTime timestamp;

  <Plugin>CacheUpdatedEventArgs({
    required this.items,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       super('<plugin>_cache_updated');
}
```

**示例**：
```dart
// Day 插件的纪念日缓存更新事件
class MemorialDayCacheUpdatedEventArgs extends EventArgs {
  final List<MemorialDay> items;
  final DateTime timestamp;

  MemorialDayCacheUpdatedEventArgs({
    required this.items,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       super('memorial_day_cache_updated');
}
```

### 步骤 2：修改控制器广播事件

在控制器的数据变更方法中，广播携带数据的事件：

```dart
// lib/plugins/<plugin>/controllers/<plugin>_controller.dart

class <Plugin>Controller extends ChangeNotifier {
  final List<<Model>> _items = [];

  // 添加数据
  Future<void> addItem(<Model> item) async {
    _items.add(item);
    await _saveItems();
    notifyListeners();

    // 广播缓存更新事件（携带所有数据）
    _broadcastCacheUpdated();
  }

  // 更新数据
  Future<void> updateItem(<Model> item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      await _saveItems();
      notifyListeners();
      _broadcastCacheUpdated();
    }
  }

  // 删除数据
  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _saveItems();
    notifyListeners();
    _broadcastCacheUpdated();
  }

  // 广播缓存更新事件
  void _broadcastCacheUpdated() {
    debugPrint('[<Plugin>Controller] Broadcasting cache_updated with ${_items.length} items');
    EventManager.instance.broadcast(
      '<plugin>_cache_updated',
      <Plugin>CacheUpdatedEventArgs(items: List.from(_items)),
    );
  }
}
```

**重要**：
- 使用 `List.from(_items)` 创建数据副本，避免外部修改
- 在数据保存完成后再广播事件
- 添加调试日志便于排查问题

### 步骤 3：修改小组件使用事件数据

将小组件从 `LiveSelectorWidget` 或 `FutureBuilder` 模式改为事件携带数据模式：

```dart
// lib/plugins/<plugin>/home_widgets/register_<widget>.dart

/// 使用事件携带数据模式的小组件
class _<Plugin>Widget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _<Plugin>Widget({
    required this.config,
    required this.widgetDefinition,
  });

  @override
  State<_<Plugin>Widget> createState() => _<Plugin>WidgetState();
}

class _<Plugin>WidgetState extends State<_<Plugin>Widget> {
  /// 缓存的数据（从事件中获取）
  List<<Model>>? _cachedItems;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// 加载初始数据（首次显示时）
  void _loadInitialData() {
    final plugin = PluginManager.instance.getPlugin('<plugin>') as <Plugin>?;
    _cachedItems = plugin?.getAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['<plugin>_cache_updated'],
      onEventWithData: (args) {
        if (args is <Plugin>CacheUpdatedEventArgs) {
          debugPrint('[<Plugin>Widget] Received cache_updated: ${args.items.length} items');
          setState(() {
            _cachedItems = args.items;
          });
        }
      },
      child: _buildContent(),
    );
  }

  /// 构建内容（使用缓存的数据）
  Widget _buildContent() {
    final items = _cachedItems ?? [];

    if (items.isEmpty) {
      return _buildEmpty(context);
    }

    // 使用数据进行渲染
    return _buildWithData(items);
  }

  Widget _buildEmpty(BuildContext context) {
    // 空状态 UI
  }

  Widget _buildWithData(List<<Model>> items) {
    // 数据展示 UI
  }
}
```

### 步骤 4：验证修复

1. **首次加载**：小组件应正确显示初始数据
2. **添加数据**：新数据应立即出现在小组件中
3. **更新数据**：修改后的数据应立即反映
4. **删除数据**：删除后小组件应立即更新

## 完整示例

### 控制器 (day_controller.dart)

```dart
/// 纪念日缓存更新事件参数
class MemorialDayCacheUpdatedEventArgs extends EventArgs {
  final List<MemorialDay> items;
  final DateTime timestamp;

  MemorialDayCacheUpdatedEventArgs({
    required this.items,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
       super('memorial_day_cache_updated');
}

class DayController extends ChangeNotifier {
  final List<MemorialDay> _memorialDays = [];

  List<MemorialDay> get memorialDays => _memorialDays;

  // 添加纪念日
  Future<void> addMemorialDay(MemorialDay memorialDay) async {
    _memorialDays.add(memorialDay);
    _sortMemorialDays();
    await _saveMemorialDays();
    notifyListeners();
    _broadcastCacheUpdated();
  }

  // 更新纪念日
  Future<void> updateMemorialDay(MemorialDay memorialDay) async {
    final index = _memorialDays.indexWhere((day) => day.id == memorialDay.id);
    if (index != -1) {
      _memorialDays[index] = memorialDay;
      _sortMemorialDays();
      await _saveMemorialDays();
      notifyListeners();
      _broadcastCacheUpdated();
    }
  }

  // 删除纪念日
  Future<void> deleteMemorialDay(String id) async {
    _memorialDays.removeWhere((day) => day.id == id);
    await _saveMemorialDays();
    notifyListeners();
    _broadcastCacheUpdated();
  }

  // 广播缓存更新事件
  void _broadcastCacheUpdated() {
    debugPrint('[DayController] Broadcasting cache_updated with ${_memorialDays.length} items');
    EventManager.instance.broadcast(
      'memorial_day_cache_updated',
      MemorialDayCacheUpdatedEventArgs(items: List.from(_memorialDays)),
    );
  }
}
```

### 小组件 (register_date_range_list_widget.dart)

```dart
class _DateRangeListWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final HomeWidget widgetDefinition;

  const _DateRangeListWidget({
    required this.config,
    required this.widgetDefinition,
  });

  @override
  State<_DateRangeListWidget> createState() => _DateRangeListWidgetState();
}

class _DateRangeListWidgetState extends State<_DateRangeListWidget> {
  /// 缓存的纪念日列表（从事件中获取）
  List<MemorialDay>? _cachedMemorialDays;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final plugin = DayPlugin.instance;
    _cachedMemorialDays = plugin.getAllMemorialDays();
  }

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['memorial_day_cache_updated'],
      onEventWithData: (args) {
        if (args is MemorialDayCacheUpdatedEventArgs) {
          setState(() {
            _cachedMemorialDays = args.items;
          });
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final allDays = _cachedMemorialDays ?? [];
    if (allDays.isEmpty) {
      return _buildEmpty(context);
    }

    // 过滤和渲染数据
    final filteredDays = _filterDays(allDays);
    return _buildWithData(filteredDays);
  }
}
```

## 检查清单

### 控制器修改

- [ ] 创建了 `<Plugin>CacheUpdatedEventArgs` 事件参数类
- [ ] 事件参数类包含 `items` 字段存储最新数据
- [ ] 事件参数类包含 `timestamp` 字段记录更新时间
- [ ] 事件名称遵循 `<plugin>_cache_updated` 命名规范
- [ ] 在添加/更新/删除方法中都调用了广播方法
- [ ] 广播在数据保存完成后执行（`await _saveItems()` 之后）
- [ ] 使用 `List.from()` 创建数据副本
- [ ] 添加了调试日志

### 小组件修改

- [ ] 使用 StatefulWidget 维护缓存数据
- [ ] 缓存变量是 State 的成员变量（不是 builder 中的局部变量）
- [ ] 在 `initState` 中加载初始数据
- [ ] 使用 `EventListenerContainer` 监听缓存更新事件
- [ ] 使用 `onEventWithData` 接收事件数据
- [ ] 在 `onEventWithData` 中进行了类型检查
- [ ] 更新数据时调用了 `setState`
- [ ] 移除了对 `LiveSelectorWidget` 或 `FutureBuilder` 的依赖

### 测试验证

- [ ] 首次加载显示正确数据
- [ ] 添加数据后小组件立即更新
- [ ] 更新数据后小组件立即更新
- [ ] 删除数据后小组件立即更新
- [ ] 调试日志正确输出

## 常见问题

### Q1: 为什么要创建数据副本？

```dart
// ✅ 正确 - 创建副本
<Plugin>CacheUpdatedEventArgs(items: List.from(_items))

// ❌ 错误 - 直接传递引用
<Plugin>CacheUpdatedEventArgs(items: _items)
```

直接传递引用可能导致外部代码修改数据时影响缓存的一致性。

### Q2: 首次加载时事件还没触发怎么办？

在 `initState` 中主动获取初始数据：

```dart
@override
void initState() {
  super.initState();
  _loadInitialData();  // 主动获取初始数据
}

void _loadInitialData() {
  final plugin = PluginManager.instance.getPlugin('<plugin>') as <Plugin>?;
  _cachedItems = plugin?.getAllItems();
}
```

### Q3: 如果需要过滤数据怎么办？

在 `_buildContent` 方法中进行过滤，而不是在事件处理中：

```dart
Widget _buildContent() {
  final allItems = _cachedItems ?? [];
  final filteredItems = _applyFilters(allItems);  // 在这里过滤

  if (filteredItems.isEmpty) {
    return _buildEmpty(context);
  }

  return _buildWithData(filteredItems);
}
```

### Q4: 如何保持与旧事件的兼容性？

可以同时广播两种事件：

```dart
void _notifyEvent(String action, Model item) {
  // 1. 广播单个项目事件（保持兼容）
  EventManager.instance.broadcast(
    '<plugin>_$action',
    ItemEventArgs(itemId: item.id, ...),
  );

  // 2. 广播缓存更新事件（携带全部数据）
  EventManager.instance.broadcast(
    '<plugin>_cache_updated',
    <Plugin>CacheUpdatedEventArgs(items: List.from(_items)),
  );
}
```

### Q5: 多个小组件共享数据会冲突吗？

不会。每个小组件实例都有自己的 `_cachedItems` 状态变量，事件触发时各自独立更新。

## 相关技能

- [check-widget-update-issues](../check-widget-update-issues.md) - 诊断小组件更新问题
- [event-listener-container](../event-listener-container/SKILL.md) - EventListenerContainer 使用指南

## 参考实现

- `lib/plugins/day/controllers/day_controller.dart` - Day 插件控制器
- `lib/plugins/day/home_widgets/register_date_range_list_widget.dart` - Day 插件小组件
