# 🤖 OpenAI 助手插件

![OpenAI Plugin](/icon.png)

## 插件简介

OpenAI 助手插件是 Memento 的 AI 核心，提供多服务商支持的 AI 助手管理、数据分析应用、工具调用 (Tool App) 和插件数据提示词生成功能。支持 OpenAI、Anthropic、Google、本地模型等多种 LLM 服务商，让 AI 深度集成到您的个人数据管理和工作流中。

## 主要功能

### 🧠 多服务商支持

- **OpenAI**：GPT-4、GPT-3.5 系列模型
- **Anthropic**：Claude 3.5 Sonnet、Claude 3 Haiku 等
- **Google**：Gemini Pro、Gemini Ultra 等
- **本地模型**：支持 Ollama 等本地部署方案
- **自定义端点**：兼容 OpenAI API 格式的任意服务商

### 👥 AI 助手管理

- **多角色助手**：创建具有不同人格和专长的 AI 助手
- **个性化配置**：每个助手独立的系统提示词、模型和参数
- **工具绑定**：为助手配置可调用的工具应用
- **上下文管理**：维护对话历史和上下文

### 📊 数据分析应用

- **插件数据集成**：直接分析其他插件的数据
- **自动提示词生成**：为各插件自动生成数据摘要提示词
- **跨插件查询**：使用自然语言查询多个插件的数据
- **洞察提取**：从个人数据中发现模式和趋势

### 🔧 工具调用 (Function Calling)

- **插件功能调用**：AI 可直接调用其他插件的功能
- **参数验证**：自动验证和转换函数参数
- **链式调用**：支持多步工具调用和结果传递
- **自定义工具**：创建任意插件功能的 AI 工具

## 使用场景

### 1. 个人数据分析

- **日记洞察**：分析日记内容，发现情绪变化和生活模式
- **活动统计**：基于活动记录，分析作息习惯和健康趋势
- **账单分析**：智能分析消费习惯，提供理财建议
- **习惯追踪**：分析习惯打卡数据，优化行为改进

### 2. 智能任务管理

- **任务分解**：AI 自动将大任务拆分为可执行的小任务
- **优先级排序**：基于重要性和紧急程度智能排序
- **时间规划**：根据历史数据预测任务耗时
- **提醒建议**：基于上下文智能提醒

### 3. 知识管理

- **笔记整理**：自动分类和标签化笔记内容
- **关联发现**：发现不同笔记之间的潜在联系
- **内容总结**：快速总结长篇文档的核心要点
- **检索增强**：使用自然语言检索相关信息

### 4. 创意与内容生成

- **头脑风暴**：基于个人数据进行创意扩展
- **内容创作**：根据偏好和历史生成个性化内容
- **文案优化**：润色和优化日常写作
- **多语言翻译**：准确的文档翻译和本地化

### 5. 决策支持

- **选择建议**：基于历史选择和结果提供决策建议
- **风险评估**：识别潜在问题和风险点
- **方案比较**：多维度对比不同方案的优劣
- **趋势预测**：基于历史数据预测未来趋势

## API 文档

### 核心 API

#### 发送消息

```dart
Future<String> sendMessage({
  required String agentId,
  required String message,
  List<Message>? context,  // 上下文消息
  Map<String, dynamic>? metadata,
}) async {
  // 发送消息并获取AI回复
}
```

#### 数据分析

```dart
Future<String> analyzePluginData({
  required String pluginId,
  required String query,
  String? agentId,
}) async {
  // 分析指定插件的数据
  // 返回基于数据的AI分析结果
}
```

#### 工具调用

```dart
Future<dynamic> executeToolApp({
  required String toolAppId,
  required Map<String, dynamic> parameters,
}) async {
  // 执行AI工具应用
  // 返回执行结果
}
```

## 数据模型

### AIAgent (AI 助手)

AI 助手是个性化的 AI 实例，每个助手具有独特的配置和能力。

