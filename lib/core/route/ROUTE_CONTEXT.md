# 路由上下文管理使用指南

## 概述

路由上下文管理系统提供了一种**不触发页面刷新**的方式来更新当前路由信息，主要用于支持"询问当前上下文"等需要获取页面状态的功能。

**工作原理**：
1. 页面通过 `RouteHistoryManager.updateCurrentContext()` 更新当前上下文（不刷新页面）
2. "询问当前上下文"功能通过 `RouteParser.parseRoute()` 获取路由信息
3. `RouteParser` **优先使用** `RouteHistoryManager` 中的上下文，而不是路由系统的信息
4. 这样就实现了在不刷新页面的情况下，动态更新上下文信息

## 核心功能

### 1. 更新当前路由上下文（不刷新页面）

在页面内部状态变化时，可以更新路由上下文而不触发导航或页面重建：

```dart
RouteHistoryManager.updateCurrentContext(
  pageId: '/diary_detail',
  title: '日记详情',
  params: {'date': '2025-12-22'},
  icon: Icons.book, // 可选
);
```

### 2. 获取当前路由上下文

"询问当前上下文"功能或其他需要获取页面状态的功能可以通过以下方式读取：

```dart
// 获取完整上下文
final context = RouteHistoryManager.getCurrentContext();
if (context != null) {
  print('当前页面: ${context.pageId}');
  print('页面标题: ${context.title}');
  print('页面参数: ${context.params}');
}

// 获取所有参数
final params = RouteHistoryManager.getCurrentParams();
final date = params['date']; // '2025-12-22'

// 获取特定参数
final date = RouteHistoryManager.getCurrentParam<String>('date');
final count = RouteHistoryManager.getCurrentParam<int>('count', defaultValue: 0);
```

## 使用场景

### 场景一：日记日历切换日期

在日历页面切换日期时，只需要更新上下文，不需要刷新页面：

```dart
void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
  setState(() {
    _selectedDay = selectedDay;
  });

  // 更新路由上下文（不刷新页面）
  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);

  // 获取实际路由名称（推荐做法）
  final actualRouteName = ModalRoute.of(context)?.settings.name ?? '/diary';

  RouteHistoryManager.updateCurrentContext(
    pageId: actualRouteName,
    title: '日记详情 - $dateStr',
    params: {'date': dateStr},
  );
}
```

### 场景二：列表页滚动位置

记录用户当前查看的列表项：

```dart
void _onScroll() {
  final firstVisibleIndex = _scrollController.offset ~/ _itemHeight;

  RouteHistoryManager.updateCurrentContext(
    pageId: '/todo_list',
    title: '待办列表',
    params: {
      'scrollIndex': firstVisibleIndex,
      'category': _currentCategory,
    },
  );
}
```

### 场景三：标签页切换

记录当前激活的标签：

```dart
void _onTabChanged(int index) {
  setState(() {
    _currentTabIndex = index;
  });

  RouteHistoryManager.updateCurrentContext(
    pageId: '/settings',
    title: '设置 - ${_tabs[index].name}',
    params: {'activeTab': _tabs[index].id},
  );
}
```

## 与路由历史的区别

| 功能 | 当前路由上下文 | 路由历史 |
|-----|-------------|---------|
| **存储方式** | 内存（单例） | 持久化 |
| **数据范围** | 仅当前页面 | 所有访问过的页面 |
| **更新频率** | 高频（状态变化时） | 低频（页面切换时） |
| **主要用途** | 实时获取当前状态 | 访问历史、统计分析 |

建议：
- ✅ 使用 `RouteHistoryManager.updateCurrentContext()` 更新当前上下文（不刷新页面）
- ✅ 使用 `RouteHistoryManager.recordPageVisit()` 记录页面访问历史（持久化）

## 注意事项

1. **不会触发导航**：`updateCurrentContext()` 只更新内存中的上下文，不会触发 Navigator 的任何操作。

2. **非持久化**：当前路由上下文存储在内存中，应用重启后会丢失。如需持久化，请使用 `RouteHistoryManager.recordPageVisit()`。

3. **单例模式**：全局只有一个当前路由上下文，每次调用都会覆盖之前的值。

4. **参数类型**：参数必须是可序列化的基本类型（String、int、bool、List、Map 等）。

5. **路由名称建议**：推荐使用 `ModalRoute.of(context)?.settings.name` 获取实际路由名称，避免硬编码。

6. **优先级机制**：`RouteParser` 获取路由信息的优先级为：
   - **最高**：`RouteHistoryManager.getCurrentContext()`（手动设置）
   - **次高**：GetX 路由系统（`Get.routing.current`）
   - **最低**：Flutter 原生路由（`ModalRoute.of(context)?.settings.name`）

## 迁移指南

如果你之前使用 `pushReplacementNamed()` 来更新路由参数，现在应该改用 `RouteHistoryManager.updateCurrentContext()`：

```dart
// ❌ 旧方式（会刷新页面）
Navigator.pushReplacementNamed(
  context,
  '/diary_detail',
  arguments: {'date': '2025-12-22'},
);

// ✅ 新方式（不刷新页面）
RouteHistoryManager.updateCurrentContext(
  pageId: '/diary_detail',
  title: '日记详情',
  params: {'date': '2025-12-22'},
);
```

## API 参考

### RouteHistoryManager.updateCurrentContext()

```dart
static void updateCurrentContext({
  required String pageId,
  required String title,
  Map<String, dynamic>? params,
  IconData? icon,
})
```

**参数：**
- `pageId`: 页面唯一标识符
- `title`: 页面标题
- `params`: 页面参数（可选）
- `icon`: 页面图标（可选）

### RouteHistoryManager.getCurrentContext()

```dart
static PageVisitRecord? getCurrentContext()
```

**返回：** 当前路由上下文，如果没有则返回 null

### RouteHistoryManager.getCurrentParams()

```dart
static Map<String, dynamic> getCurrentParams()
```

**返回：** 当前路由参数，如果没有则返回空 Map

### RouteHistoryManager.getCurrentParam()

```dart
static T? getCurrentParam<T>(String key, {T? defaultValue})
```

**参数：**
- `key`: 参数键
- `defaultValue`: 默认值（参数不存在时返回）

**返回：** 指定类型的参数值
