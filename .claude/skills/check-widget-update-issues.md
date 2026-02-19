---
name: check-widget-update-issues
description: 检查小组件更新问题，诊断首次加载显示"暂无数据"、数据变化后UI不更新、事件未触发等问题。检查事件监听、缓存刷新通知、事件名称匹配、事件携带数据等。
---

# Check Widget Update Issues

检查和诊断小组件更新相关问题，包括首次加载显示"暂无数据"、数据变化后UI不更新、事件未触发等。

## Usage

```bash
# 检查指定插件的小组件更新问题
/check-widget-update-issues <plugin-id>

# 示例
/check-widget-update-issues activity
/check-widget-update-issues todo
/check-widget-update-issues diary
```

## Arguments

- `<plugin-id>`: 插件ID，例如 `activity`、`todo`、`diary`

## Workflow

### 1. 定位小组件相关文件

首先找到插件的小组件相关文件：

```bash
# 查找注册文件
find lib/plugins/<plugin-id>/home_widgets -name "register*.dart"

# 查找 providers 文件
find lib/plugins/<plugin-id>/home_widgets -name "providers.dart"

# 查找插件主文件
ls lib/plugins/<plugin-id>/<plugin-id>_plugin.dart
```

### 2. 检查事件监听

在 `register_*.dart` 或 `providers.dart` 文件中检查小组件是否正确监听了数据变化事件：

**传统模式（向后兼容）：**
```dart
EventListenerContainer(
  events: const [
    '<plugin>_<action>',
    '<plugin>_<action>',
  ],
  onEvent: () => setState(() {}),
  child: buildWidget(...),
)
```

**优化模式（事件携带数据，推荐）：**
```dart
class _WidgetState extends State<_Widget> {
  List<DataItem>? _cachedItems;

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['xxx_cache_updated'],
      onEventWithData: (args) {
        if (args is XxxCacheUpdatedEventArgs) {
          setState(() {
            _cachedItems = args.items; // 直接使用事件数据
          });
        }
      },
      child: _buildContent(context, _cachedItems),
    );
  }
}
```

**检查清单：**
- [ ] 使用了 `EventListenerContainer` 包裹小组件
- [ ] `events` 列表包含所有相关的数据变化事件
- [ ] `onEvent` 回调调用了 `setState(() {})` 或 `onEventWithData` 正确更新状态
- [ ] 如果使用 `onEventWithData`，缓存变量必须是 StatefulWidget 的状态变量（不是 builder 闭包中的局部变量）

**常见问题：**
1. ❌ 缺少 `EventListenerContainer`
   ```dart
   // 错误 - 没有事件监听
   builder: (context, setState) {
     return buildWidget(context, config);
   }
   ```

2. ❌ 事件列表不完整
   ```dart
   // 错误 - 只监听了添加事件，没有更新和删除
   events: const ['activity_added'],
   ```

3. ❌ 没有调用 setState
   ```dart
   // 错误 - 事件回调没有触发更新
   EventListenerContainer(
     events: const ['activity_added'],
     onEvent: () {}, // 忘记了 setState(() {})
   )
   ```

4. ❌ 缓存变量是局部变量（使用 `onEventWithData` 时）
   ```dart
   // 错误 - cachedItems 是 builder 闭包中的局部变量
   return StatefulBuilder(
     builder: (context, setState) {
       List<DataItem>? cachedItems;  // ❌ 每次重建都会重置为 null
       return EventListenerContainer(
         onEventWithData: (args) {
           setState(() {
             cachedItems = args.items;  // ❌ 设置后下次重建又变回 null
           });
         },
         child: ...,
       );
     },
   );
   ```

### 3. 检查事件是否触发

**关键诊断方法：添加调试日志**

在插件中添加：
```dart
Future<void> _refreshCache() async {
  debugPrint('[Plugin] _refreshCache called, _isInitialized=$_isInitialized');
  if (!_isInitialized) return;

  try {
    final items = await getData();
    debugPrint('[Plugin] Broadcasting xxx_cache_updated with ${items.length} items');

    eventManager.broadcast(
      'xxx_cache_updated',
      XxxCacheUpdatedEventArgs(items: items, period: DateTime.now()),
    );
  } catch (e) {
    debugPrint('[Plugin] 刷新缓存失败: $e');
  }
}
```

