# HomeWidgetSize 语义化 API 迁移指南

> 更新日期：2026-02-19

## 概述

本次更新为 `HomeWidgetSize` 添加了**语义化辅助方法**，让小组件的布局判断更加清晰、灵活，同时支持**可变网格列数**的场景。

### 新增 API 一览

| API | 返回类型 | 说明 |
|-----|---------|------|
| `isWide` | `bool` | 是否为宽型组件（宽度 > 高度） |
| `isTall` | `bool` | 是否为高型组件（高度 > 宽度） |
| `isSquare` | `bool` | 是否为正方形组件 |
| `isIconSized` | `bool` | 是否为图标型（1x1） |
| `isCardSized` | `bool` | 是否为卡片型（≥2格） |
| `category` | `SizeCategory` | 尺寸类别枚举 |
| `aspectRatio` | `double` | 宽高比 |
| `getWidthRatio(columns)` | `double` | 相对网格的宽度比例（0-1） |
| `isFullWidth(columns)` | `bool` | 是否占满整行 |

---

## 新增枚举：SizeCategory

基于 `min(width, height)` 判断组件的基础尺寸级别：

```dart
enum SizeCategory {
  mini,   // 最小边为 1（1x1, 1x2, 2x1 等）
  small,  // 最小边为 2（2x2, 2x3, 3x2, 4x1, 4x2 等）
  medium, // 最小边为 3（3x3, 3x4, 4x3 等）
  large,  // 最小边为 4（4x4, 4x5, 5x4 等）
  xlarge, // 最小边 ≥5
}
```

**对应关系**：
| 尺寸类型 | category | 说明 |
|---------|----------|------|
| 1x1 | mini | 图标组件 |
| 2x1, 1x2 | mini | 小型卡片 |
| 2x2 | small | 标准卡片 |
| 4x1, 4x2 | small | 宽型卡片 |
| 2x3, 3x2 | small | 高/宽卡片 |
| 3x3 | medium | 中型正方形 |
| 4x3, 3x4 | medium | 中型高/宽卡片 |
| 4x4 | large | 大型正方形 |

---

## 迁移示例

### 1. 布局方向判断

**旧方式（不推荐）：**
```dart
if (size is WideSize || size is Wide2Size || size is Wide3Size) {
  return _buildHorizontalLayout();
}
```

**新方式（推荐）：**
```dart
if (size.isWide) {
  return _buildHorizontalLayout();
}
```

**优势**：自动适配任何宽型尺寸，包括未来新增的尺寸类型。

---

### 2. 字体/图标大小判断

**旧方式（不推荐）：**
```dart
double iconSize;
if (size is SmallSize) {
  iconSize = 18;
} else if (size is MediumSize || size is WideSize) {
  iconSize = 24;
} else {
  iconSize = 28;
}
```

**新方式（推荐）：**
```dart
final iconSize = switch (size.category) {
  SizeCategory.mini => 16.0,
  SizeCategory.small => 20.0,
  SizeCategory.medium => 24.0,
  SizeCategory.large => 28.0,
  SizeCategory.xlarge => 32.0,
};
```

**优势**：使用 Dart 3 的 switch expression，代码更简洁。

---

### 3. 结合网格列数判断

**场景**：用户可以自定义 HomeScreen 的网格列数（1-10列）

**旧方式（问题）：**
```dart
// WideSize 固定为 4 列，但用户可能设置了 2 列网格
if (size is WideSize) {
  // 这个判断在 2 列网格中不准确！
}
```

**新方式（推荐）：**
```dart
// 从 HomeLayoutManager 获取当前网格列数
final gridColumns = HomeLayoutManager().gridCrossAxisCount;

// 判断是否占满整行
if (size.isFullWidth(gridColumns)) {
  return _buildFullWidthLayout();
}

// 或者判断相对比例
final widthRatio = size.getWidthRatio(gridColumns);
if (widthRatio > 0.5) {
  // 占据超过一半宽度
}
```

---

### 4. 结合 LayoutBuilder 获取实际像素

**推荐模式**：语义化判断 + 实际像素值

