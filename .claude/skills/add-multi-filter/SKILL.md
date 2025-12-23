---
name: add-multi-filter
description: 为Flutter插件视图添加多条件过滤功能（MultiFilterBar），支持标签、关键词、日期、优先级、复选框等多种过滤类型。替代传统的FilterDialog，提供更直观的两层级交互UI。适用场景：(1) 列表视图需要多维度筛选，(2) 数据量较大需要快速过滤，(3) 需要实时显示过滤条件的应用
---

# Add Multi-Filter

为Flutter插件视图添加强大的多条件过滤功能，使用 SuperCupertinoNavigationWrapper 的 MultiFilterBar 组件。

## Usage

```bash
# 基础用法 - 自动检测过滤需求
/add-multi-filter <view-file>

# 指定过滤条件类型
/add-multi-filter <view-file> --filters tags,priority,date,status

# 指定控制器变量名
/add-multi-filter <view-file> --controller _controller
```

**Examples:**

```bash
# 为待办事项插件添加过滤
/add-multi-filter lib/plugins/todo/views/todo_main_view.dart

# 为日记插件添加标签和日期过滤
/add-multi-filter lib/plugins/diary/views/diary_list_view.dart --filters tags,dateRange

# 自定义控制器名称
/add-multi-filter lib/plugins/activity/views/activity_list_view.dart --controller _activityController
```

## Arguments

- `<view-file>`: 目标 Flutter 视图文件路径（包含 SuperCupertinoNavigationWrapper）
- `--filters <types>`: 过滤条件类型列表（逗号分隔）
  - 可选值：`tags`, `keyword`, `priority`, `date`, `dateRange`, `status`, `custom`
  - 默认：自动检测（基于控制器方法）
- `--controller <name>`: 控制器变量名（默认：自动检测）

## Workflow

### 1. Analyze Target File

读取目标文件并识别：

- SuperCupertinoNavigationWrapper 位置
- 控制器变量名（如 `_plugin.taskController`）
- 现有的过滤/排序功能
- 可用的数据（标签列表、优先级枚举等）

### 2. Add Required Imports

在文件顶部添加导入：

```dart
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
```

### 3. Create Filter Items Method

创建 `_buildFilterItems()` 方法，根据检测到的数据结构构建过滤条件：

```dart
/// 构建过滤条件列表
List<FilterItem> _buildFilterItems() {
  // 获取动态数据
  final availableTags = _controller.getAllTags();

  return [
    // 1. 标签多选过滤（如果有标签）
    if (availableTags.isNotEmpty)
      FilterItem(
        id: 'tags',
        title: 'plugin_tags'.tr,
        type: FilterType.tagsMultiple,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildTagsFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            availableTags: availableTags,
          );
        },
        getBadge: FilterBuilders.tagsBadge,
      ),

    // 2. 优先级过滤（如果有优先级枚举）
    FilterItem(
      id: 'priority',
      title: 'plugin_priority'.tr,
      type: FilterType.custom,
      builder: (context, currentValue, onChanged) {
        return FilterBuilders.buildPriorityFilter<PriorityEnum>(
          context: context,
          currentValue: currentValue,
          onChanged: onChanged,
          priorityLabels: {
            PriorityEnum.low: 'plugin_low'.tr,
            PriorityEnum.medium: 'plugin_medium'.tr,
            PriorityEnum.high: 'plugin_high'.tr,
          },
          priorityColors: const {
            PriorityEnum.low: Colors.green,
            PriorityEnum.medium: Colors.orange,
            PriorityEnum.high: Colors.red,
          },
        );
      },
      getBadge: (value) => FilterBuilders.priorityBadge(
        value,
        {
          PriorityEnum.low: 'plugin_low'.tr,
          PriorityEnum.medium: 'plugin_medium'.tr,
          PriorityEnum.high: 'plugin_high'.tr,
        },
      ),
    ),

    // 3. 日期范围过滤
    FilterItem(
      id: 'dateRange',
      title: 'plugin_dateRange'.tr,
      type: FilterType.dateRange,
      builder: (context, currentValue, onChanged) {
        return FilterBuilders.buildDateRangeFilter(
          context: context,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      },
      getBadge: FilterBuilders.dateRangeBadge,
    ),

    // 4. 状态复选框过滤
    FilterItem(
      id: 'status',
      title: 'plugin_status'.tr,
      type: FilterType.checkbox,
      builder: (context, currentValue, onChanged) {
        return FilterBuilders.buildCheckboxFilter(
          context: context,
          currentValue: currentValue,
          onChanged: onChanged,
          options: {
            'option1': 'plugin_option1'.tr,
            'option2': 'plugin_option2'.tr,
          },
        );
      },
      getBadge: FilterBuilders.checkboxBadge,
      initialValue: const {
        'option1': true,
        'option2': true,
      },
    ),
  ];
}
```

