[根目录](../../../CLAUDE.md) > [lib](../../) > [screens](../) > **home_screen**

---

# 主屏幕 (Home Screen) - 模块文档

## 模块职责

主屏幕是应用的核心入口，提供：

- **自定义主页布局**：灵活的网格布局系统，支持不同尺寸的小组件
- **网格大小调节**：支持 1-10 列可配置网格（默认 4 列）
- **小组件系统**：每个插件可注册多个小组件（1x1、2x1、2x2）
- **文件夹管理**：支持创建文件夹组织小组件，可在文件夹内添加组件
- **拖拽排序**：支持长按拖拽重新排列小组件和文件夹
- **持久化配置**：自动保存布局和网格配置到本地存储

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
- 管理网格布局配置（列数）
- 自动保存到配置文件

**关键 API**:
```dart
class HomeLayoutManager extends ChangeNotifier {
  /// 主页项目列表
  List<HomeItem> get items;

  /// 网格列数（默认为4，支持1-10）
  int get gridCrossAxisCount;

  /// 添加项目
  void addItem(HomeItem item);

  /// 移除项目
  void removeItem(String itemId);

  /// 重新排序
  void reorder(int oldIndex, int newIndex);

  /// 将项目移动到文件夹
  void moveToFolder(String itemId, String folderId);

  /// 直接添加项目到文件夹
  void addItemToFolder(HomeItem item, String folderId);

  /// 从文件夹中移出
  void removeFromFolder(String itemId, String folderId);

  /// 设置网格列数（1-10）
  void setGridCrossAxisCount(int count);

  /// 生成唯一ID
  String generateId();
}
```

**存储路径**: `configs/home_layout/settings.json`

**数据格式**:
```json
{
  "gridCrossAxisCount": 4,
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

### HomeWidgetSize (尺寸系统)

**文件**: `models/home_widget_size.dart`

**迁移指南**: [MIGRATION_GUIDE.md](models/MIGRATION_GUIDE.md)

#### 尺寸类型

| 类型 | 网格 | 说明 |
|------|------|------|
| `SmallSize` | 1x1 | 图标组件 |
| `MediumSize` | 2x1 | 横向卡片 |
| `LargeSize` | 2x2 | 大卡片 |
| `Large3Size` | 2x3 | 高卡片 |
| `WideSize` | 4x1 | 全宽卡片 |
| `Wide2Size` | 4x2 | 全宽大卡片 |
| `Wide3Size` | 4x3 | 全宽超大卡片 |
| `CustomSize` | 自定义 | 任意尺寸 |

#### 语义化 API（推荐使用）

```dart
// 布局方向判断
size.isWide      // 宽度 > 高度
size.isTall      // 高度 > 宽度
size.isSquare    // 宽度 == 高度

// 尺寸类别
size.category    // SizeCategory.mini/small/medium/large/xlarge

// 网格适配
size.getWidthRatio(gridColumns)   // 0.0 - 1.0
size.isFullWidth(gridColumns)     // 是否占满整行

// 便捷方法
size.isIconSized  // 1x1
size.isCardSized  // ≥2格
size.aspectRatio  // 宽高比
```

#### 使用示例

```dart
builder: (context, config) {
  final size = config['widgetSize'] as HomeWidgetSize;

  return LayoutBuilder(
    builder: (context, constraints) {
      // 结合语义 + 实际像素
      if (size.isWide && constraints.maxWidth > 300) {
        return _buildFullLayout(constraints);
      } else if (size.category == SizeCategory.mini) {
        return _buildIconLayout(constraints);
      }
      return _buildStandardLayout(constraints);
    },
  );
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

### 调节网格大小

```
用户点击右上角 ⋮ → 网格大小
  ↓
显示网格大小调节对话框
  ↓
使用滑块或 +/- 按钮调节（1-10列）
  ↓
HomeLayoutManager.setGridCrossAxisCount()
  ↓
实时更新主页布局并自动保存
```

### 文件夹内添加组件

```
用户点击文件夹卡片
  ↓
打开 FolderDialog
  ↓
点击右上角 + 按钮 → 添加小组件
  ↓
显示 AddWidgetDialog（携带 folderId）
  ↓
选择一个小组件
  ↓
HomeLayoutManager.addItemToFolder()
  ↓
组件添加到文件夹内部
```

---

## 常见问题 (FAQ)

### Q1: 如何修改主页网格的列数？

**用户操作方式**（推荐）：
1. 打开应用首页
2. 点击右上角的 ⋮ (更多按钮)
3. 选择"网格大小"
4. 使用滑块或 +/- 按钮调节（支持 1-10 列）
5. 配置会自动保存并实时生效

**代码方式**（开发者）：
```dart
// 通过 HomeLayoutManager 设置
final layoutManager = HomeLayoutManager();
layoutManager.setGridCrossAxisCount(3);  // 改为 3 列

// 或在 HomeScreen 中修改默认值
// 在 home_layout_manager.dart 中修改 _gridCrossAxisCount 的默认值
int _gridCrossAxisCount = 4;  // 改为你想要的默认值
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

### Q5: 如何使用拖拽排序？

拖拽排序功能已实现，使用方法：

**用户操作**：
1. 长按任意小组件或文件夹卡片（约 300 毫秒）
2. 卡片会变为半透明状态，并显示拖拽指示器
3. 拖动卡片到目标位置
4. 松开手指完成排序
5. 排序会自动保存

**视觉反馈**：
- 拖拽时原位置卡片变为 30% 不透明度
- 拖拽反馈显示拖拽指示器图标
- 目标位置会显示蓝色边框提示
- 提供触觉反馈（震动）

**开发者注意**：
- 使用 `LongPressDraggable` 和 `DragTarget` 实现
- 长按延迟为 300ms，防止误触
- 在文件夹内也支持拖拽排序（使用 3 列布局）

### Q6: 如何在文件夹内添加组件？

**用户操作**：
1. 点击主页的文件夹卡片打开文件夹
2. 在文件夹对话框中，点击右上角的 + 按钮
3. 选择"添加小组件"
4. 选择要添加的组件
5. 组件会直接添加到文件夹内部

**开发者注意**：
- `AddWidgetDialog` 接收可选的 `folderId` 参数
- 如果提供了 `folderId`，组件会添加到指定文件夹
- 使用 `layoutManager.addItemToFolder(item, folderId)` 方法

```dart
// 在文件夹内添加组件
showDialog(
  context: context,
  builder: (context) => AddWidgetDialog(folderId: folder.id),
);
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


---

**上级目录**: [返回根文档](../../../CLAUDE.md)
