---
name: widget-size-checklist
description: 确保小组件组件根据 HomeWidgetSize 正确调整各元素大小，包括容器、图标、字体、间距、线条粗细等
---

# Widget Size Checklist - 小组件大小自检清单

确保小组件组件根据 `HomeWidgetSize` 正确调整各元素大小。

## Usage

```bash
# 检查小组件大小适配
/widget-size-checklist <widget_file_path>

# 示例
/widget-size-checklist lib/screens/widgets_gallery/common_widgets/widgets/circular_metrics_card.dart
```

## HomeWidgetSize 常用方法速查

### 尺寸和布局方法

| 方法 | 说明 | Small | Medium | Large | Wide | Wide2 |
|------|------|-------|--------|-------|------|-------|
| `getPadding()` | 外层容器内边距 | 8px | 12px | 16px | 12px | 16px |
| `getTitleSpacing()` | 标题与内容间距 | 16px | 20px | 24px | 20px | 24px |
| `getItemSpacing()` | 列表项之间间距 | 6px | 8px | 12px | 8px | 12px |
| `getSmallSpacing()` | 紧密元素间距 | 2px | 4px | 6px | 4px | 6px |
| `getHeightConstraints()` | 高度约束 | 150-250 | 200-350 | 250-450 | 200-350 | 250-450 |

### 字体大小方法

| 方法 | 说明 | Small | Medium | Large | Wide | Wide2 |
|------|------|-------|--------|-------|------|-------|
| `getLargeFontSize()` | 大标题/数值 | 36px | 48px | 56px | 48px | 56px |
| `getTitleFontSize()` | 标题 | 16px | 24px | 28px | 24px | 28px |
| `getSubtitleFontSize()` | 副标题/标签 | 12px | 14px | 16px | 14px | 16px |
| `getLegendFontSize()` | 图例/小字 | 10px | 12px | 14px | 12px | 14px |

### 图形元素方法

| 方法 | 说明 | Small | Medium | Large | Wide | Wide2 |
|------|------|-------|--------|-------|------|-------|
| `getIconSize()` | 图标大小 | 18px | 24px | 28px | 24px | 28px |
| `getStrokeWidth()` | 线条粗细 | 6px | 8px | 10px | 8px | 10px |
| `getLegendIndicatorWidth()` | 指示器宽度 | 16px | 24px | 32px | 24px | 32px |
| `getLegendIndicatorHeight()` | 指示器高度 | 8px | 12px | 16px | 12px | 16px |
| `getBarWidth()` | 柱状图柱宽 | 12px | 16px | 20px | 16px | 20px |
| `getBarSpacing()` | 柱间距 | 0.5px | 1px | 1.5px | 1px | 1.5px |

### 缩放系数（可直接使用）

| 系数 | 默认值 | 用途 |
|------|--------|------|
| `iconContainerScale` | 2.0 | 图标容器大小 = 图标大小 × 2 |
| `progressStrokeScale` | 0.4 | 进度条粗细 = strokeWidth × 0.4 |

## Checklist

### 1. 组件参数检查

- [ ] 组件声明中有 `final HomeWidgetSize size` 参数
- [ ] 构造函数中有 `this.size = const MediumSize()` 默认值
- [ ] `fromProps` 工厂方法正确接收并传递 size 参数

```dart
class MyWidget extends StatefulWidget {
  final HomeWidgetSize size;

  const MyWidget({
    super.key,
    required this.data,
    this.size = const MediumSize(),  // 默认值
  });

  factory MyWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MyWidget(
      data: props['data'],
      size: size,  // 必须传递
    );
  }
}
```

### 2. 外层容器检查

- [ ] 外层 Container 使用 `widget.size.getPadding()`
- [ ] 外层 Container 使用 `widget.size.getHeightConstraints()`
- [ ] 外层 Container 使用 `widget.size.getTitleSpacing()`（如有标题）