### 4. Create Filter Handler Method

创建 `_applyMultiFilters()` 方法处理过滤变更：

```dart
/// 应用多条件过滤
void _applyMultiFilters(Map<String, dynamic> filters) {
  // 构建过滤参数
  final filterParams = <String, dynamic>{};

  // 标签过滤
  if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
    filterParams['tags'] = filters['tags'];
  }

  // 优先级过滤
  if (filters['priority'] != null) {
    filterParams['priority'] = filters['priority'];
  }

  // 日期范围过滤
  if (filters['dateRange'] != null) {
    final range = filters['dateRange'] as DateTimeRange;
    filterParams['startDate'] = range.start;
    filterParams['endDate'] = range.end;
  }

  // 状态过滤
  if (filters['status'] != null) {
    final status = filters['status'] as Map<String, bool>;
    filterParams['option1'] = status['option1'] ?? true;
    filterParams['option2'] = status['option2'] ?? true;
  }

  // 应用过滤
  if (filterParams.isEmpty) {
    _controller.clearFilter();
  } else {
    _controller.applyFilter(filterParams);
  }

  setState(() {});
}
```

### 5. Update SuperCupertinoNavigationWrapper

在 SuperCupertinoNavigationWrapper 中添加多条件过滤配置：

```dart
SuperCupertinoNavigationWrapper(
  // ... 现有配置 ...

  // 启用多条件过滤
  enableMultiFilter: true,
  multiFilterItems: _buildFilterItems(),
  multiFilterBarHeight: 50,
  onMultiFilterChanged: _applyMultiFilters,

  // ... 其他配置 ...
)
```

### 6. Remove Old Filter Dialog (Optional)

如果存在旧的 FilterDialog：

1. 移除 FilterDialog 导入
2. 删除 `_showFilterDialog()` 方法
3. 移除 actions 中的 filter 按钮：

```dart
// 移除这个按钮
IconButton(
  icon: const Icon(Icons.filter_alt),
  onPressed: _showFilterDialog,  // ❌ 删除
),
```

### 7. Add Internationalization Strings

在插件的国际化文件中添加必要的字符串：

**中文 (zh):**

```dart
'plugin_tags': '标签',
'plugin_priority': '优先级',
'plugin_low': '低',
'plugin_medium': '中',
'plugin_high': '高',
'plugin_dateRange': '日期范围',
'plugin_status': '状态',
'plugin_option1': '选项1',
'plugin_option2': '选项2',
```

**英文 (en):**

```dart
'plugin_tags': 'Tags',
'plugin_priority': 'Priority',
'plugin_low': 'Low',
'plugin_medium': 'Medium',
'plugin_high': 'High',
'plugin_dateRange': 'Date Range',
'plugin_status': 'Status',
'plugin_option1': 'Option 1',
'plugin_option2': 'Option 2',
```

## Filter Types Guide

### Available Filter Types

