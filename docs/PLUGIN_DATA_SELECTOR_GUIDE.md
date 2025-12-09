# 插件数据选择器系统指南

> 本文档面向 AI/LLM，用于快速理解如何为 Memento 插件注册数据选择器。

---

## 系统概述

**插件数据选择器系统**允许各插件注册自己的数据选择器，提供统一的数据选择 UI。用户可以通过 Bottom Sheet 形式选择插件数据（如聊天消息、日记条目、AI Agent 等）。

### 核心特性

- **多级选择**：支持层级导航（如：频道 → 消息）
- **多视图类型**：列表 (list)、网格 (grid)、日历 (calendar)
- **单选/多选**：可配置选择模式
- **搜索过滤**：支持本地搜索
- **完整路径返回**：返回选择路径 + 最终数据对象

---

## 核心文件位置

```
lib/core/services/plugin_data_selector/
├── index.dart                              # 导出文件
├── plugin_data_selector_service.dart       # 核心服务（单例）
└── models/
    ├── index.dart                          # 模型导出
    ├── selectable_item.dart                # 可选项模型
    ├── selector_step.dart                  # 选择步骤
    ├── selector_definition.dart            # 选择器定义
    ├── selector_config.dart                # 显示配置
    └── selector_result.dart                # 返回结果

lib/widgets/data_selector_sheet/
├── data_selector_sheet.dart                # 主 Sheet 组件
├── components/                             # UI 组件
└── views/                                  # 视图实现
```

---

## 快速开始

### 1. 导入依赖

```dart
import 'package:Memento/core/services/plugin_data_selector/index.dart';
```

### 2. 在插件 initialize() 中注册

```dart
@override
Future<void> initialize() async {
  // ... 其他初始化代码

  // 注册数据选择器（放在初始化末尾）
  _registerDataSelectors();
}
```

### 3. 实现注册方法

```dart
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'myplugin.item',           // 格式: {pluginId}.{selectorName}
    pluginId: id,                   // 插件 ID
    name: '选择项目',               // 显示名称
    icon: icon,                     // 插件图标
    color: color,                   // 主题色
    searchable: true,               // 是否支持搜索
    selectionMode: SelectionMode.single,  // 单选/多选
    steps: [
      SelectorStep(
        id: 'item',
        title: '选择项目',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (_) async {
          // 返回可选项列表
          return myItems.map((item) => SelectableItem(
            id: item.id,
            title: item.name,
            subtitle: item.description,
            icon: Icons.folder,
            rawData: item,  // ⚠️ 重要：原始数据对象
          )).toList();
        },
      ),
    ],
  ));
}
```

---

## 核心模型详解

### SelectableItem（可选项）

```dart
SelectableItem(
  id: String,                    // 唯一标识（必需）
  title: String,                 // 显示标题（必需）
  subtitle: String?,             // 副标题
  icon: IconData?,               // 图标
  color: Color?,                 // 颜色
  avatarPath: String?,           // 头像路径
  rawData: dynamic,              // ⚠️ 原始数据对象（选择后返回）
  metadata: Map<String, dynamic>?, // 附加元数据
  selectable: bool,              // 是否可选（默认 true）
)
```

### SelectorStep（选择步骤）

```dart
SelectorStep(
  id: String,                    // 步骤 ID（必需）
  title: String,                 // 步骤标题（必需）
  viewType: SelectorViewType,    // 视图类型（必需）
  dataLoader: SelectorDataLoader, // 数据加载器（必需）
  isFinalStep: bool,             // 是否最终步骤（默认 false）
  searchFilter: SelectorSearchFilter?, // 自定义搜索过滤器
  emptyText: String?,            // 空状态提示
  gridCrossAxisCount: int,       // 网格列数（默认 2）
  gridChildAspectRatio: double,  // 网格宽高比（默认 1.0）
)
```

### SelectorViewType（视图类型）

| 类型 | 说明 | 适用场景 |
|------|------|---------|
| `list` | 列表视图 | 默认选择，消息、联系人等 |
| `grid` | 网格视图 | AI Agent、图标选择等 |
| `calendar` | 日历视图 | 日记、按日期选择 |

### SelectionMode（选择模式）

| 模式 | 说明 |
|------|------|
| `single` | 单选（点击即选中） |
| `multiple` | 多选（勾选后确认） |

---

## 多级选择示例

以 Chat 插件为例：先选频道，再选消息

```dart
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'chat.message',
    pluginId: id,
    name: '选择消息',
    icon: Icons.message,
    color: color,
    steps: [
      // 第一步：选择频道
      SelectorStep(
        id: 'channel',
        title: '选择频道',
        viewType: SelectorViewType.list,
        isFinalStep: false,  // ⚠️ 非最终步骤
        dataLoader: (_) async {
          return channels.map((c) => SelectableItem(
            id: c.id,
            title: c.title,
            icon: Icons.chat,
            rawData: c,
          )).toList();
        },
      ),
      // 第二步：选择消息
      SelectorStep(
        id: 'message',
        title: '选择消息',
        viewType: SelectorViewType.list,
        isFinalStep: true,  // ⚠️ 最终步骤
        dataLoader: (previousSelections) async {
          // ⚠️ 从 previousSelections 获取上一步选择的数据
          final channel = previousSelections['channel'] as Channel;
          return channel.messages.map((m) => SelectableItem(
            id: m.id,
            title: m.content,
            rawData: m,
          )).toList();
        },
      ),
    ],
  ));
}
```

---

## 自定义搜索过滤器

默认搜索仅匹配 `title` 和 `subtitle`。如需自定义：