在 `EventListenerContainer` 中添加（临时调试）：
```dart
// 设置调试开关
const _kDebugEventListener = true;

void _registerEventListeners() {
  for (final event in widget.events) {
    void handler(EventArgs args) {
      if (_kDebugEventListener) {
        debugPrint('[EventListenerContainer] Received event: $event, args type: ${args.runtimeType}');
      }
      // ...
    }
    EventManager.instance.subscribe(event, handler);
    if (_kDebugEventListener) {
      debugPrint('[EventListenerContainer] Subscribed to: $event');
    }
  }
}
```

**检查日志输出：**
1. `[EventListenerContainer] Subscribed to: xxx_cache_updated` - 订阅成功
2. `[Plugin] _refreshCache called` - 刷新方法被调用
3. `[Plugin] Broadcasting xxx_cache_updated with X items` - 广播执行
4. `[EventListenerContainer] Received event: xxx_cache_updated` - 事件接收
5. `[EventListenerContainer] Calling onEventWithData` - 回调执行

### 4. 检查缓存刷新通知

在插件主文件 `<plugin-id>_plugin.dart` 中检查缓存刷新方法：

**传统模式：**
```dart
Future<void> refreshCache() async {
  if (!_isInitialized) return;

  try {
    final data = await _service.getData();
    _cachedData = data;
    _cacheValid = true;

    // 缓存刷新完成后通知监听器
    eventManager.broadcast('<plugin>_cache_updated', EventArgs());
  } catch (e) {
    debugPrint('[$Plugin] 刷新缓存失败: $e');
  }
}
```

**优化模式（事件携带数据，推荐）：**
```dart
Future<void> refreshCache() async {
  if (!_isInitialized) return;

  try {
    final data = await _service.getData();
    _cachedData = data;
    _cacheValid = true;

    // 广播时携带数据（性能优化：小组件可直接使用，无需再次获取）
    eventManager.broadcast(
      '<plugin>_cache_updated',
      XxxCacheUpdatedEventArgs(
        items: data,
        period: DateTime.now(),
      ),
    );
  } catch (e) {
    debugPrint('[$Plugin] 刷新缓存失败: $e');
  }
}
```

**检查清单：**
- [ ] 缓存刷新完成后发送了 `*_cache_updated` 事件
- [ ] 事件名称符合命名规范 `{plugin}_cache_updated`
- [ ] 在所有缓存刷新路径都发送了事件
- [ ] （推荐）事件携带数据，减少小组件重复获取

**常见问题：**
1. ❌ 缓存刷新后没有发送事件
   ```dart
   // 错误 - 缓存刷新完成后没有通知
   Future<void> refreshCache() async {
     final data = await _service.getData();
     _cachedData = data;
     _cacheValid = true;
     // 忘记了 eventManager.broadcast(...)
   }
   ```

2. ❌ 事件发送时机错误
   ```dart
   // 错误 - 在异步操作完成前就发送事件
   Future<void> refreshCache() async {
     eventManager.broadcast('cache_updated', EventArgs()); // 太早了！
     final data = await _service.getData(); // 还没完成
     _cachedData = data;
   }
   ```

3. ❌ 触发事件链断裂
   ```dart
   // 错误 - _refreshCache 没有被调用
   void _setupEventListeners() {
     eventManager.subscribe('xxx_added', (_) => _refreshCache());
     // 但 xxx_added 事件从未被广播！
   }
   ```
   检查数据操作（如 saveItem、deleteItem）是否广播了相应的事件。

### 5. 检查事件名称匹配

确保插件发送的事件和小组件监听的事件名称一致：

| 插件侧（发送） | 小组件侧（监听） | 是否匹配 |
|----------------|------------------|----------|
| `activity_added` | `activity_added` | ✅ |
| `activity_cache_updated` | `activity_cache_updated` | ✅ |
| `todo_created` | `todo_added` | ❌ |

**检查方法：**
```bash
# 搜索插件发送的事件
grep -r "eventManager.broadcast" lib/plugins/<plugin-id>/ | grep -o "'[^']*'"

# 搜索小组件监听的事件
grep -r "events: const" lib/plugins/<plugin-id>/home_widgets/ | grep -o "'[^']*'"
```

