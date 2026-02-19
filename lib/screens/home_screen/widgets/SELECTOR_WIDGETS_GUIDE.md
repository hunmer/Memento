# Selector Widget 使用指南

本文档介绍主页小组件系统中各种 Selector Widget 的区别和使用场景。

---

## 快速选择指南

| Widget | 使用场景 | 数据源 | 是否自动更新 |
|--------|----------|--------|-------------|
| `GenericIconWidget` | 快速添加简单图标小组件 | 无数据 | 不适用 |
| `GenericSelectorWidget` | 数据不变的小组件（如统计概览） | 静态数据 | ❌ 不自动更新 |
| `BaseSelectorWidget` | 使用配置数据的小组件 | `savedProps` | ❌ 不自动更新 |
| `LiveSelectorWidget` | 需要实时更新的小组件 | Provider 函数 | ✅ 自动更新 |

---

## 1. GenericIconWidget（简单图标）

### 适用场景
- 只需要显示一个图标和名称
- 不需要显示任何动态数据
- 用户点击后导航到插件主页面

### 示例
```dart
GenericIconWidget(
  icon: Icons.chat,
  iconColor: Colors.blue,
  label: '聊天',
  onTap: () => Navigator.pushNamed(context, '/chat'),
)
```

### 使用情况
- 聊天、日记、活动等插件的主入口图标
- 纯导航性小组件

---

## 2. GenericSelectorWidget（通用选择器）

### 适用场景
- 小组件显示的数据是静态的，不会变化
- 不需要监听事件自动更新
- 数据来自用户配置，但配置后不变

### 数据流
```
用户配置 → savedProps → 渲染组件
```

### 示例
```dart
GenericSelectorWidget(
  widgetDefinition: widgetDefinition,
  config: config,
)
```

### 使用情况
- **不使用**：已基本被 `BaseSelectorWidget` 和 `LiveSelectorWidget` 替代
- 遗留代码可能仍在使用

---

## 3. BaseSelectorWidget（基础选择器）

### 适用场景
- 使用公共小组件（CommonWidget）显示数据
- 数据来源于用户保存的配置（`savedProps`）
- 数据配置后不需要实时更新

### 数据流
```
用户配置 → savedProps → 公共小组件渲染
```

### 事件处理
- **不会**在事件触发时重新获取数据
- **不会**自动更新 UI

### 实现要点
```dart
class MyWidget extends BaseSelectorWidget {
  @override
  List<String> get eventListeners => [
    'my_event',  // 仅用于导航时的上下文
  ];

  @override
  String get widgetTag => 'MyWidget';

  @override
  Widget buildDefaultWidget(BuildContext context, SelectorResult result) {
    return HomeWidget.buildDefaultConfiguredWidget(
      context,
      result,
      widgetDefinition,
    );
  }
}
```

### 使用情况
- **不推荐**：已被 `LiveSelectorWidget` 替代
- 仅在不需要实时更新的场景使用

---

## 4. LiveSelectorWidget（实时数据选择器）⭐

### 适用场景
- 使用公共小组件显示数据
- 数据需要实时更新（如打卡状态、账单统计）
- 数据来自 Provider 函数动态获取

### 数据流
```
用户配置 → item ID
    ↓
事件触发（如 checkin_completed）
    ↓
getLiveData() → provideCommonWidgets() → 获取最新数据
    ↓
渲染公共小组件
```

### 事件处理
- **会**在事件触发时重新获取数据
- **会**自动更新 UI

### 实现要点
```dart
class MyWidget extends LiveSelectorWidget {
  @override
  List<String> get eventListeners => const [
    'checkin_completed',   // 打卡完成
    'checkin_cancelled',   // 取消打卡
    'checkin_reset',       // 重置打卡
    'checkin_deleted',     // 删除项目
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) {
    // 1. 从配置中提取数据
    final data = _extractDataFromConfig(config);

    // 2. 调用 provider 获取实时数据
    return provideMyCommonWidgets(data);
  }

  @override
  String get widgetTag => 'MyWidget';

  // 可选：自定义空状态
  @override
  Widget buildEmpty(BuildContext context) {
    return Center(child: Text('暂无数据'));
  }
}
```

### 使用情况
- **推荐使用**：大多数需要动态数据的小组件
- 示例：
  - 签到状态组件（需要实时显示打卡状态）
  - 账单统计组件（需要实时显示账单数据）
  - 物品列表组件（需要实时显示物品数据）

---

## 关键区别对比

### 数据更新机制

| Widget | 数据获取时机 | 自动更新 |
|--------|-------------|---------|
| `GenericIconWidget` | 无数据 | 不适用 |
| `GenericSelectorWidget` | 初始化时 | ❌ 不自动更新 |
| `BaseSelectorWidget` | 初始化时，使用 `savedProps` | ❌ 不自动更新 |
| `LiveSelectorWidget` | 初始化时 + 每次事件触发 | ✅ 自动更新 |

