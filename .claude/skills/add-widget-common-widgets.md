---
name: add-widget-common-widgets
description: 将指定源文件中的组件添加到公共小组件系统，支持插件数据选择后使用公共组件样式渲染。(1)添加fromProps工厂方法，(2)添加JSON序列化支持，(3)移除硬编码内容转为可配置参数，(4)注册到common_widgets列表
---

# Add Widget to Common Widgets System

将指定源文件中的组件添加到公共小组件系统，使插件可以通过 `commonWidgetsProvider` 使用这些组件样式。

## Usage

```bash
# 将示例组件添加为公共小组件
/add-widget-common-widgets <source-file> <component-name>

# 示例 - 从 screens 目录添加
/add-widget-common-widgets lib/screens/widgets_gallery/screens/segmented_progress_card_example.dart SegmentedProgressCard
/add-widget-common-widgets lib/screens/widgets_gallery/screens/milestone_card_example.dart MilestoneCard
/add-widget-common-widgets lib/screens/widgets_gallery/screens/monthly_progress_with_dots_card_example.dart MonthlyProgressWithDotsCard
```

## Arguments

- `<source-file>`: 源文件路径（相对于项目根目录的 Dart 文件路径），例如 `lib/screens/widgets_gallery/screens/segmented_progress_card_example.dart`
- `<component-name>`: 组件类名（包含或不包含 `Widget` 后缀均可），例如 `SegmentedProgressCard` 或 `SegmentedProgressCardWidget`

## Workflow

### 1. Read and Analyze Source File

读取传入的源文件，分析组件结构：

```dart
// 传入的文件: lib/screens/widgets_gallery/screens/segmented_progress_card_example.dart
// 组件名称: SegmentedProgressCardWidget
```

检查以下内容：
- 组件是否为 StatefulWidget
- 有哪些自定义数据模型需要添加 JSON 序列化
- 有哪些硬编码的值需要改为参数
- 组件的构造函数参数列表

### 2. Add Required Imports

在示例文件顶部添加必要的 import：

```dart
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
```

**修改示例：**
```dart
// Before
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

// After
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
```

### 3. Add JSON Serialization for Data Models

为组件使用的数据模型添加 `fromJson` 和 `toJson` 方法：

```dart
// Before
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

// After
class SegmentData {
  final String label;
  final double value;
  final Color color;

  const SegmentData({
    required this.label,
    required this.value,
    required this.color,
  });

  /// 从 JSON 创建
  factory SegmentData.fromJson(Map<String, dynamic> json) {
    return SegmentData(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color.value,
    };
  }
}
```

**数据类型处理规则：**

| 数据类型 | JSON 转换方式 |
|---------|--------------|
| `String` | `json['field'] as String? ?? ''` |
| `int` | `json['field'] as int? ?? 0` |
| `double` | `(json['field'] as num?)?.toDouble() ?? 0.0` |
| `bool` | `json['field'] as bool? ?? false` |
| `Color` | `Color(json['field'] as int? ?? 0xFF000000)` |
| `List<String>` | `(json['field'] as List<dynamic>)?.cast<String>() ?? []` |
| `List<T>` | `(json['field'] as List<dynamic>)?.map((e) => T.fromJson(e)).toList() ?? []` |
| `enum` | 需要自定义映射逻辑 |

### 4. Add fromProps Factory Method

在组件的 StatefulWidget 类中添加 `fromProps` 工厂方法：

```dart
class SegmentedProgressCardWidget extends StatefulWidget {
  final String title;
  final double currentValue;
  final double targetValue;
  final List<SegmentData> segments;
  final String unit;

  const SegmentedProgressCardWidget({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.segments,
    this.unit = '',
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory SegmentedProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final segmentsList = (props['segments'] as List<dynamic>?)
            ?.map((e) => SegmentData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return SegmentedProgressCardWidget(
      title: props['title'] as String? ?? '',
      currentValue: (props['currentValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (props['targetValue'] as num?)?.toDouble() ?? 0.0,
      segments: segmentsList,
      unit: props['unit'] as String? ?? '',
    );
  }

  @override
  State<SegmentedProgressCardWidget> createState() =>
      _SegmentedProgressCardWidgetState();
}
```

**fromProps 编写模板：**

```dart
/// 从 props 创建实例（用于公共小组件系统）
factory {WidgetName}.fromProps(
  Map<String, dynamic> props,
  HomeWidgetSize size,
) {
  return {WidgetName}(
    // 字段1: props['field1'] as Type? ?? defaultValue,
    // 字段2: (props['field2'] as num?)?.toDouble() ?? 0.0,
    // 列表: (props['listField'] as List<dynamic>?)?.map((e) => Model.fromJson(e)).toList() ?? [],
    // 可选对象: props['optionalField'] != null ? Type(props['optionalField']) : null,
  );
}
```

