---
name: create-common-widget-from-renderer
description: 将插件中内置的dataRenderer（自定义UI）封装成标准的公共小组件，使其可被其他插件或功能复用。核心特性：(1)提取dataRenderer的UI逻辑创建独立组件文件，(2)在common_widgets.dart中注册新组件，(3)在_provideCommonWidgets中添加数据提供函数，(4)移除旧的内置渲染器代码
---

# Create Common Widget from dataRenderer

将插件中内置的 `dataRenderer`（自定义 UI）封装成标准的公共小组件，使其可被其他插件复用。

## Usage

```bash
# 将插件的内置渲染器封装为公共组件
/create-common-widget-from-renderer <plugin-path> --widget-id <widget-id> --component-id <component-id>

# 完整参数
/create-common-widget-from-renderer lib/plugins/checkin \
  --widget-id checkin_item_selector \
  --component-id checkinItemCard
```

**Examples:**

```bash
# 将签到项目的内置卡片封装为公共组件
/create-common-widget-from-renderer lib/plugins/checkin \
  --widget-id checkin_item_selector \
  --component-id checkinItemCard

# 将日记条目的内置卡片封装为公共组件
/create-common-widget-from-renderer lib/plugins/diary \
  --widget-id diary_entry_selector \
  --component-id diaryEntryCard
```

## Arguments

- `<plugin-path>`: 插件根目录路径（包含 `home_widgets.dart`）
- `--widget-id <id>`: 源小组件 ID（包含内置 `dataRenderer` 的选择器小组件）
- `--component-id <id>`: 新公共组件的 ID（驼峰命名，如 `checkinItemCard`）

## Workflow

### 1. Analyze Existing dataRenderer

读取并分析现有的 `dataRenderer` 实现：

```dart
// 示例：lib/plugins/checkin/home_widgets.dart

static Widget _renderCheckinItemData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 result.data 获取数据
  final itemData = result.data as Map<String, dynamic>;
  final itemId = itemData['id'] as String?;

  // 获取最新数据
  final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
  final checkinItem = plugin?.checkinItems.firstWhere(...);

  // 构建 UI
  return Container(
    child: Column(
      children: [
        // 图标和标题
        // 打卡状态
        // 热力图
      ],
    ),
  );
}
```

**识别关键元素：**
- 输入数据结构（从 `result.data` 获取）
- UI 组件结构（布局、样式）
- 动态数据获取（如通过 PluginManager）
- 尺寸适配逻辑（medium/large 的差异）

### 2. Create Standalone Widget Component

在 `lib/screens/widgets_gallery/common_widgets/widgets/` 创建新组件文件：

```dart
// lib/screens/widgets_gallery/common_widgets/widgets/checkin_item_card.dart

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 签到项目卡片小组件
///
/// 显示签到项目的名称、图标、今日打卡状态和热力图
class CheckinItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;
  final HomeWidgetSize size;

  const CheckinItemCardWidget({
    super.key,
    required this.props,
    required this.size,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory CheckinItemCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CheckinItemCardWidget(
      props: props,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 从 props 获取数据（避免直接访问插件）
    final name = props['title'] as String? ?? '签到项目';
    final group = props['subtitle'] as String?;
    final colorValue = props['color'] as int? ?? 0xFF007AFF;
    final iconCode = props['iconCodePoint'] as int? ?? Icons.checklist.codePoint;
    final isCheckedToday = props['isCheckedToday'] as bool? ?? false;

    final itemColor = Color(colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // UI 构建逻辑（从原 dataRenderer 复制并调整）
          _buildHeader(theme, itemColor, name, group, iconCode, isCheckedToday),
          if (size == HomeWidgetSize.medium || size == HomeWidgetSize.large)
            _buildHeatmap(itemColor),
        ],
      ),
    );
  }

  Widget _buildHeader(...) { /* ... */ }
  Widget _buildHeatmap(...) { /* ... */ }
}
```

**关键点：**
- 使用 `props` 参数而不是直接访问 `PluginManager`
- 实现 `fromProps` 工厂方法
- 根据 `size` 参数调整显示内容
- 纯展示组件，不处理事件

### 3. Register in common_widgets.dart

在公共组件注册表中添加新组件：

