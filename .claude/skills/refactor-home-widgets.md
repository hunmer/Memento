---
name: refactor-home-widgets
description: 将插件的 home_widgets.dart 文件中的 HomeWidgetRegistry.register 注册方法分离到多个文件，保持功能不变
---

# Refactor Home Widgets Registry

将插件中 `home_widgets.dart` 文件里的 `HomeWidgetRegistry.register` 注册方法分离到多个独立文件，便于维护和扩展。

## Usage

```bash
# 对指定插件进行重构
/refactor-home-widgets <plugin-name>

# 示例 - 重构 activity 插件
/refactor-home-widgets activity

# 示例 - 重构 bill 插件
/refactor-home-widgets bill
```

## Arguments

- `<plugin-name>`: 插件目录名称（相对于 `lib/plugins/`），例如 `activity`、`bill`、`diary`

## Workflow

### 1. Analyze Source File

读取 `lib/plugins/{plugin}/home_widgets.dart` 文件，分析其结构：

```dart
// 典型结构
class {Plugin}HomeWidgets {
  static void register() {
    final registry = HomeWidgetRegistry();

    // 多个 registry.register() 调用
    registry.register(HomeWidget(...));
    registry.register(HomeWidget(...));
    ...
  }

  // 多个静态方法作为 builder、provider 等
  static Widget _buildWidget1(...) {...}
  static Map<String, dynamic> _provideData1(...) {...}
  ...
}

// 多个小组件类定义
class Widget1 extends StatelessWidget {...}
class Widget2 extends StatefulWidget {...}
```

### 2. Identify Components

识别以下组件类型：

| 组件类型 | 识别方式 | 分离到文件 |
|---------|---------|-----------|
| **图标组件** | `GenericIconWidget` 简单展示 | `register_icon_widget.dart` |
| **概览组件** | 带 `availableStatsProvider` | `register_overview_widget.dart` |
| **快捷入口** | 导航到编辑页面 | `register_create_shortcut.dart` |
| **上次活动** | 显示历史记录 | `register_last_activity.dart` |
| **公共组件** | `commonWidgetsProvider` | `register_common_widgets.dart` |
| **图表组件** | 图表/统计展示 | `register_weekly_chart.dart` |
| **标签图表** | 带 `selectorId` | `register_tag_weekly_chart.dart` |

### 3. Create Directory Structure

创建新的模块目录：

```bash
lib/plugins/{plugin}/
├── home_widgets/              # 新建目录
│   ├── home_widgets.dart      # 主入口，导出所有
│   ├── data.dart              # 数据模型
│   ├── utils.dart             # 工具函数
│   ├── providers.dart         # 数据提供者
│   ├── widgets.dart           # 小组件导出
│   ├── register_*.dart        # 各组件注册
│   └── widgets/               # 小组件类
│       ├── activity_create_shortcut.dart
│       └── activity_last_activity.dart
└── home_widgets.dart          # 原始文件（删除）
```

### 4. Extract Data Models

将数据模型类提取到 `data.dart`：

```dart
// data.dart
/// 插件主页小组件数据模型

class DayActivityData {
  final DateTime date;
  final int totalMinutes;
  final int activityCount;

  const DayActivityData({
    required this.date,
    required this.totalMinutes,
    required this.activityCount,
  });
}

class TimeSlotData {
  final int hour;
  final int minute;
  final int durationMinutes;
  final Map<String, int> tagDurations;

  TimeSlotData({
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    this.tagDurations = const {},
  });
}
```

### 5. Extract Utilities

将工具函数提取到 `utils.dart`：

```dart
// utils.dart
/// 插件主页小组件工具函数

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 根据平均活动时长获取状态描述
String getActivityStatus(double avgMinutes) {
  if (avgMinutes >= 720) return '非常活跃';
  // ...
}

/// 格式化时间范围
String formatTimeRangeStatic(DateTime start, DateTime end) {
  return '${formatTimeStatic(start)} - ${formatTimeStatic(end)}';
}

/// 从标签生成颜色
Color getColorFromTag(String tag) {
  final baseHue = (tag.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
}
```

### 6. Extract Providers

将数据提供者函数提取到 `providers.dart`：

```dart
// providers.dart
/// 插件主页小组件数据提供者

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import '../activity_plugin.dart';
import 'data.dart';
import 'utils.dart';

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('{plugin}') as {Plugin}Plugin?;
    if (plugin == null) return [];
    // ...
  } catch (e) {
    return [];
  }
}

/// 公共小组件提供者函数
Map<String, Map<String, dynamic>> provideCommonWidgets(
  Map<String, dynamic> data,
) {
  // 实现逻辑
}
```

### 7. Extract Widget Classes

将小组件类提取到 `widgets/` 目录：

```dart
// widgets/activity_create_shortcut.dart
/// 创建活动快捷入口小组件（1x1）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import '../../screens/activity_edit_screen.dart';
import '../../activity_plugin.dart';

class ActivityCreateShortcutWidget extends StatelessWidget {
  const ActivityCreateShortcutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

### 8. Create Register Files

为每种组件类型创建独立的注册文件：

```dart
// register_icon_widget.dart
/// 插件 - 图标组件注册

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

void registerIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: '{plugin}_icon',
      pluginId: '{plugin}',
      name: '{plugin}_widgetName'.tr,
      description: '{plugin}_widgetDescription'.tr,
      icon: Icons.icon_name,
      color: Colors.pluginColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryRecord'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.icon_name,
        color: Colors.pluginColor,
        name: '{plugin}_widgetName'.tr,
      ),
    ),
  );
}
```

### 9. Create Main Entry Point

创建主入口文件 `home_widgets.dart`：

```dart
// home_widgets.dart
/// 插件的主页小组件注册
///
/// 提供多个主页小组件：
/// - [registerIconWidget] - 1x1 简单图标组件
/// - [registerOverviewWidget] - 2x2 详细卡片组件
/// - ...
library;

export 'data.dart';
export 'utils.dart';
export 'providers.dart';
export 'widgets.dart';

// 注册文件
export 'register_icon_widget.dart';
export 'register_overview_widget.dart';
export 'register_create_shortcut.dart';
export 'register_last_activity.dart';
export 'register_common_widgets.dart';
export 'register_weekly_chart.dart';
export 'register_tag_weekly_chart.dart';

import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'register_icon_widget.dart';
import 'register_overview_widget.dart';
import 'register_create_shortcut.dart';
import 'register_last_activity.dart';
import 'register_common_widgets.dart';
import 'register_weekly_chart.dart';
import 'register_tag_weekly_chart.dart';

/// 注册所有插件的小组件
void register(HomeWidgetRegistry registry) {
  registerIconWidget(registry);
  registerOverviewWidget(registry);
  registerCreateShortcutWidget(registry);
  registerLastActivityWidget(registry);
  registerCommonWidgets(registry);
  registerWeeklyChartWidget(registry);
  registerTagWeeklyChartWidget(registry);
}
```

### 10. Update Import References

更新 `lib/core/app_widgets/home_widget_service.dart` 中的导入路径：

```dart
// Before
import 'package:Memento/plugins/{plugin}/home_widgets.dart';

// After
import 'package:Memento/plugins/{plugin}/home_widgets/home_widgets.dart' as {Plugin}HomeWidgets;
```

### 11. Delete Original File

删除原始的 `lib/plugins/{plugin}/home_widgets.dart` 文件。

## Complete Example: Refactoring activity Plugin

### Step 1: Analyze original file

原始文件 `lib/plugins/activity/home_widgets.dart` 包含：
- 7 个 `registry.register()` 调用
- 多个 `_build*`、`_provide*` 静态方法
- 2 个小组件类 (`ActivityCreateShortcutWidget`, `ActivityLastActivityWidget`)
- 多个工具函数和辅助类

### Step 2: Create directory and files

```bash
mkdir lib/plugins/activity/home_widgets
mkdir lib/plugins/activity/home_widgets/widgets
```

创建以下文件：
- `home_widgets.dart`
- `data.dart`
- `utils.dart`
- `providers.dart`
- `widgets.dart`
- `register_icon_widget.dart`
- `register_overview_widget.dart`
- `register_create_shortcut.dart`
- `register_last_activity.dart`
- `register_common_widgets.dart`
- `register_weekly_chart.dart`
- `register_tag_weekly_chart.dart`
- `widgets/activity_create_shortcut.dart`
- `widgets/activity_last_activity.dart`

### Step 3: Verify

运行分析检查：

```bash
flutter analyze lib/plugins/activity/home_widgets/
```

确保无错误后，删除原始文件。

## Checklist

- [ ] 创建了 `home_widgets/` 目录结构
- [ ] 提取了数据模型到 `data.dart`
- [ ] 提取了工具函数到 `utils.dart`
- [ ] 提取了数据提供者到 `providers.dart`
- [ ] 提取了小组件类到 `widgets/` 目录
- [ ] 为每种组件类型创建了独立的注册文件
- [ ] 创建了主入口 `home_widgets.dart` 并正确导出
- [ ] 更新了 `home_widget_service.dart` 的导入路径
- [ ] 删除了原始的 `home_widgets.dart` 文件
- [ ] 运行 `flutter analyze` 无错误

## Troubleshooting

### Issue: 导入路径错误

**原因**: 新文件位置改变导致相对导入失效

**解决**: 使用正确的相对路径或包导入

```dart
// 对于同级目录的导入
import '../models/activity_record.dart';

// 对于 widgets 子目录的导入
import '../../activity_plugin.dart';
```

### Issue: 缺少 `get` 包的导入

**原因**: 使用 `.tr` 进行国际化翻译

**解决**: 添加 `package:get/get.dart` 导入

```dart
import 'package:get/get.dart';
```

### Issue: 小组件类找不到

**原因**: 注册文件使用了未导入的组件类

**解决**: 在 `widgets.dart` 中正确导出

```dart
// widgets.dart
export 'widgets/activity_create_shortcut.dart';
export 'widgets/activity_last_activity.dart';
```

## Notes

- 保持原有的国际化翻译键不变
- 保留所有注释和文档
- 确保导入路径正确且简洁
- 每个注册文件保持职责单一
- 小组件类可以独立使用，不需要依赖注册逻辑
