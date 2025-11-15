# 工具调用功能测试指南

## ✅ 实施完成总结

所有开发步骤已完成：

1. ✅ 数据模型层 - `tool_call_step.dart`
2. ✅ ChatMessage 扩展 - 添加 `toolCall` 字段
3. ✅ AIAgent 扩展 - 添加 `enableFunctionCalling` 字段
4. ✅ 工具服务 - `tool_service.dart` 完整实现
5. ✅ JS 执行层 - `mobile_js_engine.dart` 注入 `callPluginAnalysis`
6. ✅ JS Bridge 管理器 - 注册插件分析处理器
7. ✅ Agent Chat 插件初始化 - 工具服务启动
8. ✅ Prompt 替换控制器 - `executeMethod` 方法
9. ✅ ChatController - 完整工具调用处理逻辑
10. ✅ UI 设置界面 - Agent 编辑页面添加开关

---

## 🧪 测试准备

### 1. 构建应用

```bash
# 移动端测试（推荐）
flutter run -d android  # 或 ios

# Web 测试（可选，但 JS 引擎可能行为不同）
flutter run -d chrome
```

### 2. 创建测试 Agent

1. 打开应用，进入 **OpenAI** 插件
2. 点击 **创建新 Agent**
3. 填写基本信息：
   - 名称：`工具调用测试助手`
   - 描述：`用于测试插件功能调用`
   - System Prompt：
     ```
     你是一个智能助手，可以调用插件功能获取用户的数据。
     当用户询问他们的任务、日记、账单等信息时，你应该使用工具调用来获取数据。
     ```
4. **重要**：启用 **"启用插件功能调用"** 开关 ✅
5. 保存 Agent

### 3. 创建测试会话

1. 进入 **Agent Chat** 插件
2. 创建新会话
3. 选择刚才创建的 `工具调用测试助手`

---

## 📝 测试用例

### 测试用例 1：简单数据查询（TODO 列表）

**测试目标**：验证 AI 能识别意图并返回工具调用

**测试步骤**：
1. 在聊天框输入：`我今天有哪些任务？`
2. 发送消息

**预期结果**：
```
AI 响应：（识别用户意图）

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

🔧 **步骤 1: 获取待办任务**
📝 查询今天的任务列表
⏳ 正在执行...

（执行成功后显示）
✅ 执行成功
```json
{"tasks": [...]}
```

（AI 继续生成）
根据查询结果，您今天有以下任务：
1. ...
2. ...
```

**验证点**：
- ✅ AI 返回了 JSON 格式的工具调用
- ✅ 显示 "⚙️ 正在准备工具调用..." 状态
- ✅ 显示执行步骤和进度
- ✅ 执行成功后显示结果
- ✅ AI 继续生成基于结果的回复

---

### 测试用例 2：数据分析（日记统计）

**测试目标**：验证复杂工具调用和数据处理

**测试步骤**：
1. 输入：`分析我本月的日记，告诉我写了多少篇`
2. 发送消息

**预期结果**：
```
AI 响应包含工具调用 JSON

🔧 **步骤 1: 获取本月日记**
📝 查询本月所有日记条目
⏳ 正在执行...

✅ 执行成功
```json
{"entries": [{"date": "2025-01-01", ...}, ...]}
```

（AI 分析结果）
您本月共写了 15 篇日记，平均每天...
```

**验证点**：
- ✅ 正确调用 `diary_getDiaries` 方法
- ✅ 返回的数据格式正确
- ✅ AI 能基于数据进行分析

---

### 测试用例 3：错误处理（无效 JS 代码）

**测试目标**：验证错误处理机制

**测试步骤**：
1. 手动构造一个错误的请求（或等待 AI 生成错误代码）
2. 观察错误提示

**预期结果**：
```
🔧 **步骤 1: xxx**
📝 xxx
⏳ 正在执行...

❌ 执行失败: [错误详情]

（流程中断，不继续执行后续步骤）
```

**验证点**：
- ✅ 显示错误信息
- ✅ 流程立即中断
- ✅ 不重试
- ✅ 不继续执行后续步骤

---

### 测试用例 4：多步骤工具调用

**测试目标**：验证多个工具按顺序执行

**测试步骤**：
1. 输入：`统计我本月的日记和任务完成情况`
2. 发送消息

