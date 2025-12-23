---
description: 为Flutter页面添加路由上下文记录功能，支持日期等参数的AI上下文识别
allowed-tools: Read(**), Edit(**), Glob(**), Grep(**)
argument-hint: <page-file-path> --route <route-name> [--date-param] [--custom-param <param-name>]
# examples:
#   - /add-route-context lib/plugins/diary/screens/diary_calendar_screen.dart --route /diary_detail --date-param
#   - /add-route-context lib/plugins/activity/screens/activity_timeline_screen.dart --route /activity_timeline --date-param
#   - /add-route-context lib/screens/my_screen.dart --route /my_route --custom-param userId
---

# Claude Skill: 添加路由上下文记录

该技能帮助开发者为Flutter页面添加路由上下文记录功能，使AI助手能够通过"询问当前上下文"功能获取用户当前查看的页面状态（如日期、ID等参数）。

---

## 功能说明

该技能会自动完成以下操作：

1. **在目标页面中添加路由记录**
   - 导入 `RouteHistoryManager`
   - 创建 `_updateRouteContext()` 方法
   - 在初始化时调用上下文更新
   - 在参数变化时调用上下文更新

2. **在路由解析器中添加参数解析规则**
   - 在 `lib/core/action/built_in/ask_context_action/route_parser.dart` 中添加路由模板
   - 支持 `{date}`、`{id}` 等占位符参数

---

## 使用方法

### 基础用法（日期参数）

```bash
/add-route-context lib/plugins/diary/screens/diary_calendar_screen.dart --route /diary_detail --date-param
```

这将：
- 在日记日历页面添加路由记录功能
- 当日期变化时自动更新上下文为 `用户正在查看 YYYY-MM-DD 的日记`

### 自定义参数

```bash
/add-route-context lib/screens/user_profile_screen.dart --route /user_profile --custom-param userId
```

这将添加自定义参数支持，上下文为 `用户正在查看 {userId} 的用户资料`

---

## 工作流程

### 第一步：分析目标文件结构

1. 读取目标Flutter页面文件
2. 识别关键组件：
   - State类名称
   - 参数变量名（如 `_selectedDate`、`_userId` 等）
   - 参数变化回调方法（如 `_onDateChanged`、`_onUserChanged` 等）
   - 初始化方法（`initState` 或 `_initializeService` 等）

### 第二步：添加RouteHistoryManager导入

在文件顶部导入语句中添加：

```dart
import 'package:Memento/core/route/route_history_manager.dart';
```

### 第三步：创建路由上下文更新方法

根据参数类型（日期/自定义）创建对应的更新方法：

**日期参数示例：**

```dart
/// 更新路由上下文,使"询问当前上下文"功能能获取到当前日期
void _updateRouteContext(DateTime date) {
  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  RouteHistoryManager.updateCurrentContext(
    pageId: "/route_name",
    title: '页面标题 - $dateStr',
    params: {'date': dateStr},
  );
}
```

**自定义参数示例：**

```dart
/// 更新路由上下文
void _updateRouteContext(String paramValue) {
  RouteHistoryManager.updateCurrentContext(
    pageId: "/route_name",
    title: '页面标题 - $paramValue',
    params: {'paramName': paramValue},
  );
}
```

### 第四步：在初始化时调用

在 `initState()` 或异步初始化方法的末尾添加调用：

```dart
Future<void> _initializeService() async {
  // ... 原有初始化代码 ...

  // 初始化时设置路由上下文
  _updateRouteContext(_initialParam);
}
```

### 第五步：在参数变化时调用

在参数变化的回调方法中添加调用：

```dart
void _onParamChanged(ParamType newParam) {
  if (newParam == _currentParam) return;

  setState(() {
    _currentParam = newParam;
  });
  // ... 其他逻辑 ...

  // 更新路由上下文
  _updateRouteContext(newParam);
}
```

### 第六步：更新路由解析器

在 `lib/core/action/built_in/ask_context_action/route_parser.dart` 的 `_routeTemplates` 映射中添加路由模板：

**日期参数示例：**

```dart
// 插件名称
'/route_name': '用户正在查看 {date} 的XXX',
```

