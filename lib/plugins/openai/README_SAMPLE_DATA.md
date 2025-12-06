# OpenAI 插件示例数据说明

## 概述

本文档说明了 OpenAI 插件中示例数据的使用方法和扩展指南。每个 AI agent 都配有独特的图标和颜色，方便用户识别和选择。

## 文件结构

```
lib/plugins/openai/
├── sample_data.dart              # 示例数据文件
├── models/
│   ├── prompt_preset.dart        # 提示词预设模型（已更新）
│   └── ai_agent.dart             # AI 助手模型
└── services/
    └── prompt_preset_service.dart # 提示词预设服务（已增强）
```

## 🎨 AI 助手图标设计

每个 AI 助手都有独特的 Material Design 图标和配色方案：

| AI 助手类型 | 图标 | 颜色 | 描述 |
|------------|------|------|------|
| 通用助手 | 💬 chat_bubble_outline | 🔵 蓝色 | 日常对话和问答 |
| 数据分析专家 | 📊 analytics_outlined | 🟢 绿色 | 数据分析和洞察 |
| 创意写作助手 | ✍️ create_outlined | 🟣 紫色 | 创意写作和文案 |
| 编程助手 | 💻 code_outlined | 🔷 靛蓝色 | 编程和技术支持 |
| 学习导师 | 🎓 school_outlined | 🟠 橙色 | 学习和教育辅导 |
| 健康生活顾问 | ❤️ favorite_outline | 🔴 红色 | 健康和生活方式 |
| 旅行规划师 | 🧭 explore_outlined | 🟢 青色 | 旅行和出行规划 |
| 心理支持顾问 | 🧠 psychology_outlined | 🌸 粉色 | 心理和情感支持 |

### 图标字段说明

在 AIAgent 模型中，每个 agent 包含以下图标相关字段：

```dart
'icon': Icons.chat_bubble_outline.codePoint,  // 图标代码点
'iconColor': Colors.blue.value,               // 图标颜色值
```

## 功能特性

### 1. 示例数据文件 (`sample_data.dart`)

**AI 助手示例（8个）**
- 通用助手 - 友好助手，适合日常对话
- 数据分析专家 - 专业数据分析，提供深度洞察
- 创意写作助手 - 专业创意写作伙伴
- 编程助手 - 专业软件开发顾问
- 学习导师 - 耐心学习顾问
- 健康生活顾问 - 专业健康管理
- 旅行规划师 - 专业旅行顾问
- 心理支持顾问 - 温暖心理支持

**提示词预设（10个）**
- 通用问答助手 - 日常问答模板
- 数据分析专家 - 数据分析专用模板
- 创意写作伙伴 - 创意写作模板
- 代码审查专家 - 代码优化模板
- 智能学习导师 - 学习辅导模板
- 健康生活顾问 - 健康管理模板
- 旅行规划大师 - 旅行规划模板
- 心理支持伙伴 - 心理支持模板
- 插件数据分析 - Memento 插件数据分析模板
- 日常聊天伙伴 - 轻松日常对话模板

### 2. 自动初始化

在 `openai_plugin.dart` 的 `initializeDefaultData()` 方法中：

```dart
@override
Future<void> initializeDefaultData() async {
  // 初始化 AI 助手数据
  final agentData = await storage.read('$storageDir/agents.json');
  if (agentData.isEmpty) {
    final defaultAgents = OpenAISampleData.defaultAgents;
    await storage.write('$storageDir/agents.json', {'agents': defaultAgents});
    debugPrint('已初始化 ${defaultAgents.length} 个默认智能体');
  }

  // 初始化提示词预设数据
  await _initializePromptPresets();
}
```

### 3. 增强的 PromptPresetService

新增功能：
- ✅ 按类别筛选预设
- ✅ 按标签搜索预设
- ✅ 获取默认预设
- ✅ 获取统计信息
- ✅ 导入/导出预设
- ✅ 重置为默认预设

### 4. PromptPreset 模型增强

新增字段：
- `category` - 预设类别（如：communication, analysis, creative 等）
- `isDefault` - 是否为默认预设

## 使用指南

### 在插件中使用示例数据

```dart
import 'package:Memento/plugins/openai/sample_data.dart';

// 获取默认 AI 助手
final agents = OpenAISampleData.defaultAgents;

// 获取默认提示词预设
final presets = OpenAISampleData.defaultPresets;
```

### 在 PromptPresetService 中使用

```dart
import 'package:Memento/plugins/openai/services/prompt_preset_service.dart';

// 获取服务实例
final service = PromptPresetService();

// 按类别筛选
final analysisPresets = service.getPresetsByCategory('analysis');

// 搜索预设
final searchResults = service.searchPresets('数据');

// 获取统计信息
final stats = service.getPresetStats();

// 导出预设
final jsonData = service.exportPresets();

// 导入预设
await service.importPresets(jsonData);

// 重置为默认
await service.resetToDefaults();
```

## 预设类别说明

| 类别代码 | 中文名称 | 描述 |
|---------|---------|------|
| communication | 通用对话 | 日常对话和交流 |
| analysis | 数据分析 | 数据分析和洞察 |
| creative | 创意写作 | 文学创作和文案 |
| technical | 技术编程 | 代码和技术相关 |
| education | 学习教育 | 学习和教育辅导 |
| lifestyle | 健康生活 | 健康和生活方式 |
| travel | 旅行规划 | 旅行和出行规划 |
| support | 心理支持 | 情感和心理支持 |

