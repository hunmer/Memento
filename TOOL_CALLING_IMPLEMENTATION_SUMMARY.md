# 工具调用功能实施完成总结

## 📋 项目概述

**功能名称**: AI 聊天插件功能调用（Tool Calling）

**实施时间**: 2025-01-16

**目标**: 允许 AI 通过工具调用机制动态执行插件方法，获取用户数据并基于数据生成智能回复。

---

## ✅ 完成的工作

### 阶段 1：数据模型层

#### 1.1 工具调用数据模型
**文件**: `lib/plugins/agent_chat/models/tool_call_step.dart`

创建了完整的工具调用数据结构：

- `ToolCallStep`: 单个工具调用步骤
  - `method`: 方法类型（目前仅支持 `run_js`）
  - `title`: 步骤标题
  - `desc`: 步骤描述
  - `data`: JavaScript 代码
  - `status`: 执行状态（pending/running/success/failed）
  - `result`: 执行结果
  - `error`: 错误信息

- `ToolCallResponse`: 工具调用响应
  - `steps`: 步骤列表
  - 便捷方法：`allSuccess`, `hasFailure`, `successResults`

- `ToolCallStatus`: 枚举类型（pending/running/success/failed）

#### 1.2 ChatMessage 扩展
**文件**: `lib/plugins/agent_chat/models/chat_message.dart`

- 添加 `ToolCallResponse? toolCall` 字段
- 更新 `fromJson`, `toJson`, `copyWith` 方法

#### 1.3 AIAgent 扩展
**文件**: `lib/plugins/openai/models/ai_agent.dart`

- 添加 `bool enableFunctionCalling` 字段（默认 false）
- 更新所有相关方法以支持该字段

---

### 阶段 2：核心服务层

#### 2.1 工具服务
**文件**: `lib/plugins/agent_chat/services/tool_service.dart`

**核心功能**：

1. **初始化** (`initialize`)
   - 加载所有 JS API 文档（从 `assets/jsapi/` 目录）
   - 生成工具列表 Prompt 供 AI 使用
   - 缓存工具列表避免重复生成

2. **工具调用检测** (`containsToolCall`)
   - 使用正则表达式检测 AI 响应中是否包含工具调用 JSON
   - 支持 Markdown 代码块和纯文本格式

3. **JSON 解析** (`parseToolCallFromResponse`)
   - 从 AI 响应中提取 JSON
   - 支持 ```json 代码块和纯 JSON
   - 解析为 `ToolCallResponse` 对象

4. **JS 代码执行** (`executeJsCode`)
   - 包装用户代码，注入 `callPluginAnalysis` 支持
   - 通过 `JSBridgeManager` 执行
   - 返回执行结果或错误

5. **工具列表生成** (`getToolListPrompt`)
   - 将所有插件方法格式化为 Markdown
   - 包含方法签名、参数、返回值、示例
   - 添加工具调用格式说明

**实现亮点**：
- ✅ 支持多种 JSON 格式提取
- ✅ 详细的错误处理
- ✅ 高效的工具列表缓存
- ✅ 完整的 JS 代码包装

---

### 阶段 3：JS 执行基础设施

#### 3.1 移动端 JS 引擎
**文件**: `lib/core/js_bridge/platform/mobile_js_engine.dart`

**修改内容**：

1. **全局函数注入** (第 168-179 行)
   ```javascript
   globalThis.callPluginAnalysis = function(methodName, params) {
     var callId = Date.now() + '_' + Math.floor(Math.random() * 1000000);
     var resultKey = '_callPluginAnalysis_callback_' + callId;
     var config = {
       methodName: String(methodName),
       params: params || {}
     };
     sendMessage('_callPluginAnalysis', JSON.stringify({ callId, config }));
     return new Promise(function(resolve, reject) {
       globalThis.__PENDING_CALLS__[resultKey].resolve = resolve;
       globalThis.__PENDING_CALLS__[resultKey].reject = reject;
     });
   };
   ```

2. **消息处理器** (第 789-837 行)
   - `_callPluginAnalysis`: 调用 Dart 端的插件分析方法
   - `_returnPluginAnalysisResult`: 将结果返回给 JS Promise

3. **处理器注册** (第 824-829 行)
   - `setPluginAnalysisHandler`: 允许外部注册插件分析处理逻辑

**工作原理**：
```
JS Code
  ↓
callPluginAnalysis(method, params)
  ↓
sendMessage('_callPluginAnalysis')
  ↓
Dart: _onPluginAnalysis(method, params)
  ↓
