# MultiFilterBar 快速参考

## 🚀 快速开始（3步）

### 1. 添加导入

```dart
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
```

### 2. 创建两个方法

```dart
/// 构建过滤条件
List<FilterItem> _buildFilterItems() {
  return [
    // 添加你的过滤条件...
  ];
}

/// 应用过滤
void _applyMultiFilters(Map<String, dynamic> filters) {
  // 处理过滤逻辑...
}
```

### 3. 启用过滤

```dart
SuperCupertinoNavigationWrapper(
  enableMultiFilter: true,
  multiFilterItems: _buildFilterItems(),
  onMultiFilterChanged: _applyMultiFilters,
  // ...
)
```

---

## 📋 常用过滤条件模板

### 标签多选

```dart
FilterItem(
  id: 'tags',
  title: 'xxx_tags'.tr,
  type: FilterType.tagsMultiple,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildTagsFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      availableTags: ['标签1', '标签2', '标签3'],
    );
  },
  getBadge: FilterBuilders.tagsBadge,
),
```

### 优先级选择

```dart
FilterItem(
  id: 'priority',
  title: 'xxx_priority'.tr,
  type: FilterType.custom,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildPriorityFilter<YourPriorityEnum>(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      priorityLabels: {
        YourPriorityEnum.low: 'xxx_low'.tr,
        YourPriorityEnum.medium: 'xxx_medium'.tr,
        YourPriorityEnum.high: 'xxx_high'.tr,
      },
      priorityColors: const {
        YourPriorityEnum.low: Colors.green,
        YourPriorityEnum.medium: Colors.orange,
        YourPriorityEnum.high: Colors.red,
      },
    );
  },
  getBadge: (value) => FilterBuilders.priorityBadge(value, {...}),
),
```

### 日期范围

```dart
FilterItem(
  id: 'dateRange',
  title: 'xxx_dateRange'.tr,
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

### 复选框

```dart
FilterItem(
  id: 'status',
  title: 'xxx_status'.tr,
  type: FilterType.checkbox,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildCheckboxFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      options: {
        'option1': 'xxx_option1'.tr,
        'option2': 'xxx_option2'.tr,
      },
    );
  },
  getBadge: FilterBuilders.checkboxBadge,
  initialValue: const {
    'option1': true,
    'option2': true,
  },
),
```

### 关键词输入

```dart
FilterItem(
  id: 'keyword',
  title: 'xxx_keyword'.tr,
  type: FilterType.input,
  builder: (context, currentValue, onChanged) {
    return FilterBuilders.buildKeywordFilter(
      context: context,
      currentValue: currentValue,
      onChanged: onChanged,
      placeholder: 'xxx_searchHint'.tr,
    );
  },
  getBadge: FilterBuilders.keywordBadge,
),
```

---

## 🔧 处理过滤逻辑

### 标准模板

```dart
void _applyMultiFilters(Map<String, dynamic> filters) {
  final filterParams = <String, dynamic>{};

  // 1. 处理标签
  if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
    filterParams['tags'] = filters['tags'];
  }

  // 2. 处理优先级
  if (filters['priority'] != null) {
    filterParams['priority'] = filters['priority'];
  }

  // 3. 处理日期范围
  if (filters['dateRange'] != null) {
    final range = filters['dateRange'] as DateTimeRange;
    filterParams['startDate'] = range.start;
    filterParams['endDate'] = range.end;
  }

  // 4. 处理复选框
  if (filters['status'] != null) {
    final status = filters['status'] as Map<String, bool>;
    filterParams['showOption1'] = status['option1'] ?? true;
    filterParams['showOption2'] = status['option2'] ?? true;
  }

  // 5. 应用过滤
  if (filterParams.isEmpty) {
    _controller.clearFilter();
  } else {
    _controller.applyFilter(filterParams);
  }

  setState(() {});
}
```

---

## 🌍 国际化字符串

### 中文 (zh)

```dart
'xxx_tags': '标签',
'xxx_priority': '优先级',
'xxx_low': '低',
'xxx_medium': '中',
'xxx_high': '高',
'xxx_dateRange': '日期范围',
'xxx_status': '状态',
'xxx_option1': '选项1',
'xxx_option2': '选项2',
'xxx_keyword': '关键词',
'xxx_searchHint': '搜索...',
```

### 英文 (en)

```dart
'xxx_tags': 'Tags',
'xxx_priority': 'Priority',
'xxx_low': 'Low',
'xxx_medium': 'Medium',
'xxx_high': 'High',
'xxx_dateRange': 'Date Range',
'xxx_status': 'Status',
'xxx_option1': 'Option 1',
'xxx_option2': 'Option 2',
'xxx_keyword': 'Keyword',
'xxx_searchHint': 'Search...',
```

**注意**：需要在核心模块添加以下字符串（如果还没有）：

```dart
// lib/core/l10n/core_translations_zh.dart
'core_searchPlaceholder': '搜索...',
'core_clearAll': '清空所有',
'core_selectDate': '选择日期',
'core_selectDateRange': '选择日期范围',
'core_searchScope': '搜索范围',
```

---

## ✅ 检查清单

完成后验证：

- [ ] 导入了 `super_cupertino_navigation_wrapper/index.dart`
- [ ] 创建了 `_buildFilterItems()` 方法
- [ ] 创建了 `_applyMultiFilters()` 方法
- [ ] 在 SuperCupertinoNavigationWrapper 中启用了过滤
- [ ] 添加了所有必要的国际化字符串
- [ ] 运行 `flutter analyze` 无错误
- [ ] 测试了所有过滤条件
- [ ] 测试了清空功能
- [ ] 测试了搜索模式（过滤栏应隐藏）

---

## 🐛 常见问题

### Q: 过滤不生效？

检查控制器是否正确实现了 `applyFilter()` 方法。

### Q: Badge 不显示？

确保 `getBadge` 函数返回非空字符串，或者值确实有过滤内容。

### Q: 标签列表为空？

检查数据源方法（如 `getAllTags()`）是否正确返回数据。

### Q: 类型错误？

注意泛型类型，特别是 `buildPriorityFilter<YourEnum>`。

---

## 📚 更多信息

- 完整文档：`SKILL.md`
- 使用示例：`lib/widgets/super_cupertino_navigation_wrapper/USAGE_EXAMPLE.md`
- Todo 插件示例：`lib/plugins/todo/views/todo_bottombar_view.dart`
