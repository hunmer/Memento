---
name: add-route-context
description: 为Flutter页面添加路由上下文记录功能，支持日期等参数的AI上下文识别。当需要让AI助手通过"询问当前上下文"功能获取页面状态（如日期、ID等参数）时使用。适用场景：(1) 日期驱动的页面（日记、活动、日历等），(2) ID驱动的页面（用户详情、订单详情等），(3) 任何需要AI理解当前页面参数的场景
---

# Add Route Context

为Flutter页面添加路由上下文记录，使AI助手能理解用户当前查看的页面参数。

## Workflow

### 1. Analyze Target File

Read the target file and identify:

- State class name
- Parameter variable (e.g., `_selectedDate`, `_userId`)
- Parameter change method (e.g., `_onDateChanged`)
- Initialization method (e.g., `initState`, `_initializeService`)

### 2. Add RouteHistoryManager Import

```dart
import 'package:Memento/core/route/route_history_manager.dart';
```

### 3. Create Update Method

**For DateTime parameter:**

```dart
/// 更新路由上下文,使"询问当前上下文"功能能获取到当前日期
void _updateRouteContext(DateTime date) {
  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  RouteHistoryManager.updateCurrentContext(
    pageId: "/route_name",
    title: '页面标题 - $dateStr',
    params: {'date': dateStr},
  );
}
```

**For custom parameter:**

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

### 4. Call in Initialization

Add call at end of initialization method:

```dart
Future<void> _initializeService() async {
  // ... existing code ...

  // 初始化时设置路由上下文
  _updateRouteContext(_initialParam);
}
```

### 5. Call on Parameter Change

Add call in parameter change handler:

```dart
void _onParamChanged(ParamType newParam) {
  if (newParam == _currentParam) return;

  setState(() {
    _currentParam = newParam;
  });
  // ... existing code ...

  // 更新路由上下文
  _updateRouteContext(newParam);
}
```

### 6. Update Route Parser

Add route template to `lib/core/action/built_in/ask_context_action/route_parser.dart`:

```dart
static const Map<String, String> _routeTemplates = {
  // ... existing routes ...

  // 插件名称
  '/route_name': '用户正在查看 {paramName} 的XXX',
};
```

**DateTime parameter example:**

```dart
'/activity_timeline': '用户正在查看 {date} 的活动时间轴',
```

**Custom parameter example:**

```dart
'/user_profile': '用户正在查看 {userId} 的用户资料',
```

## Detection Patterns

### DateTime Variables

Look for variables matching:
- Names: `_selectedDate`, `_currentDate`, `_focusedDay`, `date`
- Type: `DateTime`

Look for methods matching:
- Names: `_onDateChanged`, `_onDayChanged`, `_selectDate`
- Parameter type: `DateTime`

### Custom Parameters

Look for variables matching the `--param` argument name.

## Result

After execution:

**在页面加载时：**
- AI上下文：`用户正在查看 2025-12-22 的活动时间轴`

**在参数变化时：**
- AI上下文自动更新：`用户正在查看 2025-12-21 的活动时间轴`

## Notes

- Extract update logic to separate method to avoid duplication
- Use Chinese comments matching existing codebase style
- Format dates as `YYYY-MM-DD` for consistency
- Route parser uses `RegExp(r'\{(\w+)\}')` for placeholder replacement
- Verify with `flutter analyze` after changes