PromptReplacementController.executeMethod()
  ↓
Plugin Analysis Method
  ↓
Result → JS Promise.resolve()
```

#### 3.2 JS Bridge 管理器
**文件**: `lib/core/js_bridge/js_bridge_manager.dart`

**新增方法**：
```dart
void registerPluginAnalysisHandler(
  Future<String> Function(String methodName, Map<String, dynamic> params) handler,
)
```

**功能**：
- 注册全局的插件分析处理器
- 将处理器传递给 `MobileJSEngine`
- 统一管理 JS 与 Dart 的通信

---

### 阶段 4：集成与控制逻辑

#### 4.1 Agent Chat 插件初始化
**文件**: `lib/plugins/agent_chat/agent_chat_plugin.dart`

**修改内容**：

```dart
@override
Future<void> initialize() async {
  // ... 现有初始化代码

  // 初始化工具服务
  await ToolService.initialize();

  // 注册插件分析处理器
  final openaiPlugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
  if (openaiPlugin != null) {
    JSBridgeManager.instance.registerPluginAnalysisHandler(
      (methodName, params) async {
        return await openaiPlugin.getPromptReplacementController().executeMethod(
          methodName,
          params,
        );
      },
    );
  }
}
```

**作用**：
- 在插件启动时加载工具服务
- 连接 JS Bridge 和 OpenAI 插件的 Prompt 替换控制器
- 使 JS 能调用所有注册的插件方法

#### 4.2 Prompt 替换控制器扩展
**文件**: `lib/plugins/openai/controllers/prompt_replacement_controller.dart`

**新增方法**：

```dart
Future<String> executeMethod(
  String methodName,
  Map<String, dynamic> params,
) async {
  final callback = _methods[methodName];
  if (callback == null) {
    throw Exception('方法 $methodName 未注册');
  }
  try {
    final result = await callback(params);
    return result;
  } catch (e) {
    debugPrint('执行方法 $methodName 时出错: $e');
    rethrow;
  }
}
```

**功能**：
- 提供直接执行已注册方法的接口
- 用于工具调用时动态调用插件方法
- 统一错误处理

#### 4.3 ChatController 核心逻辑
**文件**: `lib/plugins/agent_chat/controllers/chat_controller.dart`

**主要修改**：

1. **添加导入** (第 5, 13, 17 行)
   ```dart
   import 'package:uuid/uuid.dart';
   import '../models/tool_call_step.dart';
   import '../services/tool_service.dart';
   ```

2. **修改 `_requestAIResponse`** (第 242-268 行)
   - 添加 `isCollectingToolCall` 标志
   - 在启用工具调用时，将工具列表注入 System Prompt
   ```dart
   if (_currentAgent!.enableFunctionCalling && contextMessages.isNotEmpty) {
     final toolsPrompt = ToolService.getToolListPrompt();
     final originalSystemPrompt = contextMessages[0].content;
     contextMessages[0] = ChatCompletionMessage.system(
       content: originalSystemPrompt is String
           ? originalSystemPrompt + toolsPrompt
           : toolsPrompt,
     );
   }
   ```

3. **修改 `onToken` 回调** (第 279-310 行)
   - 检测工具调用 JSON
   - 显示收集中状态："⚙️ 正在准备工具调用..."
   - 收集完成前暂停流式显示

4. **修改 `onComplete` 回调** (第 324-344 行)
   - 检查是否需要执行工具调用
   - 如果包含工具调用，调用 `_handleToolCall`
   - 否则正常完成消息

5. **新增 `_handleToolCall` 方法** (第 542-623 行)
   - 解析工具调用 JSON
   - 逐步执行每个工具步骤
   - 实时更新 UI 状态：
     - ⏳ 正在执行...
     - ✅ 执行成功（显示结果）
     - ❌ 执行失败（显示错误并中断）
   - 所有步骤成功后，调用 `_continueWithToolResult`

6. **新增 `_buildToolResultMessage` 方法** (第 625-640 行)
   - 格式化工具执行结果为文本
   - 包含所有步骤的结果

7. **新增 `_continueWithToolResult` 方法** (第 642-667 行)
   - 创建工具结果消息（标记为 `isToolResult: true`）
   - 创建新的 AI 消息
   - 重新请求 AI（上下文自动包含工具结果）

**执行流程**：
```
用户消息
  ↓
_requestAIResponse (注入工具列表)
  ↓
AI 流式响应
  ↓
onToken: 检测工具调用 → 显示收集状态
  ↓
onComplete: 检测到工具调用
  ↓
_handleToolCall
  ↓