| 类型 | FilterType | 构建器方法 | Badge方法 | 返回值 |
|------|-----------|-----------|----------|--------|
| 标签多选 | `tagsMultiple` | `buildTagsFilter` | `tagsBadge` | `List<String>` |
| 标签单选 | `tagsSingle` | `buildTagFilter` | `tagBadge` | `String?` |
| 关键词 | `input` | `buildKeywordFilter` | `keywordBadge` | `String` |
| 优先级 | `custom` | `buildPriorityFilter<T>` | `priorityBadge` | `T?` |
| 日期范围 | `dateRange` | `buildDateRangeFilter` | `dateRangeBadge` | `DateTimeRange?` |
| 单日期 | `date` | `buildDateFilter` | `dateBadge` | `DateTime?` |
| 复选框 | `checkbox` | `buildCheckboxFilter` | `checkboxBadge` | `Map<String, bool>` |
| 自定义 | `custom` | 自定义 widget | 自定义函数 | 任意类型 |

### Detection Patterns

#### Tags Filter
查找方法：
- `getAllTags()`, `getTags()`
- 返回类型：`List<String>` 或 `Set<String>`

#### Priority Filter
查找枚举：
- 名称包含 `Priority`
- 值：`low`, `medium`, `high`

#### Date Filter
查找方法：
- `applyFilter()` 接受 `startDate`, `endDate` 参数
- `DateTime` 类型的字段

#### Status Filter
查找方法：
- `applyFilter()` 接受 `showCompleted`, `showIncomplete` 等布尔参数

## Controller Requirements

控制器需要实现以下方法：

```dart
class YourController extends ChangeNotifier {
  // 必需：应用过滤
  void applyFilter(Map<String, dynamic> filter) {
    // 实现过滤逻辑
  }

  // 必需：清除过滤
  void clearFilter() {
    // 清除所有过滤条件
  }

  // 可选：获取标签列表
  List<String> getAllTags() {
    return _items.expand((item) => item.tags).toSet().toList();
  }

  // 可选：获取过滤后的数据
  List<YourModel> get filteredItems {
    return _applyFilterLogic(_items);
  }
}
```

## Example: Complete Implementation

