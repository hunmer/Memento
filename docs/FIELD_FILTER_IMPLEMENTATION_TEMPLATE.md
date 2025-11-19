# 字段过滤功能实现模板

> **创建时间**: 2025-11-19
> **适用范围**: 所有需要添加 fields 参数支持的插件

---

## 📋 实现步骤

### 1. 修改 `prompt_replacements.dart`

在每个插件的 `services/prompt_replacements.dart` 中修改数据查询方法。

#### 修改前（仅支持 mode）

```dart
Future<String> getData(Map<String, dynamic> params) async {
  try {
    // 1. 解析参数
    final mode = AnalysisModeUtils.parseFromParams(params);

    // 2. 获取数据
    final allData = await _getAllData(params);

    // 3. 根据模式转换数据
    final result = _convertByMode(allData, mode);

    // 4. 返回 JSON 字符串
    return FieldUtils.toJsonString(result);
  } catch (e) {
    // 错误处理
  }
}
```

#### 修改后（支持 mode + fields）

```dart
Future<String> getData(Map<String, dynamic> params) async {
  try {
    // 1. 解析参数
    final mode = AnalysisModeUtils.parseFromParams(params);
    final customFields = params['fields'] as List<dynamic>?;  // 🆕 添加这行

    // 2. 获取数据
    final allData = await _getAllData(params);

    // 3. 根据 customFields 或 mode 转换数据
    Map<String, dynamic> result;

    // 🆕 添加以下判断逻辑
    if (customFields != null && customFields.isNotEmpty) {
      // 优先使用 fields 参数（白名单模式）
      final fieldList = customFields.map((e) => e.toString()).toList();
      final filteredRecords = FieldUtils.simplifyRecords(
        allData,
        keepFields: fieldList,
      );
      result = FieldUtils.buildCompactResponse(
        {'total': filteredRecords.length},
        filteredRecords,
      );
    } else {
      // 使用 mode 参数
      result = _convertByMode(allData, mode);
    }

    // 4. 返回 JSON 字符串
    return FieldUtils.toJsonString(result);
  } catch (e) {
    // 错误处理
  }
}
```

### 2. 更新文档注释

```dart
/// 获取数据并格式化为文本
///
/// 参数:
/// - [其他参数...]
/// - mode: 数据模式 (summary/compact/full, 默认summary)
/// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)  // 🆕 添加
///
/// 返回格式:
/// - summary: 仅统计数据 { sum: {...} }
/// - compact: 简化记录 { sum: {...}, recs: [...] }
/// - full: 完整数据 (包含所有字段)
/// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)  // 🆕 添加
Future<String> getData(Map<String, dynamic> params) async {
  // ...
}
```

---

## 🔧 核心代码片段

### 关键导入

确保文件顶部有以下导入：

```dart
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';
```

### 字段过滤逻辑（复制粘贴）

```dart
// 解析 fields 参数
final customFields = params['fields'] as List<dynamic>?;

// 判断逻辑
Map<String, dynamic> result;

if (customFields != null && customFields.isNotEmpty) {
  // 优先使用 fields 参数（白名单模式）
  final fieldList = customFields.map((e) => e.toString()).toList();
  final filteredRecords = FieldUtils.simplifyRecords(
    allData,  // 替换为实际的数据变量名
    keepFields: fieldList,
  );
  result = FieldUtils.buildCompactResponse(
    {'total': filteredRecords.length},
    filteredRecords,
  );
} else {
  // 使用 mode 参数
  result = _convertByMode(allData, mode);  // 保持原有逻辑
}
```

---

## 📝 逐插件实现清单

### 已完成
- ✅ **activity** - 阶段2完成

### 待更新（共18个）

| 插件 | 文件路径 | 优先级 | 状态 |
|------|---------|-------|------|
| **bill** | `lib/plugins/bill/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **calendar** | `lib/plugins/calendar/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |
| **calendar_album** | `lib/plugins/calendar_album/services/prompt_replacements.dart` | 低 | ⚠️ 待更新 |
| **chat** | `lib/plugins/chat/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **checkin** | `lib/plugins/checkin/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **contact** | `lib/plugins/contact/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |
| **database** | `lib/plugins/database/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **day** | `lib/plugins/day/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |
| **diary** | `lib/plugins/diary/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **goods** | `lib/plugins/goods/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |
| **habits** | `lib/plugins/habits/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |
| **nodes** | `lib/plugins/nodes/services/prompt_replacements.dart` | 低 | ⚠️ 待更新 |
| **notes** | `lib/plugins/notes/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **scripts_center** | `lib/plugins/scripts_center/services/prompt_replacements.dart` | 低 | ⚠️ 待更新 |
| **store** | `lib/plugins/store/services/prompt_replacements.dart` | 低 | ⚠️ 待更新 |
| **timer** | `lib/plugins/timer/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |
| **todo** | `lib/plugins/todo/services/prompt_replacements.dart` | 高 | ⚠️ 待更新 |
| **tracker** | `lib/plugins/tracker/services/prompt_replacements.dart` | 中 | ⚠️ 待更新 |