**关键字段：**
- `id`：助手唯一标识符 (UUID)
- `name`：助手显示名称
- `providerId`：使用的 LLM 服务商 ID
- `model`：具体的模型名称 (如 gpt-4-turbo)
- `systemPrompt`：系统提示词，定义助手行为
- `temperature`：随机性参数 (0.0-2.0)
- `maxTokens`：最大生成 token 数
- `enableToolCalling`：是否启用工具调用
- `toolAppIds`：可用的工具应用列表

**示例配置：**
```json
{
  "id": "agent_123",
  "name": "数据分析专家",
  "providerId": "openai",
  "model": "gpt-4-turbo",
  "systemPrompt": "你是一个专业的数据分析师，擅长从个人数据中发现模式和洞察。",
  "temperature": 0.5,
  "maxTokens": 4096,
  "enableToolCalling": true,
  "toolAppIds": ["tool_diary_search", "tool_activity_stats"]
}
```

### ServiceProvider (服务商)

定义 LLM 服务提供商的配置信息。

**关键字段：**
- `id`：服务商唯一标识符
- `name`：服务商显示名称
- `type`：服务商类型 (openai/anthropic/google/local/custom)
- `apiKey`：API 密钥
- `baseUrl`：自定义 API 端点 (可选)
- `availableModels`：可用模型列表
- `config`：额外配置参数

### ToolApp (工具应用)

定义 AI 可调用的工具功能。

**关键字段：**
- `id`：工具唯一标识符
- `name`：工具名称
- `description`：功能描述
- `pluginId`：目标插件 ID
- `functionName`：调用的函数名
- `parameters`：参数定义和验证规则

**示例工具：**
```json
{
  "id": "tool_diary_search",
  "name": "搜索日记",
  "description": "在日记中搜索包含指定关键词的条目",
  "pluginId": "diary",
  "functionName": "searchEntries",
  "parameters": {
    "keyword": {
      "type": "string",
      "description": "搜索关键词",
      "required": true
    },
    "startDate": {
      "type": "date",
      "description": "开始日期",
      "required": false
    }
  }
}
```

### LLMModel (模型定义)

定义可用的 LLM 模型及其特性。

**关键字段：**
- `id`：模型 ID (如 gpt-4, claude-3-opus)
- `name`：模型显示名称
- `providerId`：所属服务商
- `contextWindow`：上下文窗口大小
- `costPer1kTokens`：每 1k tokens 成本
- `supportsVision`：是否支持图像输入
- `supportsFunctionCalling`：是否支持函数调用

## 快速开始

### 配置 API

1. 进入设置页面
2. 选择「OpenAI 配置」
3. 输入您的 API Key
4. 选择默认模型
5. 保存设置

### 开始对话

1. 点击「新建对话」
2. 输入您的问题或需求
3. 选择合适的 AI 模型
4. 点击「发送」
5. 查看 AI 的回复

### 使用模板

1. 点击「模板库」
2. 选择适合的模板
3. 填入具体参数
4. 生成内容

## 高级功能

### 对话历史

- **历史记录**：保存所有对话历史
- **搜索功能**：快速查找历史对话
- **分类管理**：按主题组织对话
- **导出分享**：导出重要对话内容

### 自定义提示

- **提示词库**：保存常用提示词
- **角色扮演**：设置 AI 的角色和风格
- **参数调优**：调整生成参数
- **批处理**：批量处理多个任务

### API 管理

- **密钥管理**：安全管理 API 密钥
- **使用统计**：查看 API 调用量
- **成本控制**：设置预算限制
- **备用方案**：配置多个 API 提供商

## 数据安全

- **本地优先**：敏感数据本地处理
- **加密传输**：API 通信全程加密
- **隐私保护**：不保存敏感对话内容
- **合规性**：遵循数据保护法规

## 最佳实践

### 提升 AI 回复质量

1. **明确需求**：清晰地描述您的目标
2. **提供上下文**：给出必要的背景信息
3. **分步引导**：复杂任务拆分成小步骤
4. **迭代优化**：根据结果调整提示词