解析 JSON → 逐步执行 → 更新 UI
  ↓
_buildToolResultMessage
  ↓
_continueWithToolResult
  ↓
创建结果消息 + 新 AI 消息
  ↓
_requestAIResponse (包含工具结果)
  ↓
AI 基于结果生成最终回复
```

---

### 阶段 5：用户界面

#### 5.1 Agent 编辑界面
**文件**: `lib/plugins/openai/screens/agent_edit_screen.dart`

**修改内容**：

1. **添加状态变量** (第 50 行)
   ```dart
   bool _enableFunctionCalling = false;
   ```

2. **初始化时加载** (第 71 行)
   ```dart
   _enableFunctionCalling = widget.agent!.enableFunctionCalling;
   ```

3. **保存时包含** (第 247 行)
   ```dart
   enableFunctionCalling: _enableFunctionCalling,
   ```

4. **UI 开关** (第 737-746 行)
   ```dart
   SwitchListTile(
     title: const Text('启用插件功能调用'),
     subtitle: const Text('允许 AI 调用插件功能获取数据'),
     value: _enableFunctionCalling,
     onChanged: (value) {
       setState(() {
         _enableFunctionCalling = value;
       });
     },
   ),
   ```

**界面位置**：
在 Agent 编辑页面的标签（Tags）下方，测试按钮上方。

---

## 🎯 功能特性

### 核心特性

1. **智能意图识别**
   - AI 自动识别用户需要查询数据的意图
   - 返回 JSON 格式的工具调用步骤

2. **动态 JS 执行**
   - 客户端执行 AI 生成的 JavaScript 代码
   - 安全的沙箱环境（QuickJS）
   - 支持调用所有注册的插件方法

3. **实时状态更新**
   - ⚙️ 正在准备工具调用...
   - ⏳ 正在执行...
   - ✅ 执行成功（显示结果）
   - ❌ 执行失败（显示错误）

4. **多步骤支持**
   - 单次对话可执行多个工具调用
   - 按顺序执行，任一失败则中断

5. **结果回传**
   - 工具执行结果自动添加到消息历史
   - AI 基于结果继续生成智能回复

6. **错误处理**
   - JS 执行失败立即中断
   - 显示友好的错误信息
   - 无重试机制（按需求设计）

7. **开关控制**
   - Agent 级别的功能开关
   - 默认关闭，手动启用

### 技术亮点

- ✅ **零依赖注入**: 无需修改运行时，使用现有 JS Bridge 框架
- ✅ **向后兼容**: 不影响现有功能，开关控制
- ✅ **类型安全**: 完整的 Dart 类型系统
- ✅ **错误恢复**: 失败不崩溃，友好提示
- ✅ **性能优化**: 工具列表缓存，减少构建时间
- ✅ **用户体验**: 实时状态反馈，过程可见

---

## 📁 文件清单

### 新建文件 (2)

1. `lib/plugins/agent_chat/models/tool_call_step.dart` - 工具调用数据模型
2. `lib/plugins/agent_chat/services/tool_service.dart` - 工具服务

### 修改文件 (7)

1. `lib/plugins/agent_chat/models/chat_message.dart` - 添加 toolCall 字段
2. `lib/plugins/openai/models/ai_agent.dart` - 添加 enableFunctionCalling 字段
3. `lib/core/js_bridge/platform/mobile_js_engine.dart` - 注入 callPluginAnalysis
4. `lib/core/js_bridge/js_bridge_manager.dart` - 注册插件分析处理器
5. `lib/plugins/agent_chat/agent_chat_plugin.dart` - 初始化工具服务
6. `lib/plugins/openai/controllers/prompt_replacement_controller.dart` - executeMethod
7. `lib/plugins/agent_chat/controllers/chat_controller.dart` - 工具调用处理逻辑
8. `lib/plugins/openai/screens/agent_edit_screen.dart` - UI 开关

### 文档文件 (3)

1. `TOOL_CALLING_IMPLEMENTATION_GUIDE.md` - 实施指南（原有）
2. `TOOL_CALLING_TEST_GUIDE.md` - 测试指南（新建）
3. `TOOL_CALLING_IMPLEMENTATION_SUMMARY.md` - 本文档

### 临时文件 (1)

1. `chat_controller_tool_calling.patch` - ChatController 补丁文件（可删除）

---

## 🔧 技术栈

- **语言**: Dart 3.7+, JavaScript (ES6+)
- **框架**: Flutter 3.7+
- **JS 引擎**: QuickJS (mobile), dart:js (web)
- **状态管理**: Provider + ChangeNotifier
- **AI 服务**: openai_dart (支持多服务商)
- **数据格式**: JSON

---

## 📊 代码统计

- **新增代码**: 约 800 行
- **修改代码**: 约 200 行
- **总计**: 约 1000 行
- **文件数**: 10 个文件修改/新建
- **覆盖模块**: 3 个插件（agent_chat, openai, core）

---

## 🧪 测试状态

**单元测试**: ❌ 未编写（项目暂无测试）

**集成测试**: ❌ 未编写

**手动测试**: ⏳ 待执行

**测试计划**: 已提供详细测试指南（见 `TOOL_CALLING_TEST_GUIDE.md`）

---

## 📝 使用说明

### 开启功能

1. 打开 OpenAI 插件
2. 创建或编辑 AI Agent
3. 启用 **"启用插件功能调用"** 开关
4. 保存 Agent
5. 在 Agent Chat 中使用该 Agent

### 示例对话

```
用户: 我今天有哪些任务？

