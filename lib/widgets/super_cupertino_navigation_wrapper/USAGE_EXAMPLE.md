# SuperCupertinoNavigationWrapper - MultiFilterBar 使用指南

## 概述

MultiFilterBar 是一个强大的多条件过滤组件，支持多种过滤类型和层级化的 UI 交互。

## 基本特性

- ✅ 支持多种过滤条件类型（标签、关键词、日期、复选框等）
- ✅ 两层级 UI：过滤条件列表 → 详细内容
- ✅ 自动显示过滤条件的 badge
- ✅ 一键清空所有过滤条件
- ✅ 内置常用过滤条件构建器

## 快速开始

### 1. 导入必要的包

```dart
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
```

### 2. 基本用法

```dart
SuperCupertinoNavigationWrapper(
  title: Text('任务列表'),
  largeTitle: '任务列表',
  enableMultiFilter: true,
  multiFilterItems: [
    FilterItem(
      id: 'tags',
      title: '标签',
      type: FilterType.tagsMultiple,
      builder: (context, currentValue, onChanged) {
        return FilterBuilders.buildTagsFilter(
          context: context,
          currentValue: currentValue,
          onChanged: onChanged,
          availableTags: ['工作', '生活', '学习'],
        );
      },
      getBadge: FilterBuilders.tagsBadge,
    ),
    FilterItem(
      id: 'keyword',
      title: '关键词',
      type: FilterType.input,
      builder: (context, currentValue, onChanged) {
        return FilterBuilders.buildKeywordFilter(
          context: context,
          currentValue: currentValue,
          onChanged: onChanged,
          placeholder: '搜索标题或描述',
        );
      },
      getBadge: FilterBuilders.keywordBadge,
    ),
  ],
  onMultiFilterChanged: (filters) {
    // filters: {'tags': ['工作', '学习'], 'keyword': '测试'}
    print('过滤条件变更: $filters');
    _applyFilters(filters);
  },
  body: YourContentWidget(),
)
```

## Todo 插件集成示例

### 完整示例代码

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';

class TodoTaskListView extends StatefulWidget {
  const TodoTaskListView({super.key});

  @override
  State<TodoTaskListView> createState() => _TodoTaskListViewState();
}