### 内部实现

#### BaseSelectorWidget（不自动更新）
```dart
StatefulBuilder(
  builder: (context, setState) {
    return EventListenerContainer(
      events: eventListeners,
      onEvent: () => setState(() {}),  // setState 但不重新获取数据
      child: _buildWithSavedProps(),    // 只用 savedProps
    ),
  },
)
```

#### LiveSelectorWidget（自动更新）
```dart
StatefulBuilder(
  builder: (context, setState) {
    return EventListenerContainer(
      events: eventListeners,
      onEvent: () => setState(() {}),  // setState 导致 FutureBuilder 重新执行
      child: FutureBuilder(
        future: getLiveData(config),     // 每次都重新获取数据
        builder: (context, snapshot) {
          // 用最新数据渲染
        },
      ),
    ),
  },
)
```

---

## 迁移指南

### 从 BaseSelectorWidget 迁移到 LiveSelectorWidget

如果你的小组件数据需要动态更新，进行以下步骤：

#### 1. 修改导入
```dart
// 旧
import 'package:Memento/screens/home_screen/widgets/base/base_selector_widget.dart';

// 新
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
```

#### 2. 修改继承的基类
```dart
// 旧
class _MyWidget extends BaseSelectorWidget {
  // ...
}

// 新
class _MyWidget extends LiveSelectorWidget {
  // ...
}
```

#### 3. 实现 getLiveData 方法
```dart
@override
Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) {
  // 提取配置数据
  final data = _extractDataFromConfig(config);
  // 调用 provider 获取实时数据
  return provideMyCommonWidgets(data);
}
```

#### 4. 删除 buildDefaultWidget 方法（LiveSelectorWidget 不需要）

---

## 最佳实践

### 1. 优先使用 LiveSelectorWidget
- 大多数需要显示数据的小组件都应该使用 `LiveSelectorWidget`
- 确保数据始终是最新的

### 2. 正确设置事件监听
```dart
@override
List<String> get eventListeners => const [
  'item_added',      // 添加时更新
  'item_deleted',    // 删除时更新
  'item_updated',    // 更新时更新
];
```

### 3. 自定义空状态
```dart
@override
Widget buildEmpty(BuildContext context) {
  final theme = Theme.of(context);
  return SizedBox.expand(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 8),
          Text('暂无数据'),
        ],
      ),
    ),
  );
}
```

### 4. 从配置中提取数据的模式
```dart
Map<String, dynamic> _extractDataFromConfig(Map<String, dynamic> config) {
  try {
    final selectorConfig = config['selectorWidgetConfig'] as Map<String, dynamic>?;
    if (selectorConfig != null) {
      final selectedData = selectorConfig['selectedData'] as Map<String, dynamic>?;
      if (selectedData != null && selectedData.containsKey('data')) {
        final dataArray = selectedData['data'] as List<dynamic>?;
        if (dataArray != null && dataArray.isNotEmpty) {
          // 单选：返回第一个元素
          return dataArray[0] as Map<String, dynamic>;
          // 多选：返回 {'items': dataArray}
          // return {'items': List<Map<String, dynamic>>.from(dataArray)};
        }
      }
    }
  } catch (e) {
    debugPrint('[MyWidget] 提取数据失败: $e');
  }
  return {};
}
```

---

## 常见问题

### Q1: 为什么我的小组件数据没有更新？
**A**: 检查以下几点：
1. 是否使用了 `BaseSelectorWidget` 而不是 `LiveSelectorWidget`？
2. `eventListeners` 是否包含了正确的事件名称？
3. Provider 函数是否正确返回了最新数据？

### Q2: BaseSelectorWidget 还有使用场景吗？
**A**: 基本没有。`LiveSelectorWidget` 可以完成 `BaseSelectorWidget` 的所有功能，并且支持自动更新。

### Q3: 如何确定应该监听哪些事件？
**A**: 查看对应插件的文档，找到事件系统部分。例如：
- 打卡插件：`checkin_completed`, `checkin_cancelled`, `checkin_reset`, `checkin_deleted`
- 账单插件：`bill_added`, `bill_deleted`, `account_added`, `account_deleted`
- 物品插件：`goods_item_added`, `goods_item_deleted`

---

## 总结

| Widget | 状态 | 推荐度 |
|--------|------|--------|
| `GenericIconWidget` | ✅ 活跃 | ⭐⭐⭐⭐⭐（纯导航小组件） |
| `GenericSelectorWidget` | ⚠️ 遗留 | ⭐（仅用于静态数据） |
| `BaseSelectorWidget` | ⚠️ 遗留 | ⭐（基本被 LiveSelectorWidget 替代） |
| `LiveSelectorWidget` | ✅ 活跃 | ⭐⭐⭐⭐⭐（推荐用于所有动态数据小组件） |

**核心原则**：需要显示动态数据的小组件，一律使用 `LiveSelectorWidget`。
