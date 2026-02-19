# HomeWidgetSize 语义化 API 迁移指南

> 更新日期：2026-02-19

## 概述

本次更新为 `HomeWidgetSize` 进行了**重大重构**：

1. 新增**语义化辅助方法**（`isWide`, `isTall`, `category` 等）
2. **重构现有 getter 方法**，统一使用 `category` 判断尺寸级别

### ⚠️ 破坏性变更

所有 `get*()` 方法现在基于 `category` 返回值，而不是具体的尺寸类型。

**影响**：2x2 (LargeSize) 之前返回"大"尺寸参数，现在返回"小"尺寸参数。

| 尺寸 | category | 之前行为 | 现在行为 |
|------|----------|---------|---------|
| 1x1 | mini | 小 | 最小 |
| 2x1 | mini | 中 | 最小 |
| **2x2** | **small** | **大** | **小** |
| 4x1 | small | 中 | 小 |
| 4x2 | small | 大 | 小 |
| 3x3 | medium | 大 | 中 |
| 4x4 | large | 大 | 大 |

---

## 新增 API 一览

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

## SizeCategory 定义

基于 `min(width, height)` 判断组件的基础尺寸级别：

```dart
enum SizeCategory {
  mini,   // 最小边为 1（1x1, 1x2, 2x1）
  small,  // 最小边为 2（2x2, 2x3, 3x2, 4x1, 4x2）
  medium, // 最小边为 3（3x3, 3x4, 4x3）
  large,  // 最小边为 4（4x4, 4x5, 5x4）
  xlarge, // 最小边 ≥5
}
```

**尺寸对应表**：

| 尺寸 | category | getLargeFontSize() | getPadding() |
|------|----------|-------------------|--------------|
| 1x1 | mini | 24 | 8 |
| 2x1, 1x2 | mini | 24 | 8 |
| **2x2** | **small** | **32** | **12** |
| 4x1, 4x2 | small | 32 | 12 |
| 3x3 | medium | 40 | 14 |
| 4x4 | large | 48 | 16 |

---

## 迁移示例

### 1. 布局方向判断

**旧方式**：
```dart
if (size is WideSize || size is Wide2Size || size is Wide3Size) {
  return _buildHorizontalLayout();
}
```

**新方式**：
```dart
if (size.isWide) {
  return _buildHorizontalLayout();
}
```

---

### 2. 字体/图标大小

**现在统一使用 `category`**：

```dart
final fontSize = size.getLargeFontSize();
// 2x2 (small) → 32
// 3x3 (medium) → 40
// 4x4 (large) → 48
```

---

### 3. 结合 LayoutBuilder

**推荐模式**：语义化判断 + 实际像素值

```dart
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // 使用 size 的 getter 方法（基于 category）
      final fontSize = size.getLargeFontSize();
      final padding = size.getPadding();

      // 或直接使用 category
      if (size.category == SizeCategory.mini) {
        return _buildCompactLayout();
      }

      return _buildStandardLayout();
    },
  );
}
```

---

## 向后兼容性

### 尺寸类保持不变

- ✅ `SmallSize`, `MediumSize`, `LargeSize` 等类定义保持不变
- ✅ `is SmallSize` 等类型检查仍然有效
- ⚠️ `get*()` 方法返回值**已改变**

### get*() 方法返回值变化

| 方法 | 2x2 之前 | 2x2 现在 |
|------|---------|---------|
| `getLargeFontSize()` | 56 | 32 |
| `getTitleFontSize()` | 28 | 16 |
| `getPadding()` | 16 | 12 |
| `getIconSize()` | 28 | 20 |

---

## 为什么要改？

1. **语义一致性**：2x2 应该是"小"尺寸，而不是"大"尺寸
2. **可变网格支持**：配合用户自定义的网格列数
3. **更合理的缩放**：UI 元素大小与组件实际尺寸匹配

---

## 相关文件

- `lib/screens/home_screen/models/home_widget_size.dart` - 尺寸定义文件
- `lib/screens/home_screen/managers/home_layout_manager.dart` - 网格列数配置
- `lib/screens/home_screen/widgets/home_card.dart` - 小组件渲染
