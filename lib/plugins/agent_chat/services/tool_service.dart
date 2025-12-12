import 'dart:convert';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'tool_config_manager.dart';
import 'package:Memento/plugins/webview/services/js_tool_service.dart';

/// 模板修改策略
enum TemplateStrategy {
  /// 关键词替换 - 简单的字符串替换
  replace,
  /// 重写代码 - AI 根据需求重新生成代码
  rewrite,
}

/// 工具模版匹配结果
class TemplateMatch {
  final String id;
  final TemplateStrategy strategy;
  final List<ReplacementRule>? replacements;
  final List<Map<String, dynamic>>? rewrittenSteps;

  TemplateMatch({
    required this.id,
    this.strategy = TemplateStrategy.replace,
    this.replacements,
    this.rewrittenSteps,
  });

  factory TemplateMatch.fromJson(Map<String, dynamic> json) {
    final replacementsList = json['replacements'] as List<dynamic>?;
    final rewrittenStepsList = json['rewritten_steps'] as List<dynamic>?;
    final strategyStr = json['strategy'] as String? ?? 'replace';

    return TemplateMatch(
      id: json['id'] as String,
      strategy: strategyStr == 'rewrite'
          ? TemplateStrategy.rewrite
          : TemplateStrategy.replace,
      replacements: replacementsList
          ?.map((r) => ReplacementRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      rewrittenSteps: rewrittenStepsList
          ?.map((s) => s as Map<String, dynamic>)
          .toList(),
    );
  }
}

/// 参数替换规则
class ReplacementRule {
  final String from;
  final String to;

  ReplacementRule({required this.from, required this.to});

  factory ReplacementRule.fromJson(Map<String, dynamic> json) {
    return ReplacementRule(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }
}

/// 工具服务 - 负责工具调用的解析、执行和 Prompt 生成
class ToolService {
  static String? _cachedToolListPrompt;
  static String? _cachedToolBriefPrompt;
  static bool _initialized = false;

