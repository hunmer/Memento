---
name: migrate-event-data-optimization
description: 迁移小组件到事件携带数据模式，优化刷新性能。将数据直接放在事件中传递，小组件直接使用事件数据，避免重复的缓存访问操作。
---

# 事件数据优化迁移指南

将小组件从"事件通知 + 再次获取数据"模式迁移到"事件携带数据"模式，减少重复的缓存访问操作。

## 背景

### 优化前流程（传统模式）

```
数据变更 → 广播事件（无数据）→ N 个小组件监听 → 每个小组件都调用 plugin.getXxxSync() 获取数据
```

**问题**：如果同一页面上有多个小组件监听同一事件，会造成重复的缓存访问操作。

### 优化后流程（推荐模式）

```
数据变更 → 广播事件（携带数据）→ N 个小组件监听 → 直接使用事件中的数据
```

**优势**：数据只获取一次，所有小组件直接使用事件携带的数据。

## 迁移步骤

### 第一步：创建携带数据的事件参数类

在插件主文件中创建新的事件参数类，继承 `EventArgs`：

```dart
// lib/plugins/<plugin-id>/<plugin-id>_plugin.dart

/// 缓存更新事件参数（携带数据，性能优化）
class XxxCacheUpdatedEventArgs extends EventArgs {
  /// 数据列表
  final List<DataItem> items;

  /// 当前时间段（如月份/日期）
  final DateTime period;

  /// 条目数量
  final int count;

  XxxCacheUpdatedEventArgs({
    required this.items,
    required this.period,
  }) : count = items.length,
       super('xxx_cache_updated');
}
```

**命名规范**：`{Plugin}CacheUpdatedEventArgs`

### 第二步：修改缓存刷新方法

修改插件中的缓存刷新方法，在广播时携带数据：

```dart
// lib/plugins/<plugin-id>/<plugin-id>_plugin.dart

// 修改前：
Future<void> _refreshCache() async {
  if (!_isInitialized) return;

  try {
    await getData();
    eventManager.broadcast('xxx_cache_updated', EventArgs());
  } catch (e) {
    debugPrint('[Plugin] 刷新缓存失败: $e');
  }
}

// 修改后：
Future<void> _refreshCache() async {
  if (!_isInitialized) return;

  try {
    final items = await getData();
    final now = DateTime.now();

    // 广播时携带数据（性能优化：小组件可直接使用，无需再次获取）
    eventManager.broadcast(
      'xxx_cache_updated',
      XxxCacheUpdatedEventArgs(
        items: items,
        period: DateTime(now.year, now.month),
      ),
    );
  } catch (e) {
    debugPrint('[Plugin] 刷新缓存失败: $e');
  }
}
```

### 第三步：修改小组件使用新 API

修改小组件使用 `onEventWithData` 参数，直接使用事件携带的数据：

```dart
// lib/plugins/<plugin-id>/home_widgets/providers.dart

// 修改前：
Widget buildXxxWidget(BuildContext context, Map<String, dynamic> config) {
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['xxx_cache_updated'],
        onEvent: () => setState(() {}),
        child: _buildContent(context, config),
      );
    },
  );
}

Widget _buildContent(BuildContext context, Map<String, dynamic> config) {
  // 每次重建都从插件获取数据
  final plugin = PluginManager.instance.getPlugin('xxx') as XxxPlugin?;
  final items = plugin?.getXxxSync() ?? [];
  // ... 渲染
}

// 修改后：
Widget buildXxxWidget(BuildContext context, Map<String, dynamic> config) {
  return _XxxWidgetStatefulWidget(config: config);
}

/// 内部 StatefulWidget 用于持有缓存的事件数据
class _XxxWidgetStatefulWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const _XxxWidgetStatefulWidget({required this.config});

  @override
  State<_XxxWidgetStatefulWidget> createState() => _XxxWidgetStatefulWidgetState();
}

class _XxxWidgetStatefulWidgetState extends State<_XxxWidgetStatefulWidget> {
  /// 缓存的事件数据（性能优化：直接使用事件携带的数据）
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
      child: _buildContent(context, widget.config, _cachedItems),
    );
  }
}

Widget _buildContent(
  BuildContext context,
  Map<String, dynamic> config,
  List<DataItem>? cachedItems,
) {
  // 优先使用事件携带的缓存数据，否则从插件获取（首次构建时的回退）
  List<DataItem> items;

  if (cachedItems != null) {
    items = cachedItems;  // 性能优化路径
  } else {
    // 回退：从插件同步获取（首次构建或向后兼容）
    final plugin = PluginManager.instance.getPlugin('xxx') as XxxPlugin?;
    items = plugin?.getXxxSync() ?? [];
  }

  // ... 渲染
}
```

### 第四步：更新数据获取方法签名

如果数据获取方法需要支持可选的缓存数据参数：

```dart
// lib/plugins/<plugin-id>/home_widgets/providers.dart

/// 获取小组件数据
/// [cachedItems] 事件携带的缓存数据（性能优化），为 null 时从插件获取
Map<String, dynamic>? _getXxxDataSync(
  String widgetId,
  List<DataItem>? cachedItems,
) {
  try {
    // 优先使用事件携带的缓存数据
    List<DataItem> items;

    if (cachedItems != null) {
      items = cachedItems;
    } else {
      // 回退：从插件同步获取
      final plugin = PluginManager.instance.getPlugin('xxx') as XxxPlugin?;
      if (plugin == null) return null;
      items = plugin.getXxxSync();
    }

    // ... 数据处理
  } catch (e) {
    debugPrint('[Plugin] 获取数据失败: $e');
    return null;
  }
}
```