### 成本优化

1. **选择合适模型**：根据任务选择最优模型
2. **控制对话长度**：避免不必要的长对话
3. **使用缓存**：重复问题利用缓存结果
4. **监控使用量**：定期查看 API 使用统计

## 常见问题

### 配置与使用

**Q: 如何添加新的 LLM 服务商？**
A:
1. 在服务商管理界面添加新的服务商配置
2. 输入 API Key 和自定义端点（如果需要）
3. 选择可用的模型
4. 测试连接成功后即可使用

**Q: 如何让 AI 访问我的插件数据？**
A: 有两种方式：
- **数据分析方式**：在插件中注册数据分析方法，AI 可以获取数据摘要
- **工具调用方式**：创建 ToolApp，AI 可以直接调用插件的特定功能

**Q: 如何控制 AI 的回复质量？**
A: 调整助手参数：
- `temperature`: 0.0-1.0 (越低越确定，越高越随机)
- `systemPrompt`: 详细描述角色和任务
- `maxTokens`: 限制回复长度
- `model`: 选择更强大的模型

**Q: 支持哪些 LLM 服务商？**
A:
- ✅ OpenAI (GPT-3.5, GPT-4)
- ✅ Anthropic (Claude)
- ✅ Google (Gemini)
- ✅ 自定义端点（兼容 OpenAI API 格式的服务）
- ⚠️ 本地模型（Ollama 等，需自行配置）

### 技术问题

**Q: API Key 泄露了怎么办？**
A: 立即在对应服务商官网重置您的 API Key，并检查最近的使用记录。

**Q: AI 回复不准确怎么改善？**
A: 尝试提供更多上下文，或使用更具体的提示词，也可以更换其他模型。

**Q: 如何降低 API 成本？**
A: 使用 GPT-3.5 代替 GPT-4，缩短对话长度，使用缓存功能。

**Q: 工具调用失败怎么处理？**
A:
1. 检查工具参数是否完整和正确
2. 确认目标插件功能是否正常
3. 查看工具应用的执行日志
4. 验证 AI 模型是否支持函数调用

**Q: 支持离线使用吗？**
A: 目前需要网络连接调用 AI 服务，已支持本地模型（如 Ollama）配置。

### 数据分析

**Q: 如何为我的插件添加数据分析功能？**
A:
1. 创建 `PluginAnalysisMethod` 子类
2. 实现 `generatePrompt()` 方法返回数据摘要
3. 在插件中注册到 OpenAI 插件的分析服务

**Q: AI 分析的数据从哪里来？**
A: AI 分析的数据来自各插件注册的数据摘要方法，系统会自动聚合相关数据并生成提示词。

**Q: 可以同时分析多个插件的数据吗？**
A: 可以，AI 可以跨插件查询和分析数据，只需在查询中指定要分析的插件。

## 相关文件

### 核心文件
- `openai_plugin.dart` - 插件主类
- `models/ai_agent.dart` - AI助手模型
- `models/service_provider.dart` - 服务商模型
- `models/tool_app.dart` - 工具应用模型
- `models/llm_models.dart` - LLM模型定义
- `models/plugin_analysis_method.dart` - 插件分析方法接口

### 服务层
- `services/request_service.dart` - API请求服务
- `services/plugin_analysis_service.dart` - 插件分析服务
- `services/test_service.dart` - 测试服务

### 国际化
- `l10n/openai_localizations.dart`
- `l10n/openai_localizations_zh.dart`
- `l10n/openai_localizations_en.dart`

## 更新日志

- **2025-11-13**：初始化 OpenAI 插件文档，识别 6 个模型、3 个服务
- **v1.1.8**：新增 Claude 模型支持
- **v1.1.5**：优化数据分析功能
- **v1.1.0**：添加多模型切换
- **v1.0.0**：首次发布，集成 GPT 模型

---

开始使用 OpenAI 助手，让 AI 为您的工作和生活赋能！
