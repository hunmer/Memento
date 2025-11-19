# JSAPI 分页控制器实现指南

本指南展示如何为插件的 JSAPI 添加分页功能，以减少单次返回的数据量，提高性能和响应速度。

## 目录

- [为什么需要分页](#为什么需要分页)
- [分页控制器实现](#分页控制器实现)
- [修改现有 API 函数](#修改现有-api-函数)
- [更新 JSON 配置](#更新-json-配置)
- [测试分页功能](#测试分页功能)
- [最佳实践](#最佳实践)

---

## 为什么需要分页

当 JSAPI 返回大量数据时会导致：
- **性能下降**：大量数据序列化/反序列化消耗时间
- **内存占用**：一次性加载所有数据占用大量内存
- **响应缓慢**：前端渲染大量数据导致卡顿
- **Token 消耗**：AI 对话中大量数据消耗更多 Token

**适用场景**：
- 返回列表数据的 API（如 `getItems`, `getAll`, `search` 等）
- 数据量可能超过 50 条的查询
- 支持 `findAll=true` 的查找方法

---

## 分页控制器实现

### 步骤 1: 添加通用分页函数

在插件类中添加通用分页控制器方法：

```dart
// lib/plugins/your_plugin/your_plugin.dart

/// 分页控制器 - 对列表进行分页处理
/// @param list 原始数据列表
/// @param offset 起始位置（默认 0）
/// @param count 返回数量（默认 100）
/// @return 分页后的数据，包含 data、total、offset、count、hasMore
Map<String, dynamic> _paginate<T>(
  List<T> list, {
  int offset = 0,
  int count = 100,
}) {
  final total = list.length;
  final start = offset.clamp(0, total);
  final end = (start + count).clamp(start, total);
  final data = list.sublist(start, end);

  return {
    'data': data,
    'total': total,
    'offset': start,
    'count': data.length,
    'hasMore': end < total,
  };
}
```

**返回字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `data` | Array | 分页后的数据列表 |
| `total` | Number | 总数据量 |
| `offset` | Number | 实际起始位置 |
| `count` | Number | 实际返回数量 |
| `hasMore` | Boolean | 是否还有更多数据 |

---

## 修改现有 API 函数

### 场景 1: 简单列表 API

**原代码**（无分页）：

```dart
/// 获取所有项目
Future<String> _jsGetItems(Map<String, dynamic> params) async {
  final items = service.getItems();
  final itemsJson = items.map((i) => i.toJson()).toList();
  return jsonEncode(itemsJson);
}
```

**修改后**（支持分页，向后兼容）：

```dart
/// 获取所有项目
/// 支持分页参数: offset, count
Future<String> _jsGetItems(Map<String, dynamic> params) async {
  final items = service.getItems();
  final itemsJson = items.map((i) => i.toJson()).toList();

  // 检查是否需要分页
  final int? offset = params['offset'];
  final int? count = params['count'];

  if (offset != null || count != null) {
    final paginated = _paginate(
      itemsJson,
      offset: offset ?? 0,
      count: count ?? 100,
    );
    return jsonEncode(paginated);
  }

  // 兼容旧版本：无分页参数时返回全部数据
  return jsonEncode(itemsJson);
}
```

### 场景 2: 异步数据 API

**原代码**：

```dart
/// 获取频道消息
Future<String> _jsGetMessages(Map<String, dynamic> params) async {
  final String? channelId = params['channelId'];
  if (channelId == null) {
    return jsonEncode({'error': '缺少必需参数: channelId'});
  }

  final messages = await service.getMessages(channelId);
  final messagesJson = await Future.wait(
    messages.map((m) => m.toJson()),
  );
  return jsonEncode(messagesJson);
}
```

**修改后**：

```dart
/// 获取频道消息
/// 支持分页参数: offset, count
Future<String> _jsGetMessages(Map<String, dynamic> params) async {
  final String? channelId = params['channelId'];
  if (channelId == null) {
    return jsonEncode({'error': '缺少必需参数: channelId'});
  }

  final int? offset = params['offset'];
  final int? count = params['count'];

  final messages = await service.getMessages(channelId);
  if (messages.isEmpty) {
    // 返回空结果（根据是否使用分页返回不同格式）
    return jsonEncode(offset != null || count != null
      ? {'data': [], 'total': 0, 'offset': 0, 'count': 0, 'hasMore': false}
      : []);
  }

  final messagesJson = await Future.wait(
    messages.map((m) => m.toJson()),
  );

  // 新版分页逻辑
  if (offset != null || count != null) {
    final paginated = _paginate(
      messagesJson,
      offset: offset ?? 0,
      count: count ?? 100,
    );
    return jsonEncode(paginated);
  }

  // 无分页参数时返回全部数据
  return jsonEncode(messagesJson);
}
```

### 场景 3: 查找 API（findAll 模式）

**原代码**：

```dart
/// 通用查找
Future<String> _jsFindBy(Map<String, dynamic> params) async {
  final bool findAll = params['findAll'] ?? false;
  final List<Item> matchedItems = []; // 查找逻辑...

  if (findAll) {
    return jsonEncode(matchedItems.map((i) => i.toJson()).toList());
  } else {
    if (matchedItems.isEmpty) return jsonEncode(null);
    return jsonEncode(matchedItems.first.toJson());
  }
}
```

**修改后**：

```dart
/// 通用查找
/// @param params.findAll 是否返回所有匹配项
/// @param params.offset 分页起始位置（仅 findAll=true 时有效）
/// @param params.count 返回数量（仅 findAll=true 时有效）
Future<String> _jsFindBy(Map<String, dynamic> params) async {
  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  final List<Item> matchedItems = []; // 查找逻辑...

  if (findAll) {
    final itemsJson = matchedItems.map((i) => i.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        itemsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(itemsJson);
  } else {
    if (matchedItems.isEmpty) return jsonEncode(null);
    return jsonEncode(matchedItems.first.toJson());
  }
}
```

---

## 更新 JSON 配置

修改插件的 `tools/*.json` 文件，添加分页参数文档和示例。

### 更新参数列表

**原配置**：

```json
{
  "getItems": {
    "title": "获取所有项目",
    "description": "获取所有项目的列表",
    "parameters": [],
    "returns": {
      "type": "Array",
      "description": "项目列表"
    }
  }
}
```

**修改后**：

```json
{
  "getItems": {
    "title": "获取所有项目",
    "description": "获取所有项目的列表，支持分页",
    "parameters": [
      {
        "name": "offset",
        "type": "number",
        "required": false,
        "description": "分页起始位置（默认 0）"
      },
      {
        "name": "count",
        "type": "number",
        "required": false,
        "description": "返回数量（默认 100）"
      }
    ],
    "returns": {
      "type": "Array|Object",
      "description": "无分页参数时返回项目数组；有分页参数时返回 {data, total, offset, count, hasMore}"
    }
  }
}
```

### 添加分页示例

```json
{
  "getItems": {
    "examples": [
      {
        "title": "获取所有项目",
        "code": "const items = await Memento.plugins.yourPlugin.getItems();\nsetResult(JSON.stringify(items, null, 2));"
      },
      {
        "title": "分页获取项目（前20个）",
        "code": "const result = await Memento.plugins.yourPlugin.getItems({offset: 0, count: 20});\nsetResult(`共 ${result.total} 个项目，当前返回 ${result.data.length} 个`);"
      },
      {
        "title": "分页获取项目（第二页）",
        "code": "const result = await Memento.plugins.yourPlugin.getItems({offset: 20, count: 20});\nsetResult(`还有更多: ${result.hasMore}`);"
      },
      {
        "title": "遍历所有项目（分页加载）",
        "code": "let allItems = [];\nlet offset = 0;\nconst count = 50;\n\nwhile (true) {\n  const result = await Memento.plugins.yourPlugin.getItems({offset, count});\n  allItems = allItems.concat(result.data);\n  \n  if (!result.hasMore) break;\n  offset += count;\n}\n\nsetResult(`共加载 ${allItems.length} 个项目`);"
      }
    ],
    "notes": "使用分页参数可以控制返回数据量，提高性能。推荐每页 20-100 条数据。"
  }
}
```

---

## 测试分页功能

### 测试用例

创建测试数据并验证分页功能：

```dart
// test/plugins/your_plugin_test.dart

void main() {
  group('分页功能测试', () {
    test('无分页参数时返回全部数据', () async {
      final result = await plugin._jsGetItems({});
      final data = jsonDecode(result);
      expect(data, isA<List>());
    });

    test('分页参数返回分页对象', () async {
      final result = await plugin._jsGetItems({'offset': 0, 'count': 10});
      final data = jsonDecode(result);

      expect(data, isA<Map>());
      expect(data['data'], isA<List>());
      expect(data['total'], isA<int>());
      expect(data['offset'], equals(0));
      expect(data['count'], lessThanOrEqualTo(10));
      expect(data['hasMore'], isA<bool>());
    });

    test('offset 超出范围时返回空列表', () async {
      final result = await plugin._jsGetItems({'offset': 9999, 'count': 10});
      final data = jsonDecode(result);

      expect(data['data'], isEmpty);
      expect(data['hasMore'], equals(false));
    });

    test('count 为 0 时返回空列表', () async {
      final result = await plugin._jsGetItems({'offset': 0, 'count': 0});
      final data = jsonDecode(result);

      expect(data['data'], isEmpty);
    });
  });
}
```

### 手动测试

在 agent_chat 中测试 JSAPI：

```javascript
// 测试 1: 无分页参数
const allItems = await Memento.plugins.yourPlugin.getItems();
console.log('全部数据:', allItems.length);

// 测试 2: 分页获取
const page1 = await Memento.plugins.yourPlugin.getItems({offset: 0, count: 10});
console.log('第一页:', page1);

// 测试 3: 遍历所有数据
let total = 0;
let offset = 0;
while (true) {
  const result = await Memento.plugins.yourPlugin.getItems({offset, count: 50});
  total += result.data.length;
  if (!result.hasMore) break;
  offset += 50;
}
console.log('总数据量:', total);
```

---

## 最佳实践

### 1. 默认分页大小

```dart
// 推荐的默认值
Map<String, dynamic> _paginate<T>(
  List<T> list, {
  int offset = 0,
  int count = 100,  // 默认 100，可根据数据大小调整
})
```

**建议**：
- 小数据量（<1KB/条）：默认 100-200
- 中等数据量（1-10KB/条）：默认 50-100
- 大数据量（>10KB/条）：默认 20-50

### 2. 向后兼容性

始终保持向后兼容，无分页参数时返回原有格式：

```dart
// ✅ 正确：保持向后兼容
if (offset != null || count != null) {
  return jsonEncode(_paginate(data, offset: offset ?? 0, count: count ?? 100));
}
return jsonEncode(data);

// ❌ 错误：破坏向后兼容
return jsonEncode(_paginate(data, offset: offset ?? 0, count: count ?? 100));
```

### 3. 空数据处理

确保空数据时也返回正确格式：

```dart
if (data.isEmpty) {
  return jsonEncode(offset != null || count != null
    ? {'data': [], 'total': 0, 'offset': 0, 'count': 0, 'hasMore': false}
    : []);
}
```

### 4. 参数验证

```dart
// 验证 offset 和 count 的合法性
final offset = (params['offset'] as int?)?.clamp(0, double.maxFinite.toInt()) ?? 0;
final count = (params['count'] as int?)?.clamp(0, 1000) ?? 100; // 限制最大值

// 或者在 _paginate 中处理
final start = offset.clamp(0, total);
final end = (start + count.clamp(0, 1000)).clamp(start, total);
```

### 5. 性能优化

对于数据库查询，在数据库层面进行分页：

```dart
// ❌ 不推荐：先查询全部再分页
Future<String> _jsGetItems(Map<String, dynamic> params) async {
  final allItems = await database.getAllItems(); // 查询全部
  final itemsJson = allItems.map((i) => i.toJson()).toList();

  if (offset != null || count != null) {
    return jsonEncode(_paginate(itemsJson, offset: offset!, count: count!));
  }
  return jsonEncode(itemsJson);
}

// ✅ 推荐：在数据库层面分页
Future<String> _jsGetItems(Map<String, dynamic> params) async {
  final int? offset = params['offset'];
  final int? count = params['count'];

  if (offset != null || count != null) {
    // 直接从数据库获取分页数据
    final items = await database.getItems(
      limit: count ?? 100,
      offset: offset ?? 0,
    );
    final total = await database.getItemsCount();

    return jsonEncode({
      'data': items.map((i) => i.toJson()).toList(),
      'total': total,
      'offset': offset ?? 0,
      'count': items.length,
      'hasMore': (offset ?? 0) + items.length < total,
    });
  }

  // 无分页参数时返回全部
  final allItems = await database.getAllItems();
  return jsonEncode(allItems.map((i) => i.toJson()).toList());
}
```

### 6. 错误处理

```dart
Future<String> _jsGetItems(Map<String, dynamic> params) async {
  try {
    final int? offset = params['offset'];
    final int? count = params['count'];

    // 参数验证
    if (offset != null && offset < 0) {
      return jsonEncode({'error': 'offset 不能为负数'});
    }
    if (count != null && count < 0) {
      return jsonEncode({'error': 'count 不能为负数'});
    }
    if (count != null && count > 1000) {
      return jsonEncode({'error': 'count 不能超过 1000'});
    }

    // 业务逻辑...

  } catch (e) {
    return jsonEncode({'error': '获取数据失败: ${e.toString()}'});
  }
}
```

### 7. 文档注释

在代码中添加清晰的文档注释：

```dart
/// 获取所有项目
///
/// 支持分页参数:
/// - `offset` (可选): 起始位置，默认 0
/// - `count` (可选): 返回数量，默认 100
///
/// 返回格式:
/// - 无分页参数: `Array<Item>` - 项目数组
/// - 有分页参数: `{data: Array<Item>, total: number, offset: number, count: number, hasMore: boolean}`
///
/// 示例:
/// ```javascript
/// // 获取全部
/// const items = await Memento.plugins.yourPlugin.getItems();
///
/// // 分页获取
/// const result = await Memento.plugins.yourPlugin.getItems({offset: 0, count: 20});
/// console.log(`共 ${result.total} 个，当前 ${result.data.length} 个`);
/// ```
Future<String> _jsGetItems(Map<String, dynamic> params) async {
  // 实现...
}
```

---

## 完整示例

参考 `lib/plugins/chat/chat_plugin.dart` 中的实现：

- **分页控制器**: 第 162-186 行
- **getChannels**: 第 190-211 行
- **getMessages**: 第 303-347 行
- **findChannelBy**: 第 392-446 行
- **findChannelByTitle**: 第 476-530 行
- **findMessageBy**: 第 534-610 行
- **findMessageByContent**: 第 668-752 行

配置文件参考: `lib/plugins/agent_chat/tools/chat.json`

---

## 迁移清单

为现有插件添加分页功能时，按照以下清单操作：

- [ ] 在插件类中添加 `_paginate()` 方法
- [ ] 识别需要分页的 API 函数（返回列表的方法）
- [ ] 为每个 API 函数添加 `offset` 和 `count` 参数
- [ ] 实现分页逻辑（保持向后兼容）
- [ ] 处理空数据情况
- [ ] 更新 JSON 配置文件的参数列表
- [ ] 添加分页示例代码
- [ ] 更新 `notes` 字段说明
- [ ] 编写单元测试
- [ ] 手动测试各种场景
- [ ] 更新插件文档（如有）

---

## 常见问题

### Q1: 是否所有 API 都需要分页？

**不需要**。只有返回列表数据且可能数据量较大的 API 才需要分页。单条数据查询（如 `getById`）不需要分页。

### Q2: 分页参数是必需的吗？

**不是必需的**。为了保持向后兼容，分页参数应该是可选的。无分页参数时返回原有格式。

### Q3: 如何处理已有的 limit 参数？

**保留 limit 参数，同时添加 offset/count**。在实现中优先处理 offset/count，当它们不存在时再使用 limit。参考 `getMessages` 的实现（第 315 行）。

### Q4: 分页对象的字段可以自定义吗？

**不推荐自定义**。统一使用 `{data, total, offset, count, hasMore}` 格式，保持全局一致性。

### Q5: 如何优化大数据量查询？

**在数据源层面分页**。不要先查询全部数据再分页，而是在数据库/服务层直接实现分页查询（参考最佳实践第5条）。

---

## 相关资源

- **示例代码**: `lib/plugins/chat/chat_plugin.dart`
- **配置示例**: `lib/plugins/agent_chat/tools/chat.json`
- **JS Bridge 文档**: `lib/core/js_bridge/JS_API_README.md`
- **插件开发文档**: `CLAUDE.md`

---

**文档版本**: 1.0.0
**最后更新**: 2025-11-19
**维护者**: Memento 开发团队