## 扩展指南

### 添加新的 AI 助手

在 `sample_data.dart` 中的 `defaultAgents` 列表中添加：

```dart
{
  'id': uuid.v4(),
  'name': '新助手名称',
  'description': '助手描述',
  'serviceProviderId': '服务商ID',
  'baseUrl': 'API地址',
  'headers': {'api-key': 'YOUR_API_KEY'},
  'model': '模型名称',
  'systemPrompt': '系统提示词',
  'tags': ['标签1', '标签2'],
  'temperature': 0.7,
  'maxLength': 2048,
  'enableFunctionCalling': false,
  'icon': Icons.new_releases_outlined.codePoint,  // 自定义图标
  'iconColor': Colors.amber.value,                // 自定义颜色
  'createdAt': now,
  'updatedAt': now,
}
```

**图标选择建议**：
- 通用功能：chat_bubble_outline, help_outline, assistant_outline
- 数据相关：analytics_outlined, insert_chart_outlined, pie_chart_outlined
- 创意类：create_outlined, brush_outlined, draw_outlined
- 技术类：code_outlined, developer_mode_outlined, computer_outlined
- 教育类：school_outlined, menu_book_outlined, lightbulb_outline
- 健康类：favorite_outline, health_and_safety_outlined, spa_outlined
- 旅行类：explore_outlined, flight_outlined, map_outlined
- 心理类：psychology_outlined, support_outlined, self_improvement_outlined

**配色建议**：
- 蓝色系：Colors.blue, Colors.lightBlue, Colors.indigo
- 绿色系：Colors.green, Colors.lightGreen, Colors.teal
- 紫色系：Colors.purple, Colors.deepPurple
- 暖色系：Colors.orange, Colors.amber, Colors.red
- 中性色：Colors.grey, Colors.blueGrey

### 添加新的提示词预设

在 `sample_data.dart` 中的 `defaultPresets` 列表中添加：

```dart
PromptPreset(
  id: uuid.v4(),
  name: '预设名称',
  description: '预设描述',
  content: '''提示词内容''',
  tags: ['标签1', '标签2'],
  category: '类别代码',
  isDefault: true,
  createdAt: now,
  updatedAt: now,
)
```

### 添加新的预设类别

在 `PromptPresetService` 的 `categoryNames` 映射中添加：

```dart
static const Map<String, String> categoryNames = {
  '新类别': '新类别名称',
  // ... 其他类别
};
```

## 数据存储结构

### AI 助手数据（JSON）
```json
{
  "agents": [
    {
      "id": "uuid",
      "name": "助手名称",
      "description": "助手描述",
      "serviceProviderId": "服务商ID",
      "baseUrl": "API地址",
      "headers": {"api-key": "密钥"},
      "model": "模型名称",
      "systemPrompt": "系统提示词",
      "tags": ["标签"],
      "temperature": 0.7,
      "maxTokens": 2048,
      "enableToolCalling": false,
      "createdAt": "2025-01-01T00:00:00.000Z",
      "updatedAt": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

### 提示词预设数据（JSON）
```json
{
  "presets": [
    {
      "id": "uuid",
      "name": "预设名称",
      "description": "预设描述",
      "content": "提示词内容",
      "tags": ["标签"],
      "category": "类别",
      "isDefault": true,
      "createdAt": "2025-01-01T00:00:00.000Z",
      "updatedAt": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

## 最佳实践

1. **示例数据设计**：
   - 提供多样化、实用的示例
   - 使用清晰的结构和注释
   - 包含不同场景和使用案例

2. **版本兼容性**：
   - 在模型中添加新字段时保持向后兼容
   - 使用默认值处理缺失字段

3. **用户数据保护**：
   - 在初始化前检查用户是否已有数据
   - 仅在数据为空或不存在时创建默认数据

4. **扩展性考虑**：
   - 使用枚举定义常量（如类别）
   - 提供清晰的接口和文档
   - 支持导入/导出功能

## 相关文件

- `sample_data.dart` - 示例数据定义
- `prompt_preset.dart` - 数据模型
- `prompt_preset_service.dart` - 业务逻辑服务
- `openai_plugin.dart` - 插件主类

## 更新日志

- **2025-12-06**: 创建示例数据文件，增强 PromptPresetService
  - ✅ 添加 8 个不同风格的 AI 助手
  - ✅ 添加 10 个专业提示词预设
  - ✅ 增强 PromptPreset 模型（添加 category 和 isDefault 字段）
  - ✅ 增强 PromptPresetService（添加筛选、搜索、导入/导出功能）
  - ✅ 实现自动初始化机制
  - ✅ **为每个 AI 助手添加独特图标和配色**
    - 通用助手 - 聊天气泡图标（蓝色）
    - 数据分析专家 - 分析图表图标（绿色）
    - 创意写作助手 - 创作图标（紫色）
    - 编程助手 - 代码图标（靛蓝色）
    - 学习导师 - 学校图标（橙色）
    - 健康生活顾问 - 心形图标（红色）
    - 旅行规划师 - 探索图标（青色）
    - 心理支持顾问 - 心理学图标（粉色）
  - ✅ 更新文档，提供图标选择和配色建议