```dart
Container(
  padding: widget.size.getPadding(),
  constraints: widget.size.getHeightConstraints(),
  decoration: BoxDecoration(...),
  child: Column(
    children: [
      Text('标题', style: TextStyle(fontSize: widget.size.getTitleFontSize())),
      SizedBox(height: widget.size.getTitleSpacing()),
      // 内容
    ],
  ),
)
```

### 3. 子组件传递检查

- [ ] 所有子组件都接收并使用 size 参数
- [ ] 列表项组件接收 size 并传递

```dart
// 列表项
_MyItemWidget(
  data: item,
  size: widget.size,  // 必须传递
)
```

### 4. 内部元素大小检查

#### 容器大小

- [ ] 容器宽高根据 size 计算（如 `getIconSize() * iconContainerScale`）

```dart
final iconSize = size.getIconSize();
final containerSize = iconSize * size.iconContainerScale;

SizedBox(
  width: containerSize,
  height: containerSize,
  child: ...
)
```

#### 图标大小

- [ ] Icon 组件使用 `size.getIconSize()` 或其倍数

```dart
Icon(
  Icons.star,
  size: size.getIconSize() * 0.8,  // 可根据需要调整倍数
  color: Colors.amber,
)
```

#### 字体大小

- [ ] 标题使用 `getTitleFontSize()`
- [ ] 大数值使用 `getLargeFontSize() * 0.35`（约 13-20px）
- [ ] 标签/副标题使用 `getSubtitleFontSize()`
- [ ] 小字/图例使用 `getLegendFontSize()`

```dart
Text(
  '大数值',
  style: TextStyle(
    fontSize: size.getLargeFontSize() * 0.35,  // 约 13-20px
    fontWeight: FontWeight.w700,
  ),
),
SizedBox(height: size.getSmallSpacing()),
Text(
  '标签',
  style: TextStyle(
    fontSize: size.getSubtitleFontSize(),
    fontWeight: FontWeight.w500,
  ),
)
```

#### 间距

- [ ] 元素之间使用 `getItemSpacing()` 或 `getSmallSpacing()`

```dart
SizedBox(width: size.getSmallSpacing() * 2),  // 行间距
SizedBox(height: size.getSmallSpacing()),       // 列间距
```

### 5. CustomPainter 检查

- [ ] CustomPainter 接收 strokeWidth 参数
- [ ] 使用 strokeWidth 绘制，而非固定值
- [ ] shouldRepaint 检查 strokeWidth

```dart
class _MyPainter extends CustomPainter {
  final double strokeWidth;

  _MyPainter({this.strokeWidth = 2.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth  // 使用参数
      ..style = PaintingStyle.stroke;
    // ...
  }

  @override
  bool shouldRepaint(covariant _MyPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;  // 检查变化
  }
}

// 使用
CustomPaint(
  painter: _MyPainter(
    strokeWidth: widget.size.getStrokeWidth() * widget.size.progressStrokeScale,
  ),
  child: ...
)
```

### 6. 示例文件检查

- [ ] 示例文件中为不同尺寸传递对应的 size
- [ ] 导入 HomeWidgetSize
- [ ] **Wide/Wide2 尺寸宽度应填满屏幕**，使用 `MediaQuery.of(context).size.width - 32`

```dart
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

// 小尺寸
MyWidget(data: data, size: const SmallSize()),

// 中尺寸
MyWidget(data: data, size: const MediumSize()),

// 大尺寸
MyWidget(data: data, size: const LargeSize()),

// 中宽尺寸 (4x1) - 宽度填满屏幕
SizedBox(
  width: MediaQuery.of(context).size.width - 32,
  height: 160,
  child: MyWidget(data: data, size: const WideSize()),
),

// 大宽尺寸 (4x2) - 宽度填满屏幕
SizedBox(
  width: MediaQuery.of(context).size.width - 32,
  height: 320,
  child: MyWidget(data: data, size: const Wide2Size()),
),
```

## Common Pitfalls

### 1. 子组件未接收 size 参数

