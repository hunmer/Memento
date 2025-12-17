# Memento Prompt 数据格式规范 v2.0

> **版本**: 2.0
> **发布日期**: 2025-01-15
> **状态**: 正式版
> **维护者**: Memento Team

---

## 📋 目录

1. [概述](#概述)
2. [设计目标](#设计目标)
3. [三种数据模式](#三种数据模式)
4. [字段命名规范](#字段命名规范)
5. [数据结构模板](#数据结构模板)
6. [插件实现指南](#插件实现指南)
7. [最佳实践](#最佳实践)
8. [迁移指南](#迁移指南)
9. [FAQ](#faq)

---

## 概述

本规范定义了 Memento 项目中所有插件的 **Prompt 数据返回格式**，旨在：
- 统一不同插件的数据格式
- 优化 AI Prompt 的 token 消耗
- 提升 AI 对数据的理解能力
- 降低代码维护成本

### 适用范围

本规范适用于以下场景：
- 插件的 `prompt_replacements.dart` 方法实现
- 通过 `OpenAIPlugin.registerPromptReplacementMethod()` 注册的所有 Prompt 方法
- 需要为 AI 分析提供数据的任何场景

### 核心文件

- **枚举定义**: `lib/core/analysis/analysis_mode.dart`
- **工具类**: `lib/core/analysis/field_utils.dart`
- **本文档**: `docs/PROMPT_DATA_SPEC.md`

---

## 设计目标

### 1. Token 优化

通过分级数据模式，大幅减少 AI Prompt 的 token 消耗：

| 场景 | 优化前 | 优化后 (summary) | 节省率 |
|------|--------|-----------------|--------|
| 7天活动记录（50条） | ~8000 tokens | ~800 tokens | **90%** |
| 7篇日记（每篇2000字） | ~14000 tokens | ~1400 tokens | **90%** |
| 20条笔记（每条500字） | ~10000 tokens | ~1000 tokens | **90%** |
| 100条账单记录 | ~4000 tokens | ~1200 tokens | **70%** |
| **总计** | **~36000 tokens** | **~4400 tokens** | **87.8%** |

### 2. 格式统一

所有插件遵循相同的数据结构模板：
```json
{
  "sum": { /* 统计摘要 */ },
  "recs": [ /* 记录列表 */ ]
}
```

### 3. 可扩展性

支持插件根据自身特点扩展数据结构，同时保持核心字段的一致性。

---

## 三种数据模式

### AnalysisMode.summary（摘要模式）

**用途**: 仅返回统计数据，无详细记录列表。

**适用场景**:
- 快速概览数据趋势
- 生成统计报告
- Token 预算有限时

**返回格式**:
```json
{
  "sum": {
    "total": 100,      // 总数
    "cnt": 50,         // 计数
    "dur": 3600,       // 时长（分钟）
    "avg": 72          // 平均值
  }
}
```

**Token 消耗**: 最低（约为 full 模式的 10%）

---

### AnalysisMode.compact（紧凑模式）

**用途**: 返回简化字段的记录列表。

**适用场景**:
- 需要查看具体记录但不需要完整内容
- 平衡数据详细度和 token 消耗
- 列表展示和快速筛选

**返回格式**:
```json
{
  "sum": {
    "total": 10
  },
  "recs": [
    {
      "id": "uuid-1",
      "title": "记录标题",
      "ts": "2025-01-15T09:00:00",
      "tags": ["标签1", "标签2"],
      "cat": "类别",
      "status": "active"
    }
  ]
}
```

**省略字段**:
- `description`/`content` (冗长的描述内容)
- `metadata` (元数据)
- 其他非核心字段

**Token 消耗**: 中等（约为 full 模式的 30-50%）

---

### AnalysisMode.full（完整模式）

**用途**: 返回所有字段的完整数据。

**适用场景**:
- 需要访问所有数据字段
- 详细分析和数据导出
- 向后兼容旧版实现

**返回格式**: 与 jsAPI 返回的原始数据一致

**Token 消耗**: 最高（100%）

---

## 字段命名规范

### 核心原则

1. **常用字段不缩写**: `id`, `title`, `tags`, `status`, `priority`
2. **冗长字段使用缩写**: `description` → `desc`, `count` → `cnt`
3. **时间字段保持简洁**: `startTime` → `start`, `timestamp` → `ts`
4. **统计字段统一前缀**: 所有统计数据放在 `sum` 对象下

### 标准字段缩写表

| 完整字段名 | 缩写 | 说明 |
|-----------|------|------|
| **统计类** | | |
| `total` | `total` | 总数（不缩写，常用） |
| `count` | `cnt` | 计数 |
| `duration` | `dur` | 时长（分钟） |
| `average` | `avg` | 平均值 |
| `income` | `inc` | 收入 |
| `expense` | `exp` | 支出 |
| `balance` | `bal` | 余额 |
| `minimum` | `min` | 最小值 |
| `maximum` | `max` | 最大值 |
| **记录类** | | |
| `records` | `recs` | 记录列表 |
| `description` | `desc` | 描述 |
| `timestamp` | `ts` | 时间戳 |
| `category` | `cat` | 类别 |
| `quantity` | `qty` | 数量 |
| **时间类** | | |
| `startTime` | `start` | 开始时间 |
| `endTime` | `end` | 结束时间 |
| `createdAt` | `created` | 创建时间 |
| `updatedAt` | `updated` | 更新时间 |
| `dueDate` | `due` | 截止日期 |

### 时间格式

所有时间字段统一使用 **ISO 8601** 格式：
```
2025-01-15T09:30:00.000Z
```

---

## 数据结构模板

### 模板 1: 活动记录类

适用于 Activity, Diary, Checkin 等时间轴类插件。

#### Summary 模式
```json
{
  "sum": {
    "total": 50,           // 总记录数
    "dur": 3600,           // 总时长（分钟）
    "avg": 72,             // 平均时长
    "topTags": [           // 高频标签
      {"tag": "学习", "cnt": 20},
      {"tag": "运动", "cnt": 15}
    ]
  }
}
```

#### Compact 模式
```json
{
  "sum": { "total": 50, "dur": 3600 },
  "recs": [
    {
      "id": "uuid-1",
      "title": "阅读《深度学习》",
      "start": "2025-01-15T09:00:00",
      "end": "2025-01-15T10:30:00",
      "tags": ["学习", "AI"],
      "dur": 90              // 该记录时长
    }
  ]
}
```

---

### 模板 2: 财务账单类

适用于 Bill, Tracker 等数值统计类插件。

#### Summary 模式
```json
{
  "sum": {
    "total": 100,          // 总记录数
    "inc": 5000.00,        // 总收入
    "exp": 3200.00,        // 总支出
    "net": 1800.00,        // 净值
    "topCat": [            // 高频类别
      {"cat": "餐饮", "amount": -1200.00},
      {"cat": "工资", "amount": 5000.00}
    ]
  }
}
```

#### Compact 模式
```json
{
  "sum": { "total": 100, "net": 1800.00 },
  "recs": [
    {
      "id": "uuid-1",
      "title": "午餐",
      "date": "2025-01-15",
      "amount": -35.50,
      "cat": "餐饮",
      "account": "现金"
    }
  ]
}
```

---

### 模板 3: 任务目标类

适用于 Todo, Tracker, Habits 等目标管理类插件。

#### Summary 模式
```json
{
  "sum": {
    "total": 20,           // 总任务数
    "todo": 8,             // 待办
    "inProgress": 5,       // 进行中
    "done": 7,             // 已完成
    "overdue": 2           // 逾期
  }
}
```

#### Compact 模式
```json
{
  "sum": { "total": 20, "overdue": 2 },
  "recs": [
    {
      "id": "uuid-1",
      "title": "完成季度报告",
      "status": "inProgress",
      "priority": "high",
      "due": "2025-01-20T18:00:00",
      "tags": ["工作"]
    }
  ]
}
```

---

### 模板 4: 内容管理类

适用于 Notes, Diary, Nodes 等文本内容类插件。

#### Summary 模式
```json
{
  "sum": {
    "total": 20,           // 总笔记数
    "folders": 5,          // 文件夹数
    "totalWords": 15000,   // 总字数
    "topTags": [
      {"tag": "技术", "cnt": 8}
    ]
  }
}
```

#### Compact 模式
```json
{
  "sum": { "total": 20 },
  "recs": [
    {
      "id": "uuid-1",
      "title": "Flutter 开发笔记",
      "folder": "技术",
      "created": "2025-01-15T09:00:00",
      "tags": ["Flutter", "移动开发"],
      "desc": "关于 Flutter 的学习笔记，包含..."  // 截断至100字
    }
  ]
}
```

**重要**: `content` 字段在 compact 模式下应该：
- 完全省略，或
- 截断至 100 字以内并标记为 `desc`

---

## 插件实现指南

### 1. 创建 Prompt Replacements 类

在插件的 `services/` 目录下创建 `prompt_replacements.dart`:

```dart
import 'dart:convert';
import '../../core/analysis/analysis_mode.dart';
import '../../core/analysis/field_utils.dart';
import '../xxx_plugin.dart';

class XxxPromptReplacements {
  final XxxPlugin _plugin;

  XxxPromptReplacements(this._plugin);

  /// 获取 XXX 数据的 Prompt 方法
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选)
  /// - endDate: 结束日期 (可选)
  /// - mode: 数据模式 (summary/compact/full)
  Future<String> getXxxData(Map<String, dynamic> params) async {
    // 1. 解析参数
    final mode = AnalysisModeUtils.parseFromParams(params);
    final dateRange = FieldUtils.parseDateRange(params);

    // 2. 调用 jsAPI 获取原始数据
    final jsResult = await _plugin.callJSAPI('getXxx', {
      'startDate': dateRange?['startDate']?.toIso8601String(),
      'endDate': dateRange?['endDate']?.toIso8601String(),
    });
    final rawData = jsonDecode(jsResult);

    // 3. 根据模式转换数据
    final result = _convertByMode(rawData, mode);

    // 4. 返回 JSON 字符串
    return FieldUtils.toJsonString(result);
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(dynamic rawData, AnalysisMode mode) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(rawData);
      case AnalysisMode.compact:
        return _buildCompact(rawData);
      case AnalysisMode.full:
        return FieldUtils.buildFullResponse(rawData);
    }
  }

  /// 构建摘要数据
  Map<String, dynamic> _buildSummary(dynamic rawData) {
    final records = (rawData as List?) ?? [];

    return FieldUtils.buildSummaryResponse({
      'total': records.length,
      // ... 其他统计字段
    });
  }

  /// 构建紧凑数据
  Map<String, dynamic> _buildCompact(dynamic rawData) {
    final records = (rawData as List?) ?? [];

    // 简化记录
    final compactRecords = FieldUtils.simplifyRecords(
      records,
      removeFields: ['description', 'content', 'metadata'],
    );

    return FieldUtils.buildCompactResponse(
      {'total': records.length},
      compactRecords,
    );
  }
}
```

### 2. 注册 Prompt 方法

在插件的 `controls/prompt_controller.dart` 中注册：

```dart
import 'package:memento/plugins/openai/openai_plugin.dart';
import '../xxx_plugin.dart';
import '../services/prompt_replacements.dart';

class XxxPromptController {
  final XxxPlugin plugin;
  late final XxxPromptReplacements _replacements;

  XxxPromptController(this.plugin) {
    _replacements = XxxPromptReplacements(plugin);
    _registerPromptMethods();
  }

  void _registerPromptMethods() {
    Future.delayed(const Duration(seconds: 1), () {
      try {
        OpenAIPlugin.registerPromptReplacementMethod(
          'xxx_getXxxData',
          _replacements.getXxxData,
        );
      } catch (e) {
        // 重试逻辑
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    });
  }
}
```

### 3. 在插件初始化中创建 Controller

在 `xxx_plugin.dart` 的 `initialize()` 方法中：

```dart
@override
Future<void> initialize() async {
  // ... 其他初始化逻辑

  // 初始化 Prompt Controller
  XxxPromptController(this);

  // ... 其他逻辑
}
```

---

## 最佳实践

### 1. 优先复用 jsAPI

**推荐做法**:
```dart
// ✅ 正确：复用 jsAPI
Future<String> getData(params) async {
  final jsResult = await _plugin.callJSAPI('getData', params);
  return _convertByMode(jsonDecode(jsResult), mode);
}
```

**不推荐做法**:
```dart
// ❌ 错误：重复实现数据查询逻辑
Future<String> getData(params) async {
  final storage = _plugin.storage;
  final data = await storage.read('data_key'); // 与 jsAPI 重复
  // ...
}
```

### 2. 合理使用 Summary 模式

对于以下场景，**强制使用 summary 模式**作为默认值：
- 时间范围超过 30 天
- 记录数超过 100 条
- 单条记录字段数超过 20 个

### 3. 截断冗长字段

对于 `description`, `content`, `notes` 等文本字段：
- Summary 模式：完全省略
- Compact 模式：截断至 100 字
- Full 模式：完整返回

```dart
final compactRecords = FieldUtils.truncateRecordFields(
  records,
  ['content', 'description'],
  100, // 最大长度
);
```

### 4. 提供有意义的统计数据

不要只返回 `total` 字段，应包含业务相关的统计：

```dart
// ✅ 推荐
{
  "sum": {
    "total": 50,
    "dur": 3600,
    "avg": 72,
    "topTags": [...]
  }
}

// ❌ 不推荐
{
  "sum": {
    "total": 50
  }
}
```

### 5. 保持字段一致性

同一插件的不同方法应使用相同的字段命名：

```dart
// ✅ 推荐
xxx_getTasks() => { "sum": { "total": 10 } }
xxx_getCompletedTasks() => { "sum": { "total": 5 } }

// ❌ 不推荐
xxx_getTasks() => { "summary": { "count": 10 } }
xxx_getCompletedTasks() => { "sum": { "total": 5 } }
```

---

## 迁移指南

### 从旧版本迁移

#### 步骤 1: 添加模式参数支持

```dart
// 旧版本
Future<String> getData(Map<String, dynamic> params) async {
  final data = await _fetchData();
  return jsonEncode(data); // 总是返回完整数据
}

// 新版本
Future<String> getData(Map<String, dynamic> params) async {
  final mode = AnalysisModeUtils.parseFromParams(params);
  final data = await _fetchData();
  return _convertByMode(data, mode);
}
```

#### 步骤 2: 统一字段命名

使用查找替换工具批量修改：
- `totalDuration` → `dur`
- `totalIncome` → `inc`
- `totalExpense` → `exp`
- `records` → `recs`
- `description` → `desc`

#### 步骤 3: 添加数据简化逻辑

```dart
Map<String, dynamic> _buildCompact(data) {
  // 添加字段过滤
  final simplified = FieldUtils.simplifyRecords(
    data,
    removeFields: ['metadata', 'rawContent'],
  );

  // 添加文本截断
  final truncated = FieldUtils.truncateRecordFields(
    simplified,
    ['description', 'notes'],
    100,
  );

  return FieldUtils.buildCompactResponse(
    {'total': data.length},
    truncated,
  );
}
```

### 向后兼容性

为确保平滑迁移，遵循以下规则：

1. **保留旧字段 6 个月**:
```dart
{
  "sum": {
    "total": 100,
    "totalCount": 100  // 旧字段，标记为 deprecated
  }
}
```

2. **添加版本标识**:
```dart
{
  "version": 2,  // 表示使用新格式
  "sum": { ... }
}
```

3. **文档说明**:
在插件的 `CLAUDE.md` 中添加迁移说明章节。

---

## FAQ

### Q1: 为什么要使用缩写？

**A**: 缩写的主要目的是减少 token 消耗。例如：
- `totalDuration` (13字符) → `dur` (3字符)，节省 76% 空间
- 对于 100 条记录，可节省约 1000 个字符（~200 tokens）

但并非所有字段都缩写：
- 常用字段（`id`, `title`, `tags`）保持完整，提高可读性
- 只对冗长且高频出现的字段使用缩写

### Q2: AI 能理解缩写吗？

**A**: 能够理解，因为：
1. 我们在 Prompt 中提供了字段说明文档
2. 缩写遵循常见规范（如 `cnt` = count, `dur` = duration）
3. AI 模型具有强大的上下文理解能力

### Q3: 何时使用哪种模式？

| 场景 | 推荐模式 |
|------|----------|
| "过去一周我做了多少活动？" | `summary` |
| "列出我本周的所有任务" | `compact` |
| "显示昨天的日记详细内容" | `full` |
| "分析我的消费习惯" | `summary` |
| "查找包含关键词的笔记" | `compact` |

**经验法则**:
- 需要统计数据 → `summary`
- 需要查看列表 → `compact`
- 需要完整内容 → `full`

### Q4: 如何测试 Prompt 方法？

```dart
// 测试用例示例
void testPromptMethod() async {
  final params = {
    'mode': 'summary',
    'startDate': '2025-01-01',
    'endDate': '2025-01-07',
  };

  final result = await getXxxData(params);
  final data = jsonDecode(result);

  // 验证数据结构
  assert(data.containsKey('sum'));
  assert(data['sum'].containsKey('total'));

  print('Token estimate: ${result.length ~/ 4}'); // 粗略估算
}
```

### Q5: 现有的 jsAPI 不符合需求怎么办？

优先考虑以下顺序：
1. 修改 jsAPI 以满足 Prompt 需求
2. 添加新的 jsAPI 方法
3. 在 Prompt Replacements 中添加额外处理逻辑

**示例**:
```dart
Future<String> getData(params) async {
  // 调用 jsAPI 获取基础数据
  final jsResult = await _plugin.callJSAPI('getData', params);
  var data = jsonDecode(jsResult);

  // 添加 jsAPI 未提供的统计数据
  data = _addStatistics(data);

  return _convertByMode(data, mode);
}
```

---

## 附录

### 附录 A: 完整示例

查看以下插件的实现作为参考：
- [lib/plugins/activity/](../lib/plugins/activity/) - 活动记录类插件
- [lib/plugins/bill/](../lib/plugins/bill/) - 财务账单类插件
- [lib/plugins/todo/](../lib/plugins/todo/) - 任务目标类插件（计划实现）

### 附录 B: Token 计算工具

使用以下工具估算 token 消耗：
```dart
int estimateTokens(String jsonStr) {
  // 粗略估算：4 个字符 ≈ 1 token
  return jsonStr.length ~/ 4;
}
```

### 附录 C: 相关文档

- [插件开发指南](../CLAUDE.md#插件开发规范)
- [jsAPI 文档](../lib/core/js_bridge/README.md)
- [OpenAI 插件文档](../lib/plugins/openai/CLAUDE.md)

---

**文档版本历史**:
- **v2.0** (2025-01-15): 正式发布，定义三种数据模式和字段规范
- **v1.0** (2024-xx-xx): 初版，各插件自定义格式（已废弃）

**反馈与贡献**:
如有疑问或建议，请在 GitHub Issues 中提出。
