---
name: migrate-home-widget-common-widgets
description: 将现有插件HomeWidget迁移到公共小组件系统，支持用户选择插件数据后从多种公共组件样式中选择渲染方式。核心特性：(1)添加commonWidgetsProvider函数返回可用公共组件及props，(2)保持原有dataSelector和数据选择功能，(3)支持公共组件实时预览和选择
---

# Migrate HomeWidget to Common Widgets

将现有插件的选择器类型 HomeWidget 迁移到公共小组件系统，让用户在选择数据后可以从多种公共小组件样式中选择。

## Usage

```bash
# 为现有插件添加公共组件支持
/migrate-home-widget-common-widgets <plugin-path> --widget-id <widget-id>

# 完整参数
/migrate-home-widget-common-widgets lib/plugins/chat \
  --widget-id chat_channel_selector
```

**Examples:**

```bash
# 迁移聊天插件的频道选择器
/migrate-home-widget-common-widgets lib/plugins/chat \
  --widget-id chat_channel_selector

# 迁移待办插件的任务选择器
/migrate-home-widget-common-widgets lib/plugins/todo \
  --widget-id todo_task_selector

# 迁移日记插件的条目选择器
/migrate-home-widget-common-widgets lib/plugins/diary \
  --widget-id diary_entry_selector
```

## Arguments

- `<plugin-path>`: 插件根目录路径（包含 `home_widgets.dart`）
- `--widget-id <id>`: 要迁移的小组件 ID（必须是使用 selectorId 的选择器类型小组件）

## Workflow

### 1. Analyze Current Widget

读取并分析现有的 home_widget 实现：

- 检查是否是选择器类型小组件（有 `selectorId`）
- 确认 `dataSelector` 函数返回的数据结构
- 确认 `dataRenderer` 函数的渲染逻辑
- 识别可用于公共组件的数据字段

```dart
// 示例：读取 chat 插件的 home_widgets.dart
// lib/plugins/chat/home_widgets.dart

// 现有实现：
registry.register(
  HomeWidget(
    id: 'chat_channel_selector',
    selectorId: 'chat.channel',
    dataRenderer: _renderChannelData,
    navigationHandler: _navigateToChannel,
    dataSelector: _extractChannelData,
    // ...
  ),
);
```

### 2. Identify Data Fields

从 `dataSelector` 返回的数据中识别可用于公共组件的字段：

```dart
// 示例：chat 插件的 dataSelector 返回数据
static Map<String, dynamic> _extractChannelData(List<dynamic> dataArray) {
  return {
    'id': ...,
    'title': ...,           // 可用于：title
    'messageCount': ...,    // 可用于：进度、数值
    'lastMessage': ...,     // 可用于：subtitle、pendingTasks
    'lastMessageTime': ..., // 可用于：subtitle
  };
}
```

### 3. Add commonWidgetsProvider Function

在 `home_widgets.dart` 中添加 `commonWidgetsProvider` 函数：

```dart
/// 公共小组件提供者函数
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  // data 包含从 dataSelector 返回的数据
  final messageCount = (data['messageCount'] as int?) ?? 0;
  final title = (data['title'] as String?) ?? '频道';
  final lastMessage = (data['lastMessage'] as String?) ?? '';

  return {
    // 圆形进度卡片
    'circularProgressCard': {
      'title': title,
      'subtitle': '$messageCount 条消息',
      'percentage': (messageCount / 100 * 100).clamp(0, 100).toDouble(),
      'progress': (messageCount / 100).clamp(0.0, 1.0),
    },

    // 活动进度卡片
    'activityProgressCard': {
      'title': title,
      'subtitle': '今日消息',
      'value': messageCount.toDouble(),
      'unit': '条',
      'activities': messageCount,
      'totalProgress': 10,
      'completedProgress': messageCount % 10,
    },

    // 任务进度卡片
    'taskProgressCard': {
      'title': title,
      'subtitle': '最近消息',
      'completedTasks': messageCount % 20,
      'totalTasks': 20,
      'pendingTasks': lastMessage.isNotEmpty ? [lastMessage] : [],
    },
  };
}
```

### 4. Register commonWidgetsProvider

在小组件注册中添加 `commonWidgetsProvider` 字段：