**自定义参数示例：**

```dart
'/route_name': '用户正在查看 {paramName} 的XXX',
```

---

## 参数说明

### 必需参数

- `<page-file-path>`：目标Flutter页面文件的路径（相对于项目根目录）
- `--route <route-name>`：路由名称（必须以 `/` 开头）

### 可选参数

- `--date-param`：使用日期参数（自动识别 `DateTime` 类型的变量）
- `--custom-param <param-name>`：使用自定义参数（需指定参数名称）

### 参数互斥关系

`--date-param` 和 `--custom-param` 互斥，只能选择其一。如果都不指定，默认使用 `--date-param`。

---

## 智能识别规则

### 日期参数识别

当指定 `--date-param` 时，技能会自动查找：

1. **日期变量**：
   - 变量名包含 `date`、`selectedDate`、`currentDate`、`focusedDay` 等
   - 类型为 `DateTime`

2. **日期变化方法**：
   - 方法名包含 `onDateChanged`、`onDayChanged`、`selectDate` 等
   - 参数类型为 `DateTime`

3. **日期格式化**：
   - 自动生成 `YYYY-MM-DD` 格式的日期字符串
   - 使用 `padLeft(2, '0')` 确保两位数格式

### 自定义参数识别

当指定 `--custom-param <param-name>` 时，技能会：

1. 查找包含该参数名的变量
2. 识别该参数的变化回调方法
3. 生成对应的参数格式化代码（如需要）

---

## 示例场景

### 场景1：日记插件

**需求**：用户查看某天日记时，AI能知道具体日期

**命令**：
```bash
/add-route-context lib/plugins/diary/screens/diary_calendar_screen.dart --route /diary_detail --date-param
```

**效果**：
- AI上下文：`用户正在查看 2025-12-22 的日记`
- 用户切换到12月21日：AI上下文自动更新为 `用户正在查看 2025-12-21 的日记`

### 场景2：活动插件

**需求**：用户查看某天活动时，AI能知道具体日期

**命令**：
```bash
/add-route-context lib/plugins/activity/screens/activity_timeline_screen.dart --route /activity_timeline --date-param
```

**效果**：
- AI上下文：`用户正在查看 2025-12-22 的活动时间轴`

### 场景3：用户资料页面

**需求**：查看某个用户资料时，AI能知道用户ID

**命令**：
```bash
/add-route-context lib/screens/user_profile_screen.dart --route /user_profile --custom-param userId
```

**效果**：
- AI上下文：`用户正在查看 user123 的用户资料`

---

## 注意事项

### 1. 文件备份
技能执行前会自动检查目标文件是否存在，但建议在执行前：
- 确保代码已提交到Git
- 或手动备份关键文件

### 2. 代码风格
生成的代码会遵循：
- Dart官方代码风格指南
- 项目现有的命名规范
- 与现有代码注释语言保持一致

### 3. 路由名称规范
- 必须以 `/` 开头
- 使用小写字母和下划线
- 避免使用特殊字符

### 4. 参数名称规范
- 使用驼峰命名法（camelCase）
- 见名知义
- 与UI显示文本对应

---

## 错误处理

### 常见错误

1. **目标文件不存在**
   - 检查文件路径是否正确
   - 确保路径相对于项目根目录

2. **找不到合适的插入点**
   - 检查目标文件是否为有效的Flutter StatefulWidget
   - 确保文件中存在State类

3. **参数识别失败**
   - 手动指定参数名称：`--custom-param yourParamName`
   - 检查变量命名是否符合规范

4. **路由解析器文件不存在**
   - 确保项目中存在 `lib/core/action/built_in/ask_context_action/route_parser.dart`
   - 检查路径是否正确

---

## 技术实现细节

### RouteHistoryManager

该技能依赖项目中的 `RouteHistoryManager` 类，其核心方法为：

```dart
static void updateCurrentContext({
  required String pageId,
  required String title,
  Map<String, dynamic>? params,
})
```

### RouteParser

路由解析器使用正则表达式 `RegExp(r'\{(\w+)\}')` 提取占位符并替换为实际值。