### 5. 检查时序问题

**问题场景：首次加载显示"暂无数据"**

**原因分析：**
1. 小组件首次加载时调用同步方法获取数据
2. 同步方法发现缓存无效，异步刷新缓存
3. 同步方法立即返回空列表
4. 小组件显示"暂无数据"
5. 缓存刷新完成后，没有通知小组件更新

**解决方案：**

#### 方案 A：添加缓存更新事件（推荐）

**步骤 1：在插件中添加事件发送**

```dart
// lib/plugins/<plugin-id>/<plugin-id>_plugin.dart

Future<void> refreshCache() async {
  if (!_isInitialized) return;

  try {
    final data = await _service.getData();
    _cachedData = data;
    _cacheValid = true;

    // 添加这一行
    eventManager.broadcast('<plugin>_cache_updated', EventArgs());
  } catch (e) {
    debugPrint('[$Plugin] 刷新缓存失败: $e');
  }
}
```

**步骤 2：在小组件中添加事件监听**

```dart
// lib/plugins/<plugin-id>/home_widgets/register_*.dart

EventListenerContainer(
  events: const [
    '<plugin>_added',
    '<plugin>_updated',
    '<plugin>_deleted',
    '<plugin>_cache_updated', // 添加这一行
  ],
  onEvent: () => setState(() {}),
  child: buildWidget(context, config),
)
```

#### 方案 B：同时刷新所有缓存

如果插件有多个缓存（今日缓存、周缓存等），确保它们在事件触发时都刷新：

```dart
// lib/plugins/<plugin-id>/<plugin-id>_plugin.dart

void refreshAllCaches() {
  refreshTodayCache();
  refreshWeeklyCache();
  refreshYesterdayCache();
}

// 监听事件
eventManager.subscribe('<plugin>_added', (_) => refreshAllCaches());
eventManager.subscribe('<plugin>_updated', (_) => refreshAllCaches());
eventManager.subscribe('<plugin>_deleted', (_) => refreshAllCaches());
```

#### 方案 C：改用异步方法

修改小组件使用异步方法获取数据，并在数据加载完成前显示加载状态：

```dart
class _WidgetState extends State<Widget> {
  bool _isLoading = true;
  List<Data> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plugin = PluginManager.instance.getPlugin('<plugin-id>');
    _data = await plugin.getDataAsync(); // 使用异步方法
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_data.isEmpty) {
      return Center(child: Text('暂无数据'));
    }
    return DataWidget(data: _data);
  }
}
```

### 6. 验证修复

运行以下命令验证修复：

```bash
# 分析代码
flutter analyze lib/plugins/<plugin-id>/ --no-pub

# 运行应用
flutter run
```

**测试步骤：**
1. 首次加载小组件，检查是否正确显示数据
2. 添加/修改/删除数据，检查小组件是否正确更新
3. 重启应用，检查缓存是否正确加载

## 常见问题诊断

### Issue: 首次加载显示"暂无数据"

| 症状 | 原因 | 解决方案 |
|------|------|----------|
| 加载后立即显示"暂无数据" | 缓存无效，异步刷新中，返回空列表 | 添加 `*_cache_updated` 事件监听 |
| 加载后一直显示"暂无数据" | 缓存刷新失败 | 检查异步操作的错误处理 |

### Issue: 数据变化后UI不更新

| 症状 | 原因 | 解决方案 |
|------|------|----------|
| 添加数据后UI不变 | 小组件未监听 `*_added` 事件 | 添加事件监听 |
| 修改数据后UI不变 | 小组件未监听 `*_updated` 事件 | 添加事件监听 |
| 删除数据后UI不变 | 小组件未监听 `*_deleted` 事件 | 添加事件监听 |
| 部分变化不更新 | 事件列表不完整 | 补全所有相关事件 |

### Issue: 事件名称不匹配

**检查命令：**
```bash
# 查找插件发送的所有事件
grep -r "eventManager.broadcast" lib/plugins/<plugin-id>/ | \
  grep -oE "'[a-z_]+_[a-z]+(_[a-z]+)'" | sort -u

# 查找小组件监听的所有事件
grep -r "events: const" lib/plugins/<plugin-id>/home_widgets/ | \
  grep -oE "'[a-z_]+_[a-z]+(_[a-z]+)'" | sort -u

# 对比差异
diff <(grep ...) <(grep ...)
```