**预期结果**：
```
AI 返回 JSON 包含多个 steps

🔧 **步骤 1: 获取本月日记**
...
✅ 执行成功

🔧 **步骤 2: 获取任务列表**
...
✅ 执行成功

（AI 综合分析）
根据数据，您本月...
```

**验证点**：
- ✅ 所有步骤按顺序执行
- ✅ 每个步骤的状态正确更新
- ✅ AI 能综合多个数据源生成回复

---

## 🐛 调试技巧

### 1. 查看日志

```bash
# Android
adb logcat | grep -E "(工具调用|ToolService|callPluginAnalysis)"

# iOS
# 在 Xcode Console 中查看

# Flutter 控制台
flutter logs
```

### 2. 检查工具列表是否注入

在 ChatController 中添加调试输出（可选）：

```dart
// 在 _requestAIResponse 中添加
if (_currentAgent!.enableFunctionCalling) {
  final toolsPrompt = ToolService.getToolListPrompt();
  debugPrint('=== 工具列表 Prompt ===');
  debugPrint(toolsPrompt);
}
```

### 3. 验证 JS 执行

在 `tool_service.dart` 的 `executeJsCode` 方法中添加调试：

```dart
debugPrint('执行 JS: $jsCode');
final result = await JSBridgeManager.instance.executeCode(wrappedCode);
debugPrint('JS 结果: ${result.success ? result.value : result.error}');
```

---

## ⚠️ 常见问题

### 问题 1：AI 不返回工具调用 JSON

**可能原因**：
- Agent 的 `enableFunctionCalling` 未启用
- System Prompt 不够明确
- 工具列表未正确注入

**解决方法**：
1. 确认 Agent 设置中的开关已启用
2. 在 System Prompt 中明确说明工具调用格式
3. 检查日志确认工具列表已注入

### 问题 2：工具调用 JSON 解析失败

**可能原因**：
- AI 返回的 JSON 格式不正确
- 包含多余的文本内容

**解决方法**：
- `ToolService.parseToolCallFromResponse` 已支持从 Markdown 代码块和纯文本中提取 JSON
- 如果仍失败，检查 AI 返回的原始内容

### 问题 3：JS 执行失败

**可能原因**：
- `callPluginAnalysis` 未注入
- 插件方法未注册
- 参数格式错误

**解决方法**：
1. 确认 `agent_chat_plugin.dart` 的 `initialize` 正确注册了处理器
2. 检查 `mobile_js_engine.dart` 是否正确注入了全局函数
3. 验证插件方法已在 `PromptReplacementController` 中注册

### 问题 4：工具结果未传回 AI

**可能原因**：
- `_continueWithToolResult` 未正确调用
- 新消息未创建

**解决方法**：
- 检查 `_handleToolCall` 方法是否正确执行到最后
- 确认 `messageService.addMessage` 成功添加了结果消息

---

## 📊 性能测试

### 测试指标

1. **响应时间**：
   - 从用户发送到 AI 返回 JSON：< 5s
   - JS 执行时间：< 1s
   - AI 继续生成时间：< 5s

2. **准确性**：
   - 工具调用 JSON 格式正确率：> 90%
   - JS 执行成功率：> 95%
   - 最终回复准确率：> 85%

3. **用户体验**：
   - 状态提示清晰
   - 错误信息友好
   - 流程可中断

---

## 🎯 验收标准

所有测试用例通过，且满足以下条件：

- ✅ Agent 设置中能看到并操作 "启用插件功能调用" 开关
- ✅ 启用后，AI 能识别用户意图并返回工具调用 JSON
- ✅ 工具调用按顺序执行，状态实时更新
- ✅ 执行成功后显示结果，并继续 AI 生成
- ✅ 执行失败时显示错误，流程中断
- ✅ 多步骤工具调用正确执行
- ✅ 工具结果能正确传回 AI 用于后续生成
- ✅ 无内存泄漏或崩溃

---

## 📌 下一步优化建议

1. **增强 AI Prompt**：提供更详细的工具使用示例
2. **错误重试机制**：允许用户选择重试失败的步骤
3. **工具执行历史**：记录所有工具调用历史供用户查看
4. **权限控制**：敏感操作需要用户确认
5. **性能优化**：缓存工具列表 Prompt，减少每次构建时间
6. **国际化**：将硬编码的中文提示添加到国际化系统

---

**测试日期**: 2025-01-16
**版本**: v1.0.0
**测试平台**: Android / iOS / Web