以下是一个完整的示例（基于 todo 插件）：

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  late TodoPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = TodoPlugin.instance;
  }

  /// 构建过滤条件列表
  List<FilterItem> _buildFilterItems() {
    final availableTags = _plugin.taskController.getAllTags();

    return [
      // 标签多选
      if (availableTags.isNotEmpty)
        FilterItem(
          id: 'tags',
          title: 'todo_tags'.tr,
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            return FilterBuilders.buildTagsFilter(
              context: context,
              currentValue: currentValue,
              onChanged: onChanged,
              availableTags: availableTags,
            );
          },
          getBadge: FilterBuilders.tagsBadge,
        ),

      // 优先级
      FilterItem(
        id: 'priority',
        title: 'todo_priority'.tr,
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildPriorityFilter<TaskPriority>(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            priorityLabels: {
              TaskPriority.low: 'todo_low'.tr,
              TaskPriority.medium: 'todo_medium'.tr,
              TaskPriority.high: 'todo_high'.tr,
            },
            priorityColors: const {
              TaskPriority.low: Colors.green,
              TaskPriority.medium: Colors.orange,
              TaskPriority.high: Colors.red,
            },
          );
        },
        getBadge: (value) => FilterBuilders.priorityBadge(
          value,
          {
            TaskPriority.low: 'todo_low'.tr,
            TaskPriority.medium: 'todo_medium'.tr,
            TaskPriority.high: 'todo_high'.tr,
          },
        ),
      ),

      // 日期范围
      FilterItem(
        id: 'dateRange',
        title: 'todo_dateRange'.tr,
        type: FilterType.dateRange,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildDateRangeFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: FilterBuilders.dateRangeBadge,
      ),

      // 完成状态
      FilterItem(
        id: 'status',
        title: 'todo_status'.tr,
        type: FilterType.checkbox,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildCheckboxFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            options: {
              'showCompleted': 'todo_showCompleted'.tr,
              'showIncomplete': 'todo_showIncomplete'.tr,
            },
          );
        },
        getBadge: FilterBuilders.checkboxBadge,
        initialValue: const {
          'showCompleted': true,
          'showIncomplete': true,
        },
      ),
    ];
  }

  /// 应用多条件过滤
  void _applyMultiFilters(Map<String, dynamic> filters) {
    final filterParams = <String, dynamic>{};

    if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
      filterParams['tags'] = filters['tags'];
    }

    if (filters['priority'] != null) {
      filterParams['priority'] = filters['priority'];
    }

    if (filters['dateRange'] != null) {
      final range = filters['dateRange'] as DateTimeRange;
      filterParams['startDate'] = range.start;
      filterParams['endDate'] = range.end;
    }

    if (filters['status'] != null) {
      final status = filters['status'] as Map<String, bool>;
      filterParams['showCompleted'] = status['showCompleted'] ?? true;
      filterParams['showIncomplete'] = status['showIncomplete'] ?? true;
    }

    if (filterParams.isEmpty) {
      _plugin.taskController.clearFilter();
    } else {
      _plugin.taskController.applyFilter(filterParams);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SuperCupertinoNavigationWrapper(
      title: Text('todo_tasks'.tr),
      largeTitle: 'todo_tasks'.tr,

      // 启用多条件过滤
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _applyMultiFilters,

      body: AnimatedBuilder(
        animation: _plugin.taskController,
        builder: (context, _) {
          return TaskListWidget(
            tasks: _plugin.taskController.filteredTasks,
          );
        },
      ),
    );
  }
}
```

## Best Practices

### 1. Filter Count

建议不超过 4-5 个过滤条件，过多会影响用户体验。

### 2. Dynamic Data

对于动态数据（如标签列表），使用条件渲染：

```dart
if (availableTags.isNotEmpty)
  FilterItem(
    id: 'tags',
    // ...
  ),
```

### 3. Initial Values

为常用过滤条件设置合理的初始值：

```dart
FilterItem(
  id: 'status',
  // ...
  initialValue: const {
    'showCompleted': true,
    'showIncomplete': true,
  },
),
```

### 4. Performance

在 `onMultiFilterChanged` 中使用防抖处理（如果过滤操作很耗时）：

```dart
Timer? _filterDebounce;

void _applyMultiFilters(Map<String, dynamic> filters) {
  _filterDebounce?.cancel();
  _filterDebounce = Timer(const Duration(milliseconds: 300), () {
    // 执行过滤逻辑
  });
}
```

### 5. Internationalization

所有用户可见的文本都应该使用国际化：

```dart
title: 'plugin_filterName'.tr,
```

## Testing Checklist

完成后验证：

- [ ] `flutter analyze` 无错误
- [ ] 所有过滤条件都能正常工作
- [ ] Badge 正确显示过滤状态
- [ ] 清空按钮能清除所有过滤
- [ ] 搜索模式下过滤栏正确隐藏
- [ ] 组合多个过滤条件测试
- [ ] 国际化字符串完整

## Troubleshooting

### 过滤不生效

检查控制器的 `applyFilter()` 方法是否正确实现。

### Badge 不显示

确保 `getBadge` 函数返回非空字符串。

### 标签列表为空

检查 `getAllTags()` 方法是否正确返回数据。

### 日期选择器异常

确保导入了 Material 组件：

```dart
import 'package:flutter/material.dart';
```

## Notes

- 使用中文注释与现有代码库保持一致
- 优先使用 FilterBuilders 提供的构建器方法
- 自定义过滤器时注意类型安全
- 使用 `flutter analyze` 验证代码
- 参考 `USAGE_EXAMPLE.md` 获取更多示例
