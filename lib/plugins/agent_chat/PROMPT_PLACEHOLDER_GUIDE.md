# Agent Prompt 占位符使用指南

## 📋 概述

为了灵活组合不同部分的 Prompt（Agent 预设、工具信息等），系统支持使用占位符来构建最终的 System Prompt。

---

## 🎯 可用占位符

| 占位符 | 说明 | 内容来源 | 使用阶段 |
|--------|------|---------|---------|
| `{agent_prompt}` | Agent 的原始 systemPrompt | Agent 配置或 Prompt 预设 | 所有阶段 |
| `{tool_templates}` | 工具模版列表 | ToolService.getToolTemplatePrompt() | 第零阶段（模版匹配） |
| `{tool_brief}` | 工具简要索引 | ToolService.getToolBriefPrompt() | 第一阶段（工具需求） |
| `{tool_detail}` | 工具详细文档 | ToolService.getToolDetailPrompt() | 第二阶段（工具调用） |

---

## 🔧 使用方式

### 方式一：在 Agent 的 systemPrompt 中使用占位符

```dart
// 创建 Agent 时指定占位符
final agent = AIAgent(
  name: '智能助手',
  systemPrompt: '''
你是一个智能助手，可以调用插件功能获取用户的数据。

{agent_prompt}

当用户需要工具时，请参考以下信息：
{tool_templates}
{tool_brief}
{tool_detail}
''',
  enableFunctionCalling: true,
);
```

### 方式二：在 Prompt 预设中使用占位符

```json
{
  "id": "preset_001",
  "name": "工具调用专家",
  "content": "{agent_prompt}\n\n## 工具能力\n{tool_templates}{tool_brief}{tool_detail}"
}
```

### 方式三：使用默认模板（推荐）

如果 Agent 的 systemPrompt 或预设中**不包含任何占位符**，系统会自动使用默认模板：

```
{agent_prompt}
{tool_templates}{tool_brief}{tool_detail}
```

即：原始 Prompt + 工具相关信息（按阶段注入）

---

## 📝 占位符替换规则

### 1. 默认模板触发条件

当 systemPrompt 中**不包含任何工具相关占位符**时，系统会自动使用默认模板。

**示例**：

```dart
// Agent systemPrompt
systemPrompt: "你是一个专业的数据分析师"

// 系统自动转换为
systemPrompt: "{agent_prompt}\n{tool_templates}{tool_brief}{tool_detail}"

// 最终替换后
systemPrompt: "你是一个专业的数据分析师\n[工具模版列表][工具索引][工具详细文档]"
```

### 2. 自定义模板

如果你想自定义占位符的位置和顺序，可以在 systemPrompt 中明确指定：

```dart
systemPrompt: '''
## 角色设定
{agent_prompt}

## 可用工具模版
{tool_templates}

## 工具能力索引
{tool_brief}

## 详细工具文档
{tool_detail}

请优先使用工具模版来完成任务。
'''
```

### 3. 占位符的阶段性注入

不同阶段会注入不同的占位符内容：

| 阶段 | 注入的占位符 | 其他占位符 |
|------|------------|----------|
| 第零阶段（模版匹配） | `{tool_templates}` | 其他为空字符串 |
| 第一阶段（工具需求） | `{tool_brief}` | 其他为空字符串 |
| 第二阶段（工具调用） | `{tool_detail}` | 其他为空字符串 |
| 普通对话 | 无 | 所有为空字符串 |

**注意**：`{agent_prompt}` 始终会被替换为原始的 Agent Prompt。

---

## 🎨 最佳实践

### ✅ 推荐做法

**1. 使用默认模板（最简单）**

```dart
AIAgent(
  systemPrompt: "你是一个智能助手，擅长帮助用户管理日常数据。",
  enableFunctionCalling: true,
)
```

系统会自动在末尾追加工具信息。

**2. 自定义顺序（更灵活）**

