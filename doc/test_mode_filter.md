# Mode 参数过滤功能修复

## 问题描述

调用 `Memento.plugins.activity.getActivities({date: "2025-11-19", mode: "compact"})` 时，mode 参数没有生效，返回的仍然是完整的活动记录数据。

## 问题根源

1. **JSON 字符串无法被识别**: `_jsGetActivities` 方法返回的是 `jsonEncode(...)` 即 JSON 字符串，而 `FieldFilterService.filterData()` 只能处理 List/Map 类型，对字符串直接返回不做任何过滤。

2. **generateSummary 默认值错误**: `FilterOptions.fromParams()` 中使用 `params['generateSummary'] == true` 判断，导致未传递该参数时默认为 false（应该是 true），即使过滤成功也不会返回正确的 `{sum: {...}, recs: [...]}` 格式。

## 修复内容

### 1. 添加 JSON 字符串解析支持

**文件**: `lib/core/data_filter/field_filter_service.dart`

```dart
// 添加导入
import 'dart:convert';

// 修改 filterData 方法
static dynamic filterData(dynamic data, FilterOptions options) {
  if (!options.needsFiltering) {
    return data;
  }

  // 如果是 JSON 字符串，先尝试解析
  dynamic parsedData = data;
  if (data is String) {
    try {
      parsedData = _parseJson(data);
    } catch (e) {
      return data; // 解析失败，返回原始字符串
    }
  }

  // 后续的类型判断和过滤逻辑...
}

// 新增方法
static dynamic _parseJson(String jsonStr) {
  return jsonDecode(jsonStr);
}
```

### 2. 修复 generateSummary 默认值

**文件**: `lib/core/data_filter/filter_options.dart`

```dart
return FilterOptions(
  mode: mode,
  fields: fields,
  excludeFields: excludeFields,
  textLengthLimits: textLengthLimits,
  generateSummary: params['generateSummary'] ?? true,  // 修复：使用 ?? 而不是 ==
  abbreviateFieldNames: params['abbreviateFieldNames'] ?? false,
);
```

## 测试验证

### 测试 1: Summary 模式

```javascript
const summary = await Memento.plugins.activity.getActivities({
  date: "2025-11-19",
  mode: "summary"
});
console.log(summary);
```

**预期输出**:
```json
{
  "sum": {
    "total": 2,
    "dur": 305,
    "avgDur": 152.5
  }
}
```

### 测试 2: Compact 模式

```javascript
const compact = await Memento.plugins.activity.getActivities({
  date: "2025-11-19",
  mode: "compact"
});
console.log(compact);
```

**预期输出**:
```json
{
  "sum": {
    "total": 2,
    "dur": 305
  },
  "recs": [
    {
      "id": "3df8e1ae-ae70-4b12-a066-3507e547d04e",
      "startTime": "2025-11-19T00:00:00.000",
      "endTime": "2025-11-19T02:20:00.000",
      "title": "未命名活动",
      "tags": ["睡觉"],
      "mood": null,
      "color": null
      // 注意：没有 description 字段
    },
    // ...
  ]
}
```

### 测试 3: Fields 白名单

```javascript
const custom = await Memento.plugins.activity.getActivities({
  date: "2025-11-19",
  fields: ["id", "title", "startTime", "endTime"]
});
console.log(custom);
```

**预期输出**:
```json
{
  "sum": { "total": 2 },
  "recs": [
    {
      "id": "3df8e1ae-ae70-4b12-a066-3507e547d04e",
      "title": "未命名活动",
      "startTime": "2025-11-19T00:00:00.000",
      "endTime": "2025-11-19T02:20:00.000"
      // 只包含指定的字段
    },
    // ...
  ]
}
```

### 测试 4: 向后兼容（不传 mode 参数）

```javascript
const full = await Memento.plugins.activity.getActivities({
  date: "2025-11-19"
});
console.log(full);
```

**预期输出**: 完整的活动记录数组（与之前行为一致）

## 技术细节

### 数据流程

```
1. JavaScript 调用
   ↓
2. JS Bridge 接收参数 {date: "2025-11-19", mode: "compact"}
   ↓
3. 提取过滤参数: originalParams = {date: "2025-11-19", mode: "compact"}
   cleanedParams = {date: "2025-11-19"}
   ↓
4. 调用 _jsGetActivities(cleanedParams)
   ↓
5. 返回 Future<String> (JSON 字符串)
   ↓
6. Future resolve: awaitedResult = "[{...}, {...}]"
   ↓
7. FieldFilterService.filterFromParams(awaitedResult, originalParams)
   ├─ FilterOptions.fromParams({mode: "compact"})
   │  └─ mode = FilterMode.compact, generateSummary = true
   ├─ filterData("[{...}, {...}]", options)
   │  ├─ 检测到是字符串
   │  ├─ _parseJson("[{...}, {...}]") → List<Map>
   │  └─ _filterList(parsedList, options)
   │     ├─ 过滤每条记录（移除 description 等字段）
   │     └─ 返回 {sum: {...}, recs: [...]}
   └─ 返回过滤后的数据
```

### Compact 模式默认移除的字段

```dart
static const List<String> _defaultExcludeFieldsInCompact = [
  'description',
  'content',
  'notes',
  'metadata',
  'detail',
  'remark',
];
```

## 影响范围

✅ **所有插件的所有 jsAPI 方法自动支持字段过滤**（无需修改插件代码）

✅ **向后兼容**（不传过滤参数时行为与之前完全一致）

✅ **零侵入**（插件开发者无需关心过滤逻辑）

## 编译验证

```bash
flutter analyze lib/core/data_filter/
```

**结果**: ✅ No issues found!