**优先级说明**：
- **高**：常用插件，Token 消耗大（如 chat, diary, todo, bill, checkin, database, notes）
- **中**：中等使用频率（如 day, contact, tracker, timer, goods, habits）
- **低**：较少使用或数据量小（如 calendar_album, nodes, scripts_center, store）

---

## 🧪 测试验证

### 单元测试（可选）

```dart
void main() {
  group('字段过滤测试', () {
    test('使用 fields 参数应返回指定字段', () async {
      final params = {
        'fields': ['id', 'title'],
      };

      final result = await promptReplacements.getData(params);
      final data = jsonDecode(result);

      expect(data['recs'][0].keys, containsAll(['id', 'title']));
      expect(data['recs'][0].keys, isNot(contains('description')));
    });

    test('fields 优先级高于 mode', () async {
      final params = {
        'mode': 'full',
        'fields': ['id'],
      };

      final result = await promptReplacements.getData(params);
      final data = jsonDecode(result);

      expect(data['recs'][0].keys, equals(['id']));
    });
  });
}
```

### 手动测试（必须）

在 Agent Chat 中测试以下 JavaScript 代码：

```javascript
// 测试1: mode 参数（原有功能）
const summary = await Memento.plugins.<plugin_id>.getData({
  mode: "summary"
});
console.log("Summary:", summary);

// 测试2: fields 参数（新功能）
const customFields = await Memento.plugins.<plugin_id>.getData({
  fields: ["id", "title"]
});
console.log("Custom Fields:", customFields);

// 测试3: fields 优先级测试
const priority = await Memento.plugins.<plugin_id>.getData({
  mode: "full",
  fields: ["id"]
});
console.log("Priority:", priority);
```

---

## ⚠️ 常见问题

### Q1: 如果插件的数据结构不是数组怎么办？

**A**: 根据实际数据结构调整：

```dart
// 如果数据是 Map
if (customFields != null && customFields.isNotEmpty) {
  final fieldList = customFields.map((e) => e.toString()).toList();
  final filteredData = <String, dynamic>{};
  for (final field in fieldList) {
    if (originalData.containsKey(field)) {
      filteredData[field] = originalData[field];
    }
  }
  result = filteredData;
}
```

### Q2: 是否需要修改 `analysis_methods.dart`？

**A**: 如果插件有 `analysis_methods.dart` 文件，需要在参数定义中添加 `fields` 参数：

```dart
final parameters = [
  // ... 其他参数 ...
  PluginAnalysisParameter(
    name: 'fields',
    type: 'List<String>',
    required: false,
    description: '自定义返回字段列表（优先级高于 mode）',
    example: '["id", "title", "createdAt"]',
  ),
];
```

### Q3: 如何确保字段名有效？

**A**: `FieldUtils.simplifyRecords()` 会自动跳过不存在的字段，无需额外验证。

### Q4: 是否需要向后兼容？

**A**: 是的！`fields` 参数是可选的，如果不传入，保持原有的 `mode` 参数逻辑，完全向后兼容。

---

## 📊 Token 消耗对比（参考数据）

以 Activity 插件的 50 条记录为例：

| 模式 | 参数 | Token 消耗 | 节省比例 |
|------|------|-----------|---------|
| **full** | `mode: "full"` | ~8000 tokens | 0% |
| **compact** | `mode: "compact"` | ~2000 tokens | 75% ↓ |
| **summary** | `mode: "summary"` | ~800 tokens | 90% ↓ |
| **fields** | `fields: ["id", "title", "dur"]` | ~1500 tokens | 81% ↓ |

---

## 🎯 批量更新建议

### 方案 1: 逐个更新（推荐）

1. 按优先级从高到低更新
2. 每更新一个插件，运行 `flutter analyze`
3. 每更新一个插件，手动测试

**优点**: 稳妥，易于排查问题
**缺点**: 耗时较长

### 方案 2: 批量更新

1. 使用脚本或 IDE 批量替换
2. 一次性修改所有插件
3. 最后统一测试

**优点**: 快速
**缺点**: 风险较高，错误排查困难

### 推荐工作流

```bash
# 1. 创建分支
git checkout -b feature/add-fields-parameter

# 2. 更新高优先级插件（6个）
# - chat, diary, todo, bill, checkin, database, notes

# 3. 测试并提交
flutter analyze
git add .
git commit -m "feat: add fields parameter support for high-priority plugins"

# 4. 更新中优先级插件（7个）
# - day, contact, tracker, timer, goods, habits, notes

# 5. 测试并提交
flutter analyze
git add .
git commit -m "feat: add fields parameter support for medium-priority plugins"

# 6. 更新低优先级插件（5个）
# - calendar_album, nodes, scripts_center, store

# 7. 最终测试
flutter analyze
flutter test  # 如果有测试

# 8. 合并到主分支
git checkout master
git merge feature/add-fields-parameter
```

---

## 📚 相关文档

- [字段精简功能重构计划](FIELD_FILTER_REFACTOR_PLAN.md)
- [Prompt 数据格式规范](PROMPT_DATA_SPEC.md)
- [FieldUtils API 文档](../lib/core/analysis/field_utils.dart)

---

**维护者**: hunmer
**最后更新**: 2025-11-19