```dart
SelectorStep(
  // ...
  searchFilter: (items, query) {
    if (query.isEmpty) return items;
    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      final entry = item.rawData as DiaryEntry;
      return item.title.toLowerCase().contains(lowerQuery) ||
          entry.content.toLowerCase().contains(lowerQuery) ||
          (entry.mood?.contains(query) ?? false);
    }).toList();
  },
)
```

**⚠️ 注意**：`searchFilter` 的签名是 `List<SelectableItem> Function(List<SelectableItem> items, String query)`，不是单项过滤器！

---

## 调用选择器

```dart
// 调用选择器
final result = await pluginDataSelectorService.showSelector(
  context,
  'chat.message',  // 选择器 ID
);

// 处理结果
if (result == null || result.cancelled) {
  // 用户取消
  return;
}

// 获取选择的数据
final message = result.data as Message;

// 获取选择路径中的数据
final channel = result.getPathRawData<Channel>('channel');

// 转换为 Map
final map = result.toMap();
// {
//   'plugin': 'chat',
//   'selector': 'chat.message',
//   'path': [...],
//   'data': {...}
// }
```

---

## 已注册的选择器参考

| 选择器 ID | 插件 | 视图类型 | 层级 | 说明 |
|----------|------|---------|-----|------|
| `chat.channel` | chat | list | 1 | 选择频道 |
| `chat.message` | chat | list | 2 | 选择消息（频道→消息） |
| `openai.agent` | openai | grid | 1 | 选择 AI Agent |
| `openai.prompt` | openai | list | 1 | 选择 Prompt 预设 |
| `diary.entry` | diary | calendar | 1 | 选择日记条目 |

---

## 注意事项

### 1. ID 命名规范

```
格式: {pluginId}.{selectorName}
示例: chat.message, openai.agent, diary.entry
```

### 2. rawData 必须设置

`SelectableItem.rawData` 是选择后返回的实际数据对象，**必须设置**！

```dart
SelectableItem(
  id: item.id,
  title: item.name,
  rawData: item,  // ✅ 必须设置
)
```

### 3. 多级选择的 dataLoader

非首步骤的 `dataLoader` 接收 `previousSelections` 参数：

```dart
dataLoader: (previousSelections) async {
  // key 是上一步的 stepId，value 是选中项的 rawData
  final channel = previousSelections['channel'] as Channel;
  // ...
}
```

### 4. searchFilter 签名

```dart
// ✅ 正确：过滤整个列表
searchFilter: (List<SelectableItem> items, String query) {
  return items.where(...).toList();
}

// ❌ 错误：单项过滤
searchFilter: (SelectableItem item, String query) {
  return item.title.contains(query);  // 类型不匹配！
}
```

### 5. isFinalStep 标记

- 最后一步必须设置 `isFinalStep: true`
- 非最终步骤选中后会自动进入下一步
- 最终步骤选中后会返回结果并关闭 Sheet

### 6. 视图类型选择

| 场景 | 推荐视图 |
|------|---------|
| 列表数据、消息、联系人 | `list` |
| 卡片式展示、Agent、图标 | `grid` |
| 按日期选择、日记、日程 | `calendar` |

### 7. 网格视图配置

```dart
SelectorStep(
  viewType: SelectorViewType.grid,
  gridCrossAxisCount: 3,        // 每行 3 列
  gridChildAspectRatio: 0.8,    // 宽高比
  // ...
)
```

### 8. 多选模式

```dart
SelectorDefinition(
  selectionMode: SelectionMode.multiple,
  // ...
)

// 处理多选结果
if (result is MultiSelectorResult) {
  final items = result.selectedItems;  // List<SelectableItem>
  final count = result.selectionCount;
}
```

---

## 测试页面

设置 → 开发者测试 → **数据选择器测试**

可以：
- 查看所有已注册的选择器
- 测试各选择器功能
- 查看返回结果格式

---

## 完整示例：为新插件添加选择器

```dart
// my_plugin.dart

import 'package:Memento/core/services/plugin_data_selector/index.dart';

class MyPlugin extends BasePlugin {
  @override
  String get id => 'myplugin';

  @override
  Future<void> initialize() async {
    await storage.createDirectory(id);

    // 注册数据选择器
    _registerDataSelectors();
  }

  void _registerDataSelectors() {
    // 1. 简单单级选择器
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'myplugin.item',
      pluginId: id,
      name: '选择项目',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'item',
          title: '选择项目',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            final items = await loadItems();
            return items.map((item) => SelectableItem(
              id: item.id,
              title: item.name,
              subtitle: item.description,
              icon: Icons.folder,
              color: color,
              rawData: item,
            )).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery) ||
                  (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
            }).toList();
          },
        ),
      ],
    ));

    // 2. 多级选择器（如需要）
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'myplugin.subitem',
      pluginId: id,
      name: '选择子项目',
      icon: icon,
      color: color,
      steps: [
        SelectorStep(
          id: 'category',
          title: '选择分类',
          viewType: SelectorViewType.grid,
          isFinalStep: false,
          dataLoader: (_) async => loadCategories(),
        ),
        SelectorStep(
          id: 'item',
          title: '选择项目',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (prev) async {
            final category = prev['category'] as Category;
            return loadItemsByCategory(category.id);
          },
        ),
      ],
    ));
  }
}
```

---

## 相关文件

- 服务实现：`lib/core/services/plugin_data_selector/plugin_data_selector_service.dart`
- UI 组件：`lib/widgets/data_selector_sheet/`
- 测试页面：`lib/screens/data_selector_test/data_selector_test_screen.dart`
- 路由注册：`lib/screens/route.dart` (`/data_selector_test`)

---

**最后更新**: 2024-12-09