### Issue: 使用 GenericSelectorWidget 但数据不更新

**症状：**
- 添加了 `EventListenerContainer` 并监听了正确的事件
- `setState(() {})` 被正确调用
- 但小组件仍然显示旧数据

**原因分析：**
`GenericSelectorWidget` 使用配置时保存的静态数据快照（`selectorConfig.toSelectorResult()`），即使外层 `EventListenerContainer` 触发了重建，仍然显示配置时保存的旧数据。

**诊断方法：**
```dart
// 检查是否直接使用 GenericSelectorWidget 但没有实时数据获取机制
builder: (context, config) {
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['xxx_updated'],
        onEvent: () => setState(() {}),  // ← setState 触发了，但...
        child: GenericSelectorWidget(    // ← 这里仍然使用静态数据！
          widgetDefinition: registry.getWidget('xxx')!,
          config: config,                // ← config 中的数据是旧的
        ),
      );
    },
  );
},
```

**解决方案：实时数据获取模式**

参考 `activity` 插件的实现，不直接使用 `GenericSelectorWidget`，而是在 `EventListenerContainer` 的 `child` 中创建一个**每次重建时从插件获取最新数据**的函数：

```dart
// lib/plugins/<plugin-id>/home_widgets.dart

builder: (context, config) {
  // 解析选择器配置
  SelectorWidgetConfig? selectorConfig;
  try {
    if (config.containsKey('selectorWidgetConfig')) {
      selectorConfig = SelectorWidgetConfig.fromJson(
        config['selectorWidgetConfig'] as Map<String, dynamic>,
      );
    }
  } catch (e) {
    debugPrint('[Plugin] 解析配置失败: $e');
  }

  // 未配置状态
  if (selectorConfig == null || !selectorConfig.isConfigured) {
    return _buildUnconfiguredWidget(context);
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const [
          '<plugin>_added',
          '<plugin>_updated',
          '<plugin>_deleted',
        ],
        onEvent: () => setState(() {}),
        child: _buildSelectorContent(context, config, selectorConfig!),
      );
    },
  );
},

/// 构建选择器内容（每次重建时获取最新数据）
static Widget _buildSelectorContent(
  BuildContext context,
  Map<String, dynamic> config,
  SelectorWidgetConfig selectorConfig,
) {
  // 从配置中获取数据ID
  final selectedData = selectorConfig.selectedData;
  final dataId = selectedData?['data']?['id'] as String?;

  if (dataId == null) {
    return HomeWidget.buildErrorWidget(context, '配置数据无效');
  }

  // 检查是否使用公共小组件
  if (selectorConfig.usesCommonWidget) {
    return _buildCommonWidgetWithLiveData(
      context,
      config,
      dataId,
      selectorConfig.commonWidgetId!,
      selectorConfig.commonWidgetProps ?? {},
    );
  }

  // 使用自定义渲染器（如果有的话）
  // ...
  return _buildDefaultWidget(context, dataId);
},

/// 使用实时数据构建公共小组件
static Widget _buildCommonWidgetWithLiveData(
  BuildContext context,
  Map<String, dynamic> config,
  String dataId,
  String commonWidgetId,
  Map<String, dynamic> savedProps,
) {
  // 关键：每次重建时获取实时数据
  final liveData = _getLiveDataFromPlugin(dataId);
  if (liveData == null) {
    return HomeWidget.buildErrorWidget(context, '数据不存在');
  }

  // 转换为枚举
  final widgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
  if (widgetIdEnum == null) {
    return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
  }

  // 获取元数据
  final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);
  final size = config['widgetSize'] as HomeWidgetSize? ?? metadata.defaultSize;

  // 使用实时数据更新 props
  final liveProps = _getLiveCommonWidgetProps(commonWidgetId, liveData, savedProps);

  return CommonWidgetBuilder.build(
    context,
    widgetIdEnum,
    liveProps,
    size,
    inline: true,
  );
},

/// 从插件获取实时数据（关键方法）
static Map<String, dynamic>? _getLiveDataFromPlugin(String dataId) {
  try {
    final plugin = PluginManager.instance.getPlugin('<plugin-id>') as MyPlugin?;
    if (plugin == null) return null;

    // 从插件获取最新数据
    final item = plugin.service.getItemById(dataId);
    if (item == null) return null;

    return {
      'id': item.id,
      'title': item.title,
      // ... 其他实时字段
    };
  } catch (e) {
    debugPrint('[Plugin] 获取数据失败: $e');
    return null;
  }
},

/// 获取公共小组件的实时 Props
static Map<String, dynamic> _getLiveCommonWidgetProps(
  String commonWidgetId,
  Map<String, dynamic> liveData,
  Map<String, dynamic> savedProps,
) {
  // 根据 commonWidgetId 返回对应的实时数据格式
  switch (commonWidgetId) {
    case 'circularProgressCard':
      return {
        'title': liveData['title'],
        'subtitle': '${liveData['count']} 条记录',
        'percentage': (liveData['count'] / 100 * 100).clamp(0, 100).toDouble(),
        'progress': (liveData['count'] / 100).clamp(0.0, 1.0),
      };
    // ... 其他小组件类型
    default:
      return {
        ...savedProps,
        ...liveData,
      };
  }
},
```

