---
name: add-widget-from-prototype
description: 从 code_snippet 原型文件创建可预览的 Dart 小组件。自动分析 HTML 设计、生成 Flutter 组件、注册路由并添加到组件展示列表。
---

# Add Widget from Prototype

从 `code_snippet` 目录中的原型文件（HTML + 截图）创建 Flutter 小组件，自动完成组件生成、路由注册和列表入口添加。

## Usage

```bash
# 基础用法
/add-widget-from-prototype <prototype-path>

# 示例：从 card_widgets/widget3 创建组件
/add-widget-from-prototype code_snippet/card_widgets/widget3
```

## Arguments

- `<prototype-path>`: 原型目录路径，相对于项目根目录
  - 必须包含 `code.html` 文件
  - 建议包含 `screen.png` 截图文件

### 可选参数（交互式询问）

- `--name <name>`: 组件名称（驼峰命名，如 `SegmentedProgressCard`）
- `--route <route>`: 路由路径（如 `segmented_progress_card`）
- `--title <title>`: 列表显示标题（中文）
- `--subtitle <subtitle>`: 列表副标题
- `--icon <icon>`: 列表图标（Material Icons 名称）

## Workflow

### 1. Analyze Prototype

读取并分析原型文件：
- 读取 `code.html` 获取 HTML 结构和样式
- 读取 `screen.png` 获取视觉参考
- 提取颜色、尺寸、布局、字体等设计信息

### 2. Determine Component Name

根据设计功能推断通用组件名称：
- **避免**使用示例内容命名（如 `SpendingWidget`、`GroceriesWidget`）
- **推荐**使用功能描述命名（如 `SegmentedProgressCard`、`CategoryDistributionChart`）

常用命名模式：
| 设计类型 | 推荐命名 |
|---------|---------|
| 分段进度条 | `SegmentedProgressCard` |
| 环形/半圆仪表 | `GaugeWidget` / `HalfCircleGaugeWidget` |
| 分类统计卡片 | `CategoryStatsCard` |
| 时间线视图 | `TimelineView` / `DailyTimelineWidget` |
| 列表卡片 | `ListCard` / `ItemListWidget` |
| 数据网格 | `DataGridWidget` / `StatsGrid` |

### 3. Generate Dart Component

创建组件文件 `lib/screens/widgets_gallery/screens/[component_name]_example.dart`：

**文件结构：**
```dart
import 'package:flutter/material.dart';

/// [组件描述]示例
class [ComponentName]Example extends StatelessWidget {
  const [ComponentName]Example({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('[组件标题]')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: [ComponentName]Widget(
            // 示例数据
          ),
        ),
      ),
    );
  }
}

/// [组件描述]小组件
class [ComponentName]Widget extends StatelessWidget {
  // 组件参数
  final [Type] [param1];
  final [Type] [param2];

  const [ComponentName]Widget({
    super.key,
    required this.[param1],
    // ...
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 根据原型实现 UI
  }
}

// 辅助类和函数
class _[HelperName] extends StatelessWidget {
  // ...
}
```

### 4. Register Route

在 `lib/screens/routing/routes/widget_gallery_routes.dart` 中：
1. 添加组件导入
2. 添加路由定义

```dart
// 文件顶部添加导入
import 'package:Memento/screens/widgets_gallery/screens/[component_name]_example.dart';

// 在 routes 列表中添加（在 half_circle_gauge_widget 后面）
RouteDefinition(
  path: '/widgets_gallery/[route_name]',
  handler: (settings) => RouteHelpers.createRoute(const [ComponentName]Example(), settings: settings),
  description: '[组件描述]',
),
```

### 5. Add List Entry

在 `lib/screens/widgets_gallery/screens/home_widgets_gallery_screen.dart` 中添加列表入口：

```dart
_buildListItem(
  context,
  icon: Icons.[icon_name],
  title: '[中文标题]',
  subtitle: '[ComponentName] - [副标题]',
  route: '/widgets_gallery/[route_name]',
),
```

## Design Analysis Guidelines

### 颜色提取

从 HTML 中提取颜色：
- 背景色（浅色/深色模式）
- 主色调
- 文本颜色（标题、正文、次要文本）
- 边框/分隔线颜色

```dart
// 从 HTML 提取颜色示例
final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
final primaryColor = const Color(0xFF7B57E0);
final textColor = isDark ? Colors.white : Colors.grey.shade900;
```

### 布局转换

HTML/Tailwind → Flutter 转换：

| HTML/Tailwind | Flutter |
|--------------|---------|
| `flex row` | `Row()` |
| `flex col` | `Column()` |
| `rounded-lg` | `BorderRadius.circular(8)` |
| `p-4` | `EdgeInsets.all(16)` |
| `gap-2` | `SizedBox(height/width: 8)` |
| `w-full` | `Expanded()` 或 `double.infinity` |
| `text-center` | `TextAlign.center` |

