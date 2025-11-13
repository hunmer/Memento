[根目录](../../../CLAUDE.md) > [lib](../../) > [screens](../) > **home_screen**

---

# 主屏幕 (Home Screen) - 模块文档

## 模块职责

主屏幕是应用的核心入口，提供：

- **自定义主页布局**：灵活的网格布局系统，支持不同尺寸的小组件
- **小组件系统**：每个插件可注册多个小组件（1x1、2x1、2x2）
- **文件夹管理**：支持创建文件夹组织小组件
- **拖拽排序**：可重新排列小组件和文件夹（功能开发中）
- **持久化配置**：自动保存布局到本地存储

---

## 核心架构

### 新架构（2025-11-13 重构）

```
HomeScreen (主屏幕)
  ├── HomeLayoutManager (布局管理器)
  │   ├── 管理主页项目列表 (List<HomeItem>)
  │   ├── 增删改查操作
  │   └── 持久化到 home_layout 配置
  │
  ├── HomeWidgetRegistry (小组件注册中心)
  │   ├── 注册所有插件的小组件
  │   ├── 按分类组织
  │   └── 提供查询接口
  │
  └── UI 组件
      ├── HomeGrid - 网格布局
      ├── HomeCard - 卡片组件
      ├── AddWidgetDialog - 添加组件对话框
      ├── CreateFolderDialog - 创建文件夹对话框
      └── FolderDialog - 文件夹内容对话框
```

---

## 入口与启动

**主文件**: `home_screen.dart`

**路由**: `/` (应用默认路由)

**初始化流程**:
```dart
HomeScreen
  ├── 初始化 HomeLayoutManager
  ├── 加载布局配置 (home_layout.json)
  ├── 如果为空，创建默认布局
  └── 渲染 HomeGrid
```

---

## 核心组件

### 1. HomeLayoutManager (布局管理器)

**文件**: `managers/home_layout_manager.dart`

**职责**:
- 管理主页上的所有项目（小组件和文件夹）
- 提供增删改查、拖拽排序、文件夹管理等功能
- 自动保存到配置文件

**关键 API**:
```dart
class HomeLayoutManager extends ChangeNotifier {
  /// 主页项目列表
  List<HomeItem> get items;

  /// 添加项目
  void addItem(HomeItem item);

  /// 移除项目
  void removeItem(String itemId);

  /// 重新排序
  void reorder(int oldIndex, int newIndex);

  /// 将项目移动到文件夹
  void moveToFolder(String itemId, String folderId);

  /// 从文件夹中移出
  void removeFromFolder(String itemId, String folderId);

  /// 生成唯一ID
  String generateId();
}
```

**存储路径**: `configs/home_layout/settings.json`

**数据格式**:
```json
{
  "items": [
    {
      "id": "item_1700000001",
      "type": "widget",
      "widgetId": "chat_overview",
      "size": {"width": 2, "height": 2},
      "config": {}
    },
    {
      "id": "item_1700000002",
      "type": "folder",
      "name": "工具",
      "icon": 62057,
      "iconFontFamily": "MaterialIcons",
      "color": 4280391411,
      "children": [...]
    }
  ]
}
```

---

### 2. HomeWidgetRegistry (小组件注册中心)

**文件**: `managers/home_widget_registry.dart`

**职责**:
- 管理所有插件注册的小组件定义
- 提供按分类、按插件查询功能

**关键 API**:
```dart
class HomeWidgetRegistry {
  /// 注册小组件
  void register(HomeWidget widget);

  /// 获取指定ID的小组件
  HomeWidget? getWidget(String id);

  /// 按分类获取（用于添加对话框）
  Map<String, List<HomeWidget>> getWidgetsByCategory();

  /// 按插件ID获取
  List<HomeWidget> getWidgetsByPlugin(String pluginId);
}
```

**使用示例**:
```dart
// 在插件的 home_widgets.dart 中注册
class ChatHomeWidgets {
  static void register() {
    final registry = HomeWidgetRegistry();

    registry.register(HomeWidget(
      id: 'chat_icon',
      pluginId: 'chat',
      name: '聊天',
      icon: Icons.chat_bubble,
      color: Colors.indigoAccent,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '通讯',
      builder: (context, config) => _buildIconWidget(context),
    ));
  }
}
```

---

### 3. HomeGrid (网格布局组件)

**文件**: `widgets/home_grid.dart`

**职责**:
- 使用 `flutter_staggered_grid_view` 渲染不同尺寸的卡片
- 支持空状态显示
- 传递事件（点击、长按、重排序）

**关键特性**:
- 支持 1x1、2x1、2x2 三种尺寸
- 自适应列数（默认 2 列）
- 文件夹固定为 1x1

---

### 4. HomeCard (卡片组件)

**文件**: `widgets/home_card.dart`

**职责**:
- 渲染单个小组件或文件夹
- 处理点击事件（打开插件或文件夹）
- 显示错误状态