class _TodoTaskListViewState extends State<TodoTaskListView> {
  late TodoPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = TodoPlugin.instance;
  }

  /// 构建过滤条件列表
  List<FilterItem> _buildFilterItems() {
    // 获取所有可用标签
    final availableTags = _plugin.taskController.getAllTags();

    return [
      // 1. 标签多选过滤
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

      // 2. 关键词搜索过滤
      FilterItem(
        id: 'keyword',
        title: 'todo_searchIn'.tr,
        type: FilterType.input,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildKeywordFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            placeholder: 'todo_searchTasksHint'.tr,
          );
        },
        getBadge: FilterBuilders.keywordBadge,
      ),

      // 3. 优先级过滤
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
            priorityColors: {
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

      // 4. 日期范围过滤
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

      // 5. 完成状态过滤
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
        initialValue: {
          'showCompleted': true,
          'showIncomplete': true,
        },
      ),
    ];
  }

  /// 应用过滤条件
  void _applyFilters(Map<String, dynamic> filters) {
    // 构建过滤参数
    final filterParams = <String, dynamic>{};

    // 关键词过滤
    if (filters['keyword'] != null && filters['keyword'].toString().isNotEmpty) {
      filterParams['keyword'] = filters['keyword'];
    }

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

    // 完成状态过滤
    if (filters['status'] != null) {
      final status = filters['status'] as Map<String, bool>;
      filterParams['showCompleted'] = status['showCompleted'] ?? true;
      filterParams['showIncomplete'] = status['showIncomplete'] ?? true;
    }

    // 应用过滤
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
      title: Text('todo_todoTasks'.tr),
      largeTitle: 'todo_todoTasks'.tr,
      automaticallyImplyLeading: false,

      // 启用多条件过滤
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _applyFilters,

      // 其他操作按钮
      actions: [
        IconButton(
          icon: Icon(
            _plugin.taskController.isGridView
                ? Icons.view_list
                : Icons.dashboard,
          ),
          onPressed: _plugin.taskController.toggleViewMode,
        ),
        PopupMenuButton<SortBy>(
          icon: const Icon(Icons.sort),
          onSelected: _plugin.taskController.setSortBy,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: SortBy.dueDate,
              child: Text('todo_sortByDueDate'.tr),
            ),
            PopupMenuItem(
              value: SortBy.priority,
              child: Text('todo_sortByPriority'.tr),
            ),
            PopupMenuItem(
              value: SortBy.custom,
              child: Text('todo_customSort'.tr),
            ),
          ],
        ),
      ],

      // 任务列表内容
      body: AnimatedBuilder(
        animation: _plugin.taskController,
        builder: (context, child) {
          return TaskListView(
            tasks: _plugin.taskController.filteredTasks,
            isGridView: _plugin.taskController.isGridView,
          );
        },
      ),
    );
  }
}
```

## 过滤条件类型详解

### 1. 标签多选 (tagsMultiple)

```dart
FilterItem(
  id: 'tags',
  title: '标签',
  type: FilterType.tagsMultiple,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildTagsFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      availableTags: ['工作', '生活', '学习', '紧急'],
    );
  },
  getBadge: FilterBuilders.tagsBadge, // 显示选中的标签数量
),
```

**返回值**: `List<String>` - 选中的标签列表
**Badge 示例**: `"2"` (选中了 2 个标签)

### 2. 标签单选 (tagsSingle)

```dart
FilterItem(
  id: 'tag',
  title: '分类',
  type: FilterType.tagsSingle,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildTagFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      availableTags: ['工作', '生活', '学习'],
    );
  },
  getBadge: FilterBuilders.tagBadge, // 显示选中的标签名称
),
```

**返回值**: `String?` - 选中的标签名称
**Badge 示例**: `"工作"`

### 3. 关键词搜索 (input)

```dart
FilterItem(
  id: 'keyword',
  title: '关键词',
  type: FilterType.input,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildKeywordFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      placeholder: '搜索标题和描述',
    );
  },
  getBadge: FilterBuilders.keywordBadge, // 显示关键词（最多10个字符）
),
```

**返回值**: `String` - 输入的关键词
**Badge 示例**: `"项目文档"` 或 `"这是一个很长..."`

### 4. 优先级选择 (custom)

```dart
FilterItem(
  id: 'priority',
  title: '优先级',
  type: FilterType.custom,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildPriorityFilter<TaskPriority>(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      priorityLabels: {
        TaskPriority.low: '低',
        TaskPriority.medium: '中',
        TaskPriority.high: '高',
      },
      priorityColors: {
        TaskPriority.low: Colors.green,
        TaskPriority.medium: Colors.orange,
        TaskPriority.high: Colors.red,
      },
    );
  },
  getBadge: (value) => FilterBuilders.priorityBadge(
    value,
    {
      TaskPriority.low: '低',
      TaskPriority.medium: '中',
      TaskPriority.high: '高',
    },
  ),
),
```

**返回值**: `T?` (泛型优先级枚举) - 选中的优先级
**Badge 示例**: `"高"`

### 5. 日期范围选择 (dateRange)

```dart
FilterItem(
  id: 'dateRange',
  title: '日期范围',
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
```

**返回值**: `DateTimeRange?` - 选中的日期范围
**Badge 示例**: `"2025-01-15~2025-01-20"`

### 6. 单日期选择 (date)

```dart
FilterItem(
  id: 'date',
  title: '截止日期',
  type: FilterType.date,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildDateFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
    );
  },
  getBadge: FilterBuilders.dateBadge,
),
```

**返回值**: `DateTime?` - 选中的日期
**Badge 示例**: `"2025-01-20"`

### 7. 复选框 (checkbox)

```dart
FilterItem(
  id: 'status',
  title: '状态',
  type: FilterType.checkbox,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildCheckboxFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      options: {
        'showCompleted': '显示已完成',
        'showIncomplete': '显示未完成',
        'showOverdue': '显示已逾期',
      },
    );
  },
  getBadge: FilterBuilders.checkboxBadge, // 显示选中的选项数量
  initialValue: {
    'showCompleted': true,
    'showIncomplete': true,
    'showOverdue': false,
  },
),
```

**返回值**: `Map<String, bool>` - 各选项的选中状态
**Badge 示例**: `"2"` (选中了 2 个选项)

## 自定义过滤条件

### 自定义 Builder

```dart
FilterItem(
  id: 'custom',
  title: '自定义过滤',
  type: FilterType.custom,
  builder: (context, currentValue, onChanged) {
    // 完全自定义的 UI
    return Column(
      children: [
        Slider(
          value: (currentValue as double?) ?? 0,
          onChanged: onChanged,
          min: 0,
          max: 100,
        ),
        Text('当前值: ${currentValue ?? 0}'),
      ],
    );
  },
  getBadge: (value) {
    if (value != null && value > 0) {
      return value.toStringAsFixed(0);
    }
    return null;
  },
),
```

### 自定义 Badge 生成器

```dart
FilterItem(
  id: 'tags',
  title: '标签',
  type: FilterType.tagsMultiple,
  builder: ...,
  getBadge: (value) {
    if (value is List<String>) {
      if (value.isEmpty) return null;
      if (value.length == 1) return value.first;
      return '${value.first} +${value.length - 1}';
    }
    return null;
  },
),
```

**Badge 示例**:
- 无选中: 无 badge
- 选中 1 个: `"工作"`
- 选中多个: `"工作 +2"`

## 最佳实践

### 1. 过滤条件数量

建议不超过 5-6 个过滤条件，过多会导致用户体验下降。

### 2. 初始值设置

为常用过滤条件设置合理的初始值：

```dart
FilterItem(
  id: 'status',
  title: '状态',
  type: FilterType.checkbox,
  builder: ...,
  initialValue: {
    'showCompleted': true,
    'showIncomplete': true,
  },
),
```

### 3. 过滤性能优化

在 `onMultiFilterChanged` 中使用防抖处理：

```dart
Timer? _filterDebounce;