  /// 第零阶段 JSON Schema - 工具模版匹配
  static const Map<String, dynamic> toolTemplateMatchSchema = {
    'type': 'object',
    'properties': {
      'use_tool_temps': {
        'type': 'array',
        'description': '匹配的工具模版列表',
        'items': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': '模版ID',
            },
            'strategy': {
              'type': 'string',
              'enum': ['replace', 'rewrite'],
              'description': '修改策略：replace=关键词替换（简单参数变化），rewrite=重写代码（复杂逻辑变化）',
            },
            'replacements': {
              'type': 'array',
              'description': '需要替换的参数列表（strategy=replace时使用）',
              'items': {
                'type': 'object',
                'properties': {
                  'from': {
                    'type': 'string',
                    'description': '要替换的原始字符串',
                  },
                  'to': {
                    'type': 'string',
                    'description': '替换后的新字符串',
                  },
                },
                'required': ['from', 'to'],
                'additionalProperties': false,
              },
            },
            'rewritten_steps': {
              'type': 'array',
              'description': '重写后的代码步骤（strategy=rewrite时使用）',
              'items': {
                'type': 'object',
                'properties': {
                  'method': {
                    'type': 'string',
                    'enum': ['run_js'],
                    'description': '执行方法',
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
                    'description': 'JavaScript 代码',
                  },
                },
                'required': ['method', 'title', 'desc', 'data'],
                'additionalProperties': false,
              },
            },
          },
          'required': ['id', 'strategy'],
          'additionalProperties': false,
        },
      },
    },
    'required': ['use_tool_temps'],
    'additionalProperties': false,
  };

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

  /// 刷新工具缓存（当有新工具注册时调用）
  ///
  /// 此方法用于在 JS 工具动态注册后更新缓存，确保工具列表保持最新
  static Future<void> refreshCache() async {
    if (!_initialized) {
      print('[ToolService] 警告：工具服务未初始化，跳过刷新');
      return;
    }

    try {
      // 重新生成并缓存两种 Prompt
      _cachedToolBriefPrompt = _generateToolBriefPrompt();
      _cachedToolListPrompt = await _generateToolListPrompt();

      print('[ToolService] 缓存已刷新，当前加载了 ${_cachedToolBriefPrompt?.length ?? 0} 字符的简要索引');
    } catch (e) {
      print('[ToolService] 刷新缓存失败: $e');
    }
  }

  /// 检查内容是否包含工具调用 JSON
  static bool containsToolCall(String content) {
    // 使用通用JSON解析方法检查是否包含有效的工具调用
    final json = parseJsonFromResponse(content, requiredField: 'steps');
    if (json != null && json.containsKey('steps')) {
      try {
        final steps = json['steps'];
        return steps is List;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// 从 AI 回复中解析工具调用
  static ToolCallResponse? parseToolCallFromResponse(String response) {
    try {
      // 使用通用JSON解析方法
      final json = parseJsonFromResponse(response, requiredField: 'steps');

      if (json == null) {
        print('[ToolService] 未找到工具调用 JSON');
        return null;
      }

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
      // 检查是否是 JS 工具调用（格式：js_tool:<toolId>:<paramsJson>）
      if (jsCode.startsWith('js_tool:')) {
        return await _executeJsTool(jsCode);
      }

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

  /// 执行 JS 工具
  static Future<String> _executeJsTool(String jsCode) async {
    try {
      // 解析工具调用格式：js_tool:<toolId>:<paramsJson>
      final parts = jsCode.split(':');
      if (parts.length < 3) {
        throw Exception('无效的 JS 工具调用格式: $jsCode');
      }

      final toolId = parts[1];
      final paramsJson = parts.sublist(2).join(':'); // 重新组装剩余部分（防止 JSON 中包含冒号）
      final params = paramsJson.isNotEmpty ? json.decode(paramsJson) : {};

      // 通过 JSToolService 执行工具
      final jsToolService = JSToolService();
      final result = await jsToolService.executeTool(toolId, params);

      if (!result['success']) {
        throw Exception(result['error'] ?? '工具执行失败');
      }

      // 返回结果
      return json.encode(result['data'] ?? {});
    } catch (e) {
      print('[ToolService] JS 工具执行失败: $e');
      print('[ToolService] 调用代码: $jsCode');
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
    buffer.writeln('1. **当前时间**：你无法感知时间流逝，**绝对禁止**硬编码日期时间字符串（如 "2025-01-15"、"今天是1月15日"）');
    buffer.writeln('2. **用户数据**：所有用户的任务、笔记、日记等数据都存储在本地，必须使用插件工具获取');
    buffer.writeln('\n### 🚫 严格禁止的行为');
    buffer.writeln('1. **禁止硬编码日期时间**：');
    buffer.writeln('   - ❌ 错误：`const date = "2025-01-15"` 或 `const content = "今天是2025年1月15日"`');
    buffer.writeln('   - ✅ 正确：`const date = await Memento.system.getCustomDate({format: "yyyy-MM-dd"})`');
    buffer.writeln('2. **禁止使用占位符变量**：');
    buffer.writeln('   - ❌ 错误：`const channelId = "your_channel_id"` 或 `accountId: "请填入账户ID"`');
    buffer.writeln('   - ✅ 正确：先查询获取真实数据，然后使用实际的ID');
    buffer.writeln('   - ✅ 示例：`const channels = await Memento.plugins.chat.getChannels(); const firstChannel = channels[0]; await Memento.plugins.chat.sendMessage({channelId: firstChannel.id, content: "消息内容"})`');
    buffer.writeln('\n### 系统 API（在 JavaScript 代码中直接调用）');
    buffer.writeln('\n当需要时间或设备信息时，**必须在 JavaScript 代码中调用系统API**，不要作为单独的步骤：');
    buffer.writeln('\n#### 🌟 推荐：getCustomDate（解决时区问题）');
    buffer.writeln('- `await Memento.system.getCustomDate(options)` - **推荐使用**，一次调用解决所有日期需求');
    buffer.writeln('  - **options 参数**：');
    buffer.writeln('    - `baseDate`: 基准日期（时间戳或ISO字符串），默认当前时间');
    buffer.writeln('    - `timezone`: "local"（默认）或 "UTC"');
    buffer.writeln('    - `add`: 增加时间 `{days, hours, minutes, seconds, milliseconds}`');
    buffer.writeln('    - `subtract`: 减少时间 `{days, hours, minutes, seconds, milliseconds}`');
    buffer.writeln('    - `relativePosition`: 相对位置，可选值：');
    buffer.writeln('      - `startOfDay` / `endOfDay` - 当天凌晨/结束');
    buffer.writeln('      - `startOfHour` / `endOfHour` - 小时开始/结束');
    buffer.writeln('      - `startOfMonth` / `endOfMonth` - 月初/月末');
    buffer.writeln('      - `startOfWeek` / `endOfWeek` - 周一/周日');
    buffer.writeln('      - `startOfYear` / `endOfYear` - 年初/年末');
    buffer.writeln('    - `format`: 返回格式');
    buffer.writeln('      - `"object"`（默认）: 返回完整对象 `{timestamp, datetime, year, month, day, ...}`');
    buffer.writeln('      - `"timestamp"`: 仅返回时间戳');
    buffer.writeln('      - `"iso"`: 返回 ISO 8601 字符串');
    buffer.writeln('      - `"text"`: 返回相对时间（如"3天前"）');
    buffer.writeln('      - 自定义格式如 `"yyyy-MM-dd HH:mm:ss"`');
    buffer.writeln('\n  **使用示例**：');
    buffer.writeln('  ```javascript');
    buffer.writeln('  // 获取今天凌晨（解决时区问题）');
    buffer.writeln('  const todayStart = await Memento.system.getCustomDate({relativePosition: "startOfDay"});');
    buffer.writeln('  ');
    buffer.writeln('  // 获取明天凌晨的时间戳');
    buffer.writeln('  const tomorrowStart = await Memento.system.getCustomDate({');
    buffer.writeln('    add: {days: 1},');
    buffer.writeln('    relativePosition: "startOfDay",');
    buffer.writeln('    format: "timestamp"');
    buffer.writeln('  });');
    buffer.writeln('  ');
    buffer.writeln('  // 获取本周一凌晨');
    buffer.writeln('  const weekStart = await Memento.system.getCustomDate({relativePosition: "startOfWeek"});');
    buffer.writeln('  ');
    buffer.writeln('  // 获取3天前的日期，格式化输出');
    buffer.writeln('  const threeDaysAgo = await Memento.system.getCustomDate({');
    buffer.writeln('    subtract: {days: 3},');
    buffer.writeln('    format: "yyyy-MM-dd"');
    buffer.writeln('  });');
    buffer.writeln('  ```');
    buffer.writeln('\n#### 其他时间 API');
    buffer.writeln('- `await Memento.system.getCurrentTime()` - 获取当前时间，返回 `{timestamp, datetime, year, month, day, hour, minute, second, weekday, weekdayName}`');
    buffer.writeln('- `await Memento.system.getTimestamp()` - 获取当前时间戳（毫秒）');
    buffer.writeln('- `await Memento.system.formatDate(dateInput, format)` - 格式化日期');
    buffer.writeln('\n#### 设备与应用信息');
    buffer.writeln('- `await Memento.system.getDeviceInfo()` - 获取设备信息');
    buffer.writeln('- `await Memento.system.getAppInfo()` - 获取应用信息');
    buffer.writeln('\n### 步骤间结果传递 API（多步骤协作）\n');
    buffer.writeln('当工具调用包含多个步骤时，可以使用以下 API 在步骤之间传递数据：\n');
    buffer.writeln('#### ⚠️ 强制要求：必须使用对象类型\n');
    buffer.writeln('- **setResult 必须传入对象**：value 参数必须是对象类型 `{}`，不能是原始值或数组');
    buffer.writeln('- **getResult 返回对象**：返回值永远是对象类型，通过属性访问数据\n');
    buffer.writeln('#### API 说明\n');
    buffer.writeln('- `await Memento.toolCall.setResult({id?, value})` - 保存结果供后续步骤使用');
    buffer.writeln('  - `id` (可选): 自定义结果 ID，如 "userData"、"taskList"');
    buffer.writeln('  - `value` (必需): **必须是对象** `{key: value}`，不能是数组或原始值');
    buffer.writeln('- `await Memento.toolCall.getResult({id?, step?, default?})` - 获取之前步骤的结果');
    buffer.writeln('  - `id` (可选): 结果 ID');
    buffer.writeln('  - `step` (可选): 步骤索引（从 0 开始），如 `{step: 0}` 获取第一个步骤的结果');
    buffer.writeln('  - `default` (可选): 默认值，结果不存在时返回');
    buffer.writeln('  - **返回值**: 永远是对象类型，通过 `result.propertyName` 访问数据');
    buffer.writeln('\n**自动保存**：每个步骤执行成功后，结果会自动保存到 `step_N`（N 为步骤索引）');
    buffer.writeln('\n**🚫 错误示例（禁止）**:');
    buffer.writeln('```javascript');
    buffer.writeln('// ❌ 错误：setResult 传入数组');
    buffer.writeln('const tasks = await Memento.plugins.todo.getTasks();');
    buffer.writeln('await Memento.toolCall.setResult({value: tasks}); // 错误！tasks 是数组');
    buffer.writeln('');
    buffer.writeln('// ❌ 错误：getResult 当作数组使用');
    buffer.writeln('const tasks = await Memento.toolCall.getResult({step: 0});');
    buffer.writeln('if (tasks.length > 0) { ... } // 错误！tasks 是对象不是数组');
    buffer.writeln('```\n');
    buffer.writeln('**✅ 正确示例（必须遵循）**:');
    buffer.writeln('```javascript');
    buffer.writeln('// ✅ 正确：setResult 传入对象，用属性包装数据');
    buffer.writeln('const tasks = await Memento.plugins.todo.getTasks();');
    buffer.writeln('await Memento.toolCall.setResult({value: {tasks, count: tasks.length}}); // 正确！');
    buffer.writeln('');
    buffer.writeln('// ✅ 正确：getResult 返回对象，通过属性访问');
    buffer.writeln('const result = await Memento.toolCall.getResult({step: 0});');
    buffer.writeln('if (result.tasks && result.tasks.length > 0) { ... } // 正确！');
    buffer.writeln('```');
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

    // 添加插件别名映射
    buffer.write(ToolConfigManager.generatePluginAliasesPrompt());

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
    buffer.writeln(r'      "data": "const today = await Memento.system.getCustomDate(); const tasks = await Memento.plugins.todo.getTodayTasks(); const result = `今天是${today.month}月${today.day}日，有 ${tasks.length} 个任务`; setResult(result); return result;"');
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
    buffer.writeln('**示例 4：步骤间数据传递（查询→分析→生成报告）**\n');
    buffer.writeln('使用 setResult/getResult 在步骤之间传递数据（⚠️ 必须使用对象类型）：\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "查询今日任务",');
    buffer.writeln('      "desc": "获取今天的任务列表",');
    final step1Example = '''const tasks = await Memento.plugins.todo.getTodayTasks(); await Memento.toolCall.setResult({id: 'todayTasks', value: {tasks, count: tasks.length}}); return `已获取 \${tasks.length} 个任务`;''';
    buffer.writeln('      "data": "${step1Example.replaceAll('"', '\\"')}"');
    buffer.writeln('    },');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "统计任务情况",');
    buffer.writeln('      "desc": "分析任务完成情况",');
    final step2Example = '''const result = await Memento.toolCall.getResult({id: 'todayTasks'}); const tasks = result.tasks; const completed = tasks.filter(t => t.completed).length; const rate = (completed / tasks.length * 100).toFixed(1); return `完成率: \${rate}%`;''';
    buffer.writeln('      "data": "${step2Example.replaceAll('"', '\\"')}"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');
    buffer.writeln('**示例 5：多步骤操作链（查询条件+创建）**\n');
    buffer.writeln('当用户说"创建明天的任务"时，直接完成创建，不要询问确认：\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "steps": [');
    buffer.writeln('    {');
    buffer.writeln('      "method": "run_js",');
    buffer.writeln('      "title": "创建明天的任务",');
    buffer.writeln('      "desc": "获取明天日期并创建任务",');
    final createTaskExample = '''const tomorrow = await Memento.system.getCustomDate({add: {days: 1}, relativePosition: 'startOfDay', format: 'timestamp'}); const result = await Memento.plugins.todo.createTask('New Task', { dueDate: tomorrow }); const msg = result.success ? 'Task created successfully' : 'Failed to create task'; setResult(msg); return msg;''';
    buffer.writeln('      "data": "${createTaskExample.replaceAll('"', '\\"')}"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```\n');

    buffer.writeln('### ⚠️ 注意事项\n');
    buffer.writeln('1. **🚫 绝对禁止硬编码日期时间**：任何涉及日期时间的代码，推荐使用 `await Memento.system.getCustomDate(options)` 获取和处理时间');
    buffer.writeln('   - 生成日记内容时，使用系统API获取的真实日期，不要使用你知识中的日期');
    buffer.writeln('   - 创建任务、账单等需要日期的操作，都必须先调用系统API');
    buffer.writeln('2. **🚫 绝对禁止使用占位符**：不允许使用 "your_xxx_id"、"请填入xxx" 等占位符');
    buffer.writeln('   - 如果用户未指定ID，优先遍历已有数据选择合适的（第一个、最近的、符合条件的）');
    buffer.writeln('   - 如果没有数据，应该先创建数据再执行操作，或者返回明确的错误提示');
    buffer.writeln('3. **系统 API 直接调用**: `Memento.system.*` API 不需要作为单独的工具步骤，直接在代码中调用');
    buffer.writeln('4. **返回结果**: JavaScript 代码必须先调用 `setResult(result)` 设置返回值，然后 `return result`');
    buffer.writeln('5. **JSON 字符串转义**: data 字段中的 JavaScript 代码需要正确转义引号');
    buffer.writeln('6. **异步操作**: 所有插件方法都是异步的，必须使用 `await`\n');

    return buffer.toString();
  }

  /// 后备工具 Prompt（当初始化失败时使用）
  static String _getFallbackToolPrompt() {
    return r'''

## 🛠️ 可用工具列表

### ⚠️ 重要提示

作为 AI 助手，你**无法直接获取**以下类型的信息：
1. **当前时间**：你无法感知时间流逝，**绝对禁止**硬编码日期时间字符串（如 "2025-01-15"、"今天是1月15日"）
2. **用户数据**：所有用户的任务、笔记、日记等数据都存储在本地，必须使用插件工具获取

### 🚫 严格禁止的行为
1. **禁止硬编码日期时间**：
   - ❌ 错误：`const date = "2025-01-15"` 或 `const content = "今天是2025年1月15日"`
   - ✅ 正确：`const date = await Memento.system.getCustomDate({format: "yyyy-MM-dd"})`
2. **禁止使用占位符变量**：
   - ❌ 错误：`const channelId = "your_channel_id"` 或 `accountId: "请填入账户ID"`
   - ✅ 正确：先查询获取真实数据，然后使用实际的ID
   - ✅ 策略：用户未指定时，优先选择第一个、最近的、或符合条件的数据
   - ✅ 策略：如果没有可用数据，先创建数据再执行操作，或返回明确错误

### 系统 API（在 JavaScript 代码中直接调用）

当需要时间或设备信息时，**必须在 JavaScript 代码中调用系统API**，不要作为单独的步骤：
- `await Memento.system.getCustomDate(options)` - **推荐使用**，一次调用解决所有日期需求
  - options: `{baseDate?, timezone?, add?, subtract?, relativePosition?, format?}`
  - relativePosition: "startOfDay"、"endOfDay"、"startOfWeek"、"startOfMonth" 等
  - format: "object"(默认)、"timestamp"、"iso"、"text" 或自定义格式
- `await Memento.system.getCurrentTime()` - 获取当前时间，返回 `{timestamp, datetime, year, month, day, ...}`
- `await Memento.system.getTimestamp()` - 获取当前时间戳（毫秒）
- `await Memento.system.formatDate(dateInput, format)` - 格式化日期
- `await Memento.system.getDeviceInfo()` - 获取设备信息
- `await Memento.system.getAppInfo()` - 获取应用信息

### 步骤间结果传递 API（多步骤协作）

当工具调用包含多个步骤时，可以使用以下 API 在步骤之间传递数据：

#### ⚠️ 强制要求：必须使用对象类型

- **setResult 必须传入对象**：value 参数必须是对象类型 `{}`，不能是原始值或数组
- **getResult 返回对象**：返回值永远是对象类型，通过属性访问数据

#### API 说明

- `await Memento.toolCall.setResult({id?, value})` - 保存结果供后续步骤使用
  - `id` (可选): 自定义结果 ID
  - `value` (必需): **必须是对象** `{key: value}`，不能是数组或原始值
- `await Memento.toolCall.getResult({id?, step?, default?})` - 获取之前步骤的结果
  - `id` (可选): 结果 ID
  - `step` (可选): 步骤索引（从 0 开始）
  - `default` (可选): 默认值
  - **返回值**: 永远是对象类型，通过 `result.propertyName` 访问数据

**自动保存**：每个步骤执行成功后，结果会自动保存到 `step_N`

**🚫 错误示例（禁止）**:
```javascript
// ❌ 错误：setResult 传入数组
const tasks = await Memento.plugins.todo.getTasks();
await Memento.toolCall.setResult({value: tasks}); // 错误！tasks 是数组

// ❌ 错误：getResult 当作数组使用
const tasks = await Memento.toolCall.getResult({step: 0});
if (tasks.length > 0) { ... } // 错误！tasks 是对象不是数组
```

**✅ 正确示例（必须遵循）**:
```javascript
// ✅ 正确：setResult 传入对象，用属性包装数据
const tasks = await Memento.plugins.todo.getTasks();
await Memento.toolCall.setResult({value: {tasks, count: tasks.length}}); // 正确！

// ✅ 正确：getResult 返回对象，通过属性访问
const result = await Memento.toolCall.getResult({step: 0});
if (result.tasks && result.tasks.length > 0) { ... } // 正确！
```

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
const today = await Memento.system.getCustomDate();
const tasks = await Memento.plugins.todo.getTodayTasks();
const result = `今天是 ${today.month}月${today.day}日，有 ${tasks.length} 个任务`;
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

    // 添加字段过滤机制说明
    buffer.writeln('### ⚙️ 字段过滤机制（减少 Token 消耗）\n');
    buffer.writeln('**所有返回数据的插件方法**都支持以下可选参数来优化返回的数据量：\n');
    buffer.writeln('#### 参数说明\n');
    buffer.writeln('1. **mode** (字符串): 数据模式');
    buffer.writeln('   - `"summary"` 或 `"s"`: 仅返回统计数据（推荐：最省 Token）');
    buffer.writeln('   - `"compact"` 或 `"c"`: 返回简化字段的记录列表（平衡）');
    buffer.writeln('   - `"full"` 或 `"f"`: 返回完整数据（默认）');
    buffer.writeln('');
    buffer.writeln('2. **fields** (数组): 直接指定返回字段（优先级高于 mode）');
    buffer.writeln('   - 示例: `fields: ["id", "title", "start", "end"]`');
    buffer.writeln('   - 只返回指定字段，其他字段忽略\n');
    buffer.writeln('#### 使用建议\n');
    buffer.writeln('- 当只需要统计时，使用 `mode: "summary"`');
    buffer.writeln('- 当需要列表但不需要详细描述时，使用 `mode: "compact"`');
    buffer.writeln('- 当需要特定字段时，使用 `fields: [...]`');
    buffer.writeln('- Token 节省比例：summary(90%) > compact(75%) > full(0%)\n');
    buffer.writeln('#### 使用示例\n');
    buffer.writeln('```javascript');
    buffer.writeln('// 示例1: 使用 mode 参数获取摘要数据（最省 Token）');
    buffer.writeln('const summary = await Memento.plugins.activity.getActivities({');
    buffer.writeln('  startDate: "2025-01-01",');
    buffer.writeln('  endDate: "2025-01-31",');
    buffer.writeln('  mode: "summary"  // 仅返回统计数据');
    buffer.writeln('});');
    buffer.writeln('// 返回: { sum: { total: 50, dur: 3600, avg: 72 } }\n');
    buffer.writeln('// 示例2: 使用 fields 参数指定返回字段');
    buffer.writeln('const compactData = await Memento.plugins.activity.getActivities({');
    buffer.writeln('  startDate: "2025-01-01",');
    buffer.writeln('  endDate: "2025-01-31",');
    buffer.writeln('  fields: ["id", "title", "start", "end", "dur"]  // 只返回这些字段');
    buffer.writeln('});');
    buffer.writeln('// 返回: { recs: [{ id, title, start, end, dur }, ...] }');
    buffer.writeln('```\n');
    buffer.writeln('---\n');

    buffer.writeln('### 🚫 严格禁止的行为\n');
    buffer.writeln('1. **绝对禁止硬编码日期时间**：');
    buffer.writeln('   - ❌ 错误：`const date = "2025-01-15"` 或 `const content = "今天是2025年1月15日"`');
    buffer.writeln('   - ❌ 错误：在生成日记内容、任务标题等地方使用你知识中的日期');
    buffer.writeln('   - ✅ 正确：`const date = await Memento.system.getCustomDate({format: "yyyy-MM-dd"})`');
    buffer.writeln('   - ✅ 正确：在生成的内容中使用系统API返回的真实日期');
    buffer.writeln('2. **绝对禁止使用占位符变量**：');
    buffer.writeln('   - ❌ 错误：`const channelId = "your_channel_id"` 或 `accountId: "请填入账户ID"`');
    buffer.writeln('   - ✅ 正确：`const channels = await Memento.plugins.chat.getChannels(); if (channels.length > 0) { const channelId = channels[0].id; ... }`');
    buffer.writeln('   - ✅ 策略：用户未指定时，优先选择第一个、最近的、或符合条件的数据');
    buffer.writeln('   - ✅ 策略：如果没有可用数据，先创建数据再执行操作，或返回明确错误\n');

    buffer.writeln('### 系统 API（始终可用）\n');
    buffer.writeln('在生成的 JavaScript 代码中，你**必须使用**以下系统 API 获取时间信息：\n');
    buffer.writeln('- `await Memento.system.getCustomDate(options)` - **推荐使用，解决时区问题**');
    buffer.writeln('  - options: `{baseDate?, timezone?, add?, subtract?, relativePosition?, format?}`');
    buffer.writeln('  - relativePosition: "startOfDay"、"endOfDay"、"startOfWeek"、"startOfMonth" 等');
    buffer.writeln('  - format: "object"、"timestamp"、"iso"、"text" 或自定义格式如 "yyyy-MM-dd"');
    buffer.writeln('  - 示例：`await Memento.system.getCustomDate({relativePosition: "startOfDay", format: "timestamp"})`');
    buffer.writeln('- `await Memento.system.getCurrentTime()` - 获取当前时间');
    buffer.writeln('  - 返回：`{ timestamp, datetime, year, month, day, hour, minute, second, weekday, weekdayName }`');
    buffer.writeln('- `await Memento.system.getTimestamp()` - 获取当前时间戳（毫秒）');
    buffer.writeln('- `await Memento.system.formatDate(dateInput, format)` - 格式化日期');
    buffer.writeln('  - dateInput: 时间戳（毫秒）或 ISO 字符串');
    buffer.writeln('  - format: 格式模板，如 "yyyy-MM-dd HH:mm:ss"');
    buffer.writeln('- `await Memento.system.getDeviceInfo()` - 获取设备信息');
    buffer.writeln('- `await Memento.system.getAppInfo()` - 获取应用信息\n');
    buffer.writeln('⚠️ **重要**：不要将系统 API 作为单独的步骤，而是在需要时直接在代码中调用！\n');
    buffer.writeln('### 步骤间结果传递 API（多步骤数据共享）\n');
    buffer.writeln('当需要在多个步骤之间传递数据时，使用以下 API：\n');
    buffer.writeln('#### ⚠️ 强制要求：必须使用对象类型\n');
    buffer.writeln('- **setResult 必须传入对象**：value 参数必须是对象类型 `{}`，不能是原始值或数组');
    buffer.writeln('- **getResult 返回对象**：返回值永远是对象类型，通过属性访问数据\n');
    buffer.writeln('**设置结果**：');
    buffer.writeln('```javascript');
    buffer.writeln('await Memento.toolCall.setResult({');
    buffer.writeln('  id: "myData",    // 可选：自定义 ID');
    buffer.writeln('  value: {data: dataObj}   // 必需：必须是对象，用属性包装数据');
    buffer.writeln('});');
    buffer.writeln('```\n');
    buffer.writeln('**获取结果**：');
    buffer.writeln('```javascript');
    buffer.writeln('// 方式1: 通过自定义 ID');
    buffer.writeln('const result = await Memento.toolCall.getResult({id: "myData"});');
    buffer.writeln('const data = result.data; // 通过属性访问');
    buffer.writeln('');
    buffer.writeln('// 方式2: 通过步骤索引（0 = 第一个步骤）');
    buffer.writeln('const prevResult = await Memento.toolCall.getResult({step: 0});');
    buffer.writeln('const tasks = prevResult.tasks; // 通过属性访问数组');
    buffer.writeln('');
    buffer.writeln('// 方式3: 带默认值（防止获取失败）');
    buffer.writeln('const config = await Memento.toolCall.getResult({');
    buffer.writeln('  id: "config",');
    buffer.writeln('  default: {theme: "light"}');
    buffer.writeln('});');
    buffer.writeln('```\n');
    buffer.writeln('**🚫 错误示例（禁止）**:');
    buffer.writeln('```javascript');
    buffer.writeln('// ❌ 错误：setResult 传入数组');
    buffer.writeln('const tasks = await Memento.plugins.todo.getTasks();');
    buffer.writeln('await Memento.toolCall.setResult({id: "tasks", value: tasks}); // 错误！tasks 是数组');
    buffer.writeln('');
    buffer.writeln('// ❌ 错误：getResult 当作数组使用');
    buffer.writeln('const tasks = await Memento.toolCall.getResult({id: "tasks"});');
    buffer.writeln('if (tasks.length > 0) { ... } // 错误！tasks 是对象不是数组');
    buffer.writeln('```\n');
    buffer.writeln('**✅ 正确示例（必须遵循）**:');
    buffer.writeln('```javascript');
    buffer.writeln('// ✅ 正确：setResult 传入对象，用属性包装数据');
    buffer.writeln('const tasks = await Memento.plugins.todo.getTasks();');
    buffer.writeln('await Memento.toolCall.setResult({id: "taskData", value: {tasks, count: tasks.length}}); // 正确！');
    buffer.writeln('');
    buffer.writeln('// ✅ 正确：getResult 返回对象，通过属性访问');
    buffer.writeln('const result = await Memento.toolCall.getResult({id: "taskData"});');
    buffer.writeln('if (result.tasks && result.tasks.length > 0) { ... } // 正确！');
    buffer.writeln('```\n');
    buffer.writeln('**自动保存**：每个步骤的结果会自动保存到 `step_N`，可直接通过索引获取。\n');

    // 添加插件别名映射
    buffer.write(ToolConfigManager.generatePluginAliasesPrompt());

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
      // 使用通用JSON解析方法
      final json = parseJsonFromResponse(response, requiredField: 'needed_tools');

      if (json == null || !json.containsKey('needed_tools')) {
        return null;
      }

      final tools = json['needed_tools'] as List<dynamic>;
      return tools.map((e) => e.toString()).toList();
    } catch (e) {
      print('[ToolService] 解析工具需求失败: $e');
      return null;
    }
  }

  // ==================== 工具模版匹配支持（第零阶段）====================

  /// 生成工具模版列表 Prompt（第零阶段）
  ///
  /// 参数：
  /// - templates: 工具模版列表（需要从 ToolTemplateService 获取）
  ///
  /// 返回格式化的模版列表字符串，用于让 AI 匹配合适的模版
  static String getToolTemplatePrompt(List<dynamic> templates) {
    if (templates.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n## 📋 可用工具模版');
    buffer.writeln('\n以下是已保存的工具模版列表。请分析用户的需求，判断是否有合适的模版可以使用。');
    buffer.writeln('\n### 🎯 双策略选择');
    buffer.writeln('你需要根据用户需求与模版的差异程度选择合适的修改策略：\n');
    buffer.writeln('**策略1: `replace` - 关键词替换**（优先选择）');
    buffer.writeln('- 适用场景：功能相同，只是参数/名称不同');
    buffer.writeln('- 示例：模版"签到早起"→用户输入"签到早睡"，只需替换"早起"→"早睡"');
    buffer.writeln('- 返回：`{"id": "xxx", "strategy": "replace", "replacements": [{"from": "早起", "to": "早睡"}]}`\n');
    buffer.writeln('**策略2: `rewrite` - 重写代码**');
    buffer.writeln('- 适用场景：逻辑需要修改，简单替换无法满足');
    buffer.writeln('- 示例：模版"记录跑步5公里"→用户输入"记录游泳30分钟"（单位和逻辑都不同）');
    buffer.writeln('- 返回：`{"id": "xxx", "strategy": "rewrite", "rewritten_steps": [...]}`\n');
    buffer.writeln('### 📝 返回格式\n');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "use_tool_temps": [');
    buffer.writeln('    {');
    buffer.writeln('      "id": "template_id",');
    buffer.writeln('      "strategy": "replace",  // 或 "rewrite"');
    buffer.writeln('      "replacements": [{"from": "原字符串", "to": "新字符串"}],  // strategy=replace时');
    buffer.writeln('      "rewritten_steps": [...]  // strategy=rewrite时');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('\n如果没有合适的模版，返回空数组：');
    buffer.writeln('```json');
    buffer.writeln('{"use_tool_temps": []}');
    buffer.writeln('```\n');
    buffer.writeln('### 工具模版列表\n');

    // 格式化模版列表为 [['id', 'title', 'desc'], ...]
    for (final template in templates) {
      // template 可能是 SavedToolTemplate 对象，需要访问其属性
      final id = template.id ?? 'unknown';
      final name = template.name ?? '未命名模版';
      final description = template.description ?? '无描述';

      buffer.writeln('**$id**: $name');
      buffer.writeln('  描述: $description');

      // 显示声明的工具
      if (template.declaredTools != null && template.declaredTools.isNotEmpty) {
        final toolNames = template.declaredTools
            .map((t) => t['toolName'] ?? t['toolId'])
            .join(', ');
        buffer.writeln('  使用工具: $toolNames');
      }

      // 🔍 添加代码预览（前2个步骤，每个步骤最多200字符）
      if (template.steps != null && template.steps.isNotEmpty) {
        buffer.writeln('  代码预览:');
        for (int i = 0; i < template.steps.length && i < 2; i++) {
          final step = template.steps[i];
          final code = step.data.length > 200
              ? '${step.data.substring(0, 200)}...'
              : step.data;
          // 转义代码中的特殊字符，避免破坏 Markdown 格式
          final escapedCode = code
              .replaceAll('`', '\\`')
              .replaceAll('\n', ' ');
          buffer.writeln('    - ${step.title}: `$escapedCode`');
        }
      }

      buffer.writeln();
    }

    buffer.writeln('### 匹配规则\n');
    buffer.writeln('1. **完全匹配**：用户需求与模版完全一致');
    buffer.writeln('   → `{"id": "xxx", "strategy": "replace", "replacements": []}`\n');
    buffer.writeln('2. **参数化匹配**：功能相同但参数不同（优先使用 replace 策略）');
    buffer.writeln('   - 示例：模版"签到早起"，代码中有 `i.name === "早起"`，用户输入"签到早睡"');
    buffer.writeln('   → `{"id": "xxx", "strategy": "replace", "replacements": [{"from": "早起", "to": "早睡"}]}`\n');
    buffer.writeln('3. **逻辑变更**：需要修改代码逻辑（使用 rewrite 策略）');
    buffer.writeln('   - 示例：原模版记录"个数"，用户想改成记录"时长"');
    buffer.writeln('   → `{"id": "xxx", "strategy": "rewrite", "rewritten_steps": [...]}`\n');
    buffer.writeln('4. **多模版**：可以返回多个模版（如果用户需求可以拆分为多个任务）');
    buffer.writeln('5. **无匹配**：不确定或没有合适的模版 → 返回空数组');
    buffer.writeln('6. **优先级**：replace > rewrite（能用替换解决的就不要重写）\n');
    buffer.writeln('⚠️ **重要**：');
    buffer.writeln('- `strategy` 字段**必填**，必须是 "replace" 或 "rewrite"');
    buffer.writeln('- replacements 中的 `from` 必须是**代码预览中实际存在**的精确字符串');
    buffer.writeln('- rewritten_steps 需要完整的代码步骤，参考原模版的代码结构');

    return buffer.toString();
  }

  /// 从AI响应中提取JSON字符串（通用方法）
  ///
  /// 支持以下格式：
  /// 1. ```json {...}``` 代码块
  /// 2. 直接的JSON对象（需要提供必填字段名用于匹配）
  /// 3. 整个响应就是JSON（作为最后尝试）
  ///
  /// 参数：
  /// - [response]: AI的完整响应
  /// - [requiredField]: 用于匹配直接JSON的必填字段名（如 "use_tool_temps", "strategy", "steps"）
  ///
  /// 返回提取的JSON字符串，如果提取失败返回null
  static String? extractJsonFromResponse(String response, {String? requiredField}) {
    // 1. 尝试从 ```json ... ``` 代码块中提取
    final jsonBlockMatch = RegExp(
      r'```json\s*(\{[\s\S]*?\})\s*```',
      multiLine: true,
    ).firstMatch(response);

    if (jsonBlockMatch != null) {
      return jsonBlockMatch.group(1);
    }

    // 2. 如果提供了必填字段名，尝试提取直接的JSON对象
    if (requiredField != null) {
      // 构建正则表达式匹配包含必填字段的JSON对象
      final pattern = r'\{\s*"' + RegExp.escape(requiredField) + r'\s*:[\s\S]*?\}';
      final directJsonMatch = RegExp(pattern, multiLine: true).firstMatch(response);
      if (directJsonMatch != null) {
        return directJsonMatch.group(0);
      }
    }

    // 3. 尝试提取第一个JSON对象（通用匹配）
    final genericJsonMatch = RegExp(r'\{[\s\S]*?\}', multiLine: true).firstMatch(response);
    if (genericJsonMatch != null) {
      return genericJsonMatch.group(0);
    }

    return null;
  }

  /// 修复常见的AI返回JSON格式错误
  static String _fixInvalidJson(String jsonStr) {
    // 尝试先解析，如果成功则不需要修复
    try {
      jsonDecode(jsonStr);
      return jsonStr;
    } catch (_) {
      // 继续修复
    }

    // 修复模式：将 JSON 对象中单引号包裹的字符串值转为双引号
    // 例如：{"from": '早起', "to": '晨跑'} -> {"from": "早起", "to": "晨跑"}
    final buffer = StringBuffer();
    bool inDoubleQuote = false;
    bool inSingleQuote = false;
    bool escaped = false;

    for (int i = 0; i < jsonStr.length; i++) {
      final char = jsonStr[i];

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        buffer.write(char);
        continue;
      }

      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        buffer.write(char);
      } else if (char == "'" && !inDoubleQuote) {
        // 单引号转双引号
        inSingleQuote = !inSingleQuote;
        buffer.write('"');
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  /// 解析 AI 返回的工具模版匹配结果
  static List<TemplateMatch>? parseToolTemplateMatch(String response) {
    try {
      // 使用通用JSON提取方法
      final jsonStr = extractJsonFromResponse(response, requiredField: 'use_tool_temps');

      if (jsonStr == null) {
        print('[ToolService] 未找到工具模版匹配 JSON');
        return null;
      }

      // 修复JSON格式错误并解析
      final fixedJsonStr = _fixInvalidJson(jsonStr);
      final json = jsonDecode(fixedJsonStr) as Map<String, dynamic>;
      if (!json.containsKey('use_tool_temps')) {
        print('[ToolService] JSON 中缺少 use_tool_temps 字段');
        return null;
      }

      final templates = json['use_tool_temps'] as List<dynamic>;
      final matches = templates.map((e) {
        if (e is String) {
          // 兼容旧格式（只有ID）
          return TemplateMatch(id: e);
        } else if (e is Map<String, dynamic>) {
          // 新格式（包含replacements）
          return TemplateMatch.fromJson(e);
        } else {
          throw Exception('无效的模版匹配格式');
        }
      }).toList();

      print('[ToolService] 成功解析工具模版匹配，匹配到 ${matches.length} 个模版');
      for (var match in matches) {
        if (match.replacements != null && match.replacements!.isNotEmpty) {
          print('[ToolService]   - ${match.id}: ${match.replacements!.length} 个参数替换');
        }
      }
      return matches;

    } catch (e) {
      print('[ToolService] 解析工具模版匹配失败: $e');
      return null;
    }
  }

  /// 应用参数替换到模版步骤
  static List<ToolCallStep> applyReplacements(
    List<ToolCallStep> steps,
    List<ReplacementRule> replacements,
  ) {
    if (replacements.isEmpty) return steps;

    return steps.map((step) {
      String newData = step.data;
      String newTitle = step.title;
      String newDesc = step.desc;

      // 对每个替换规则应用到代码、标题、描述
      for (var rule in replacements) {
        newData = newData.replaceAll(rule.from, rule.to);
        newTitle = newTitle.replaceAll(rule.from, rule.to);
        newDesc = newDesc.replaceAll(rule.from, rule.to);
      }

      // 创建新的步骤对象
      return ToolCallStep(
        method: step.method,
        title: newTitle,
        desc: newDesc,
        data: newData,
      );
    }).toList();
  }

  /// 通用JSON解析方法（带格式修复）
  ///
  /// 参数：
  /// - [response]: AI的完整响应
  /// - [requiredField]: 用于匹配的必填字段名
  ///
  /// 返回解析后的JSON对象，解析失败返回null
  static Map<String, dynamic>? parseJsonFromResponse(String response, {String? requiredField}) {
    try {
      // 使用通用JSON提取方法
      final jsonStr = extractJsonFromResponse(response, requiredField: requiredField);

      if (jsonStr == null) {
        print('[ToolService] 未找到JSON');
        return null;
      }

      // 修复JSON格式错误并解析
      final fixedJsonStr = _fixInvalidJson(jsonStr);
      return jsonDecode(fixedJsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('[ToolService] JSON解析失败: $e');
      return null;
    }
  }
}
