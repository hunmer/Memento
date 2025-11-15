import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tool_call_step.dart';
import '../../../core/js_bridge/js_bridge_manager.dart';

/// 工具服务 - 负责工具调用的解析、执行和 Prompt 生成
class ToolService {
  static String? _cachedToolListPrompt;
  static bool _initialized = false;

  /// 初始化工具服务（加载所有 JS API 文档）
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 生成并缓存工具列表 Prompt
      _cachedToolListPrompt = await _generateToolListPrompt();
      _initialized = true;
      print('[ToolService] 初始化成功，加载了 ${_cachedToolListPrompt?.length ?? 0} 字符的工具描述');
    } catch (e) {
      print('[ToolService] 初始化失败: $e');
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

  /// 获取工具列表 Prompt（用于添加到 system prompt）
  static String getToolListPrompt() {
    if (!_initialized) {
      print('[ToolService] 警告：工具服务未初始化，使用后备 Prompt');
      return _getFallbackToolPrompt();
    }
    return _cachedToolListPrompt ?? _getFallbackToolPrompt();
  }

  /// 生成工具列表 Prompt（从 JS API 文档）
  static Future<String> _generateToolListPrompt() async {
    final buffer = StringBuffer();

    buffer.writeln('\n## 🛠️ 可用工具列表');
    buffer.writeln('\n你可以调用以下插件功能来获取数据或执行操作。');
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

    // 添加 JS API 工具
    buffer.writeln('### 📚 JS API 工具\n');
    buffer.writeln('在 JavaScript 代码中，你可以通过 `Memento.<插件ID>.<方法名>()` 调用以下功能：\n');

    final jsApiDocs = await _loadJsApiDocs();
    if (jsApiDocs.isNotEmpty) {
      for (var doc in jsApiDocs) {
        buffer.writeln(doc);
        buffer.writeln();
      }
    } else {
      buffer.writeln('（暂无 JS API 工具）\n');
    }

    // 添加数据分析工具
    buffer.writeln('### 📊 数据分析工具\n');
    buffer.writeln('通过 `callPluginAnalysis(methodName, params)` 调用以下数据分析方法：\n');

    final analysisTools = _getAnalysisTools();
    if (analysisTools.isNotEmpty) {
      for (var tool in analysisTools) {
        buffer.writeln(tool);
        buffer.writeln();
      }
    } else {
      buffer.writeln('（暂无数据分析工具）\n');
    }

    // 使用示例
    buffer.writeln('### 💡 使用示例\n');
    buffer.writeln('**示例 1：获取今日任务**');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "获取今日任务",');
    buffer.writeln('      "desc": "查询今天的所有待办任务",');
    buffer.writeln('      "data": "const tasks = await Memento.todo.getTodayTasks(); setResult(JSON.stringify(tasks));"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');

    buffer.writeln('**示例 2：分析日记数据**');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "获取本月日记",');
    buffer.writeln('      "desc": "查询并分析本月的日记内容",');
    buffer.writeln('      "data": "const data = await callPluginAnalysis(\'diary_getDiaries\', {startDate: \'2025-01-01\', endDate: \'2025-01-31\', mode: \'summary\'}); setResult(data);"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');

    buffer.writeln('### ⚠️ 注意事项\n');
    buffer.writeln('1. **必须使用 setResult()**: JavaScript 代码最后必须调用 `setResult()` 返回结果');
    buffer.writeln('2. **JSON 字符串转义**: data 字段中的 JavaScript 代码需要正确转义引号');
    buffer.writeln('3. **异步操作**: 所有插件方法都是异步的，必须使用 `await`');
    buffer.writeln('4. **错误处理**: 如果代码执行失败，工具调用流程会中断\n');

    return buffer.toString();
  }

  /// 加载所有 JS API 文档
  static Future<List<String>> _loadJsApiDocs() async {
    final docs = <String>[];

    // 已知的 JS API 文档路径
    final knownDocs = [
      {'plugin': 'todo', 'file': 'lib/plugins/todo/JS_API.md'},
      {'plugin': 'notes', 'file': 'lib/plugins/notes/JS_API_DOC.md'},
      {'plugin': 'tracker', 'file': 'lib/plugins/tracker/JS_API_GUIDE.md'},
      {'plugin': 'store', 'file': 'lib/plugins/store/JS_API.md'},
      {'plugin': 'timer', 'file': 'lib/plugins/timer/JS_API.md'},
    ];

    for (var doc in knownDocs) {
      try {
        final content = await rootBundle.loadString('assets/${doc['file']}');
        final summary = _extractApiSummaryFromMarkdown(content, doc['plugin']!);
        if (summary.isNotEmpty) {
          docs.add(summary);
        }
      } catch (e) {
        // 文档不存在，跳过
        print('[ToolService] 无法加载 ${doc['file']}: $e');
      }
    }

    // 如果文档加载失败，返回硬编码的基础 API
    if (docs.isEmpty) {
      docs.add('**todo** (待办任务)\n  - `getTasks(status?, priority?)` - 获取任务列表\n  - `getTodayTasks()` - 获取今日任务\n  - `createTask(title, desc?, startDate?, dueDate?, priority?, tags?)` - 创建任务');
      docs.add('**notes** (笔记)\n  - `getNotes(params?)` - 获取笔记列表\n  - `createNote(title, content)` - 创建笔记');
    }

    return docs;
  }

  /// 从 Markdown 文档中提取 API 摘要
  static String _extractApiSummaryFromMarkdown(String markdown, String pluginId) {
    final buffer = StringBuffer();
    buffer.writeln('**$pluginId**');

    // 简单的正则匹配 ### `methodName(...)` 格式
    final methodRegex = RegExp(r'###\s+`([^`]+)`\s*\n\*\*描述\*\*:\s*([^\n]+)', multiLine: true);
    final matches = methodRegex.allMatches(markdown);

    if (matches.isEmpty) {
      return '';
    }

    for (var match in matches.take(10)) { // 最多取前10个方法
      final signature = match.group(1);
      final description = match.group(2);
      buffer.writeln('  - `$signature` - $description');
    }

    return buffer.toString();
  }

  /// 获取数据分析工具列表
  static List<String> _getAnalysisTools() {
    final tools = <String>[];

    // 从 PluginAnalysisMethod 获取（如果可访问）
    // 这里先硬编码常用的分析方法
    tools.add('**diary_getDiaries** - 获取日记数据\n  参数: {startDate, endDate, mode}');
    tools.add('**bill_getBills** - 获取账单数据\n  参数: {startDate, endDate, type}');
    tools.add('**activity_getActivities** - 获取活动记录\n  参数: {startDate, endDate, tags}');

    return tools;
  }

  /// 后备工具 Prompt（当初始化失败时使用）
  static String _getFallbackToolPrompt() {
    return '''

## 🛠️ 可用工具列表

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

### 常用 API

**todo** (待办任务)
  - `Memento.todo.getTasks(status, priority)` - 获取任务
  - `Memento.todo.getTodayTasks()` - 获取今日任务

**notes** (笔记)
  - `Memento.notes.getNotes(params)` - 获取笔记

使用 `setResult()` 返回结果。
''';
  }
}