void _applyFilters(Map<String, dynamic> filters) {
  _filterDebounce?.cancel();
  _filterDebounce = Timer(const Duration(milliseconds: 300), () {
    // 执行过滤逻辑
    _plugin.taskController.applyFilter(filters);
    setState(() {});
  });
}
```

### 4. 过滤条件持久化

保存用户的过滤偏好：

```dart
// 保存
await _plugin.storageManager.saveSettings('filter_preferences', filters);

// 恢复
final savedFilters = await _plugin.storageManager.getSetting('filter_preferences');
if (savedFilters != null) {
  _multiFilterState.initializeFromMap(savedFilters);
}
```

## 与旧版 API 兼容

新的 MultiFilterBar 完全向后兼容，旧的 `enableFilterBar` 和 `filterBarChild` 依然有效：

```dart
SuperCupertinoNavigationWrapper(
  // 旧 API - 仍然有效
  enableFilterBar: true,
  filterBarChild: MyOldFilterWidget(),

  // 新 API - enableMultiFilter 为 true 时会优先使用
  enableMultiFilter: false,
  multiFilterItems: [],
)
```

**注意**: 当 `enableMultiFilter` 为 `true` 时，旧的 `filterBarChild` 不会显示。

## 常见问题

### Q1: 如何在过滤条件中获取插件数据？

直接在 `_buildFilterItems()` 方法中访问插件实例：

```dart
List<FilterItem> _buildFilterItems() {
  final availableTags = _plugin.taskController.getAllTags(); // ✅

  return [
    FilterItem(
      id: 'tags',
      title: '标签',
      builder: (context, currentValue, onChanged) {
        return FilterBuilders.buildTagsFilter(
          availableTags: availableTags, // 使用动态数据
          ...
        );
      },
    ),
  ];
}
```

### Q2: 如何动态更新过滤条件列表？

使用 `setState` 重新构建过滤条件：

```dart
void _refreshFilterItems() {
  setState(() {
    // _buildFilterItems() 会被重新调用
  });
}
```

### Q3: 如何清空所有过滤条件？

MultiFilterBar 已内置清空按钮，也可以通过代码清空：

```dart
// 通过访问 MultiFilterState
final multiFilterState = MultiFilterState();
multiFilterState.clearAll();
```

### Q4: 过滤条件太多时如何优化 UI？

建议将不常用的过滤条件分组或使用二级菜单：

```dart
// 方案1: 分组
FilterItem(
  id: 'advanced',
  title: '高级选项',
  type: FilterType.custom,
  builder: (context, currentValue, onChanged) {
    return ExpansionTile(
      title: Text('更多筛选'),
      children: [
        // 多个子过滤条件
      ],
    );
  },
),

// 方案2: 保留常用的 3-4 个，其他移到对话框
FilterItem(
  id: 'more',
  title: '更多',
  type: FilterType.custom,
  builder: (context, currentValue, onChanged) {
    return TextButton(
      onPressed: () => _showAdvancedFilterDialog(),
      child: Text('高级筛选'),
    );
  },
),
```

## 迁移指南

### 从 FilterDialog 迁移到 MultiFilterBar

#### 旧代码 (使用 FilterDialog)

```dart
IconButton(
  icon: const Icon(Icons.filter_alt),
  onPressed: () async {
    await showDialog(
      context: context,
      builder: (context) => FilterDialog(
        availableTags: _plugin.taskController.getAllTags(),
        onFilter: (filter) {
          _plugin.taskController.applyFilter(filter);
          Navigator.pop(context);
        },
      ),
    );
  },
),
```

#### 新代码 (使用 MultiFilterBar)

```dart
SuperCupertinoNavigationWrapper(
  enableMultiFilter: true,
  multiFilterItems: _buildFilterItems(),
  onMultiFilterChanged: (filters) {
    _plugin.taskController.applyFilter(_convertFilters(filters));
  },
  body: YourContentWidget(),
)
```

**优势**:
- ✅ 无需打开对话框，直接在页面上操作
- ✅ 更直观的两层级导航
- ✅ 自动显示过滤条件 badge
- ✅ 一键清空所有过滤
- ✅ 更好的用户体验

## 总结

MultiFilterBar 提供了一个功能强大且易于使用的多条件过滤解决方案。通过内置的 `FilterBuilders` 工具类，可以快速构建常用的过滤条件 UI，同时也支持完全自定义的过滤组件。

主要特点：
- 🎯 简单易用的 API
- 🎨 美观的两层级 UI
- 🔧 高度可定制
- ⚡ 性能优化
- 🔄 向后兼容

开始使用 MultiFilterBar，提升您的应用过滤体验！