```dart
AIAgent(
  systemPrompt: '''
{tool_templates}
{tool_brief}
{tool_detail}

## 核心指令
{agent_prompt}

请优先使用已有的工具模版。
''',
  enableFunctionCalling: true,
)
```

**3. 条件性使用工具信息**

```dart
AIAgent(
  systemPrompt: '''
{agent_prompt}

---

可用功能：
{tool_templates}
{tool_brief}
{tool_detail}

如果以上为空，说明当前不需要使用工具。
''',
)
```

### ❌ 避免的做法

**1. 不要重复添加相同内容**

```dart
// ❌ 错误示例
systemPrompt: '''
你是一个助手。
{agent_prompt}  // 这会导致"你是一个助手"被重复
'''
```

**2. 不要手动拼接工具信息**

```dart
// ❌ 错误示例
final toolInfo = ToolService.getToolBriefPrompt();
systemPrompt: '''
{agent_prompt}
$toolInfo  // 应该使用 {tool_brief} 占位符
'''
```

---

## 🔍 调试技巧

### 查看最终的 System Prompt

在 RequestService 中查看日志：

```
[RequestService] 替换占位符 {tool_templates} (长度: 1234)
[RequestService] 替换占位符 {tool_brief} (长度: 567)
[RequestService] 应用占位符后的 systemPrompt 长度: 5678
```

### 验证占位符是否生效

1. 开启工具调用功能
2. 发送消息
3. 检查日志中是否有 "替换占位符" 的输出
4. 如果没有，检查：
   - `enableFunctionCalling` 是否为 true
   - `preferToolTemplates` 设置是否开启（如果需要模版匹配）
   - Agent 的 systemPrompt 是否包含占位符

---

## 📚 示例：完整的工具调用 Agent 配置

```dart
final agent = AIAgent(
  id: 'agent_001',
  name: '数据分析助手',
  systemPrompt: '''
# 角色定义
{agent_prompt}

# 工具能力
你可以使用以下工具来帮助用户：

## 已保存的工具模版
{tool_templates}

## 工具功能索引
{tool_brief}

## 详细使用文档
{tool_detail}

# 工作原则
1. 优先使用已有的工具模版（如果有）
2. 如果没有合适的模版，根据工具索引选择需要的工具
3. 根据详细文档生成工具调用代码
4. 始终先获取数据，再进行分析和建议
''',
  providerId: 'openai',
  model: 'gpt-4-turbo',
  temperature: 0.7,
  enableFunctionCalling: true,
);
```

---

## ⚙️ 高级用法

### 动态占位符内容

如果你需要在运行时动态生成占位符内容，可以通过 `RequestService.streamResponse` 的 `additionalPrompts` 参数：

```dart
await RequestService.streamResponse(
  agent: agent,
  contextMessages: messages,
  additionalPrompts: {
    'tool_templates': customTemplatePrompt,
    'tool_brief': customBriefPrompt,
    'custom_placeholder': 'Your custom content',  // 自定义占位符
  },
);
```

但注意：只有 `tool_templates`, `tool_brief`, `tool_detail` 是标准占位符，其他自定义占位符需要在 Agent 的 systemPrompt 中使用 `{custom_placeholder}` 的形式。

---

## 🛠️ 实现原理

1. **获取原始 Prompt**：从 Agent 配置或 Prompt 预设获取
2. **检测占位符**：检查是否包含工具相关占位符
3. **应用默认模板**：如果没有占位符，自动构建默认模板
4. **替换占位符**：
   - 先替换 `{agent_prompt}` 为原始 Prompt
   - 再替换工具相关占位符（根据当前阶段）
   - 如果某个占位符内容为空，则移除该占位符
5. **生成最终 Prompt**：返回完整的 System Prompt

---

## 📖 相关文件

- `lib/plugins/openai/services/request_service.dart` - 占位符替换逻辑
- `lib/plugins/agent_chat/controllers/chat_controller.dart` - 三阶段工具调用流程
- `lib/plugins/agent_chat/services/tool_service.dart` - 工具 Prompt 生成

---

**最后更新**：2025-01-XX
**维护者**：hunmer