### 参数替换逻辑

```dart
// 模板：'用户正在查看 {date} 的日记'
// 参数：{'date': '2025-12-22'}
// 结果：'用户正在查看 2025-12-22 的日记'
```

---

## 最佳实践

### 1. 路由命名建议

- 使用语义化命名：`/diary_detail` 而非 `/page1`
- 保持一致性：同一插件的路由使用相同前缀

### 2. 上下文文本建议

- 使用第三人称：`用户正在查看...` 而非 `我正在查看...`
- 包含关键信息：日期、ID、名称等
- 保持简洁：不超过30个字符

### 3. 参数选择建议

- 优先使用有意义的参数：日期、ID、名称
- 避免使用临时状态：加载状态、选中索引等
- 确保参数稳定：不会频繁变化

---

## 完整示例

### 输入命令

```bash
/add-route-context lib/plugins/activity/screens/activity_timeline_screen/activity_timeline_screen.dart --route /activity_timeline --date-param
```

### 执行过程

1. ✅ 读取 `activity_timeline_screen.dart`
2. ✅ 识别日期变量 `_selectedDate`
3. ✅ 识别日期变化方法 `_onDateChanged`
4. ✅ 添加 RouteHistoryManager 导入
5. ✅ 创建 `_updateRouteContext` 方法
6. ✅ 在 `_initializeService` 末尾添加调用
7. ✅ 在 `_onDateChanged` 中添加调用
8. ✅ 更新 `route_parser.dart`，添加路由模板
9. ✅ 验证代码语法正确性

### 生成结果

**在 activity_timeline_screen.dart 中：**

```dart
import 'package:Memento/core/route/route_history_manager.dart';

// ... 其他代码 ...

void _onDateChanged(DateTime date) {
  if (date == _selectedDate) return;

  setState(() {
    _selectedDate = date;
  });
  _activityController.loadActivities(_selectedDate);

  // 更新路由上下文
  _updateRouteContext(date);
}

/// 更新路由上下文,使"询问当前上下文"功能能获取到当前日期
void _updateRouteContext(DateTime date) {
  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  RouteHistoryManager.updateCurrentContext(
    pageId: "/activity_timeline",
    title: '活动时间轴 - $dateStr',
    params: {'date': dateStr},
  );
}
```

**在 route_parser.dart 中：**

```dart
static const Map<String, String> _routeTemplates = {
  // ... 其他路由 ...

  // 活动插件
  '/activity': '用户正在查看活动记录',
  '/activity_timeline': '用户正在查看 {date} 的活动时间轴',

  // ... 其他路由 ...
};
```

---

## 验证测试

技能执行完成后，建议进行以下测试：

### 1. 编译测试

```bash
flutter analyze
```

确保没有语法错误。

### 2. 功能测试

1. 启动应用
2. 导航到目标页面
3. 打开AI对话，使用"询问当前上下文"功能
4. 验证AI是否能正确识别当前页面和参数

### 3. 参数更新测试

1. 在页面中切换参数（如切换日期）
2. 再次使用"询问当前上下文"功能
3. 验证AI上下文是否已更新

---

## 故障排查

### 问题：AI上下文未更新

**可能原因：**
- 未调用 `_updateRouteContext`
- RouteHistoryManager 未正确导入
- 路由解析器未添加对应模板

**解决方法：**
1. 检查 `_updateRouteContext` 方法是否被调用
2. 检查导入语句是否正确
3. 检查 route_parser.dart 中是否添加了路由模板

### 问题：参数占位符未被替换

**可能原因：**
- 参数名称不匹配
- params 参数未正确传递

**解决方法：**
1. 确保 `params` 中的键与模板中的占位符一致
2. 检查参数值是否正确格式化

---

## 相关文档

- [RouteHistoryManager 文档](lib/core/route/ROUTE_HISTORY_MANAGER.md)
- [RouteParser 文档](lib/core/action/built_in/ask_context_action/ROUTE_PARSER.md)
- [插件开发指南](PLUGIN_DEVELOPMENT.md)

---

## 更新日志

- **2025-12-22**: 初始版本，支持日期参数和自定义参数