## 向后兼容性

| 场景 | 兼容性 | 说明 |
|------|--------|------|
| 现有代码使用 `onEvent: () => setState(() {})` | ✅ 完全兼容 | 无需修改，仍可正常工作 |
| 新代码使用 `onEventWithData` | ✅ 新功能 | 可按需迁移 |
| 事件广播 `EventArgs()` | ✅ 仍可用 | 基类仍可使用 |
| 事件广播 `XxxCacheUpdatedEventArgs` | ✅ 子类兼容 | 继承自 EventArgs |

## 常见陷阱

### 陷阱 1：局部变量无法保存状态

❌ **错误**：在 `StatefulBuilder` 的 builder 闭包中声明缓存变量

```dart
return StatefulBuilder(
  builder: (context, setState) {
    List<DataItem>? cachedItems;  // ❌ 每次重建都会重置为 null

    return EventListenerContainer(
      onEventWithData: (args) {
        setState(() {
          cachedItems = args.items;  // ❌ 设置后，下次重建又变回 null
        });
      },
      child: ...,
    );
  },
);
```

✅ **正确**：创建专用的 StatefulWidget 持有状态

```dart
return _XxxWidgetStatefulWidget(config: config);

class _XxxWidgetStatefulWidgetState extends State<_XxxWidgetStatefulWidget> {
  List<DataItem>? _cachedItems;  // ✅ 状态变量，重建时保留

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      onEventWithData: (args) {
        if (args is XxxCacheUpdatedEventArgs) {
          setState(() {
            _cachedItems = args.items;  // ✅ 正确保存
          });
        }
      },
      child: ...,
    );
  }
}
```

### 陷阱 2：忘记类型检查

❌ **错误**：直接使用 args 而不检查类型

```dart
onEventWithData: (args) {
  setState(() {
    _cachedItems = args.items;  // ❌ EventArgs 没有 items 属性
  });
},
```

✅ **正确**：先检查类型再使用

```dart
onEventWithData: (args) {
  if (args is XxxCacheUpdatedEventArgs) {  // ✅ 类型检查
    setState(() {
      _cachedItems = args.items;
    });
  }
},
```

### 陷阱 3：首次构建无数据

⚠️ **注意**：首次构建时，事件还没有触发，`cachedItems` 为 null

```dart
Widget _buildContent(
  BuildContext context,
  Map<String, dynamic> config,
  List<DataItem>? cachedItems,
) {
  // ✅ 必须处理 cachedItems 为 null 的情况
  List<DataItem> items = cachedItems ?? _getItemsFromPlugin();

  // ... 渲染
}
```

## 检查清单

完成以下检查确保迁移正确：

- [ ] 创建了 `{Plugin}CacheUpdatedEventArgs` 事件参数类
- [ ] 事件参数类包含必要的字段（items、period、count 等）
- [ ] 缓存刷新方法在广播时创建并传递事件参数实例
- [ ] 小组件使用专用的 StatefulWidget 持有缓存数据
- [ ] 使用 `onEventWithData` 参数接收事件
- [ ] 在回调中进行了类型检查 `if (args is XxxCacheUpdatedEventArgs)`
- [ ] 处理了首次构建时缓存数据为 null 的情况
- [ ] 运行 `flutter analyze` 无错误
- [ ] 测试数据变化后小组件正常更新

## 示例：Diary 插件迁移

### 事件参数类

```dart
// lib/plugins/diary/diary_plugin.dart

/// 日记缓存更新事件参数（携带数据）
class DiaryCacheUpdatedEventArgs extends EventArgs {
  final List<(DateTime, DiaryEntry)> entries;
  final DateTime month;
  final int count;

  DiaryCacheUpdatedEventArgs({
    required this.entries,
    required this.month,
  }) : count = entries.length,
       super('diary_cache_updated');
}
```

### 缓存刷新方法

```dart
// lib/plugins/diary/diary_plugin.dart

Future<void> _refreshMonthlyEntriesCache() async {
  if (!_isInitialized) return;

  try {
    final entries = await getMonthlyDiaryEntries();
    final now = DateTime.now();

    eventManager.broadcast(
      'diary_cache_updated',
      DiaryCacheUpdatedEventArgs(
        entries: entries,
        month: DateTime(now.year, now.month),
      ),
    );
  } catch (e) {
    debugPrint('[DiaryPlugin] 刷新本月日记缓存失败: $e');
  }
}
```

### 小组件实现

```dart
// lib/plugins/diary/home_widgets/providers.dart

Widget buildMonthlyDiaryListWidget(
  BuildContext context,
  Map<String, dynamic> config,
) {
  // ... 配置验证 ...

  return _MonthlyDiaryListStatefulWidget(
    config: config,
    commonWidgetId: commonWidgetId,
  );
}

class _MonthlyDiaryListStatefulWidgetState
    extends State<_MonthlyDiaryListStatefulWidget> {
  List<(DateTime, DiaryEntry)>? _cachedEntries;

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['diary_cache_updated'],
      onEventWithData: (args) {
        if (args is DiaryCacheUpdatedEventArgs) {
          setState(() {
            _cachedEntries = args.entries;
          });
        }
      },
      child: _buildMonthlyDiaryListContent(
        context,
        widget.config,
        widget.commonWidgetId,
        _cachedEntries,
      ),
    );
  }
}
```

## 相关文档

- [check-widget-update-issues.md](../check-widget-update-issues.md) - 小组件更新问题诊断
- [event-listener-container/SKILL.md](../event-listener-container/SKILL.md) - EventListenerContainer 使用指南