**检查清单：**
- [ ] builder 中不直接使用 `GenericSelectorWidget`（除非不需要实时更新）
- [ ] 创建了 `_getLiveDataFromPlugin` 方法从插件获取最新数据
- [ ] 公共小组件使用 `CommonWidgetBuilder.build` 直接渲染
- [ ] 每次重建时都会调用数据获取方法（不是在 initState 中）

**参考实现：**
- `lib/plugins/activity/home_widgets/providers.dart` - `buildCommonWidgetsWidget` 方法
- `lib/plugins/chat/home_widgets.dart` - `_buildSelectorContent` 方法

### Issue: 事件广播时序问题导致最新数据缺失

**症状：**
- 添加数据后，小组件更新但总是缺少最新添加的一条
- 修改数据后，小组件显示的是旧数据
- 删除数据后，小组件仍然显示已删除的数据

**原因分析：**
数据保存方法（如 `saveItem()`、`updateItem()`、`deleteItem()`）中，事件广播在数据保存**之前**执行。当事件触发时，异步刷新缓存开始读取文件，但此时新数据还未保存完成，导致缓存中不包含最新数据。

**错误示例：**
```dart
// ❌ 错误顺序：先广播事件，再保存数据
static Future<void> saveItem(Item item) async {
  // 1. 先广播事件（数据还没保存！）
  eventManager.broadcast('item_created', ItemCreatedEventArgs(item));

  // 2. 然后才保存数据
  await storage.writeJson(itemPath, item.toJson());
  await _updateIndex(item.id);
}
```

**正确示例：**
```dart
// ✅ 正确顺序：先保存数据，再广播事件
static Future<void> saveItem(Item item) async {
  // 1. 保存数据
  await storage.writeJson(itemPath, item.toJson());
  await _updateIndex(item.id);

  // 2. 数据保存完成后再广播事件
  eventManager.broadcast('item_created', ItemCreatedEventArgs(item));
}
```

**检查方法：**
```bash
# 查找所有数据保存/更新/删除方法
grep -n "Future.*save\|Future.*update\|Future.*delete" \
  lib/plugins/<plugin-id>/utils/*.dart \
  lib/plugins/<plugin-id>/services/*.dart

# 检查事件广播是否在数据保存之前
# 手动检查每个方法中的事件广播位置
```

**检查清单：**
- [ ] 在 `saveItem` 中，事件广播在 `writeJson/writeFile` **之后**
- [ ] 在 `updateItem` 中，事件广播在数据写入**之后**
- [ ] 在 `deleteItem` 中，事件广播在 `deleteFile` **之后**
- [ ] 索引更新（如果有）在事件广播**之前**完成
- [ ] 事件广播是操作的**最后一步**