### 响应式处理

根据原型固定尺寸或使用响应式布局：

```dart
// 固定尺寸（桌面小组件风格）
Container(
  width: 280,
  height: 280,
  // ...
)

// 响应式尺寸
LayoutBuilder(
  builder: (context, constraints) {
    return Container(
      width: constraints.maxWidth,
      // ...
    );
  },
)
```

### 图表处理

原型中包含图表时：
- **优先使用 `fl_chart` 包**实现图表
- 简单图表可用 `CustomPainter` 自定义绘制
- 进度条/仪表盘可用自定义组件

```dart
// fl_chart 示例
import 'package:fl_chart/fl_chart.dart';

PieChart(
  PieChartData(
    sections: [
      PieChartSectionData(value: 30, color: Colors.blue),
      PieChartSectionData(value: 70, color: Colors.green),
    ],
  ),
)
```

## Naming Best Practices

### ✅ 推荐命名

| 功能 | 组件名称 | 原因 |
|-----|---------|-----|
| 分段进度条 | `SegmentedProgressCard` | 描述布局结构 |
| 分类统计 | `CategoryStatsCard` | 通用，可复用 |
| 圆形仪表 | `CircularGaugeWidget` | 描述形状 |
| 时间线 | `TimelineWidget` | 描述视图类型 |

### ❌ 避免命名

| 功能 | 避免命名 | 原因 |
|-----|---------|-----|
| 消费展示 | `SpendingWidget` | 过于具体 |
| 购物统计 | `ShoppingWidget` | 限于购物场景 |
| 任务列表 | `TodoListWidget` | 仅适用于 Todo |

### 命名模式

- **Card**: 卡片容器组件
- **Widget**: 通用小组件
- **Chart**: 图表类组件
- **View**: 完整视图
- **Item**: 列表项

## Animation Guidelines

### 动画效果要求

创建的小组件必须包含动画效果以提升用户体验：

#### 1. 组件入场动画

**必需实现：**
- 淡入效果（Opacity 从 0 到 1）
- 位移效果（从下方上移约 20px）
- 多个元素依次延迟出现（每个延迟约 150ms）

**实现方式：**
```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: // 组件内容
          ),
        );
      },
    );
  }
}
```

#### 2. 进度条动画

**适用场景：** 组件包含进度条、仪表盘等数据展示

**实现方式：**
- 使用 `CustomPainter` 绘制进度条
- 将动画值传递给 painter：`progress * animation.value`
- 进度条从 0 平滑增长到目标值

```dart
class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _ProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景圆环
    // 绘制进度圆弧（使用 progress 值）
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

#### 3. 数字计数动画

**必需实现：** 组件中的数值显示必须使用 `AnimatedFlipCounter`

**实现方式：**
```dart
import 'package:animated_flip_counter/animated_flip_counter.dart';

// 在 AnimatedBuilder 中使用
AnimatedFlipCounter(
  value: data.value * itemAnimation.value,  // 从 0 增长到目标值
  fractionDigits: data.value % 1 != 0 ? 2 : 0,  // 自动识别整数/小数
  textStyle: const TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  ),
),
```

**注意：**
- 必须乘以动画值：`value * animation.value`
- 自动判断是否需要小数位数
- 保持与原设计一致的文本样式

#### 4. 多元素延迟动画

**适用场景：** 组件包含多个列表项或卡片

**实现方式：**
```dart
for (int i = 0; i < items.length; i++) ...[
  if (i > 0) const SizedBox(height: 24),
  _ItemWidget(
    data: items[i],
    animation: _animation,
    index: i,  // 传递索引用于计算延迟
  ),
]

// 在子组件中
final itemAnimation = CurvedAnimation(
  parent: animation,
  curve: Interval(
    index * 0.15,  // 延迟开始
    0.6 + index * 0.15,  // 延迟结束
    curve: Curves.easeOutCubic,
  ),
);
```

### 动画时序示例

```
时间轴 (0-1200ms), 3个元素:
├── 0-180ms:      元素1 开始淡入+上滑
├── 0-930ms:      元素1 进度条/数字增长
├── 180-360ms:    元素2 开始淡入+上滑
├── 180-1110ms:   元素2 进度条/数字增长
├── 360-540ms:    元素3 开始淡入+上滑
└── 360-1200ms:   元素3 进度条/数字增长
```

## Component Structure Template

### 完整示例（含动画）

```dart
import 'package:flutter/material.dart';

/// 分段进度条统计卡片示例
class SegmentedProgressCardExample extends StatelessWidget {
  const SegmentedProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分段进度条统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SegmentedProgressCardWidget(
            segments: [
              SegmentData(label: '类别A', value: 45, color: Color(0xFFE14462)),
              SegmentData(label: '类别B', value: 30, color: Color(0xFF7B57E0)),
            ],
            total: 100,
            unit: '单位',
          ),
        ),
      ),
    );
  }
}

