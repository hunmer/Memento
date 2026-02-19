# 响应式小组件布局系统

## 概述

2025-02-19 升级了主页小组件的布局系统，使其能够根据实际像素尺寸响应式调整布局，而不仅仅依赖网格占比。

## 问题背景

### 旧系统的问题

1. **静态网格占比**：小组件只能通过网格占比（如 2x2、1x1）来确定尺寸
2. **无法响应窗口变化**：调整窗口大小时，虽然网格占比不变，但实际像素尺寸变化了
3. **布局判断不灵活**：公共组件使用 `widget.size is SmallSize` 判断布局，无法感知像素尺寸变化

### 示例场景

- 小组件配置为 2x2（LargeSize）
- 窗口宽度 400px 时，实际像素尺寸约 200x200
- 窗口宽度 200px 时，实际像素尺寸约 100x100
- 旧系统：两种情况下 `widget.size is SmallSize` 都返回 false
- 新系统：根据像素尺寸动态判断，小窗口时自动切换为紧凑布局

## 解决方案

### 核心架构

```
HomeGrid (LayoutBuilder 计算网格尺寸)
    └── WidgetGridScope (InheritedWidget 传递 metrics)
            └── HomeCard
                    ↓ 注入到 config
                    _pixelWidth, _pixelHeight, _pixelCategory
                    ↓
            SelectorWidget (Live/Base/Generic)
                    ↓ 传递 _pixelCategory
                    CommonWidgetBuilder.build
                            ↓ 创建有效 size
                            effectiveSize = HomeWidgetSize.fromCategory(pixelCategory)
                            ↓
                    公共组件 (如 NewsCardWidget)
```

### 新增文件

| 文件 | 说明 |
|------|------|
| `models/widget_grid_metrics.dart` | 网格尺寸信息模型 |
| `widgets/widget_grid_scope.dart` | InheritedWidget，传递网格信息 |
| `models/home_widget_size_extension.dart` | 扩展方法（可选使用） |

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `models/home_widget_size.dart` | 添加 `getPixelSize()`、`getEffectiveCategory()`、`fromCategory()` 方法 |
| `widgets/home_grid.dart` | 使用 LayoutBuilder 计算网格尺寸，用 WidgetGridScope 包裹 |
| `widgets/home_card.dart` | 注入 `_pixelWidth`、`_pixelHeight`、`_pixelCategory` 到 config |
| `widgets/base/live_selector_widget.dart` | 传递 `_pixelCategory` 给公共组件 |
| `widgets/base/base_selector_widget.dart` | 传递 `_pixelCategory` 给公共组件 |
| `widgets/generic_selector_widget.dart` | 传递 `_pixelCategory` 给公共组件 |
| `widgets/home_widget.dart` | 传递 `_pixelCategory` 给公共组件 |
| `widgets_gallery/common_widgets/common_widgets.dart` | `CommonWidgetBuilder.build` 使用 `_pixelCategory` 创建有效 size |

## Config 新增字段

小组件的 `config` 参数现在包含以下额外字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `_widgetItemId` | String | 小组件实例 ID |
| `_pixelWidth` | double | 实际像素宽度 |
| `_pixelHeight` | double | 实际像素高度 |
| `_gridMetrics` | WidgetGridMetrics? | 完整的网格尺寸信息 |
| `_pixelCategory` | SizeCategory | 基于像素尺寸的有效类别 |

## 像素尺寸类别阈值

基于 `min(width, height)` 判断：

| 像素范围 | 类别 | 对应 Size |
|----------|------|-----------|
| < 120px | mini | SmallSize |
| < 180px | small | SmallSize |
| < 260px | medium | MediumSize |
| < 360px | large | LargeSize |
| >= 360px | xlarge | Wide2Size |

## 使用示例

### 自定义小组件使用像素尺寸

```dart
builder: (context, config) {
  final pixelWidth = config['_pixelWidth'] as double? ?? 150.0;
  final pixelHeight = config['_pixelHeight'] as double? ?? 150.0;
  final pixelCategory = config['_pixelCategory'] as SizeCategory?;

  if (pixelCategory == SizeCategory.mini || pixelCategory == SizeCategory.small) {
    return _buildCompactLayout(pixelWidth, pixelHeight);
  } else {
    return _buildFullLayout(pixelWidth, pixelHeight);
  }
}
```

### 公共组件自动适配

公共组件无需修改，`CommonWidgetBuilder.build` 会自动根据 `_pixelCategory` 创建有效的 `HomeWidgetSize`。

例如 `NewsCardWidget`：
```dart
// widget.size is SmallSize 现在会根据像素尺寸动态判断
if (widget.size is! SmallSize)
  _buildFeaturedNewsSection(...)  // 大尺寸显示头条
```

## 向后兼容性

- **现有小组件无需修改**：`config['widgetSize']` 和 `size.category` 保持不变
- **渐进式采用**：新小组件可以使用像素尺寸信息，现有小组件继续正常工作
- **回退机制**：无法获取网格信息时使用估算值

## 注意事项

1. **不要缓存像素尺寸**：像素尺寸会随窗口大小变化，应在 `build` 方法中实时获取
2. **优先使用 `_pixelCategory`**：相比直接判断像素值，使用类别更稳定
3. **测试不同窗口尺寸**：确保小组件在各种尺寸下都能正确显示