### 5. Remove Hardcoded Values

将组件中的硬编码内容改为可接受参数：

**示例 - 移除硬编码的颜色：**

```dart
// Before - 硬编码颜色
final primaryColor = const Color(0xFF7C5CFF);
final gaugeBackgroundColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

// After - 使用参数或主题色
final primaryColor = widget.primaryColor ?? Theme.of(context).colorScheme.primary;
final gaugeBackgroundColor = isDark
    ? const Color(0xFF3A3A3C)
    : const Color(0xFFE5E5EA);
```

**示例 - 移除硬编码的文本：**

```dart
// Before
Text('Shopping', style: ...)

// After
Text(widget.title, style: ...)
```

**示例 - 移除硬编码的尺寸：**

```dart
// Before
Container(width: 300, height: 300, ...)

// After - 根据小组件尺寸自适应
Container(
  width: size == HomeWidgetSize.large ? 300 : 200,
  height: size == HomeWidgetSize.large ? 300 : 150,
  ...
)
```

### 6. Register in common_widgets.dart

在 `lib/screens/widgets_gallery/common_widgets/common_widgets.dart` 中注册新组件：

#### Step 6.1: Add Import

根据源文件路径添加正确的 import：

```dart
// 如果源文件在 screens/ 目录下
import '../screens/{component_file}_example.dart';

// 如果源文件在其他位置，使用相对路径
import '../../{relative_path}/{component_file}.dart';
```

#### Step 6.2: Add to Enum

```dart
enum CommonWidgetId {
  // ... existing IDs
  {componentId},  // 使用 camelCase，如 segmentedProgressCard
}
```

#### Step 6.3: Add Metadata

```dart
CommonWidgetId.{componentId}: CommonWidgetMetadata(
  id: CommonWidgetId.{componentId},
  name: '{组件显示名称}',
  description: '{组件描述}',
  icon: Icons.{icon_name},
  defaultSize: HomeWidgetSize.large,
  supportedSizes: [HomeWidgetSize.large],
),
```

#### Step 6.4: Add to Builder

```dart
case CommonWidgetId.{componentId}:
  return {WidgetClassName}.fromProps(props, size);
```

### 7. Update Migration Skill Documentation

在 `.claude/skills/migrate-home-widget-common-widgets.md` 中添加新组件的使用示例：

```markdown
### SegmentedProgressCard

```dart
'segmentedProgressCard': {
  'title': '今日支出',
  'currentValue': 322.0,
  'targetValue': 443.0,
  'segments': [
    {'label': '餐饮', 'value': 37.0, 'color': 0xFFFF3B30},
    {'label': '健身', 'value': 43.0, 'color': 0xFF007AFF},
  ],
  'unit': '\$',
},
```
```

## Complete Example: Adding MultiTrackerCard

### Step 1: Read the source file

```bash
# 传入参数
source-file: lib/screens/widgets_gallery/screens/multi_tracker_card_example.dart
component-name: MultiTrackerCardWidget
```

### Step 2: Add import

```dart
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
```

### Step 3: Add to MultiTrackerData (if needed)

```dart
class MultiTrackerData {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  // ... existing code ...

  factory MultiTrackerData.fromJson(Map<String, dynamic> json) {
    return MultiTrackerData(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      maxValue: (json['maxValue'] as num?)?.toDouble() ?? 100.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'maxValue': maxValue,
      'color': color.value,
    };
  }
}
```

### Step 4: Add fromProps

```dart
class MultiTrackerCardWidget extends StatefulWidget {
  final String title;
  final List<MultiTrackerData> trackers;

  const MultiTrackerCardWidget({
    super.key,
    required this.title,
    required this.trackers,
  });

  factory MultiTrackerCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final trackersList = (props['trackers'] as List<dynamic>?)
            ?.map((e) => MultiTrackerData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return MultiTrackerCardWidget(
      title: props['title'] as String? ?? '',
      trackers: trackersList,
    );
  }

  // ...
}
```

### Step 5: Register