AI: （返回工具调用 JSON）
```json
{
  "steps": [
    {
      "method": "run_js",
      "title": "获取待办任务",
      "desc": "查询今天的任务列表",
      "data": "const result = await callPluginAnalysis('todo_getTasks', {date: 'today'}); setResult(JSON.stringify(result));"
    }
  ]
}
```

（系统执行工具调用）

AI: 根据查询结果，您今天有以下任务：
1. 完成项目文档
2. 回复客户邮件
3. ...
```

---

## ⚠️ 已知限制

1. **仅支持 run_js 方法**
   - 当前版本仅实现 JS 代码执行
   - 其他 method 类型已预留逻辑但未实现

2. **无重试机制**
   - 执行失败立即中断，不自动重试
   - 需要用户手动重新发送消息

3. **无权限控制**
   - 所有插件方法均可调用
   - 未来可能需要添加敏感操作确认

4. **性能考量**
   - 每次对话都注入完整工具列表（约 2K tokens）
   - 可能影响上下文长度

5. **Web 平台限制**
   - Web 端 JS 引擎可能行为不同
   - 推荐在移动端测试

---

## 🚀 未来优化建议

### 短期优化 (1-2 周)

1. **增强错误提示**
   - 更详细的错误信息
   - 错误类型分类（语法错误、运行时错误、超时等）

2. **性能优化**
   - 工具列表按需生成（仅包含相关插件）
   - 缓存优化

3. **用户体验**
   - 添加 "取消执行" 按钮
   - 执行进度条

### 中期优化 (1-2 月)

1. **权限系统**
   - 敏感操作需用户确认
   - 插件方法权限级别

2. **执行历史**
   - 记录所有工具调用
   - 可查看和重放

3. **重试机制**
   - 可选的自动重试
   - 用户手动重试按钮

### 长期优化 (3+ 月)

1. **扩展 method 类型**
   - 支持直接 API 调用
   - 支持文件上传/下载
   - 支持流式数据处理

2. **AI Prompt 优化**
   - 根据插件自动生成更智能的 System Prompt
   - Few-shot 示例

3. **分析与监控**
   - 工具调用成功率统计
   - 性能监控
   - 用户行为分析

---

## 🎓 学习资源

### 相关文档

- [Flutter 文档](https://docs.flutter.dev/)
- [openai_dart 文档](https://pub.dev/packages/openai_dart)
- [QuickJS 文档](https://bellard.org/quickjs/)
- [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling)

### 项目内部文档

- `CLAUDE.md` - 项目总览
- `lib/core/CLAUDE.md` - 核心层文档
- `lib/plugins/agent_chat/CLAUDE.md` - Agent Chat 插件文档
- `lib/plugins/openai/CLAUDE.md` - OpenAI 插件文档

---

## 👥 贡献者

- **开发**: AI (Claude Code)
- **需求**: 用户
- **测试**: 待定

---

## 📄 许可证

遵循项目主许可证

---

**完成日期**: 2025-01-16
**版本**: v1.0.0
**状态**: ✅ 开发完成，待测试

---

## 🎉 总结

工具调用功能已完整实现，包含：

✅ 完整的数据模型
✅ 核心服务层
✅ JS 执行基础设施
✅ 集成与控制逻辑
✅ 用户界面

所有代码已编写完成，无编译错误。接下来需要：

1. 按照 `TOOL_CALLING_TEST_GUIDE.md` 进行手动测试
2. 根据测试结果调整和优化
3. 考虑添加单元测试和集成测试（可选）

功能设计简洁、模块化，易于维护和扩展。
