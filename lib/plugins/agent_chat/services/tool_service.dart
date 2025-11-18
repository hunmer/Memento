import 'dart:convert';
import '../models/tool_call_step.dart';
import '../../../core/js_bridge/js_bridge_manager.dart';
import 'tool_config_manager.dart';

/// 工具服务 - 负责工具调用的解析、执行和 Prompt 生成
class ToolService {
  static String? _cachedToolListPrompt;
  static String? _cachedToolBriefPrompt;
  static bool _initialized = false;

  /// 第一阶段 JSON Schema - 工具需求
  static const Map<String, dynamic> toolRequestSchema = {
    'type': 'object',
    'properties': {
      'needed_tools': {
        'type': 'array',
        'description': '需要使用的工具ID列表',
        'items': {'type': 'string'},
      },
    },
    'required': ['needed_tools'],
    'additionalProperties': false,
  };

  /// 第二阶段 JSON Schema - 工具调用
  static const Map<String, dynamic> toolCallSchema = {
    'type': 'object',
    'properties': {
      'steps': {
        'type': 'array',
        'description': '工具执行步骤列表',
        'items': {
          'type': 'object',
          'properties': {
            'method': {
              'type': 'string',
              'description': '执行方法,固定为 run_js',
              'enum': ['run_js'],
            },
            'title': {
              'type': 'string',
              'description': '步骤标题',
            },
            'desc': {
              'type': 'string',
              'description': '步骤描述',
            },
            'data': {
              'type': 'string',
              'description': 'JavaScript 代码字符串',
            },
          },
          'required': ['method', 'title', 'desc', 'data'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['steps'],
    'additionalProperties': false,
  };

  /// 初始化工具服务（加载所有工具配置）
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 初始化 ToolConfigManager
      await ToolConfigManager.instance.initialize();

      // 生成并缓存两种 Prompt
      _cachedToolBriefPrompt = _generateToolBriefPrompt();
      _cachedToolListPrompt = await _generateToolListPrompt();

      _initialized = true;
      print('[ToolService] 初始化成功，加载了 ${_cachedToolBriefPrompt?.length ?? 0} 字符的简要索引');
    } catch (e) {
      print('[ToolService] 初始化失败: $e');
      _cachedToolBriefPrompt = _getFallbackBriefPrompt();
      _cachedToolListPrompt = _getFallbackToolPrompt();
    }
  }

  /// 检查内容是否包含工具调用 JSON
  static bool containsToolCall(String content) {
    // 检测 ```json ... ``` 格式
    if (content.contains('```json') && content.contains('```')) {
      final jsonMatch = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```', multiLine: true).firstMatch(content);
      if (jsonMatch != null) {
        try {
          final jsonStr = jsonMatch.group(1)!;
          final parsed = jsonDecode(jsonStr);
          return parsed is Map && parsed.containsKey('steps');
        } catch (e) {
          return false;
        }
      }
    }

    // 检测直接的 JSON 格式（查找 {"steps": ...}）
    final directJsonMatch = RegExp(r'\{\s*"steps"\s*:\s*\[[\s\S]*?\]\s*\}', multiLine: true).firstMatch(content);
    if (directJsonMatch != null) {
      try {
        jsonDecode(directJsonMatch.group(0)!);
        return true;
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  /// 从 AI 回复中解析工具调用
  static ToolCallResponse? parseToolCallFromResponse(String response) {
    try {
      String? jsonStr;

      // 1. 尝试从 ```json ... ``` 中提取
      final jsonBlockMatch = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```', multiLine: true).firstMatch(response);
      if (jsonBlockMatch != null) {
        jsonStr = jsonBlockMatch.group(1);
      } else {
        // 2. 尝试提取直接的 JSON
        final directJsonMatch = RegExp(r'\{\s*"steps"\s*:\s*\[[\s\S]*?\]\s*\}', multiLine: true).firstMatch(response);
        if (directJsonMatch != null) {
          jsonStr = directJsonMatch.group(0);
        }
      }

      if (jsonStr == null) {
        print('[ToolService] 未找到工具调用 JSON');
        return null;
      }

      // 解析 JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final toolCall = ToolCallResponse.fromJson(json);

      print('[ToolService] 成功解析工具调用，包含 ${toolCall.steps.length} 个步骤');
      return toolCall;

    } catch (e, stack) {
      print('[ToolService] 解析工具调用失败: $e');
      print(stack);
      return null;
    }
  }

  /// 执行 JS 代码
  static Future<String> executeJsCode(String jsCode) async {
    try {
      final jsBridge = JSBridgeManager.instance;

      // 执行 JS 代码
      final result = await jsBridge.evaluate(jsCode);

      if (!result.success) {
        throw Exception(result.error ?? '执行失败');
      }

      // 确保返回值是字符串
      final resultValue = result.result;
      if (resultValue == null) {
        return 'null';
      } else if (resultValue is String) {
        return resultValue;
      } else {
        // 如果是对象或数组，转为 JSON 字符串
        return json.encode(resultValue);
      }

    } catch (e) {
      print('[ToolService] JS 执行失败: $e');
      rethrow;
    }
  }

  /// 执行单个工具步骤
  static Future<String> executeToolStep(ToolCallStep step) async {
    switch (step.method) {
      case 'run_js':
        return await executeJsCode(step.data);
      default:
        throw Exception('不支持的方法类型: ${step.method}');
    }
  }

  /// 获取工具列表 Prompt（用于添加到 system prompt）
  /// @deprecated 使用 getToolBriefPrompt() 和 getToolDetailPrompt() 实现两阶段调用
  static String getToolListPrompt() {
    if (!_initialized) {
      print('[ToolService] 警告：工具服务未初始化，使用后备 Prompt');
      return _getFallbackToolPrompt();
    }
    return _cachedToolListPrompt ?? _getFallbackToolPrompt();
  }

  /// 生成工具列表 Prompt（从配置文件）
  /// 保留此方法用于向后兼容，但建议使用两阶段调用
  static Future<String> _generateToolListPrompt() async {
    final buffer = StringBuffer();

    buffer.writeln('\n## 🛠️ 可用工具列表');
    buffer.writeln('\n### ⚠️ 重要提示');
    buffer.writeln('\n作为 AI 助手，你**无法直接获取**以下类型的信息：');
    buffer.writeln('1. **当前时间**：你无法感知时间流逝，不能硬编码日期时间字符串');
    buffer.writeln('2. **用户数据**：所有用户的任务、笔记、日记等数据都存储在本地，必须使用插件工具获取');
    buffer.writeln('\n### 系统 API（在 JavaScript 代码中直接调用）');
    buffer.writeln('\n当需要时间或设备信息时，**直接在 JavaScript 代码中调用**，不要作为单独的步骤：');
    buffer.writeln('- `await Memento.system.getCurrentTime()` - 获取当前时间');
    buffer.writeln('- `await Memento.system.getTimestamp()` - 获取时间戳');
    buffer.writeln('- `await Memento.system.formatDate(dateInput, format)` - 格式化日期');
    buffer.writeln('- `await Memento.system.getDeviceInfo()` - 获取设备信息');
    buffer.writeln('- `await Memento.system.getAppInfo()` - 获取应用信息');
    buffer.writeln('\n你可以调用以下插件功能来获取数据或执行操作。');
    buffer.writeln('\n### 🎯 run_js 工具用途说明\n');
    buffer.writeln('**JavaScript 代码可用于**:');
    buffer.writeln('- ✅ 数据查询(调用插件 API 获取数据)');
    buffer.writeln('- ✅ 数据修改(执行签到、创建任务、更新数据等操作)');
    buffer.writeln('- ✅ 数据处理(过滤、排序、统计、计算等)');
    buffer.writeln('- ✅ 数据格式化(转换数据结构、格式化输出等)');
    buffer.writeln('\n**JavaScript 代码不应用于**:');
    buffer.writeln('- ❌ 生成建议、分析、总结等自然语言内容');
    buffer.writeln('- ❌ 回答用户的"为什么"、"怎么样"等分析性问题');
    buffer.writeln('- ❌ 提供指导、意见或评价');
    buffer.writeln('\n**⚠️ 重要原则**:');
    buffer.writeln('- 当用户提出明确的操作需求(如"帮我签到"、"创建任务")时,应生成完整的操作步骤,直接完成任务');
    buffer.writeln('- 不要只查询信息后询问用户确认,应该根据用户意图自动完成完整流程');
    buffer.writeln('- 一个 steps 数组中可以包含多个步骤,形成完整的操作链');
    buffer.writeln('\n**正确流程**: JavaScript 返回结构化数据 → AI 基于数据进行分析和建议');
    buffer.writeln('当需要使用工具时，请返回以下 JSON 格式：\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "执行步骤的标题",');
    buffer.writeln('      "desc": "执行步骤的描述",');
    buffer.writeln('      "data": "JavaScript 代码字符串"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');

    // 从配置加载工具列表
    final allPluginTools = ToolConfigManager.instance.getAllPluginTools();

    if (allPluginTools.isNotEmpty) {
      buffer.writeln('### 📚 可用工具\n');

      allPluginTools.forEach((pluginId, toolSet) {
        final enabledTools = toolSet.tools.entries
            .where((e) => e.value.enabled)
            .toList();

        if (enabledTools.isEmpty) return;

        buffer.writeln('**$pluginId**');
        for (final entry in enabledTools) {
          final toolId = entry.key;
          final config = entry.value;
          final signature = config.getSignature(toolId);
          buffer.writeln('  - `$signature` - ${config.getBriefDescription()}');
        }
        buffer.writeln();
      });
    } else {
      buffer.writeln('（暂无可用工具）\n');
    }

    // 使用示例
    buffer.writeln('### 💡 使用示例\n');
    buffer.writeln('**示例 1：查询今天的任务**\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "获取今日任务",');
    buffer.writeln('      "desc": "查询今天的所有待办任务",');
    buffer.writeln(r'      "data": "const time = await Memento.system.getCurrentTime(); const tasks = await Memento.plugins.todo.getTodayTasks(); const result = `今天是${time.month}月${time.day}日，有 ${tasks.length} 个任务`; setResult(result); return result;"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');
    buffer.writeln('**示例 2：查询并处理数据**\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "统计任务情况",');
    buffer.writeln('      "desc": "获取并统计今日任务",');
    buffer.writeln(r'      "data": "const tasks = await Memento.plugins.todo.getTodayTasks(); const result = { total: tasks.length, completed: tasks.filter(t => t.completed).length }; setResult(result); return result;"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');
    buffer.writeln('**示例 3：完整的签到流程（查询+执行）**\n');
    buffer.writeln('用户请求"帮我完成签到"时，应该直接执行完整流程，不要只查询后询问：\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "执行签到操作",');
    buffer.writeln('      "desc": "查找第一个未签到的项目并执行签到",');
    final checkinExample =
        '''const items = await Memento.plugins.checkin.getCheckinItems(); const target = items.find(i => !i.isCheckedToday); if (!target) { const msg = '所有项目今天都已签到'; setResult(msg); return msg; } const result = await Memento.plugins.checkin.checkin(target.id); const msg = result.success ? `签到成功: \${target.name}` : result.message; setResult(msg); return msg;''';
    buffer.writeln('      "data": "${checkinExample.replaceAll('"', '\\"')}"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');
    buffer.writeln('**示例 4：多步骤操作链（查询条件+创建）**\n');
    buffer.writeln('当用户说"创建明天的任务"时，直接完成创建，不要询问确认：\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "创建明天的任务",');
    buffer.writeln('      "desc": "获取明天日期并创建任务",');
    final createTaskExample = '''const time = await Memento.system.getCurrentTime(); const tomorrow = time.timestamp + 24 * 60 * 60 * 1000; const result = await Memento.plugins.todo.createTask('New Task', { dueDate: tomorrow }); const msg = result.success ? 'Task created successfully' : 'Failed to create task'; setResult(msg); return msg;''';
    buffer.writeln('      "data": "${createTaskExample.replaceAll('"', '\\"')}"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');

    buffer.writeln('### ⚠️ 注意事项\n');
    buffer.writeln('1. **系统 API 直接调用**: `Memento.system.*` API 不需要作为单独的工具步骤，直接在代码中调用');
    buffer.writeln('2. **返回结果**: JavaScript 代码必须先调用 `setResult(result)` 设置返回值，然后 `return result`');
    buffer.writeln('3. **JSON 字符串转义**: data 字段中的 JavaScript 代码需要正确转义引号');
    buffer.writeln('4. **异步操作**: 所有插件方法都是异步的，必须使用 `await`');
    buffer.writeln('5. **避免硬编码时间**: 不要在代码中硬编码日期时间字符串，使用 `Memento.system.getCurrentTime()` 获取\n');

    return buffer.toString();
  }

  /// 后备工具 Prompt（当初始化失败时使用）
  static String _getFallbackToolPrompt() {
    return r'''

## 🛠️ 可用工具列表

### ⚠️ 重要提示

作为 AI 助手，你**无法直接获取**以下类型的信息：
1. **当前时间**：你无法感知时间流逝，不能硬编码日期时间字符串
2. **用户数据**：所有用户的任务、笔记、日记等数据都存储在本地，必须使用插件工具获取

### 系统 API（在 JavaScript 代码中直接调用）

当需要时间或设备信息时，**直接在 JavaScript 代码中调用**，不要作为单独的步骤：
- `await Memento.system.getCurrentTime()` - 获取当前时间
- `await Memento.system.getTimestamp()` - 获取时间戳
- `await Memento.system.formatDate(dateInput, format)` - 格式化日期
- `await Memento.system.getDeviceInfo()` - 获取设备信息
- `await Memento.system.getAppInfo()` - 获取应用信息


### 🎯 run_js 工具用途说明

**JavaScript 代码可用于**:
- ✅ 数据查询(调用插件 API 获取数据)
- ✅ 数据修改(执行签到、创建任务、更新数据等操作)
- ✅ 数据处理(过滤、排序、统计、计算等)
- ✅ 数据格式化(转换数据结构、格式化输出等)

**JavaScript 代码不应用于**:
- ❌ 生成建议、分析、总结等自然语言内容
- ❌ 回答用户的"为什么"、"怎么样"等分析性问题
- ❌ 提供指导、意见或评价

**⚠️ 重要原则**:
- 当用户提出明确的操作需求时,应生成完整的操作步骤,直接完成任务
- 不要只查询信息后询问用户确认,应该根据用户意图自动完成完整流程

**正确流程**: JavaScript 返回结构化数据 → AI 基于数据进行分析和建议

你可以通过返回 JSON 格式来调用插件功能：

```json
{
  "steps": [
    {
      "method": "run_js",
      "title": "执行标题",
      "desc": "执行描述",
      "data": "JavaScript 代码"
    }
  ]
}
```

### 常用插件 API

**todo** (待办任务)
  - `Memento.plugins.todo.getTasks(status, priority)` - 获取任务
  - `Memento.plugins.todo.getTodayTasks()` - 获取今日任务

**notes** (笔记)
  - `Memento.plugins.notes.getNotes(params)` - 获取笔记

**示例**：查询今天的任务
```javascript
const time = await Memento.system.getCurrentTime();
const tasks = await Memento.plugins.todo.getTodayTasks();
const result = `今天是 ${time.month}月${time.day}日，有 ${tasks.length} 个任务`;
setResult(result);
return result;
```

必须先 `setResult(result)` 设置返回值，然后 `return result`。
''';
  }

  // ==================== 新增：两阶段工具调用支持 ====================

  /// 生成工具简要索引 Prompt（第一阶段）
  static String _generateToolBriefPrompt() {
    final toolIndex = ToolConfigManager.instance.getToolIndex(enabledOnly: true);

    final buffer = StringBuffer();
    buffer.writeln('\n## 🛠️ 可用工具');
    buffer.writeln('\n当用户询问需要数据查询的问题时，分析需求并返回：');
    buffer.writeln('```json');
    buffer.writeln('{"needed_tools": ["tool_id1", "tool_id2"]}');
    buffer.writeln('```\n');
    buffer.writeln('可用工具列表（${toolIndex.length} 个）：\n');

    for (final item in toolIndex) {
      // 跳过系统工具，因为它们不作为独立步骤
      if (item[0].startsWith('system_')) continue;
      buffer.writeln('- **${item[0]}**: ${item[1]}');
    }

    return buffer.toString();
  }

  /// 后备简要 Prompt
  static String _getFallbackBriefPrompt() {
    return '''

## 🛠️ 可用工具

当用户询问需要数据查询的问题时，分析需求并返回：
```json
{"needed_tools": ["tool_id1", "tool_id2"]}
```

可用工具列表：
- **todo_getTasks**: 获取任务列表
- **todo_getTodayTasks**: 获取今日任务
- **notes_getNotes**: 获取笔记列表
''';
  }

  /// 获取工具简要索引 Prompt（用于第一阶段 AI 请求）
  static String getToolBriefPrompt() {
    if (!_initialized) {
      print('[ToolService] 警告：工具服务未初始化，使用后备简要 Prompt');
      return _getFallbackBriefPrompt();
    }
    return _cachedToolBriefPrompt ?? _getFallbackBriefPrompt();
  }

  /// 获取工具详细文档 Prompt（第二阶段）
  static Future<String> getToolDetailPrompt(List<String> toolIds) async {
    if (toolIds.isEmpty) {
      return '';
    }

    final toolsDetails = await ToolConfigManager.instance.getToolsDetails(toolIds);

    final buffer = StringBuffer();
    buffer.writeln('\n## 📚 工具详细文档\n');
    buffer.writeln('### 系统 API（始终可用）\n');
    buffer.writeln('在生成的 JavaScript 代码中，你可以**直接调用**以下系统 API：\n');
    buffer.writeln('- `await Memento.system.getCurrentTime()` - 获取当前完整时间信息');
    buffer.writeln('  - 返回：`{ timestamp, datetime, year, month, day, hour, minute, second, weekday, weekdayName }`');
    buffer.writeln('- `await Memento.system.getTimestamp()` - 获取当前时间戳（毫秒）');
    buffer.writeln('- `await Memento.system.formatDate(dateInput, format)` - 格式化日期');
    buffer.writeln('  - dateInput: 时间戳（毫秒）或 ISO 字符串');
    buffer.writeln('  - format: 格式模板，如 "yyyy-MM-dd HH:mm:ss"');
    buffer.writeln('- `await Memento.system.getDeviceInfo()` - 获取设备信息');
    buffer.writeln('- `await Memento.system.getAppInfo()` - 获取应用信息\n');
    buffer.writeln('⚠️ **重要**：不要将系统 API 作为单独的步骤，而是在需要时直接在代码中调用！\n');
    buffer.writeln('---\n');
    buffer.writeln('以下是你需要的插件工具的详细使用说明：\n');

    toolsDetails.forEach((toolId, config) {
      buffer.writeln('### `$toolId` - ${config.title}\n');
      buffer.writeln('**描述**: ${config.description}\n');

      // 参数列表
      if (config.parameters.isNotEmpty) {
        buffer.writeln('**参数**:');
        for (final param in config.parameters) {
          final optionalMark = param.optional ? '(可选)' : '(必需)';
          buffer.writeln('- `${param.name}` $optionalMark: ${param.type} - ${param.description}');
        }
        buffer.writeln();
      }

      // 返回值
      buffer.writeln('**返回值**: ${config.returns.type} - ${config.returns.description}\n');

      // 示例代码
      if (config.examples.isNotEmpty) {
        buffer.writeln('**示例**:');
        for (final example in config.examples) {
          buffer.writeln('```javascript');
          buffer.writeln('// ${example.comment}');
          buffer.writeln(example.code);
          buffer.writeln('```\n');
        }
      }

      // 注意事项
      if (config.notes != null && config.notes!.isNotEmpty) {
        buffer.writeln('**注意**: ${config.notes}\n');
      }

      buffer.writeln('---\n');
    });

    // 添加工具调用格式说明
    buffer.writeln('\n### 🎯 run_js 工具用途说明\n');
    buffer.writeln('**JavaScript 代码可用于**:');
    buffer.writeln('- ✅ 数据查询(调用插件 API 获取数据)');
    buffer.writeln('- ✅ 数据修改(执行签到、创建任务、更新数据等操作)');
    buffer.writeln('- ✅ 数据处理(过滤、排序、统计、计算等)');
    buffer.writeln('- ✅ 数据格式化(转换数据结构、格式化输出等)');
    buffer.writeln('\n**JavaScript 代码不应用于**:');
    buffer.writeln('- ❌ 生成建议、分析、总结等自然语言内容');
    buffer.writeln('- ❌ 回答用户的"为什么"、"怎么样"等分析性问题');
    buffer.writeln('- ❌ 提供指导、意见或评价');
    buffer.writeln('\n**⚠️ 重要原则**:');
    buffer.writeln('- 当用户提出明确的操作需求时,应生成完整的操作步骤,直接完成任务');
    buffer.writeln('- 不要只查询信息后询问用户确认,应该根据用户意图自动完成完整流程');
    buffer.writeln('- 一个步骤中可以包含查询+操作的完整逻辑(如:查找项目ID → 执行签到)');
    buffer.writeln('\n**正确流程**:');
    buffer.writeln('1. JavaScript 返回结构化数据(如数组、对象)');
    buffer.writeln('2. AI 基于这些数据进行自然语言分析和建议\n');
    buffer.writeln('## 📝 生成工具调用\n');
    buffer.writeln('请根据以上文档生成 JavaScript 代码，格式如下：\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "执行步骤的标题",');
    buffer.writeln('      "desc": "执行步骤的描述",');
    buffer.writeln('      "data": "JavaScript 代码字符串"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');
    buffer.writeln('### 📋 返回结果的标准模式\n');
    buffer.writeln('```javascript');
    buffer.writeln('// 必须遵循以下模式：');
    buffer.writeln('const result = await Memento.plugins.xxx.getData();');
    buffer.writeln('setResult(result); // 1. 先设置返回值');
    buffer.writeln('return result;     // 2. 再返回');
    buffer.writeln('```\n');

    return buffer.toString();
  }

  /// 解析 AI 返回的工具需求
  static List<String>? parseToolRequest(String response) {
    try {
      // 尝试从 ```json ... ``` 中提取
      final jsonBlockMatch = RegExp(
        r'```json\s*(\{[\s\S]*?\})\s*```',
        multiLine: true,
      ).firstMatch(response);

      String? jsonStr;
      if (jsonBlockMatch != null) {
        jsonStr = jsonBlockMatch.group(1);
      } else {
        // 尝试提取直接的 JSON
        final directJsonMatch = RegExp(
          r'\{\s*"needed_tools"\s*:\s*\[[\s\S]*?\]\s*\}',
          multiLine: true,
        ).firstMatch(response);
        if (directJsonMatch != null) {
          jsonStr = directJsonMatch.group(0);
        }
      }

      if (jsonStr == null) {
        return null;
      }

      // 解析 JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (!json.containsKey('needed_tools')) {
        return null;
      }

      final tools = json['needed_tools'] as List<dynamic>;
      return tools.map((e) => e.toString()).toList();
    } catch (e) {
      print('[ToolService] 解析工具需求失败: $e');
      return null;
    }
  }
}