```dart
// ❌ 错误
_MyItemWidget(data: item)  // 缺少 size

// ✅ 正确
_MyItemWidget(data: item, size: widget.size)
```

### 2. 使用固定值而非 size 方法

```dart
// ❌ 错误
SizedBox(width: 56, height: 56)

// ✅ 正确
final containerSize = size.getIconSize() * size.iconContainerScale;
SizedBox(width: containerSize, height: containerSize)
```

### 3. CustomPainter 硬编码 strokeWidth

```dart
// ❌ 错误
backgroundPaint.strokeWidth = 2.5

// ✅ 正确
backgroundPaint.strokeWidth = strokeWidth
```

### 4. 字体大小固定

```dart
// ❌ 错误
fontSize: 16

// ✅ 正确
fontSize: size.getLargeFontSize() * 0.35
```

### 5. 示例文件未传递 size

```dart
// ❌ 错误 - 所有卡片都使用默认 MediumSize()
MyWidget(data: data)

// ✅ 正确 - 传递所有尺寸
MyWidget(data: data, size: const SmallSize())
MyWidget(data: data, size: const MediumSize())
MyWidget(data: data, size: const LargeSize())
MyWidget(data: data, size: const WideSize())
MyWidget(data: data, size: const Wide2Size())
```

## Quick Fix Template

### 添加 size 参数到子组件

```dart
// 1. 添加参数
class _MyItemWidget extends StatelessWidget {
  final MyData data;
  final HomeWidgetSize size;  // 添加

  const _MyItemWidget({
    required this.data,
    required this.size,  // 添加
  });

  // 2. 使用 size 计算尺寸
  @override
  Widget build(BuildContext context) {
    final iconSize = size.getIconSize();
    final valueFontSize = size.getLargeFontSize() * 0.35;
    final labelFontSize = size.getSubtitleFontSize();
    final spacing = size.getSmallSpacing();

    // 3. 应用尺寸
    return Row(
      children: [
        Icon(Icons.star, size: iconSize),
        SizedBox(width: spacing),
        Text('值', style: TextStyle(fontSize: valueFontSize)),
      ],
    );
  }
}
```

### 更新 CustomPainter

```dart
// 1. 添加参数
class _MyPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;  // 添加

  _MyPainter({required this.progress, this.strokeWidth = 2.5});

  // 2. 使用 strokeWidth
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth  // 使用参数
      ..style = PaintingStyle.stroke;
    // ...
  }

  // 3. 检查 strokeWidth 变化
  @override
  bool shouldRepaint(covariant _MyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
```

## Size Calculation Reference

### 环形进度条组件尺寸计算

```dart
// 图标大小
final iconSize = size.getIconSize();  // 18/24/28

// 容器大小
final containerSize = iconSize * size.iconContainerScale;  // 36/48/56

// 进度条粗细
final strokeWidth = size.getStrokeWidth() * size.progressStrokeScale;  // 2.4/3.2/4.0

// 数值字体
final valueFontSize = size.getLargeFontSize() * 0.35;  // ~13/17/20

// 标签字体的
final labelFontSize = size.getSubtitleFontSize();  // 12/14/16

// 元素间距
final itemSpacing = size.getSmallSpacing() * 2;  // 4/8/12
```

## Testing Checklist

测试时确认以下内容：

- [ ] SmallSize (1x1) 显示正常，元素不过大
- [ ] MediumSize (2x1) 显示正常
- [ ] LargeSize (2x2) 显示正常，元素不过小
- [ ] WideSize (4x1) 宽度正确填满屏幕（使用 `MediaQuery.of(context).size.width - 32`）
- [ ] Wide2Size (4x2) 宽度正确填满屏幕，高度足够展示内容
- [ ] 字体大小在不同尺寸下比例协调
- [ ] 间距在不同尺寸下合理
- [ ] 动画效果在不同尺寸下正常
- [ ] 示例页面展示五种尺寸差异明显
