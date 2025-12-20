# SmoothBottomSheet 使用指南

## 简介

`SmoothBottomSheet` 是一个基于 `smooth_sheets` 包实现的底部抽屉工具类，用于替代传统的 `showModalBottomSheet`。它提供了流畅的拖拽动画和更好的用户体验。

## 基础用法

### 1. 最简单的用法

```dart
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

// 显示简单的底部抽屉
await SmoothBottomSheet.show(
  context: context,
  builder: (context) => Container(
    padding: const EdgeInsets.all(20),
    child: Text('Hello World'),
  ),
);
```

### 2. 自定义样式

```dart
await SmoothBottomSheet.show(
  context: context,
  backgroundColor: Colors.white,
  borderRadius: 16,
  showDragHandle: true,
  swipeDismissible: true,
  builder: (context) => YourWidget(),
);
```

### 3. 带标题的抽屉

```dart
await SmoothBottomSheet.showWithTitle(
  context: context,
  title: '选择操作',
  showCloseButton: true,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: Icon(Icons.edit),
        title: Text('编辑'),
        onTap: () => Navigator.pop(context, 'edit'),
      ),
      ListTile(
        leading: Icon(Icons.delete),
        title: Text('删除'),
        onTap: () => Navigator.pop(context, 'delete'),
      ),
    ],
  ),
);
```

### 4. 带底部操作按钮

```dart
final result = await SmoothBottomSheet.showWithTitle<bool>(
  context: context,
  title: '确认操作',
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Text('确定要删除这个项目吗？'),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text('取消'),
    ),
    ElevatedButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text('确定'),
    ),
  ],
);

if (result == true) {
  // 执行删除操作
}
```

## 迁移指南

### 从 showModalBottomSheet 迁移

**之前的代码：**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 手动添加拖拽指示器
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 内容
          YourContent(),
        ],
      ),
    ),
  ),
);
```

**迁移后的代码：**
```dart
SmoothBottomSheet.show(
  context: context,
  builder: (context) => YourContent(),
);
```

### 常见场景替换

#### 场景 1: 操作菜单

**之前：**
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('编辑'),
          onTap: () {
            Navigator.pop(context);
            onEdit();
          },
        ),
        ListTile(
          leading: Icon(Icons.delete),
          title: Text('删除'),
          onTap: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
    ),
  ),
);
```

**迁移后：**
```dart
SmoothBottomSheet.show(
  context: context,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: Icon(Icons.edit),
        title: Text('编辑'),
        onTap: () {
          Navigator.pop(context);
          onEdit();
        },
      ),
      ListTile(
        leading: Icon(Icons.delete),
        title: Text('删除'),
        onTap: () {
          Navigator.pop(context);
          onDelete();
        },
      ),
    ],
  ),
);
```

#### 场景 2: 带标题的表单

**之前：**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '添加标签',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // 表单
        TextField(
          decoration: InputDecoration(labelText: '标签名称'),
        ),
        // 按钮
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, value),
              child: Text('保存'),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

**迁移后：**
```dart
SmoothBottomSheet.showWithTitle(
  context: context,
  title: '添加标签',
  child: Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      left: 16,
      right: 16,
    ),
    child: TextField(
      decoration: InputDecoration(labelText: '标签名称'),
    ),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('取消'),
    ),
    SizedBox(width: 8),
    ElevatedButton(
      onPressed: () => Navigator.pop(context, value),
      child: Text('保存'),
    ),
  ],
);
```

## API 参数说明

### SmoothBottomSheet.show()

| 参数 | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| context | BuildContext | 必需 | 上下文 |
| builder | Widget Function(BuildContext) | 必需 | 内容构建器 |
| swipeDismissible | bool | true | 是否支持滑动关闭 |
| barrierDismissible | bool | true | 是否点击背景关闭 |
| backgroundColor | Color? | null | 背景色（null 时使用主题背景色） |
| borderRadius | double | 20 | 圆角半径 |
| showDragHandle | bool | true | 是否显示拖拽指示器 |
| enableDrag | bool | true | 是否启用拖拽 |
| isScrollControlled | bool | false | 是否使用全屏高度 |
| useSafeArea | bool | true | 是否使用安全区域 |

### SmoothBottomSheet.showWithTitle()

除了 `show()` 的所有参数外，还包括：

| 参数 | 类型 | 默认值 | 说明 |
|-----|------|--------|------|
| title | String | 必需 | 标题文本 |
| child | Widget | 必需 | 内容组件（替代 builder） |
| actions | List&lt;Widget&gt;? | null | 底部操作按钮列表 |
| showCloseButton | bool | false | 是否显示关闭按钮 |

## 高级用法

### 自定义拖拽指示器

如果需要完全自定义拖拽指示器，可以设置 `showDragHandle: false`，然后在 builder 中自己添加：

```dart
SmoothBottomSheet.show(
  context: context,
  showDragHandle: false,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 自定义拖拽指示器
      Container(
        width: 60,
        height: 6,
        margin: const EdgeInsets.only(top: 16, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      // 内容
      YourContent(),
    ],
  ),
);
```

### 禁用拖拽关闭

```dart
SmoothBottomSheet.show(
  context: context,
  swipeDismissible: false,
  barrierDismissible: false,
  enableDrag: false,
  builder: (context) => YourContent(),
);
```

### 全屏高度抽屉

```dart
SmoothBottomSheet.show(
  context: context,
  isScrollControlled: true,
  builder: (context) => SizedBox(
    height: MediaQuery.of(context).size.height * 0.9,
    child: YourContent(),
  ),
);
```

## 注意事项

1. **自动处理安全区域**：默认启用 `useSafeArea`，内容会自动避开底部安全区域
2. **主题适配**：背景色默认使用 `scaffoldBackgroundColor`，自动适配深色模式
3. **拖拽指示器**：默认显示，可通过 `showDragHandle` 控制
4. **返回值**：支持泛型返回值，与 `showModalBottomSheet` 一致
5. **键盘处理**：需要手动处理键盘遮挡，可使用 `viewInsets.bottom`

## 最佳实践

1. **优先使用 `showWithTitle`**：对于有标题的抽屉，使用 `showWithTitle` 可以减少样板代码
2. **合理使用 SafeArea**：如果内容已经处理了安全区域，可以设置 `useSafeArea: false`
3. **统一圆角**：建议在整个应用中使用统一的 `borderRadius` 值
4. **处理键盘**：对于包含输入框的抽屉，记得处理键盘遮挡问题
5. **返回值类型**：使用泛型指定返回值类型，如 `SmoothBottomSheet.show<String>(...)`

## 相关资源

- [smooth_sheets 文档](https://pub.dev/packages/smooth_sheets)
- [TaskActionSheet 示例](../plugins/todo/widgets/task_action_sheet.dart)
- [WarehouseActionSheet 示例](../plugins/goods/widgets/warehouse_action_sheet.dart)