```dart
Widget build(BuildContext context) {
  final size = config['widgetSize'] as HomeWidgetSize;
  final gridColumns = HomeLayoutManager().gridCrossAxisCount;

  return LayoutBuilder(
    builder: (context, constraints) {
      // 获取实际像素尺寸
      final pixelWidth = constraints.maxWidth;
      final pixelHeight = constraints.maxHeight;

      // 结合语义 + 像素值判断
      if (size.isWide && pixelWidth > 300) {
        return _buildFullFeaturedLayout(pixelWidth, pixelHeight);
      } else if (size.category == SizeCategory.mini) {
        return _buildMinimalLayout(pixelWidth, pixelHeight);
      } else {
        return _buildStandardLayout(pixelWidth, pixelHeight);
      }
    },
  );
}
```

---

## 完整示例：CommandWidget 迁移

### 迁移前

```dart
class MyCommandWidget extends StatelessWidget {
  final HomeWidgetSize size;

  @override
  Widget build(BuildContext context) {
    if (size is SmallSize) {
      return _buildSmallWidget();
    } else if (size is MediumSize || size is WideSize) {
      return _buildMediumWidget();
    } else if (size is LargeSize || size is Wide2Size) {
      return _buildLargeWidget();
    } else {
      return _buildXLargeWidget();
    }
  }
}
```

### 迁移后

```dart
class MyCommandWidget extends StatelessWidget {
  final HomeWidgetSize size;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用语义化方法
        if (size.isIconSized) {
          return _buildIconWidget(constraints);
        }

        // 使用 category 判断
        return switch (size.category) {
          SizeCategory.mini => _buildMiniWidget(constraints),
          SizeCategory.small => _buildSmallWidget(constraints),
          SizeCategory.medium => _buildMediumWidget(constraints),
          SizeCategory.large => _buildLargeWidget(constraints),
          SizeCategory.xlarge => _buildXLargeWidget(constraints),
        };
      },
    );
  }

  Widget _buildIconWidget(BoxConstraints constraints) {
    // 可使用 constraints.maxWidth/maxHeight 获取实际像素
    final iconSize = constraints.maxWidth * 0.4;
    return Center(
      child: Icon(Icons.star, size: iconSize),
    );
  }
}
```

---

## 向后兼容性

本次更新**完全向后兼容**：

- ✅ 所有现有尺寸类（`SmallSize`, `MediumSize`, `LargeSize` 等）保持不变
- ✅ 所有现有方法（`getPadding()`, `getIconSize()` 等）保持不变
- ✅ `is SmallSize` 等类型检查仍然有效

**建议**：新代码使用语义化 API，旧代码可在重构时逐步迁移。

---

## 判断方式选择指南

| 判断方式 | 用途 | 示例场景 |
|---------|------|---------|
| `size.width / size.height` | 网格数判断 | "这个组件占 2 格宽" |
| `size.isWide / size.isTall` | 布局方向 | "使用横向/纵向布局" |
| `size.category` | 尺寸缩放 | "字号应该是 14px" |
| `size.isFullWidth(columns)` | 网格适配 | "是否占满整行" |
| `LayoutBuilder` | 实际像素 | "精确控制 UI 元素大小" |

---

## 常见问题

### Q1: 什么时候用 `isWide` vs `category`？

- `isWide`：用于决定**布局方向**（横向 vs 纵向）
- `category`：用于决定**缩放级别**（字体大小、间距等）

### Q2: 为什么要结合 `LayoutBuilder`？

`HomeWidgetSize` 只知道"占用了几个网格"，不知道实际像素。结合 `LayoutBuilder` 可以：
- 获取实际渲染尺寸
- 更精确地控制 UI 元素
- 适应不同屏幕尺寸

### Q3: 旧代码需要立即迁移吗？

**不需要**。现有代码可以继续使用。建议：
- 新功能：使用新的语义化 API
- 重构时：逐步迁移旧代码
- 关键组件：优先迁移以支持可变网格列数

---

## 相关文件

- `lib/screens/home_screen/models/home_widget_size.dart` - 尺寸定义文件
- `lib/screens/home_screen/managers/home_layout_manager.dart` - 网格列数配置
- `lib/screens/home_screen/widgets/home_card.dart` - 小组件渲染
