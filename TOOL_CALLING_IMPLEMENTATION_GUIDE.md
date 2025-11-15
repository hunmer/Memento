# 工具调用功能实施总结

## ✅ 已完成的工作（步骤 1-6）

### 1. 数据模型层 ✅
- ✅ `lib/plugins/agent_chat/models/tool_call_step.dart` - 工具调用模型
- ✅ `lib/plugins/agent_chat/models/chat_message.dart` - 添加 `toolCall` 字段
- ✅ `lib/plugins/openai/models/ai_agent.dart` - 添加 `enableFunctionCalling` 开关

### 2. 工具服务层 ✅
- ✅ `lib/plugins/agent_chat/services/tool_service.dart` - 完整实现
  - JSON 解析
  - JS 代码执行
  - 工具列表 Prompt 生成

### 3. JS 执行层 ✅
- ✅ `lib/core/js_bridge/platform/mobile_js_engine.dart`
  - 注入 `callPluginAnalysis` 全局函数
  - 实现 `_callPluginAnalysis` 方法
  - 实现 `_returnPluginAnalysisResult` 方法
  - 添加 `setPluginAnalysisHandler` 接口

### 4. JS Bridge Manager ✅
- ✅ `lib/core/js_bridge/js_bridge_manager.dart`
  - 添加 `registerPluginAnalysisHandler` 方法

---

## 🔨 剩余工作（步骤 7-10）

### 步骤 7：修改 ChatController

**文件**: `lib/plugins/agent_chat/controllers/chat_controller.dart`

#### 7.1 添加导入

```dart
import '../services/tool_service.dart';
import '../models/tool_call_step.dart';
```

#### 7.2 修改 `sendMessage` 方法

在 `_requestAIResponse` 调用之前，检查是否启用工具调用并构建完整的 system prompt：

```dart
Future<void> sendMessage() async {
  // ... 现有代码

  // 构建上下文消息
  final contextMessages = _buildContextMessages(userInput);

  // 如果启用工具调用，添加工具列表到 system prompt
  if (_currentAgent!.enableFunctionCalling) {
    final toolsPrompt = ToolService.getToolListPrompt();
    contextMessages[0] = ChatCompletionMessage.system(
      content: _currentAgent!.systemPrompt + toolsPrompt,
    );
  }

  // 请求 AI 响应
  await _requestAIResponse(aiMessage.id, userInput, selectedFiles, contextMessages);
}
```

#### 7.3 修改 `_requestAIResponse` 方法

```dart
Future<void> _requestAIResponse(
  String aiMessageId,
  String userInput,
  List<File> files,
  List<ChatCompletionMessage> contextMessages,
) async {
  final buffer = StringBuffer();
  bool isCollectingToolCall = false;

  try {
    await RequestService.streamResponse(
      agent: _currentAgent!,
      contextMessages: contextMessages,
      vision: files.isNotEmpty,
      filePath: files.isNotEmpty ? files.first.path : null,
      onToken: (token) {
        buffer.write(token);
        final content = buffer.toString();

        // 检测工具调用
        if (_currentAgent!.enableFunctionCalling &&
            ToolService.containsToolCall(content)) {
          isCollectingToolCall = true;
          // 显示收集中状态
          final displayContent = content + '\n\n⚙️ 正在准备工具调用...';
          messageService.updateAIMessageContent(
            conversation.id,
            aiMessageId,
            displayContent,
            TokenCounterService.countTokens(displayContent),
          );
        } else if (!isCollectingToolCall) {
          // 正常流式显示
          final processed = RequestService.processThinkingContent(content);
          messageService.updateAIMessageContent(
            conversation.id,
            aiMessageId,
            processed,
            TokenCounterService.countTokens(processed),
          );
        }
      },
      onError: (error) {
        messageService.updateAIMessageContent(
          conversation.id,
          aiMessageId,
          '抱歉，生成回复时出现错误：$error',
          0,
        );
        messageService.completeAIMessage(conversation.id, aiMessageId);
      },
      onComplete: () async {
        // 检查是否需要执行工具调用
        if (_currentAgent!.enableFunctionCalling &&
            ToolService.containsToolCall(buffer.toString())) {
          await _handleToolCall(aiMessageId, buffer.toString());
        } else {
          messageService.completeAIMessage(conversation.id, aiMessageId);
        }
      },
    );
  } catch (e) {
    // ... 错误处理
  } finally {
    _isSending = false;
    notifyListeners();
  }
}
```

#### 7.4 添加工具调用处理方法