```dart
registry.register(
  HomeWidget(
    id: 'chat_channel_selector',
    // ... 其他字段保持不变 ...

    // 新增：公共小组件提供者
    commonWidgetsProvider: _provideCommonWidgets,

    builder: (context, config) {
      return GenericSelectorWidget(
        widgetDefinition: registry.getWidget('chat_channel_selector')!,
        config: config,
      );
    },
  ),
);
```

### 5. Add Optional Helper Method

如果需要，可以添加辅助方法来简化数据处理：

```dart
/// 获取待办任务列表
static List<String> _getPendingTasks(Map<String, dynamic> data) {
  final lastMessage = data['lastMessage'] as String?;
  if (lastMessage != null && lastMessage.isNotEmpty) {
    return [lastMessage];
  }
  return [];
}
```

## Common Widgets Reference

### 可用的公共小组件

| 小组件 ID | 名称 | 所需 Props |
|-----------|------|-----------|
| `circularProgressCard` | 圆形进度卡片 | `title`, `subtitle`, `percentage`, `progress` |
| `activityProgressCard` | 活动进度卡片 | `title`, `subtitle`, `value`, `unit`, `activities`, `totalProgress`, `completedProgress` |
| `halfGaugeCard` | 半圆仪表盘 | `title`, `totalBudget`, `remaining`, `currency` |
| `taskProgressCard` | 任务进度卡片 | `title`, `subtitle`, `completedTasks`, `totalTasks`, `pendingTasks` |

### Props 说明

#### CircularProgressCard
```dart
{
  'title': String,           // 标题
  'subtitle': String,        // 副标题
  'percentage': double,      // 百分比 (0-100)
  'progress': double,         // 进度值 (0.0-1.0)
}
```

#### ActivityProgressCard
```dart
{
  'title': String,                  // 标题
  'subtitle': String,               // 副标题
  'value': double,                  // 主数值
  'unit': String,                   // 单位
  'activities': int,                // 活动数量
  'totalProgress': int,             // 总进度点数
  'completedProgress': int,         // 已完成进度点数
}
```

#### HalfGaugeCard
```dart
{
  'title': String,          // 标题
  'totalBudget': double,    // 总预算
  'remaining': double,      // 剩余金额
  'currency': String,       // 货币符号
}
```

#### TaskProgressCard
```dart
{
  'title': String,                  // 标题
  'subtitle': String,               // 副标题
  'completedTasks': int,            // 已完成任务数
  'totalTasks': int,                // 总任务数
  'pendingTasks': List<String>,      // 待办任务列表
}
```

## Complete Example: Chat Plugin Migration

### Before (原始实现)

```dart
// lib/plugins/chat/home_widgets.dart

registry.register(
  HomeWidget(
    id: 'chat_channel_selector',
    pluginId: 'chat',
    name: 'chat_channelQuickAccess'.tr,
    description: 'chat_channelQuickAccessDesc'.tr,
    icon: Icons.chat,
    color: Colors.indigoAccent,
    defaultSize: HomeWidgetSize.large,
    supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
    category: 'home_categoryCommunication'.tr,

    selectorId: 'chat.channel',
    dataRenderer: _renderChannelData,
    navigationHandler: _navigateToChannel,
    dataSelector: _extractChannelData,

    builder: (context, config) {
      return GenericSelectorWidget(
        widgetDefinition: registry.getWidget('chat_channel_selector')!,
        config: config,
      );
    },
  ),
);

static Map<String, dynamic> _extractChannelData(List<dynamic> dataArray) {
  // ... 数据提取逻辑 ...
}
```

### After (添加公共组件支持)

