[根目录](../../../CLAUDE.md) > [lib](../../) > [screens](../) > **home_screen**

---

# 主屏幕 (Home Screen) - 模块文档

## 模块职责

主屏幕是应用的核心入口，提供：

- **插件网格展示**：以卡片形式展示所有已注册的插件
- **卡片自定义**：支持自定义卡片大小（1x1, 2x1, 2x2）
- **插件排序**：拖拽重新排列插件顺序
- **快速访问**：点击卡片直接进入插件
- **最近使用**：高亮显示最近打开的插件

---

## 入口与启动

**主文件**: `home_screen.dart`

**路由**: `/` (应用默认路由)

**初始化流程**:
```dart
HomeScreen
  ├── 加载插件列表 (PluginManager.getAllPlugins())
  ├── 加载插件顺序配置 (PluginOrderManager)
  ├── 加载卡片大小配置 (CardSizeManager)
  └── 构建插件网格 (PluginGrid)
```

---

## 核心组件

### PluginGrid (插件网格)

**文件**: `plugin_grid.dart`

**职责**:
- 使用 `reorderable_grid_view` 包实现可拖拽网格
- 根据卡片大小动态计算布局
- 响应插件点击事件

**关键代码**:
```dart
ReorderableGridView.builder(
  itemCount: plugins.length,
  itemBuilder: (context, index) {
    final plugin = plugins[index];
    final cardSize = cardSizeManager.getCardSize(plugin.id);
    return PluginCard(
      plugin: plugin,
      size: cardSize,
      onTap: () => pluginManager.openPlugin(context, plugin),
    );
  },
  onReorder: (oldIndex, newIndex) {
    pluginOrderManager.reorderPlugins(oldIndex, newIndex);
  },
)
```

---

### PluginCard (插件卡片)

**文件**: `plugin_card.dart`

**职责**:
- 展示插件图标、名称、颜色
- 可选显示插件自定义的卡片视图 (`buildCardView`)
- 长按显示操作菜单（调整大小、删除等）

**卡片布局**:
```
┌─────────────────────┐
│  [图标]  插件名称      │
│                     │
│  (自定义卡片内容)     │
│                     │
└─────────────────────┘
```

---

### CardSizeManager (卡片大小管理)

**文件**: `card_size_manager.dart`

**职责**:
- 持久化保存每个插件的卡片大小
- 提供获取/设置卡片大小的 API

**存储路径**: `configs/card_sizes.json`

**数据格式**:
```json
{
  "chat": "2x2",
  "diary": "2x1",
  "activity": "1x1"
}
```

**API**:
```dart
// 获取卡片大小
CardSize getCardSize(String pluginId) {
  return _sizes[pluginId] ?? CardSize.medium; // 默认 2x1
}

// 设置卡片大小
Future<void> setCardSize(String pluginId, CardSize size) async {
  _sizes[pluginId] = size;
  await _saveToStorage();
}
```

---

### PluginOrderManager (插件顺序管理)

**文件**: `plugin_order_manager.dart`

**职责**:
- 持久化保存插件显示顺序
- 提供重新排序的 API

**存储路径**: `configs/plugin_order.json`

**数据格式**:
```json
["chat", "openai", "diary", "activity", ...]
```

**API**:
```dart
// 获取排序后的插件列表
List<PluginBase> getSortedPlugins(List<PluginBase> allPlugins) {
  final order = _loadOrder();
  return allPlugins.sortBy((p) => order.indexOf(p.id));
}

// 重新排序
Future<void> reorderPlugins(int oldIndex, int newIndex) async {
  final order = _loadOrder();
  final item = order.removeAt(oldIndex);
  order.insert(newIndex, item);
  await _saveOrder(order);
}
```

---

## 关键依赖

- `reorderable_grid_view`: 可拖拽网格视图
- `provider`: 状态管理（可选）
- `shared_preferences`: 配置持久化（通过 StorageManager）

---

## 数据模型

### CardSize (卡片大小)

**文件**: `card_size.dart`

```dart
enum CardSize {
  small,   // 1x1
  medium,  // 2x1
  large,   // 2x2
}

extension CardSizeExtension on CardSize {
  int get width {
    switch (this) {
      case CardSize.small: return 1;
      case CardSize.medium: return 2;
      case CardSize.large: return 2;
    }
  }

  int get height {
    switch (this) {
      case CardSize.small: return 1;
      case CardSize.medium: return 1;
      case CardSize.large: return 2;
    }
  }
}
```

---

## 用户交互流程

### 插件点击
```
用户点击插件卡片
  ↓
PluginCard.onTap()
  ↓
PluginManager.openPlugin(context, plugin)
  ↓
Navigator.pushNamed(context, '/${plugin.id}')
  ↓
跳转到插件主界面
```

### 卡片重排
```
用户长按拖拽卡片
  ↓
ReorderableGridView.onReorder()
  ↓
PluginOrderManager.reorderPlugins()
  ↓
保存新顺序到配置文件
  ↓
刷新界面
```

### 卡片大小调整
```
用户长按卡片 → 显示菜单
  ↓
选择 "调整大小"
  ↓
显示大小选择器 (Small / Medium / Large)
  ↓
CardSizeManager.setCardSize()
  ↓
保存并刷新界面
```

---

## 常见问题

### Q1: 如何让插件卡片显示自定义内容？

在插件类中重写 `buildCardView` 方法：

```dart
class MyPlugin extends PluginBase {
  @override
  Widget? buildCardView(BuildContext context) {
    return Column(
      children: [
        Text('今日数据: $todayData'),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
```

### Q2: 如何禁用插件拖拽？

暂不支持，所有插件卡片都可拖拽。如需此功能，可在 `PluginGrid` 中添加配置项。

### Q3: 卡片大小为什么没有 1x2 选项？

当前设计基于移动端竖屏，网格为 2 列布局。1x2 会导致布局不协调，因此未提供。

---

## 相关文件清单

- `home_screen.dart` - 主屏幕主类
- `plugin_grid.dart` - 插件网格组件
- `plugin_card.dart` - 插件卡片组件
- `card_size.dart` - 卡片大小枚举
- `card_size_manager.dart` - 卡片大小管理器
- `plugin_order_manager.dart` - 插件顺序管理器

---

## 变更记录

- **2025-11-13T04:06:10+00:00**: 初始化主屏幕文档

---

**上级目录**: [返回根文档](../../../CLAUDE.md)
