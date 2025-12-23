---
name: Material Design 3 配色规范守护者
description: 严格遵循Material Design 3配色规范的守护工具，提供Flutter应用界面配色最佳实践指南，确保UI一致性和可访问性
---

# Material Design 3 配色规范守护者

## 配色核心原则

### 基础配色方案
```dart
// 主题配置（全局）
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue, // 主色调种子
      brightness: Brightness.light, // 或 Brightness.dark
    ),
  ),
  // ...
)
```

### 页面级配色规范

#### 1. 页面背景
```dart
// ✅ 正确：使用系统定义的标准背景色
Scaffold(
  backgroundColor: Theme.of(context).colorScheme.surface,
  // ...
)

// ❌ 错误：硬编码颜色
// backgroundColor: Colors.white,
```

#### 2. 卡片/表单容器
```dart
// ✅ 正确：使用容器专用背景色
Card(
  color: Theme.of(context).colorScheme.surfaceContainerLow,
  child: // ...
)

// 或使用 Container
Container(
  color: Theme.of(context).colorScheme.surfaceContainer,
  child: // ...
)
```

#### 3. 文字颜色规范
```dart
// ✅ 正确：自动适配的文字颜色
Text(
  '标题文字',
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  ),
)

// ✅ 正确：InputDecoration 自动使用 onSurface
TextField(
  decoration: InputDecoration(
    labelText: '用户名',
    hintText: '请输入用户名',
    // labelStyle/hintStyle 会自动使用 onSurface 的变体
  ),
)
```

#### 4. 按钮配色
```dart
// 主要按钮
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
  ),
  onPressed: () {},
  child: Text('主要操作'),
)

// 次要按钮
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.primary,
  ),
  onPressed: () {},
  child: Text('次要操作'),
)

// 文本按钮
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.primary,
  ),
  onPressed: () {},
  child: Text('文本按钮'),
)
```

#### 5. 导航元素
```dart
// AppBar
AppBar(
  backgroundColor: Theme.of(context).colorScheme.surface,
  foregroundColor: Theme.of(context).colorScheme.onSurface,
  // ...
)

// 底部导航
NavigationBar(
  backgroundColor: Theme.of(context).colorScheme.surface,
  indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
  // ...
)
```

#### 6. 输入框状态颜色
```dart
TextField(
  decoration: InputDecoration(
    // 错误状态
    errorText: '错误信息',
    errorStyle: TextStyle(
      color: Theme.of(context).colorScheme.error,
    ),
    // 聚焦状态边框
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  ),
)
```

#### 7. 列表项
```dart
ListTile(
  tileColor: Theme.of(context).colorScheme.surface,
  textColor: Theme.of(context).colorScheme.onSurface,
  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
  // ...
)
```

## 颜色语义映射

| UI 元素 | 前景色 | 背景色 | 边框色 |
|--------|--------|--------|--------|
| 主要内容 | onSurface | surface | outline |
| 次要内容 | onSurfaceVariant | surfaceVariant | outlineVariant |
| 禁用内容 | onSurfaceDisabled | surfaceDisabled | - |
| 错误状态 | onError | error | errorContainer |
| 成功状态 | onPrimary | primary | primaryContainer |
| 警告状态 | onSecondary | secondary | secondaryContainer |

## 深色主题适配

```dart
// 主题切换
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
  // ...
)
```

## 最佳实践

1. **始终使用 Theme.of(context).colorScheme 获取颜色**
2. **避免硬编码颜色值**
3. **文字颜色使用对应的 onXxx 颜色**
4. **遵循 Material Design 3 语义化颜色规范**
5. **深色和浅色主题保持一致的视觉层次**

## 常见错误示例

```dart
// ❌ 错误：硬编码颜色
Container(color: Colors.white, ...)

// ❌ 错误：使用错误的颜色语义
Text('Hello', color: Colors.grey) // 应该使用 onSurface 或 onSurfaceVariant

// ❌ 错误：忽略主题
TextField(decoration: InputDecoration(fillColor: Colors.red))

// ✅ 正确：使用主题颜色
Container(color: Theme.of(context).colorScheme.surface)
Text('Hello', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))
TextField(decoration: InputDecoration(fillColor: Theme.of(context).colorScheme.surface))
```