```dart
// lib/plugins/chat/home_widgets.dart

registry.register(
  HomeWidget(
    id: 'chat_channel_selector',
    // ... 其他字段保持不变 ...

    // 新增：公共小组件提供者
    commonWidgetsProvider: _provideCommonWidgets,

    builder: (context, config) {
      return GenericSelectorWidget(
        widgetDefinition: registry.getWidget('chat_channel_selector')!,
        config: config,
      );
    },
  ),
);

/// 公共小组件提供者函数
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  final messageCount = (data['messageCount'] as int?) ?? 0;
  final title = (data['title'] as String?) ?? '频道';

  return {
    'circularProgressCard': {
      'title': title,
      'subtitle': '$messageCount 条消息',
      'percentage': (messageCount / 100 * 100).clamp(0, 100).toDouble(),
      'progress': (messageCount / 100).clamp(0.0, 1.0),
    },
    'activityProgressCard': {
      'title': title,
      'subtitle': '今日消息',
      'value': messageCount.toDouble(),
      'unit': '条',
      'activities': 1,
      'totalProgress': 10,
      'completedProgress': messageCount % 10,
    },
    'taskProgressCard': {
      'title': title,
      'subtitle': '最近消息',
      'completedTasks': messageCount % 20,
      'totalTasks': 20,
      'pendingTasks': _getPendingTasks(data),
    },
  };
}

/// 辅助方法：获取待办任务列表
static List<String> _getPendingTasks(Map<String, dynamic> data) {
  final lastMessage = data['lastMessage'] as String?;
  if (lastMessage != null && lastMessage.isNotEmpty) {
    return [lastMessage];
  }
  return [];
}
```

## More Examples

### Bill Plugin Example

```dart
/// 公共小组件提供者函数 - 账单插件
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  final totalSpent = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;
  final budget = (data['budget'] as num?)?.toDouble() ?? 10000.0;
  final remaining = budget - totalSpent;
  final title = (data['accountTitle'] as String?) ?? '账户';
  final period = (data['periodLabel'] as String?) ?? '本月';

  return {
    'halfGaugeCard': {
      'title': period,
      'totalBudget': budget,
      'remaining': remaining,
      'currency': '¥',
    },
    'circularProgressCard': {
      'title': title,
      'subtitle': '$period 预算使用',
      'percentage': (totalSpent / budget * 100).clamp(0, 100),
      'progress': (totalSpent / budget).clamp(0.0, 1.0),
    },
  };
}
```

### Todo Plugin Example

```dart
/// 公共小组件提供者函数 - 待办插件
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  final completedCount = (data['completedCount'] as int?) ?? 0;
  final totalCount = (data['totalCount'] as int?) ?? 0;
  final title = (data['listTitle'] as String?) ?? '任务列表';
  final pendingTasks = (data['pendingTasks'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ??
      [];

  return {
    'taskProgressCard': {
      'title': title,
      'subtitle': '$completedCount/$totalCount 已完成',
      'completedTasks': completedCount,
      'totalTasks': totalCount,
      'pendingTasks': pendingTasks.take(5).toList(),
    },
    'activityProgressCard': {
      'title': title,
      'subtitle': '完成任务数',
      'value': completedCount.toDouble(),
      'unit': '个',
      'activities': completedCount,
      'totalProgress': totalCount,
      'completedProgress': completedCount,
    },
  };
}
```

### Habits Plugin Example

```dart
/// 公共小组件提供者函数 - 习惯插件
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  final completedDays = (data['completedDays'] as int?) ?? 0;
  final targetDays = (data['targetDays'] as int?) ?? 30;
  final title = (data['habitTitle'] as String?) ?? '习惯';
  final percentage = (completedDays / targetDays * 100).clamp(0, 100);

  return {
    'circularProgressCard': {
      'title': title,
      'subtitle': '本月进度',
      'percentage': percentage.toDouble(),
      'progress': (completedDays / targetDays).clamp(0.0, 1.0),
    },
    'activityProgressCard': {
      'title': title,
      'subtitle': '累计打卡',
      'value': completedDays.toDouble(),
      'unit': '天',
      'activities': completedDays,
      'totalProgress': targetDays,
      'completedProgress': completedDays,
    },
  };
}
```

## Key Concepts

### 1. commonWidgetsProvider 函数

```dart
typedef CommonWidgetsProvider = Map<String, Map<String, dynamic>> Function(
  Map<String, dynamic> data,
);
```

该函数接收处理后的数据（从 `dataSelector` 返回），返回一个映射：

- **键**: 公共小组件 ID（如 `'circularProgressCard'`）
- **值**: 该公共小组件所需的 props 配置

### 2. Props 数据转换

将插件数据转换为公共组件所需的格式：

```dart
// 插件数据
{
  'messageCount': 45,
  'title': '工作频道',
}

// 转换为 circularProgressCard 的 props
{
  'title': '工作频道',
  'subtitle': '45 条消息',
  'percentage': 45.0,  // 45/100*100
  'progress': 0.45,    // 45/100
}
```

### 3. 数据安全处理

始终使用 `as int?` 和默认值来避免类型错误：