```dart
// lib/screens/widgets_gallery/common_widgets/common_widgets.dart

// 1. 添加 import
import 'widgets/checkin_item_card.dart';

// 2. 添加枚举值
enum CommonWidgetId {
  // ... 现有值 ...
  checkinItemCard,
}

// 3. 添加元数据
const Map<CommonWidgetId, CommonWidgetMetadata> metadata = {
  // ... 现有元数据 ...

  CommonWidgetId.checkinItemCard: CommonWidgetMetadata(
    id: CommonWidgetId.checkinItemCard,
    name: '签到项目卡片',
    description: '显示签到项目的图标、名称、今日打卡状态和热力图',
    icon: Icons.checklist,
    defaultSize: HomeWidgetSize.medium,
    supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
  ),
};

// 4. 添加构建器分支
class CommonWidgetBuilder {
  static Widget build(...) {
    switch (widgetId) {
      // ... 现有 case ...

      case CommonWidgetId.checkinItemCard:
        return CheckinItemCardWidget.fromProps(props, size);
    }
  }
}
```

### 4. Add Data Provider in home_widgets.dart

在插件的 `_provideCommonWidgets` 函数中添加新组件的数据提供：

```dart
// lib/plugins/checkin/home_widgets.dart

static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  // data 包含：id, name, group, icon, color（由 dataSelector 提供）

  final name = (data['name'] as String?) ?? '签到项目';
  final group = (data['group'] as String?) ?? '';
  final colorValue = (data['color'] as int?) ?? 0xFF007AFF;
  final iconCode = (data['icon'] as int?) ?? Icons.checklist.codePoint;

  // 获取实时数据（如需要）
  final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
  CheckinItem? item;
  bool isCheckedToday = false;

  if (plugin != null) {
    final itemId = data['id'] as String?;
    if (itemId != null) {
      item = plugin.checkinItems.firstWhere((i) => i.id == itemId, orElse: () => null);
      isCheckedToday = item?.isCheckedToday() ?? false;
    }
  }

  return {
    // 新封装的签到项目卡片
    'checkinItemCard': {
      'id': data['id'],
      'title': name,
      'subtitle': group.isNotEmpty ? group : '签到',
      'iconCodePoint': iconCode,
      'color': colorValue,
      'isCheckedToday': isCheckedToday,
      // 周数据（用于 medium 尺寸）
      'weekData': _generateWeekData(item),
      // 月度数据（用于 large 尺寸）
      'daysData': _generateMonthData(item),
    },

    // ... 其他组件 ...
  };
}

// 辅助方法：生成周数据
static List<Map<String, dynamic>> _generateWeekData(CheckinItem? item) {
  // ... 生成 7 天签到状态 ...
}

// 辅助方法：生成月度数据
static List<Map<String, dynamic>> _generateMonthData(CheckinItem? item) {
  // ... 生成当月签到状态 ...
}
```

### 5. Remove Old dataRenderer

移除不再需要的内置渲染器：

```dart
// lib/plugins/checkin/home_widgets.dart

// 移除 dataRenderer 引用
registry.register(
  HomeWidget(
    id: 'checkin_item_selector',
    // dataRenderer: _renderCheckinItemData,  // ❌ 移除
    navigationHandler: _navigateToCheckinItem,
    dataSelector: _extractCheckinItemData,
    commonWidgetsProvider: _provideCommonWidgets,
    // ...
  ),
);

// 移除旧的渲染方法
// static Widget _renderCheckinItemData(...) { ... }  // ❌ 删除
// static Widget _buildCheckinItemWidget(...) { ... }  // ❌ 删除
// static Widget _buildHeatmapGrid(...) { ... }  // ❌ 删除
```

**保留的内容：**
- `navigationHandler`：点击导航功能仍需要
- `dataSelector`：数据转换逻辑仍需要
- `_provideCommonWidgets`：公共组件数据提供

## Key Concepts

### 1. Props vs Data Access

**错误方式（组件直接访问插件）：**
```dart
final plugin = PluginManager.instance.getPlugin('checkin');
final item = plugin.checkinItems.firstWhere(...);
```

**正确方式（通过 props 传递数据）：**
```dart
// 在 _provideCommonWidgets 中获取数据并传递
final item = plugin.checkinItems.firstWhere(...);
'checkinItemCard': {
  'id': data['id'],
  'isCheckedToday': item.isCheckedToday(),
  'weekData': _generateWeekData(item),
}

// 在组件中使用 props
final isCheckedToday = props['isCheckedToday'] as bool? ?? false;
```

### 2. Size-Based Rendering

根据 `HomeWidgetSize` 调整显示内容：

```dart
@override
Widget build(BuildContext context) {
  // 显示热力图的条件
  final showHeatmap = size == HomeWidgetSize.medium ||
                     size == HomeWidgetSize.large;

  return Column(
    children: [
      _buildHeader(),
      if (showHeatmap) _buildHeatmap(),
    ],
  );
}

Widget _buildHeatmap(Color itemColor) {
  // 根据尺寸选择数据源
  if (size == HomeWidgetSize.medium) {
    return _buildWeekHeatmap(props['weekData'], itemColor);
  } else if (size == HomeWidgetSize.large) {
    return _buildMonthHeatmap(props['daysData'], itemColor);
  }
  return const SizedBox.shrink();
}
```