**修复示例：**
```dart
static Future<void> saveDiaryEntry(
  DateTime date,
  String content, {
  String title = '',
  String? mood,
}) async {
  final storage = _storage;
  try {
    final normalizedDate = _normalizeDate(date);
    final dateStr = _formatDate(normalizedDate);
    final now = DateTime.now();
    final entryPath = _getEntryPath(normalizedDate);

    DiaryEntry newEntry;

    // 检查是否存在现有条目（保存前检查，保存时用变量）
    final isUpdate = await storage.fileExists(entryPath);

    if (isUpdate) {
      // 更新现有条目
      final existingData = await storage.readJson(entryPath);
      if (existingData == null) {
        throw Exception('Failed to read existing diary entry');
      }
      final existingEntry = DiaryEntry.fromJson(existingData);

      newEntry = existingEntry.copyWith(
        title: title,
        content: content,
        mood: mood,
        updatedAt: now,
      );
    } else {
      // 创建新条目
      newEntry = DiaryEntry(
        date: normalizedDate,
        title: title,
        content: content,
        mood: mood,
        createdAt: now,
        updatedAt: now,
      );
    }

    // 确保目录存在
    await storage.createDirectory(_pluginDir);

    // 保存日记条目（在广播事件之前保存）
    await storage.writeJson(entryPath, newEntry.toJson());

    // 更新索引文件
    await _updateDiaryIndex(dateStr);

    // 同步到小组件
    await _syncWidget();

    // 在数据保存完成后再广播事件
    if (isUpdate) {
      EventManager.instance.broadcast(
        'diary_entry_updated',
        DiaryEntryUpdatedEventArgs(newEntry),
      );
    } else {
      EventManager.instance.broadcast(
        'diary_entry_created',
        DiaryEntryCreatedEventArgs(newEntry),
      );
    }

    debugPrint('Saved diary entry for $dateStr');
  } catch (e) {
    debugPrint('Error saving diary entry: $e');
    throw Exception('Failed to save diary entry: $e');
  }
}
```

## 完整示例：修复 Activity 插件

### 修复前问题
- 首次加载显示"今日暂无活动"
- 添加活动后UI不更新

### 修复步骤

#### Step 1: 修改插件刷新所有缓存

```dart
// lib/plugins/activity/activity_plugin.dart

// 原来的代码：
eventManager.subscribe('activity_added', (_) => _refreshWeeklyActivitiesCache());
eventManager.subscribe('activity_updated', (_) => _refreshWeeklyActivitiesCache());
eventManager.subscribe('activity_deleted', (_) => _refreshWeeklyActivitiesCache());

// 修改后：
void refreshAllCaches() {
  _refreshWeeklyActivitiesCache();
  refreshTodayActivitiesCache();      // 添加
  _refreshYesterdayActivitiesCache();  // 添加
}

eventManager.subscribe('activity_added', (_) => refreshAllCaches());
eventManager.subscribe('activity_updated', (_) => refreshAllCaches());
eventManager.subscribe('activity_deleted', (_) => refreshAllCaches());
```

#### Step 2: 添加缓存更新事件

```dart
// lib/plugins/activity/activity_plugin.dart

Future<void> refreshTodayActivitiesCache() async {
  if (!_isInitialized) return;

  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activities = await _activityService.getActivitiesForDate(now);
    _cachedTodayActivities = activities;
    _todayActivitiesCacheValid = true;
    _cacheDate = today;

    // 同时更新统计数据缓存
    _cachedTodayActivityCount = activities.length;
    _cachedTodayActivityDuration =
        activities.fold<int>(0, (sum, a) => sum + a.durationInMinutes);

    // 添加这一行
    eventManager.broadcast('activity_cache_updated', EventArgs());
  } catch (e) {
    debugPrint('[ActivityPlugin] 刷新今日活动缓存失败: $e');
  }
}
```

#### Step 3: 监听新事件

```dart
// lib/plugins/activity/home_widgets/register_common_widgets.dart

// 原来的代码：
EventListenerContainer(
  events: const [
    'activity_added',
    'activity_updated',
    'activity_deleted',
  ],
  onEvent: () => setState(() {}),
  child: buildCommonWidgetsWidget(context, config),
)

// 修改后：
EventListenerContainer(
  events: const [
    'activity_added',
    'activity_updated',
    'activity_deleted',
    'activity_cache_updated',  // 添加这一行
  ],
  onEvent: () => setState(() {}),
  child: buildCommonWidgetsWidget(context, config),
)
```

## 检查清单

完成以下检查确保小组件更新正常：