```dart
final messageCount = (data['messageCount'] as int?) ?? 0;
final title = (data['title'] as String?) ?? '默认标题';
```

## Best Practices

### 1. 选择合适的公共组件

根据数据类型选择：

| 数据类型 | 推荐组件 |
|---------|---------|
| 百分比/进度 | `circularProgressCard` |
| 数值 + 单位 | `activityProgressCard` |
| 预算/余额 | `halfGaugeCard` |
| 任务列表 | `taskProgressCard` |

### 2. Props 命名一致性

使用中文注释说明每个字段：

```dart
static Map<String, Map<String, dynamic>> _provideCommonWidgets(
  Map<String, dynamic> data,
) {
  return {
    'circularProgressCard': {
      'title': data['name'] as String? ?? '默认',        // 标题
      'subtitle': '共 ${data['count']} 项',                // 副标题
      'percentage': (data['percent'] as num?)?.toDouble() ?? 0,
      'progress': (data['ratio'] as num?)?.toDouble() ?? 0,
    },
  };
}
```

### 3. 计算边界处理

使用 `clamp` 避免超出范围的值：

```dart
'percentage': (value / total * 100).clamp(0, 100),
'progress': (value / total).clamp(0.0, 1.0),
```

## Testing Checklist

完成后验证：

- [ ] `flutter analyze` 无错误
- [ ] 点击小组件显示"适配公共组件"标签
- [ ] 点击后打开 CommonWidgetSelectorDialog
- [ ] 能正常选择数据
- [ ] 选择数据后显示公共组件预览
- [ ] 选择公共组件后添加到主页
- [ ] 主页上正确渲染公共组件
- [ ] 点击组件能正常导航

## Troubleshooting

### 问题 1: 公共组件预览为空

**原因**: `commonWidgetsProvider` 返回的 props 不完整

**解决**:
```dart
// ✅ 确保所有必需字段都存在
'circularProgressCard': {
  'title': data['title'] as String? ?? '默认',
  'subtitle': data['subtitle'] as String? ?? '',
  'percentage': (data['value'] as num? ?? 0).toDouble(),
  'progress': (data['ratio'] as num? ?? 0).toDouble(),
}
```

### 问题 2: 类型转换错误

**原因**: 数据类型与公共组件期望的不匹配

**解决**:
```dart
// ✅ 使用安全的类型转换
final value = (data['count'] as num?)?.toDouble() ?? 0.0;
final title = (data['name'] as String?) ?? '';
```

### 问题 3: 百分比超出范围

**原因**: 计算结果超过 0-100 或 0.0-1.0

**解决**:
```dart
// ✅ 使用 clamp 限制范围
'percentage': (value / total * 100).clamp(0, 100),
'progress': (value / total).clamp(0.0, 1.0),
```

### 问题 4: 列表数据为空导致错误

**原因**: `pendingTasks` 为 null 时组件崩溃

**解决**:
```dart
// ✅ 提供默认空列表
'pendingTasks': (data['tasks'] as List<dynamic>?)
    ?.map((e) => e.toString())
    .toList() ?? [],
```

## Migration Checklist

### 准备阶段
- [ ] 确认小组件使用 `selectorId`（选择器类型）
- [ ] 确认 `dataSelector` 函数存在并正常工作
- [ ] 识别可用于公共组件的数据字段

### 实现阶段
- [ ] 添加 `commonWidgetsProvider` 函数
- [ ] 在 `HomeWidget` 注册中添加 `commonWidgetsProvider` 字段
- [ ] 添加必要的辅助方法（如 `_getPendingTasks`）
- [ ] 运行 `flutter analyze` 验证无错误

### 测试阶段
- [ ] 测试数据选择流程
- [ ] 测试公共组件预览
- [ ] 测试组件选择和添加
- [ ] 测试主页渲染
- [ ] 测试点击导航

## Notes

- 使用中文注释与现有代码库保持一致
- `commonWidgetsProvider` 是可选字段，不影响现有功能
- 旧的 `dataRenderer` 和 `navigationHandler` 仍然有效
- 如果用户不选择公共组件，会使用默认渲染方式
- 参考 `lib/plugins/chat/home_widgets.dart` 获取完整示例
- 可用的公共组件定义在 `lib/screens/widgets_gallery/common_widgets/common_widgets.dart`