```dart
// common_widgets.dart
import '../screens/multi_tracker_card_example.dart';

enum CommonWidgetId {
  // ...
  multiTrackerCard,
}

// metadata
CommonWidgetId.multiTrackerCard: CommonWidgetMetadata(
  id: CommonWidgetId.multiTrackerCard,
  name: '多追踪器卡片',
  description: '多指标追踪展示卡片',
  icon: Icons.dashboard,
  defaultSize: HomeWidgetSize.large,
  supportedSizes: [HomeWidgetSize.large],
),

// builder
case CommonWidgetId.multiTrackerCard:
  return MultiTrackerCardWidget.fromProps(props, size);
```

## Common Patterns

### Pattern 1: Optional Color Parameter

```dart
final Color? customColor;

factory MyWidget.fromProps(Map<String, dynamic> props, HomeWidgetSize size) {
  return MyWidget(
    customColor: props['customColor'] != null
        ? Color(props['customColor'] as int)
        : null,
  );
}

// In build method
final effectiveColor = widget.customColor ?? Theme.of(context).colorScheme.primary;
```

### Pattern 2: Nested Data Structures

```dart
// Props structure
{
  'title': 'Dashboard',
  'sections': [
    {
      'title': 'Section 1',
      'items': [
        {'label': 'Item 1', 'value': 10},
        {'label': 'Item 2', 'value': 20},
      ]
    }
  ]
}

// fromProps
factory MyWidget.fromProps(Map<String, dynamic> props, HomeWidgetSize size) {
  final sectionsList = (props['sections'] as List<dynamic>?)
      ?.map((sectionJson) {
        final section = sectionJson as Map<String, dynamic>;
        final itemsList = (section['items'] as List<dynamic>?)
            ?.map((itemJson) => Item.fromJson(itemJson as Map<String, dynamic>))
            .toList() ??
            [];
        return SectionData(
          title: section['title'] as String? ?? '',
          items: itemsList,
        );
      })
      .toList() ??
      [];

  return MyWidget(
    title: props['title'] as String? ?? '',
    sections: sectionsList,
  );
}
```

### Pattern 3: Handling Image URLs

```dart
final String? imageUrl;

factory MyWidget.fromProps(Map<String, dynamic> props, HomeWidgetSize size) {
  return MyWidget(
    imageUrl: props['imageUrl'] as String?,
  );
}

// In build
Widget _buildImage() {
  if (widget.imageUrl == null) {
    return Container(color: Colors.grey.shade300);
  }
  return Image.network(
    widget.imageUrl!,
    errorBuilder: (context, error, stackTrace) {
      return Container(color: Colors.grey.shade300);
    },
  );
}
```

## Checklist

完成以下检查确保组件正确集成：

- [ ] 添加了 `import 'package:Memento/screens/home_screen/models/home_widget_size.dart';`
- [ ] 为所有自定义数据模型添加了 `fromJson` 和 `toJson`
- [ ] 添加了 `fromProps` 工厂方法
- [ ] 所有硬编码值都已改为可配置参数
- [ ] 在 `common_widgets.dart` 中添加了 import
- [ ] 在 `CommonWidgetId` 枚举中添加了新 ID
- [ ] 在 `metadata` 中添加了组件元数据
- [ ] 在 `CommonWidgetBuilder.build()` 中添加了 case 分支
- [ ] 运行 `flutter analyze` 无错误

## Testing

测试组件是否正确工作：

```dart
// 在插件的 commonWidgetsProvider 中使用
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  return {
    'newWidget': {
      'param1': 'value1',
      'param2': 123,
      'listParam': [
        {'item': 'value', 'color': 0xFFFF0000},
      ],
    },
  };
}
```

## Troubleshooting

### Issue: `fromProps` 类型转换错误

**原因**: props 中的数据类型与组件期望的不匹配

**解决**: 使用安全的类型转换
```dart
// ✅ 正确
value: (props['value'] as num?)?.toDouble() ?? 0.0

// ❌ 错误
value: props['value'] as double
```

### Issue: 列表数据为空导致崩溃

**原因**: 未提供默认空列表

**解决**:
```dart
// ✅ 正确
items: (props['items'] as List<dynamic>?)
    ?.map((e) => Item.fromJson(e))
    .toList() ?? [],
```

### Issue: Color 值解析失败

**原因**: Color 构造函数需要 int 类型的 ARGB 值

**解决**:
```dart
// ✅ 正确
color: Color(json['color'] as int? ?? 0xFF000000)

// ❌ 错误
color: json['color'] as Color? ?? Colors.red
```

## Notes

- 保持组件原有的示例功能不变
- `fromProps` 方法是对原有构造函数的补充
- 使用中文注释说明新增代码的用途
- 遵循现有代码的命名和格式规范
- 参考 `segmented_progress_card_example.dart` 获取完整示例