### 3. Factory Method Pattern

公共组件必须实现 `fromProps` 工厂方法：

```dart
class CheckinItemCardWidget extends StatelessWidget {
  factory CheckinItemCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CheckinItemCardWidget(
      props: props,
      size: size,
    );
  }
}
```

这使得 `CommonWidgetBuilder` 可以统一构建所有组件。

## Complete Example: Checkin Item Card Migration

### Before (内置渲染器)

```dart
// lib/plugins/checkin/home_widgets.dart

registry.register(
  HomeWidget(
    id: 'checkin_item_selector',
    dataRenderer: _renderCheckinItemData,  // 内置渲染器
    navigationHandler: _navigateToCheckinItem,
    dataSelector: _extractCheckinItemData,
    // ...
  ),
);

static Widget _renderCheckinItemData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 PluginManager 获取最新数据
  final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
  final itemId = result.data['id'] as String;
  final item = plugin?.checkinItems.firstWhere((i) => i.id == itemId);

  // 构建 UI
  return Container(
    child: Column([
      _buildHeader(item),
      _buildHeatmap(item),
    ]),
  );
}
```

### After (公共组件)

**1. 新建组件文件：**
```dart
// lib/screens/widgets_gallery/common_widgets/widgets/checkin_item_card.dart

class CheckinItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;
  final HomeWidgetSize size;

  factory CheckinItemCardWidget.fromProps(props, size) => /* ... */;

  @override
  Widget build(BuildContext context) {
    // 从 props 读取数据
    final name = props['title'] as String? ?? '签到项目';
    final isCheckedToday = props['isCheckedToday'] as bool? ?? false;

    return Container(
      child: Column([
        _buildHeader(name, isCheckedToday),
        if (size == HomeWidgetSize.medium || size == HomeWidgetSize.large)
          _buildHeatmap(props['weekData'] ?? props['daysData']),
      ]),
    );
  }
}
```

**2. 注册公共组件：**
```dart
// lib/screens/widgets_gallery/common_widgets/common_widgets.dart

import 'widgets/checkin_item_card.dart';

enum CommonWidgetId {
  checkinItemCard,
  // ...
}

CommonWidgetId.checkinItemCard: CommonWidgetMetadata(
  id: CommonWidgetId.checkinItemCard,
  name: '签到项目卡片',
  description: '显示签到项目的图标、名称、今日打卡状态和热力图',
  icon: Icons.checklist,
  defaultSize: HomeWidgetSize.medium,
  supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
),

case CommonWidgetId.checkinItemCard:
  return CheckinItemCardWidget.fromProps(props, size);
```

**3. 添加数据提供：**
```dart
// lib/plugins/checkin/home_widgets.dart

static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  // 获取实时数据
  final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
  final itemId = data['id'] as String?;
  final item = plugin?.checkinItems.firstWhere((i) => i.id == itemId);

  return {
    'checkinItemCard': {
      'id': data['id'],
      'title': data['name'],
      'isCheckedToday': item?.isCheckedToday() ?? false,
      'weekData': _generateWeekData(item),
      'daysData': _generateMonthData(item),
    },
  };
}
```

**4. 移除旧代码：**
```dart
// lib/plugins/checkin/home_widgets.dart

registry.register(
  HomeWidget(
    id: 'checkin_item_selector',
    // dataRenderer: _renderCheckinItemData,  // ❌ 移除
    navigationHandler: _navigateToCheckinItem,  // ✅ 保留
    dataSelector: _extractCheckinItemData,       // ✅ 保留
    commonWidgetsProvider: _provideCommonWidgets, // ✅ 保留
    // ...
  ),
);

// 删除旧方法
// static Widget _renderCheckinItemData(...) { }  // ❌ 删除
// static Widget _buildCheckinItemWidget(...) { }  // ❌ 删除
// static Widget _buildHeatmapGrid(...) { }        // ❌ 删除
```

## Best Practices

### 1. Props 字段命名

使用语义化、自描述的字段名：

```dart
// ✅ 好的命名
'checkinItemCard': {
  'title': '早起打卡',
  'subtitle': '健康习惯',
  'iconCodePoint': 0xe157,
  'color': 0xFF4CAF50,
  'isCheckedToday': true,
}

// ❌ 避免的命名
'checkinItemCard': {
  't': '早起打卡',
  'sub': '健康习惯',
  'icon': 0xe157,
  'c': 0xFF4CAF50,
  'done': true,
}
```

### 2. 数据类型安全