```dart
/// 处理工具调用
Future<void> _handleToolCall(String messageId, String aiResponse) async {
  try {
    // 1. 解析工具调用
    final toolCall = ToolService.parseToolCallFromResponse(aiResponse);
    if (toolCall == null) {
      // 解析失败，直接完成消息
      messageService.completeAIMessage(conversation.id, messageId);
      return;
    }

    // 2. 更新消息显示解析结果
    var displayContent = aiResponse + '\n\n';

    // 3. 逐步执行工具调用
    for (int i = 0; i < toolCall.steps.length; i++) {
      final step = toolCall.steps[i];

      // 显示执行中状态
      displayContent += '\n🔧 **步骤 ${i + 1}: ${step.title}**\n';
      displayContent += '📝 ${step.desc}\n';
      displayContent += '⏳ 正在执行...\n';
      messageService.updateAIMessageContent(
        conversation.id,
        messageId,
        displayContent,
        TokenCounterService.countTokens(displayContent),
      );

      // 执行工具调用
      if (step.method == 'run_js') {
        try {
          final result = await ToolService.executeJsCode(step.data);

          // 显示成功结果
          displayContent = displayContent.replaceAll(
            '⏳ 正在执行...',
            '✅ 执行成功\n```json\n$result\n```',
          );
          messageService.updateAIMessageContent(
            conversation.id,
            messageId,
            displayContent,
            TokenCounterService.countTokens(displayContent),
          );

          // 更新步骤状态
          step.result = result;
          step.status = ToolCallStatus.success;

        } catch (e) {
          // 显示错误并中断
          displayContent = displayContent.replaceAll(
            '⏳ 正在执行...',
            '❌ 执行失败: $e',
          );
          messageService.updateAIMessageContent(
            conversation.id,
            messageId,
            displayContent,
            TokenCounterService.countTokens(displayContent),
          );
          messageService.completeAIMessage(conversation.id, messageId);
          return; // 中断流程
        }
      }
    }

    // 4. 所有工具调用成功，将结果发送给 AI 继续生成
    final toolResultMessage = _buildToolResultMessage(toolCall.steps);
    await _continueWithToolResult(messageId, toolResultMessage);

  } catch (e) {
    // 解析失败
    final errorContent = aiResponse + '\n\n❌ 工具调用处理失败: $e';
    messageService.updateAIMessageContent(
      conversation.id,
      messageId,
      errorContent,
      TokenCounterService.countTokens(errorContent),
    );
    messageService.completeAIMessage(conversation.id, messageId);
  }
}

/// 构建工具结果消息
String _buildToolResultMessage(List<ToolCallStep> steps) {
  final buffer = StringBuffer();
  buffer.writeln('工具执行结果:\n');

  for (int i = 0; i < steps.length; i++) {
    final step = steps[i];
    buffer.writeln('步骤 ${i + 1}: ${step.title}');
    if (step.result != null) {
      buffer.writeln('结果: ${step.result}');
    }
    buffer.writeln();
  }

  return buffer.toString();
}

/// 使用工具结果继续对话
Future<void> _continueWithToolResult(String originalMessageId, String toolResult) async {
  // 将工具结果作为系统消息添加
  final resultMessage = ChatMessage(
    id: const Uuid().v4(),
    conversationId: conversation.id,
    content: toolResult,
    isUser: false,
    timestamp: DateTime.now(),
    metadata: {'isToolResult': true},
  );
  await messageService.addMessage(resultMessage);

  // 创建新的 AI 消息继续生成
  final newAiMessage = ChatMessage.ai(
    conversationId: conversation.id,
    isGenerating: true,
  );
  await messageService.addMessage(newAiMessage);

  // 重新构建上下文（包含工具结果）
  final contextMessages = _buildContextMessages('');

  // 继续请求 AI
  await _requestAIResponse(newAiMessage.id, '', [], contextMessages);
}
```

---

### 步骤 8：初始化工具服务

**文件**: `lib/plugins/agent_chat/agent_chat_plugin.dart`

在 `initialize()` 方法中添加：

```dart
@override
Future<void> initialize() async {
  // ... 现有初始化代码

  // 初始化工具服务
  await ToolService.initialize();

  // 注册插件分析处理器（如果 OpenAI 插件可用）
  final openaiPlugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
  if (openaiPlugin != null) {
    JSBridgeManager.instance.registerPluginAnalysisHandler(
      (methodName, params) async {
        // 调用 OpenAI 插件的 Prompt 替换控制器
        return await openaiPlugin.promptReplacementController.executeMethod(
          methodName,
          params,
        );
      },
    );
  }
}
```

---

### 步骤 9：添加 UI 设置开关

**文件**: 需要找到 Agent 设置界面（可能在 OpenAI 插件中）

添加开关控件：

```dart
SwitchListTile(
  title: const Text('启用插件功能调用'),
  subtitle: const Text('允许 AI 调用插件功能获取数据'),
  value: _agent.enableFunctionCalling,
  onChanged: (value) {
    setState(() {
      _agent = _agent.copyWith(enableFunctionCalling: value);
    });
  },
)
```

---

### 步骤 10：测试

#### 测试用例 1：简单查询
```
用户: 我今天有哪些任务？
预期: AI 返回工具调用 JSON，执行后显示任务列表
```

#### 测试用例 2：数据分析
```
用户: 分析我本月的日记
预期: AI 调用 diary_getDiaries，分析并返回总结
```

#### 测试用例 3：错误处理
```
用户: 执行一个错误的 JS 代码
预期: 显示错误信息，中断流程
```

---

## 📋 关键注意事项

1. **导入 uuid**：确保在 ChatController 中导入 `package:uuid/uuid.dart`
2. **OpenAI 插件接口**：需要确认 OpenAI 插件的 `PromptReplacementController` 是否有 `executeMethod` 方法
3. **错误处理**：所有异步操作都需要 try-catch
4. **UI 更新**：使用 `notifyListeners()` 触发 UI 更新
5. **Token 统计**：每次更新消息内容时都要更新 token 计数

---

## 🎯 下一步操作建议

1. **先完成步骤 8**（初始化），确保基础设施就绪
2. **然后步骤 7**（ChatController），这是核心逻辑
3. **再步骤 9**（UI），添加用户可见的开关
4. **最后步骤 10**（测试），验证完整流程

---

## 📞 需要帮助的地方

- 如果 OpenAI 插件的 Prompt 替换接口不同，需要调整步骤 8
- 如果找不到 Agent 设置界面，可以临时在代码中硬编码 `enableFunctionCalling = true`
- ChatController 的具体方法签名可能需要根据实际情况微调

---

生成时间: 2025-01-16
