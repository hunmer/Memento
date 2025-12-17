# 小组件路由架构说明

## 概述

本文档说明了 Memento 项目中小组件路由的模块化架构设计。通过将路由逻辑根据插件拆分，使代码更加模块化、易于维护和扩展。

## 架构设计

### 1. 核心架构

```
lib/
├── core/
│   └── routing/
│       └── plugin_route_handler.dart    # 路由处理器基类
├── plugins/
│   ├── checkin/
│   │   └── checkin_route_handler.dart   # 打卡插件路由处理器
│   └── todo/
│       └── todo_route_handler.dart      # 待办插件路由处理器
└── screens/
    └── route.dart                        # 主路由文件
```

### 2. 组件说明

#### PluginRouteHandler（基类）
- **位置**: `lib/core/routing/plugin_route_handler.dart`
- **职责**: 定义插件路由处理器的通用接口
- **主要方法**:
  - `pluginId`: 插件唯一标识符
  - `handleRoute(RouteSettings)`: 处理路由请求，返回 Route 或 null
  - `createRoute(Widget)`: 创建无动画过渡的路由

#### CheckinRouteHandler（打卡插件）
- **位置**: `lib/plugins/checkin/checkin_route_handler.dart`
- **处理的路由**:
  - `/checkin_item_selector?widgetId={widgetId}` - 小组件配置
  - `/checkin_item?itemId={itemId}&date={date}` - 小组件点击

#### TodoRouteHandler（待办插件）
- **位置**: `lib/plugins/todo/todo_route_handler.dart`
- **处理的路由**:
  - `/todo_list_selector?widgetId={widgetId}` - 小组件配置
  - `/todo_task_detail?taskId={taskId}` - 任务详情
  - `/todo_add` - 添加任务
  - `/todo_list` - 待办列表

#### AppRoutes（主路由）
- **位置**: `lib/screens/route.dart`
- **职责**: 协调所有路由处理器，处理全局路由
- **工作流程**:
  1. 遍历所有插件路由处理器
  2. 如果某个处理器能处理当前路由，直接返回
  3. 否则使用原有的 switch 逻辑处理通用路由

## 如何添加新插件的路由处理器

### 步骤 1: 创建路由处理器

在插件目录下创建 `<plugin_id>_route_handler.dart` 文件：

```dart
import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';

/// [插件名称]路由处理器
class MyPluginRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'my_plugin';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理插件特定的路由
    if (routeName.startsWith('/my_plugin_action')) {
      return _handleMyAction(routeName, settings.arguments);
    }

    // 无法处理该路由
    return null;
  }

  /// 处理具体的路由逻辑
  Route<dynamic> _handleMyAction(String routeName, Object? arguments) {
    // 解析参数
    final uri = Uri.parse(routeName);
    final param = uri.queryParameters['param'];

    // 返回对应的页面
    return createRoute(MyPluginScreen(param: param));
  }
}
```

### 步骤 2: 注册路由处理器

在 `lib/screens/route.dart` 中注册新的路由处理器：

```dart
// 1. 导入路由处理器
import 'package:Memento/plugins/my_plugin/my_plugin_route_handler.dart';

// 2. 添加到处理器列表
class AppRoutes extends NavigatorObserver {
  static final List<PluginRouteHandler> _pluginRouteHandlers = [
    CheckinRouteHandler(),
    TodoRouteHandler(),
    MyPluginRouteHandler(),  // 添加新的处理器
  ];

  // ...
}
```

### 步骤 3: 测试

运行代码分析确保无错误：

```bash
flutter analyze lib/plugins/my_plugin/my_plugin_route_handler.dart
```

## 设计优势

### 1. 模块化
- 每个插件的路由逻辑独立在各自的文件中
- 修改一个插件的路由不会影响其他插件
- 代码组织更清晰，易于理解

### 2. 可扩展性
- 添加新插件的路由只需创建新的处理器类
- 不需要修改大量的主路由文件
- 遵循开闭原则（对扩展开放，对修改关闭）

### 3. 可维护性
- 路由逻辑和插件代码紧密相关，便于维护
- 减少了主路由文件的代码量和复杂度
- 每个处理器职责单一，易于测试

### 4. 灵活性
- 插件可以自由定义自己的路由格式
- 可以在处理器中添加插件特定的路由验证和处理逻辑
- 支持复杂的参数解析和条件路由

## 路由命名规范

为保持一致性，建议遵循以下命名规范：

### 小组件配置路由
```
/{plugin_id}_xxx_selector?widgetId={widgetId}
```
示例：
- `/checkin_item_selector?widgetId=123`
- `/todo_list_selector?widgetId=456`

### 小组件点击路由
```
/{plugin_id}_xxx?param1={value1}&param2={value2}
```
示例：
- `/checkin_item?itemId=abc&date=2025-12-01`
- `/todo_task_detail?taskId=xyz`

### 插件操作路由
```
/{plugin_id}_action
```
示例：
- `/todo_add`
- `/checkin_record`

## 常见问题

### Q: 路由处理器的执行顺序重要吗？
A: 是的。路由处理器按照在 `_pluginRouteHandlers` 列表中的顺序执行。如果多个处理器可能处理相同的路由，应该将更具体的处理器放在前面。

### Q: 如何处理路由参数？
A: 有两种方式获取参数：
1. 从 `RouteSettings.arguments` 获取（通常用于程序内导航）
2. 从 URI 查询参数中解析（通常用于 Deep Link）

建议同时支持两种方式以提高兼容性。

### Q: 为什么使用无动画的路由过渡？
A: 这是项目的设计选择，可以提供更快速的页面切换体验。你可以在 `createRoute` 方法中自定义过渡效果。

### Q: 如何调试路由问题？
A:
1. 在路由处理器中添加 `debugPrint` 语句
2. 检查路由名称是否正确
3. 确认参数解析是否正常
4. 使用 Flutter DevTools 查看路由栈

## 相关文档

- [小组件实现指南](WIDGET_IMPLEMENTATION_GUIDE.md)
- [小组件快速参考](WIDGET_QUICK_REFERENCE.md)
- [项目架构文档](../CLAUDE.md)

## 更新日志

- **2025-12-01**: 初始版本，完成路由架构重构
  - 创建 `PluginRouteHandler` 基类
  - 为 checkin 和 todo 插件创建独立的路由处理器
  - 更新主路由文件使用新架构