**布局**:
- **小组件卡片**: 由 `HomeWidget.builder` 渲染自定义内容
- **文件夹卡片**: 显示图标、名称、项目数量徽章

---

### 5. UI 对话框

#### AddWidgetDialog (添加组件对话框)

**文件**: `widgets/add_widget_dialog.dart`

**特性**:
- TabBar 按分类展示小组件
- GridView 预览小组件（图标、名称、描述、支持的尺寸）
- 点击添加到主页

#### CreateFolderDialog (创建文件夹对话框)

**文件**: `widgets/create_folder_dialog.dart`

**特性**:
- 输入文件夹名称
- 选择图标（10 种常用图标）
- 选择颜色（10 种预设颜色）

#### FolderDialog (文件夹内容对话框)

**文件**: `widgets/folder_dialog.dart`

**特性**:
- 显示文件夹内的所有项目（使用 HomeGrid）
- 支持添加小组件到文件夹
- 支持从文件夹移出到主页
- 支持编辑文件夹（开发中）
- 支持删除文件夹内的项目

---

## 数据模型

### HomeItem (主页项目基类)

**文件**: `models/home_item.dart`

```dart
enum HomeItemType { widget, folder }

abstract class HomeItem {
  final String id;
  final HomeItemType type;

  Map<String, dynamic> toJson();
  static HomeItem fromJson(Map<String, dynamic> json);
}
```

### HomeWidgetItem (小组件实例)

**文件**: `models/home_widget_item.dart`

```dart
class HomeWidgetItem extends HomeItem {
  final String widgetId;         // 引用 HomeWidget.id
  final HomeWidgetSize size;     // 当前尺寸
  final Map<String, dynamic> config;  // 小组件配置
}
```

### HomeFolderItem (文件夹)

**文件**: `models/home_folder_item.dart`

```dart
class HomeFolderItem extends HomeItem {
  final String name;
  final IconData icon;
  final Color color;
  final List<HomeItem> children;  // 嵌套的项目
}
```

### HomeWidget (小组件定义)

**文件**: `widgets/home_widget.dart`

```dart
class HomeWidget {
  final String id;                   // 唯一标识
  final String pluginId;             // 所属插件
  final String name;                 // 显示名称
  final String? description;         // 描述
  final IconData icon;               // 图标
  final Color? color;                // 主题色
  final HomeWidgetSize defaultSize;  // 默认尺寸
  final List<HomeWidgetSize> supportedSizes;  // 支持的尺寸
  final String category;             // 分类
  final HomeWidgetBuilder builder;   // 构建器
}
```

### HomeWidgetSize (尺寸枚举)

**文件**: `models/home_widget_size.dart`

```dart
enum HomeWidgetSize {
  small(1, 1),   // 1x1 图标组件
  medium(2, 1),  // 2x1 横向卡片
  large(2, 2);   // 2x2 大卡片

  final int width;
  final int height;
}
```

---

## 插件开发指南

### 如何为插件添加主页小组件

#### 步骤 1: 创建小组件注册文件

在插件目录下创建 `home_widgets.dart`:

```dart
import 'package:flutter/material.dart';
import '../../screens/home_screen/models/home_widget_size.dart';
import '../../screens/home_screen/widgets/home_widget.dart';
import '../../screens/home_screen/managers/home_widget_registry.dart';

class MyPluginHomeWidgets {
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 图标组件
    registry.register(HomeWidget(
      id: 'myplugin_icon',
      pluginId: 'myplugin',
      name: '我的插件',
      description: '快速访问',
      icon: Icons.extension,
      color: Colors.blue,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: '工具',
      builder: (context, config) => _buildIconWidget(context),
    ));

    // 2x2 详情卡片
    registry.register(HomeWidget(
      id: 'myplugin_overview',
      pluginId: 'myplugin',
      name: '插件概览',
      description: '显示统计信息',
      icon: Icons.dashboard,
      color: Colors.blue,
      defaultSize: HomeWidgetSize.large,
      supportedSizes: [HomeWidgetSize.large],
      category: '工具',
      builder: (context, config) => _buildOverviewWidget(context),
    ));
  }

  static Widget _buildIconWidget(BuildContext context) {
    return Center(
      child: Icon(Icons.extension, size: 48, color: Colors.blue),
    );
  }

  static Widget _buildOverviewWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 自定义内容...
        ],
      ),
    );
  }
}
```

#### 步骤 2: 在 main.dart 中注册

```dart
// 在 _initializeHomeWidgets() 函数中添加
MyPluginHomeWidgets.register();
```

#### 步骤 3: 更新插件文档

在插件的 `CLAUDE.md` 中添加小组件说明：

```markdown
## 主页小组件

### 注册的小组件

| ID | 名称 | 尺寸 | 说明 |
|----|------|------|------|
| myplugin_icon | 我的插件 | 1x1 | 快速访问图标 |
| myplugin_overview | 插件概览 | 2x2 | 统计信息展示 |

### 注册文件
- 路径：`lib/plugins/myplugin/home_widgets.dart`
- 注册时机：`main.dart` 初始化时调用
```