始终使用类型安全的转换和默认值：

```dart
// ✅ 安全的类型转换
final name = props['title'] as String? ?? '默认名称';
final count = props['count'] as int? ?? 0;
final isChecked = props['isChecked'] as bool? ?? false;

// ❌ 不安全的直接转换
final name = props['title'] as String;  // 可能抛出异常
final count = props['count'] as int;    // 可能抛出异常
```

### 3. 尺寸适配

为不同尺寸提供不同数据：

```dart
return {
  'checkinItemCard': {
    // 通用数据
    'title': name,
    'isCheckedToday': isCheckedToday,

    // medium 尺寸使用
    'weekData': List.generate(7, (i) => {...}),

    // large 尺寸使用
    'daysData': List.generate(daysInMonth, (i) => {...}),
  },
};
```

### 4. 实时数据获取

在 `_provideCommonWidgets` 中获取实时数据，而不是在组件中：

```dart
// ✅ 在数据提供者中获取
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  final item = _getItem(data['id']);
  return {
    'checkinItemCard': {
      'isCheckedToday': item?.isCheckedToday() ?? false,
      'consecutiveDays': item?.getConsecutiveDays() ?? 0,
    },
  };
}

// ❌ 避免在组件中访问插件
class CheckinItemCardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plugin = PluginManager.instance.getPlugin('checkin');  // 不推荐
  }
}
```

## Testing Checklist

完成后验证：

- [ ] `flutter analyze` 无错误
- [ ] 公共组件能正确渲染（medium 和 large 尺寸）
- [ ] 组件显示正确的内容（标题、状态、热力图等）
- [ ] 点击组件能正常导航到详情页
- [ ] 其他插件也能使用这个公共组件
- [ ] 数据更新后组件能正确刷新

## Troubleshooting

### 问题 1: 公共组件显示为空白

**原因**: props 缺少必需字段

**解决**:
```dart
// 检查组件接收到的 props
debugPrint('[CheckinItemCard] props: $props');

// 确保所有必需字段都有默认值
final name = props['title'] as String? ?? '默认标题';
final iconCode = props['iconCodePoint'] as int? ?? Icons.checklist.codePoint;
```

### 问题 2: 热力图显示异常

**原因**: 尺寸判断逻辑错误

**解决**:
```dart
// 确保根据 size 选择正确的数据源
Widget _buildHeatmap(Color itemColor) {
  if (size == HomeWidgetSize.medium && weekData != null) {
    return _buildWeekHeatmap(weekData!, itemColor);
  } else if (size == HomeWidgetSize.large && daysData != null) {
    return _buildMonthHeatmap(daysData!, itemColor);
  }
  return const SizedBox.shrink();
}
```

### 问题 3: 点击组件无反应

**原因**: navigationHandler 或 data 配置问题

**解决**:
```dart
// 确保在 _provideCommonWidgets 中传递了 id
'checkinItemCard': {
  'id': data['id'],  // ⚠️ 必需！用于导航
  // ...
}

// 确保注册时保留了 navigationHandler
registry.register(
  HomeWidget(
    navigationHandler: _navigateToCheckinItem,  // ✅ 必需
    // ...
  ),
);
```

### 问题 4: 数据不更新

**原因**: 公共组件是 StatelessWidget，数据没有更新机制

**解决**:
公共组件的数据更新由 `GenericSelectorWidget` 处理。确保：
1. `_provideCommonWidgets` 中正确获取实时数据
2. 数据选择器配置正确保存了原始 `SelectorResult`

## Migration Checklist

### 准备阶段
- [ ] 确认 `dataRenderer` 的 UI 逻辑
- [ ] 识别需要传递给组件的数据字段
- [ ] 确定组件支持的尺寸

### 实现阶段
- [ ] 创建组件文件（`lib/screens/widgets_gallery/common_widgets/widgets/<name>.dart`）
- [ ] 在 `common_widgets.dart` 中注册（import、枚举、元数据、构建器）
- [ ] 在 `_provideCommonWidgets` 中添加数据提供
- [ ] 移除旧的 `dataRenderer` 和相关方法
- [ ] 移除不再使用的 import

### 测试阶段
- [ ] 测试 medium 尺寸显示
- [ ] 测试 large 尺寸显示
- [ ] 测试点击导航
- [ ] 测试数据更新
- [ ] 运行 `flutter analyze`

## Notes

- 公共组件应该是纯展示组件，不处理业务逻辑
- 所有数据通过 `props` 传递，不在组件内访问插件
- 实时数据在 `_provideCommonWidgets` 中获取
- 保留 `navigationHandler` 用于点击导航
- 保留 `dataSelector` 用于数据转换
- 公共组件可被其他插件复用
