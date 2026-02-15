---
name: check-widget-update-issues
description: 检查小组件更新问题，诊断首次加载显示"暂无数据"、数据变化后UI不更新等问题。检查事件监听、缓存刷新通知、事件名称匹配等。
---

# Check Widget Update Issues

检查和诊断小组件更新相关问题，包括首次加载显示"暂无数据"、数据变化后UI不更新等。

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

在 `register_*.dart` 文件中检查小组件是否正确监听了数据变化事件：

**正确模式：**
```dart
EventListenerContainer(
  events: const [
    '<plugin>_<action>',
    '<plugin>_<action>',
    // ... 其他数据变化事件
  ],
  onEvent: () => setState(() {}),
  child: buildWidget(...),
)
```

**检查清单：**
- [ ] 使用了 `EventListenerContainer` 包裹小组件
- [ ] `events` 列表包含所有相关的数据变化事件
- [ ] `onEvent` 回调调用了 `setState(() {})`

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

### 3. 检查缓存刷新通知

在插件主文件 `<plugin-id>_plugin.dart` 中检查缓存刷新方法：

**正确模式：**
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

**检查清单：**
- [ ] 缓存刷新完成后发送了 `*_cache_updated` 事件
- [ ] 事件名称符合命名规范 `{plugin}_cache_updated`
- [ ] 在所有缓存刷新路径都发送了事件

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

### 4. 检查事件名称匹配

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

- [ ] 小组件使用了 `EventListenerContainer` 包裹
- [ ] `events` 列表包含所有数据变化事件（`*_added`, `*_updated`, `*_deleted`）
- [ ] `events` 列表包含缓存更新事件（`*_cache_updated`）
- [ ] `onEvent` 回调调用了 `setState(() {})`
- [ ] 缓存刷新方法在完成后发送了 `*_cache_updated` 事件
- [ ] 事件名称在插件发送方和小组件监听方一致
- [ ] 如果有多个缓存，确保在事件触发时都刷新
- [ ] 运行 `flutter analyze` 无错误

## 相关文件

| 文件 | 说明 |
|------|------|
| `lib/plugins/<plugin-id>/<plugin-id>_plugin.dart` | 插件主文件，包含缓存刷新和事件发送逻辑 |
| `lib/plugins/<plugin-id>/home_widgets/register_*.dart` | 小组件注册文件，包含事件监听逻辑 |
| `lib/plugins/<plugin-id>/home_widgets/providers.dart` | 数据提供者，可能包含数据获取逻辑 |