---

## 用户交互流程

### 添加小组件

```
用户点击右上角 + 按钮
  ↓
显示 AddWidgetDialog
  ↓
按分类浏览小组件
  ↓
选择一个小组件
  ↓
HomeLayoutManager.addItem()
  ↓
自动保存并刷新界面
```

### 创建文件夹

```
用户点击右上角 ⋮ → 新建文件夹
  ↓
显示 CreateFolderDialog
  ↓
输入名称、选择图标和颜色
  ↓
HomeLayoutManager.addItem(HomeFolderItem)
  ↓
文件夹出现在主页
```

### 打开文件夹

```
用户点击文件夹卡片
  ↓
HomeCard._openFolderDialog()
  ↓
显示 FolderDialog
  ↓
显示文件夹内的小组件网格
  ↓
可以添加/移除/删除项目
```

### 移除项目

```
用户长按主页卡片
  ↓
显示操作菜单（TODO）
  ↓
选择"移除"
  ↓
HomeLayoutManager.removeItem()
  ↓
项目从主页消失
```

---

## 常见问题 (FAQ)

### Q1: 如何修改主页网格的列数？

在 `HomeGrid` 中修改 `crossAxisCount` 参数：

```dart
HomeGrid(
  items: items,
  crossAxisCount: 3,  // 改为 3 列
)
```

### Q2: 如何让小组件支持多种尺寸？

在注册时指定 `supportedSizes`：

```dart
registry.register(HomeWidget(
  // ...
  defaultSize: HomeWidgetSize.large,
  supportedSizes: [
    HomeWidgetSize.medium,
    HomeWidgetSize.large,
  ],
  // ...
));
```

用户在添加后可以调整尺寸（功能开发中）。

### Q3: 如何在小组件中访问插件数据？

在 `builder` 函数中获取插件实例：

```dart
builder: (context, config) {
  final plugin = PluginManager.instance.getPlugin('myplugin') as MyPlugin;
  final data = plugin.getData();

  return FutureBuilder(
    future: data,
    builder: (context, snapshot) {
      // 使用数据渲染 UI
    },
  );
}
```

### Q4: 如何持久化小组件的自定义配置？

使用 `HomeWidgetItem.config` 存储配置：

```dart
// 添加时设置初始配置
final widgetItem = HomeWidgetItem(
  id: layoutManager.generateId(),
  widgetId: 'myplugin_config',
  size: HomeWidgetSize.large,
  config: {'theme': 'dark', 'showTitle': true},
);

// 在 builder 中读取配置
builder: (context, config) {
  final theme = config['theme'] ?? 'light';
  final showTitle = config['showTitle'] ?? false;
  // 使用配置渲染 UI
}
```

### Q5: 如何实现拖拽排序？

拖拽功能目前使用简化实现，后续可以集成 `reorderable_grid_view` 包：

```dart
// TODO: 使用 ReorderableHomeGrid 替代 HomeGrid
ReorderableHomeGrid(
  items: items,
  onReorder: (oldIndex, newIndex) {
    layoutManager.reorder(oldIndex, newIndex);
  },
)
```

---

## 相关文件清单

### 核心文件
- `home_screen.dart` - 主屏幕主类
- `managers/home_layout_manager.dart` - 布局管理器
- `managers/home_widget_registry.dart` - 小组件注册中心

### 数据模型
- `models/home_item.dart` - 项目基类
- `models/home_widget_item.dart` - 小组件项
- `models/home_folder_item.dart` - 文件夹项
- `models/home_widget_size.dart` - 尺寸枚举

### UI 组件
- `widgets/home_grid.dart` - 网格布局
- `widgets/home_card.dart` - 卡片组件
- `widgets/home_widget.dart` - 小组件定义
- `widgets/add_widget_dialog.dart` - 添加组件对话框
- `widgets/create_folder_dialog.dart` - 创建文件夹对话框
- `widgets/folder_dialog.dart` - 文件夹内容对话框

### 已废弃（兼容保留）
- `card_size.dart` - 旧版卡片尺寸（已被 HomeWidgetSize 替代）
- `card_size_manager.dart` - 旧版尺寸管理器
- `plugin_order_manager.dart` - 旧版顺序管理器
- `plugin_grid.dart` - 旧版网格布局
- `plugin_card.dart` - 旧版卡片组件

---

## 变更记录 (Changelog)

- **2025-11-13T04:06:10+00:00**: 初始化主屏幕文档
- **2025-11-13T15:00:00+00:00**: 重大重构
  - 引入 `HomeLayoutManager` 统一管理布局
  - 引入 `HomeWidgetRegistry` 小组件注册系统
  - 新增文件夹功能
  - 新增添加组件对话框
  - 重构数据模型和 UI 组件
  - 废弃旧版 CardSizeManager 和 PluginOrderManager

---

**上级目录**: [返回根文档](../../../CLAUDE.md)