/// 分段数据模型
class SegmentData {
  final String label;
  final double value;
  final Color color;

  const SegmentData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// 分段进度条统计小组件
class SegmentedProgressCardWidget extends StatelessWidget {
  final List<SegmentData> segments;
  final double total;
  final String unit;

  const SegmentedProgressCardWidget({
    super.key,
    required this.segments,
    required this.total,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // 组件内容
        ],
      ),
    );
  }
}
```

## Execution Steps

当用户请求从原型创建组件时：

1. **验证原型路径**
   - 检查 `code.html` 是否存在
   - 尝试读取 `screen.png` 作为参考

2. **分析原型设计**
   - 解析 HTML 获取结构和样式
   - 提取颜色、字体、尺寸
   - 识别组件类型（卡片、图表、列表等）

3. **推断组件名称**
   - 根据设计功能确定通用名称
   - 向用户确认或让用户指定

4. **生成 Dart 代码**
   - 创建 Example 展示页
   - 创建实际 Widget 组件（必须使用 StatefulWidget）
   - 添加数据模型（如需要）
   - **实现动画效果**：
     - 入场动画（淡入 + 上滑）
     - 进度条动画（如有）
     - 数字计数动画（AnimatedFlipCounter）

5. **注册路由**
   - 在 `widget_gallery_routes.dart` 添加导入
   - 添加路由定义

6. **添加列表入口**
   - 在 `home_widgets_gallery_screen.dart` 添加入口

7. **验证代码**
   - 检查导入是否正确
   - 确认语法无误

## Checklist

完成后验证：

**文件创建：**
- [ ] 组件文件已创建：`lib/screens/widgets_gallery/screens/[name]_example.dart`
- [ ] 包含 Example 展示页和实际 Widget
- [ ] 数据模型（如需要）已定义

**路由注册：**
- [ ] `widget_gallery_routes.dart` 已添加导入
- [ ] 路由定义已添加到列表中

**列表入口：**
- [ ] `home_widgets_gallery_screen.dart` 已添加列表项
- [ ] 图标、标题、副标题正确

**代码质量：**
- [ ] 组件名称通用、可复用
- [ ] 支持深色/浅色主题
- [ ] 参数设计合理、可配置
- [ ] 代码注释清晰（中文）

**动画效果：**
- [ ] 组件使用 StatefulWidget 并添加 AnimationController
- [ ] 实现淡入 + 上滑入场动画
- [ ] 多个元素依次延迟出现（Interval 延迟）
- [ ] 进度条/仪表盘包含动画（CustomPainter + animation.value）
- [ ] 数值显示使用 AnimatedFlipCounter（value * animation.value）
- [ ] 动画时长约 1200ms，使用 easeOutCubic 曲线
- [ ] 动画资源正确释放（dispose 中调用 controller.dispose()）

## Examples

### 示例 1: 分段进度条卡片

**原型路径:** `code_snippet/card_widgets/widget2`

**推断组件名:** `SegmentedProgressCard` (而非 `SpendingCard`)

**生成结果:**
- 文件: `segmented_progress_card_example.dart`
- 路由: `/widgets_gallery/segmented_progress_card`
- 列表标题: "分段进度条卡片"

### 示例 2: 半圆仪表盘

**原型路径:** `code_snippet/gauge_widgets/widget1`

**推断组件名:** `HalfCircleGaugeWidget`

**生成结果:**
- 文件: `half_circle_gauge_widget_example.dart`
- 路由: `/widgets_gallery/half_circle_gauge_widget`
- 列表标题: "半圆仪表盘"

## Troubleshooting

### 问题 1: 原型文件不存在

**检查路径格式：**
- 相对于项目根目录的路径
- 不包含开头的 `/`
- 使用正斜杠 `/` 分隔目录

### 问题 2: 组件名称不通用

**重新命名：**
- 使用功能描述而非示例内容
- 参考命名模式表
- 询问用户期望的组件用途

### 问题 3: 颜色/尺寸不准确

**从 HTML 精确提取：**
- 颜色使用 `0xFF` 格式
- 尺寸使用原型中的数值
- 考虑深色/浅色模式差异

## Notes

- 使用中文注释与现有代码库保持一致
- 组件参数设计要灵活、可配置
- 保持与现有组件风格一致
- 参考 `half_circle_gauge_widget_example.dart` 作为模板
- 图表优先使用 `fl_chart` 包实现
- **所有组件必须包含动画效果**：入场动画、进度条动画、数字计数动画
- 使用 `animated_flip_counter` 包实现数字翻转效果（项目已包含此依赖）
- 动画时长推荐 1200ms，曲线使用 `Curves.easeOutCubic`
- 多元素动画使用 `Interval` 实现依次延迟效果（每个延迟约 15%）