### 基础检查
- [ ] 小组件使用了 `EventListenerContainer` 包裹
- [ ] `events` 列表包含所有数据变化事件（`*_added`, `*_updated`, `*_deleted`）
- [ ] `events` 列表包含缓存更新事件（`*_cache_updated`）
- [ ] `onEvent` 回调调用了 `setState(() {})`
- [ ] 缓存刷新方法在完成后发送了 `*_cache_updated` 事件
- [ ] 事件名称在插件发送方和小组件监听方一致
- [ ] 如果有多个缓存，确保在事件触发时都刷新

### 数据流检查
- [ ] **如果使用 `GenericSelectorWidget`，确保每次重建时从插件获取实时数据**（不是使用静态配置数据）
- [ ] **事件广播在数据保存**之后**（`saveItem` 中的 `eventManager.broadcast` 在 `writeJson/writeFile` 之后）**
- [ ] 索引更新（如果有）在事件广播**之前**完成
- [ ] 数据操作（saveItem、deleteItem 等）正确广播了事件

### 事件携带数据优化（推荐）
- [ ] 创建了 `{Plugin}CacheUpdatedEventArgs` 事件参数类
- [ ] 缓存刷新方法在广播时携带数据
- [ ] 小组件使用 `onEventWithData` 接收事件数据
- [ ] 缓存变量是 StatefulWidget 的状态变量（不是 builder 闭包中的局部变量）
- [ ] 在 `onEventWithData` 回调中进行了类型检查
- [ ] 处理了首次构建时缓存数据为 null 的情况

### 调试验证
- [ ] 添加调试日志验证事件订阅成功
- [ ] 添加调试日志验证事件广播执行
- [ ] 添加调试日志验证事件接收和回调执行
- [ ] 运行 `flutter analyze` 无错误

## 诊断流程图

```
小组件数据不更新
    │
    ├─→ 是否使用了 EventListenerContainer？
    │       ├─ 否 → 添加 EventListenerContainer
    │       └─ 是 ↓
    │
    ├─→ 事件是否触发？
    │       ├─ 检查方法：添加调试日志
    │       ├─ 日志显示订阅成功但未收到事件？
    │       │       ├─ 是 → 检查数据操作是否广播事件
    │       │       │       └─ 检查事件名称是否匹配
    │       │       └─ 否 ↓
    │       └─ 是 ↓
    │
    ├─→ 事件列表是否完整？
    │       ├─ 否 → 补全事件（*_added, *_updated, *_deleted, *_cache_updated）
    │       └─ 是 ↓
    │
    ├─→ onEvent/onEventWithData 是否正确？
    │       ├─ onEvent: 检查是否调用了 setState(() {})
    │       ├─ onEventWithData:
    │       │       ├─ 缓存变量是否为 StatefulWidget 的状态变量？
    │       │       ├─ 是否进行了类型检查？
    │       │       └─ 是否处理了 null 情况？
    │       └─ 是 ↓
    │
    ├─→ 是否直接使用 GenericSelectorWidget？
    │       ├─ 是 → 改用实时数据获取模式（见上文 Issue）
    │       └─ 否 ↓
    │
    ├─→ 缺少最新数据？
    │       ├─ 是 → 检查事件广播时序（见 Issue: 事件广播时序问题）
    │       │         ├─ 事件是否在数据保存**之前**广播？
    │       │         └─ 是 → 将事件广播移到保存**之后**
    │       └─ 否 ↓
    │
    └─→ 检查插件是否正确发送事件
            └─ 使用 grep 搜索 eventManager.broadcast

## 相关技能

| 技能 | 说明 |
|------|------|
| [migrate-event-data-optimization](migrate-event-data-optimization/SKILL.md) | 迁移小组件到事件携带数据模式 |
| [event-listener-container](event-listener-container/SKILL.md) | EventListenerContainer 使用指南 |

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/plugins/<plugin-id>/<plugin-id>_plugin.dart` | 插件主文件，包含缓存刷新和事件发送逻辑 |
| `lib/plugins/<plugin-id>/home_widgets/register_*.dart` | 小组件注册文件，包含事件监听逻辑 |
| `lib/plugins/<plugin-id>/home_widgets/providers.dart` | 数据提供者，可能包含数据获取逻辑 |
