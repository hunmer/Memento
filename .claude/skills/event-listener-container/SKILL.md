---
name: event-listener-container
description: 为Flutter插件视图添加事件监听容器，自动管理事件订阅/取消订阅生命周期，避免内存泄漏并减少约84%的模板代码。适用场景：(1) 插件视图需要响应全局事件更新UI，(2) 需要避免手动管理订阅导致的内存泄漏，(3) 简化事件监听实现
---

# EventListenerContainer

为Flutter插件视图添加事件监听容器，自动管理事件订阅生命周期。

## Workflow

### 1. Analyze Target File

识别以下内容：

- State class 或 StatelessWidget
- 需要监听的事件名称列表（如 `task_added`, `task_updated`）
- UI 更新逻辑（`setState()` 或控制器方法调用）

### 2. Add Import

```dart
import 'package:Memento/widgets/event_listener_container.dart';
```

### 3. Wrap UI with EventListenerContainer

在需要响应事件的 UI 外层包裹组件：

```dart
EventListenerContainer(
  events: ['task_added', 'task_updated', 'task_deleted'],
  onEvent: () => setState(() {}),
  child: MyContentWidget(),
)
```

### 4. Combine with AnimatedBuilder (Optional)

当同时依赖控制器状态和事件时：

```dart
EventListenerContainer(
  events: ['task_added', 'task_updated', 'task_deleted'],
  onEvent: () {},  // 事件触发但不直接更新
  child: AnimatedBuilder(
    animation: myController,
    builder: (context, _) {
      return MyContentWidget(data: myController.data);
    },
  ),
)
```

### 5. Multiple Independent Listeners

同一页面可以有多个独立的监听器：

```dart
Column(
  children: [
    // 监听数据变更事件
    EventListenerContainer(
      events: ['data_changed'],
      onEvent: () => setState(() => _dataVersion++),
      child: DataDisplayWidget(),
    ),
    // 监听UI相关事件
    EventListenerContainer(
      events: ['theme_changed', 'locale_changed'],
      onEvent: () => _refreshTheme(),
      child: ThemedWidget(),
    ),
  ],
)
```

### 6. Conditional Update (Optional)

在 `onEvent` 中添加条件判断：

```dart
EventListenerContainer(
  events: ['item_added', 'item_updated', 'item_deleted'],
  onEvent: () {
    final eventName = EventManager.instance.getLatestEventName() ?? '';
    if (eventName == 'item_deleted' && shouldSkipDeleteUpdate) {
      return;
    }
    setState(() {});
  },
  child: MyContentWidget(),
)
```

## Detection Patterns

### Event Names

查找以下模式的事件名称：

| 事件类型 | 命名示例 | 说明 |
|----------|----------|------|
| 添加 | `task_added`, `note_created` | 使用过去式 |
| 更新 | `task_updated`, `settings_changed` | 使用过去式 |
| 删除 | `task_deleted`, `item_removed` | 使用过去式 |
| 完成 | `task_completed`, `goal_achieved` | 使用过去式 |
| 状态变更 | `status_changed`, `visibility_updated` | 使用过去式 |

### Controller Integration

查找以下模式：

- 控制器继承自 `ChangeNotifier`
- 使用 `AnimatedBuilder` 响应控制器变化
- 控制器有 `refreshFromRemote()` 或类似方法

## Comparison: Manual vs EventListenerContainer

### Manual Approach (Before)

```dart
class MyView extends StatefulWidget {
  const MyView({super.key});

  @override
  State<MyView> createState() => _MyViewState();
}

class _MyViewState extends State<MyView> {
  final List<(String, void Function(EventArgs))> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _registerListeners();
  }

  void _registerListeners() {
    void handler1(EventArgs args) {
      if (mounted) setState(() {});
    }
    EventManager.instance.subscribe('task_added', handler1);
    _subscriptions.add(('task_added', handler1));
    // ... 更多事件
  }

  @override
  void dispose() {
    for (final (eventName, handler) in _subscriptions) {
      EventManager.instance.unsubscribe(eventName, handler);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [...]);
  }
}
```

### EventListenerContainer (After)

```dart
class MyView extends StatelessWidget {
  const MyView({super.key});

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: ['task_added', 'task_updated', 'task_deleted'],
      onEvent: () => setState(() {}),
      child: Column(children: [...]),
    );
  }
}
```

**代码量对比：**
- 手动方式：约 50 行
- EventListenerContainer：约 8 行
- **减少约 84% 的模板代码**

## Best Practices

### 1. Minimize Scope

只在需要响应事件的最小 UI 区域使用，避免不必要的重建。

### 2. Group Related Events

将相关事件分组，不要一次性监听所有事件。

### 3. Combine with Controller

对于复杂逻辑，将更新逻辑封装在控制器中，`onEvent` 只调用控制器方法：

```dart
EventListenerContainer(
  events: ['external_sync_event'],
  onEvent: () => myController.refreshFromRemote(),
  child: AnimatedBuilder(
    animation: myController,
    builder: (context, _) => ListView(...),
  ),
)
```

### 4. Debounce Updates (Optional)

如果多个事件可能连续触发，考虑使用防抖：

```dart
bool _isUpdating = false;

EventListenerContainer(
  events: ['batch_update'],
  onEvent: () {
    if (_isUpdating) return;
    _isUpdating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdating = false;
      setState(() {});
    });
  },
  child: MyContentWidget(),
)
```

## Troubleshooting

### 事件触发了但 UI 没有更新？

检查：
1. `EventListenerContainer` 是否正确包裹了目标 UI
2. `onEvent` 回调中是否调用了 `setState()` 或触发更新的方法

### 如何获取事件参数？

通过 `EventManager.instance.getLatestEvent()` 获取：

```dart
EventListenerContainer(
  events: ['item_added'],
  onEvent: () {
    final latestEvent = EventManager.instance.getLatestEvent('item_added');
    if (latestEvent != null && latestEvent is ItemEventArgs) {
      print('添加的项目ID: ${latestEvent.itemId}');
    }
    setState(() {});
  },
  child: MyContentWidget(),
)
```

### 多个监听器会重复触发吗？

不会。每个 `EventListenerContainer` 都是独立的订阅者，只会更新各自的子树。

## Notes

- 在 `initState` 自动订阅，`dispose` 自动取消订阅
- Debug 模式下自动打印事件收发日志
- 多个 `EventListenerContainer` 独立工作，不会相互干扰
- 使用中文注释与现有代码库保持一致
- 使用 `flutter analyze` 验证代码
