import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';

/// Agent Chat 插件示例数据
/// 当插件首次使用且没有数据时，自动加载这些示例数据
class AgentChatSampleData {
  /// 获取完整示例数据
  /// 包含多个分组、多个会话和丰富的对话内容
  static Map<String, dynamic> getFullSampleData() {
    final now = DateTime.now();

    // ========== 会话数据 ==========
    final conversations = [
      // 工作助手分组
      Conversation(
        id: 'conv-work-001',
        title: '代码审查助手',
        agentId: 'agent-code-review',
        groups: ['💼 工作助手'],
        contextMessageCount: 20,
        createdAt: now.subtract(const Duration(days: 20)),
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        isPinned: true,
        lastMessagePreview: '这段代码的性能可以进一步优化...',
        unreadCount: 0,
        metadata: {'type': 'code_review', 'priority': 'high'},
      ),

      // 学习伙伴分组
      Conversation(
        id: 'conv-study-001',
        title: 'Flutter 进阶学习',
        agentId: 'agent-tutor',
        groups: ['📚 学习伙伴'],
        contextMessageCount: 30,
        createdAt: now.subtract(const Duration(days: 25)),
        lastMessageAt: now.subtract(const Duration(hours: 5)),
        isPinned: true,
        lastMessagePreview: 'Provider 和 Riverpod 的区别和使用场景',
        unreadCount: 1,
        metadata: {'subject': 'Flutter', 'level': 'intermediate'},
      ),

      // 创意激发分组
      Conversation(
        id: 'conv-creative-001',
        title: '产品创意头脑风暴',
        agentId: 'agent-ideator',
        groups: ['🎨 创意激发'],
        contextMessageCount: 10,
        createdAt: now.subtract(const Duration(days: 12)),
        lastMessageAt: now.subtract(const Duration(hours: 8)),
        isPinned: false,
        lastMessagePreview: '基于用户行为分析的智能提醒系统...',
        unreadCount: 0,
        metadata: {'type': 'brainstorming', 'category': 'product'},
      ),
    ];

    // ========== 消息数据 ==========
    final messages = <String, List<ChatMessage>>{};

    // 代码审查助手会话消息
    messages['conv-work-001'] = [
      ChatMessage.user(
        conversationId: 'conv-work-001',
        content:
            '请帮我审查这段 Dart 代码，看看有什么可以优化的地方：\n\n```dart\nclass UserService {\n  List<User> users = [];\n\n  User? getUserById(String id) {\n    for (var user in users) {\n      if (user.id == id) return user;\n    }\n    return null;\n  }\n\n  void addUser(User user) {\n    users.add(user);\n  }\n}\n```',
        tokenCount: 120,
      ),
      ChatMessage.ai(
        conversationId: 'conv-work-001',
        content: '''这段代码整体结构不错，但有几个可以优化的地方：

## 🚀 性能优化

**1. 使用 HashMap 替代 List**
```dart
class UserService {
  final Map<String, User> _users = {};

  User? getUserById(String id) => _users[id];

  void addUser(User user) => _users[user.id] = user;
}
```

**性能提升**: 从 O(n) 优化到 O(1)

## 🔒 封装性优化

**2. 私有化内部数据**
```dart
class UserService {
  final Map<String, User> _users = {};

  List<User> get allUsers => List.unmodifiable(_users.values);
}
```

## ✅ 错误处理

**3. 添加输入验证**
```dart
void addUser(User user) {
  if (user.id.isEmpty) {
    throw ArgumentError('User ID cannot be empty');
  }
  _users[user.id] = user;
}
```

**改进建议**: 考虑实现 Iterable 接口或使用集合操作库如 `collection`。''',
        tokenCount: 280,
        isGenerating: false,
        metadata:
            {
                  'codeLanguage': 'dart',
                  'improvements': [
                    'performance',
                    'encapsulation',
                    'error_handling',
                  ],
                  'priority': 'high',
                }
                as Map<String, dynamic>,
      ),
      ChatMessage.user(
        conversationId: 'conv-work-001',
        content: '很好的建议！那对于并发修改的情况，应该怎么处理？',
        tokenCount: 45,
      ),
      ChatMessage.ai(
        conversationId: 'conv-work-001',
        content: '''对于并发修改，可以使用以下策略：

## 🔐 线程安全方案

**1. 使用 synchronized 锁**
```dart
import 'dart:async';

class UserService {
  final Map<String, User> _users = {};
  final _lock = Lock();

  Future<void> addUser(User user) async {
    await _lock.synchronized(() async {
      // 并发安全的操作
      _users[user.id] = user;
    });
  }
}
```

**2. 不可变集合**
```dart
class UserService {
  final Map<String, User> _users = {};

  List<User> get allUsers => List.unmodifiable(_users.values);

  UserService addUser(User user) {
    final newUsers = Map<String, User>.from(_users)..[user.id] = user;
    return UserService._(newUsers);
  }
}
```

## 📊 选择建议

- **简单场景**: 使用 Lock() 同步
- **函数式编程**: 使用不可变集合
- **高频场景**: 考虑 Actor 模型

哪种场景更适合你的应用？''',
        tokenCount: 320,
        isGenerating: false,
        metadata: {
          'topic': 'concurrency',
          'codeLanguage': 'dart',
          'approaches': ['synchronization', 'immutability', 'actor_model'],
        },
      ),
    ];

    // Flutter 进阶学习会话消息
    messages['conv-study-001'] = [
      ChatMessage.user(
        conversationId: 'conv-study-001',
        content: '能详细解释一下 Provider 和 Riverpod 的区别吗？我应该选择哪个？',
        tokenCount: 65,
      ),
      ChatMessage.ai(
        conversationId: 'conv-study-001',
        content: '''## 📊 Provider vs Riverpod 对比

### Provider
**优势**:
- ✅ 学习曲线平缓，易上手
- ✅ 社区支持丰富，资料多
- ✅ 官方推荐，稳定性好
- ✅ 语法简单直观

**劣势**:
- ❌ 依赖 BuildContext
- ❌ 重构时容易出错
- ❌ 测试相对困难
- ❌ 性能在大项目中可能下降

### Riverpod
**优势**:
- ✅ 不依赖 BuildContext
- ✅ 编译时安全
- ✅ 更好的测试支持
- ✅ 性能优秀
- ✅ 重构友好

**劣势**:
- ❌ 学习曲线陡峭
- ❌ 社区相对较小
- ❌ 语法稍复杂

## 🎯 选择建议

**选择 Provider 如果你是**:
- Flutter 初学者
- 小到中型项目
- 追求快速开发
- 团队对 Riverpod 不熟悉

**选择 Riverpod 如果你是**:
- 有状态管理经验
- 大型项目或复杂应用
- 注重代码质量和测试
- 追求最佳性能

## 💡 实际应用

很多开发者的策略是：
1. **初学阶段**: 使用 Provider
2. **进阶阶段**: 迁移到 Riverpod

你现在处于哪个阶段呢？''',
        tokenCount: 420,
        isGenerating: false,
        metadata: {
          'topic': 'state_management',
          'comparison': 'provider_vs_riverpod',
          'difficulty': 'intermediate',
        },
      ),
      ChatMessage.user(
        conversationId: 'conv-study-001',
        content: '我在做一个中等规模的项目，大概15个页面，需要管理用户状态、主题设置、网络数据等。推荐用哪个？',
        tokenCount: 95,
      ),
      ChatMessage.ai(
        conversationId: 'conv-study-001',
        content: '''## 🎯 针对你的项目推荐

对于 **15页中等规模项目**，我推荐 **Riverpod**，原因：

### 1️⃣ 项目复杂度匹配
- 15页涉及的状态管理足够复杂
- Riverpod 在这种规模下优势明显
- 网络数据 + 用户状态 + 主题 = 完美适配场景

### 2️⃣ 迁移成本分析
**如果已有 Provider 代码**:
```bash
# 使用迁移工具
dart pub global activate riverpod_generator
```

**新项目直接使用**:
```dart
// 用户状态
final userProvider = StateProvider<User?>((ref) => null);

// 主题状态
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

// 网络数据
final userDataProvider = FutureProvider<UserData>((ref) async {
  return await ApiService.getUserData();
});
```

### 3️⃣ 学习路径建议
1. **第1周**: 学习 Riverpod 基础语法
2. **第2周**: 重构现有状态
3. **第3周**: 掌握高级特性
4. **第4周**: 优化和测试

**时间投入**: 约 20-30 小时

需要我提供具体的迁移示例吗？''',
        tokenCount: 380,
        isGenerating: false,
        metadata: {
          'projectSize': 'medium',
          'pages': 15,
          'recommendation': 'riverpod',
          'migrationEffort': '20-30_hours',
        },
      ),
    ];

    // 产品创意头脑风暴会话消息
    messages['conv-creative-001'] = [
      ChatMessage.user(
        conversationId: 'conv-creative-001',
        content: '我在想做一个帮助用户提高工作效率的产品，有什么好的创意吗？',
        tokenCount: 60,
      ),
      ChatMessage.ai(
        conversationId: 'conv-creative-001',
        content: '''## 💡 工作效率产品创意集

### 🔥 热门方向

**1. AI 驱动的时间管理**
- 智能分析用户的工作模式
- 自动推荐最佳工作时间安排
- AI 助手协助处理重复性任务

**2. 知识管理系统**
- AI 自动整理笔记和文档
- 智能标签和分类
- 上下文相关的知识推荐

**3. 团队协作优化**
- 实时工作状态可视化
- 智能会议安排
- 代码/文档共享的智能版本控制

### 🎯 细分场景

**开发人员**:
- 智能代码补全和审查
- Bug 自动检测和修复建议
- 技术栈学习和推荐

**设计师**:
- AI 辅助 UI/UX 设计
- 设计资产智能管理
- 协作反馈收集分析

**产品经理**:
- 用户行为数据智能分析
- A/B 测试自动化
- 竞品监控和报告

## 🤔 深度思考

**你的用户群体**: 开发者？设计师？还是通用职场人群？
**核心痛点**: 时间管理？知识整理？还是团队协作？

我们聊聊你最感兴趣的方向？''',
        tokenCount: 380,
        isGenerating: false,
        metadata: {
          'category': 'product_idea',
          'domain': 'productivity',
          'targetUsers': 'general',
          'stage': 'ideation',
        },
      ),
      ChatMessage.user(
        conversationId: 'conv-creative-001',
        content: '我想做一个基于用户行为分析的智能提醒系统，主要针对个人用户',
        tokenCount: 70,
      ),
      ChatMessage.ai(
        conversationId: 'conv-creative-001',
        content: '''## 🚀 智能提醒系统 - 产品设计

### 📱 核心功能

**1. 行为模式学习**
```
用户日常行为数据:
- 应用使用时间
- 工作时间段
- 休息频率
- 任务完成时间
```

**2. 智能提醒策略**
- 📊 **数据驱动**: 基于历史数据预测最佳提醒时机
- 🧠 **情境感知**: 识别用户当前状态（专注/休闲/忙碌）
- 🎯 **个性化**: 每个用户独特的提醒规则

### 💎 产品亮点

**场景示例**:
- 🔥 "检测到你已连续工作2小时，建议休息10分钟"
- ☕ "现在是你的咖啡时间，需要来一杯吗？"
- 💧 "你通常在15分钟后需要补水，记得喝水哦"
- 📝 "根据你的习惯，现在是整理任务列表的好时机"

**技术实现**:
- 本地机器学习模型
- 隐私优先（数据不上传云端）
- 轻量级，低耗电

### 🎨 用户体验

**无缝集成**: 与日历、任务管理、专注应用联动
**智能过滤**: 避免过度提醒，只在真正需要时提醒
**正向激励**: 用游戏化设计让用户形成好习惯

这个方向你觉得如何？需要深入讨论某个功能吗？''',
        tokenCount: 450,
        isGenerating: false,
        metadata: {
          'productType': 'smart_reminder',
          'targetUsers': 'individual',
          'techStack': 'on_device_ml',
          'keyFeatures': ['behavior_analysis', 'smart_timing', 'context_aware'],
        },
      ),
    ];

    // 转换数据格式
    final conversationsJson = conversations.map((c) => c.toJson()).toList();
    final messagesJson = messages.map(
      (key, value) => MapEntry(key, value.map((m) => m.toJson()).toList()),
    );

    // 提取唯一分组名称
    final uniqueGroups = <String>{};
    for (final conv in conversations) {
      uniqueGroups.addAll(conv.groups);
    }

    return {
      'conversations': conversationsJson,
      'messages': messagesJson,
      'metadata': {
        'version': '2.0.0',
        'description': 'Agent Chat Plugin 完整示例数据（重构版）',
        'totalGroups': uniqueGroups.length,
        'totalConversations': conversations.length,
        'totalMessageThreads': messages.length,
        'createdAt': now.toIso8601String(),
      },
    };
  }

  /// 获取简化示例数据（用于快速测试）
  /// 包含1个分组、2个会话、每个会话3-5条消息
  static Map<String, dynamic> getSimplifiedSampleData() {
    final now = DateTime.now();

    final conversations = [
      Conversation(
        id: 'conv-simple-001',
        title: '日常问答',
        agentId: 'agent-general',
        groups: ['🤖 AI 助手'],
        createdAt: now.subtract(const Duration(days: 5)),
        lastMessageAt: now.subtract(const Duration(hours: 1)),
        lastMessagePreview: '好的，我来帮你解答这个问题',
        unreadCount: 0,
      ),
      Conversation(
        id: 'conv-simple-002',
        title: '学习笔记',
        agentId: 'agent-tutor',
        groups: ['🤖 AI 助手'],
        createdAt: now.subtract(const Duration(days: 3)),
        lastMessageAt: now.subtract(const Duration(hours: 3)),
        lastMessagePreview: 'Flutter 是一种跨平台开发框架',
        unreadCount: 0,
      ),
    ];

    final messages = <String, List<ChatMessage>>{
      'conv-simple-001': [
        ChatMessage.user(
          conversationId: 'conv-simple-001',
          content: '你好，能帮我解答一些问题吗？',
          tokenCount: 25,
        ),
        ChatMessage.ai(
          conversationId: 'conv-simple-001',
          content: '你好！我是你的AI助手，很高兴为你服务。有什么问题请尽管问，我会尽力帮助你。',
          tokenCount: 50,
          isGenerating: false,
        ),
        ChatMessage.user(
          conversationId: 'conv-simple-001',
          content: '我想了解一下 Flutter 开发',
          tokenCount: 20,
        ),
        ChatMessage.ai(
          conversationId: 'conv-simple-001',
          content: '''Flutter 是 Google 开发的一种跨平台移动应用开发框架。

**主要特点**:
- 一套代码，多平台运行 (iOS, Android, Web, Desktop)
- 高性能的原生体验
- 丰富的 UI 组件库
- 热重载开发体验

**核心技术**:
- Dart 语言
- Skia 图形引擎
- 自带 UI 组件

需要我详细介绍某个方面吗？''',
          tokenCount: 120,
          isGenerating: false,
        ),
      ],
      'conv-simple-002': [
        ChatMessage.user(
          conversationId: 'conv-simple-002',
          content: 'Flutter 的状态管理有哪些方案？',
          tokenCount: 30,
        ),
        ChatMessage.ai(
          conversationId: 'conv-simple-002',
          content: '''## 📊 Flutter 状态管理方案

### 官方方案
- **Provider**: 简单易用，推荐初学者
- **Riverpod**: Provider 的进化版，功能更强大

### 第三方方案
- **Bloc/Cubit**: 基于 streams，类型安全
- **GetX**: 功能丰富，但学习曲线陡峭
- **MobX**: 基于响应式编程

### 选择建议
- **小型项目**: Provider
- **中型项目**: Riverpod 或 Bloc
- **大型项目**: Bloc 或 GetX

你现在在学习哪个方案？''',
          tokenCount: 180,
          isGenerating: false,
        ),
        ChatMessage.user(
          conversationId: 'conv-simple-002',
          content: '推荐学习 Provider',
          tokenCount: 15,
        ),
        ChatMessage.ai(
          conversationId: 'conv-simple-002',
          content: '''很好的选择！Provider 是入门 Flutter 状态管理的最佳选择。

**学习路径**:
1. 理解 ChangeNotifier
2. 学习 Consumer 组件
3. 掌握 Selector 优化
4. 实践简单项目

**资源推荐**:
- Flutter 官方文档
- Provider 包的 examples
- 实战小项目练习

需要我为你准备详细的学习计划吗？''',
          tokenCount: 140,
          isGenerating: false,
        ),
      ],
    };

    return {
      'conversations': conversations.map((c) => c.toJson()).toList(),
      'messages': messages.map(
        (key, value) => MapEntry(key, value.map((m) => m.toJson()).toList()),
      ),
      'metadata': {
        'version': '2.0.0',
        'description': 'Agent Chat Plugin 简化示例数据（重构版）',
        'totalGroups': 1,
        'totalConversations': 2,
        'totalMessageThreads': 2,
      },
    };
  }

  /// 获取空白数据（空会话列表和空消息列表）
  /// 用于首次启动时无示例数据的场景
  static Map<String, dynamic> getEmptyData() {
    final now = DateTime.now();

    return {
      'conversations': [],
      'messages': {},
      'metadata': {
        'version': '2.0.0',
        'description': 'Agent Chat Plugin 空白数据（重构版）',
        'totalGroups': 0,
        'totalConversations': 0,
        'totalMessageThreads': 0,
        'createdAt': now.toIso8601String(),
      },
    };
  }

  /// 生成单个会话的示例消息
  /// 用于创建新会话时的欢迎消息
  static List<ChatMessage> getWelcomeMessages(String conversationId) {
    final now = DateTime.now();

    return [
      ChatMessage.ai(
        conversationId: conversationId,
        content: '''👋 欢迎使用 Agent Chat！

我是你的AI助手，可以帮助你：
- 💬 回答问题
- 💡 提供建议
- 📚 协助学习
- 🎯 解决问题

请告诉我你想要聊什么，我会尽力帮助你！''',
        tokenCount: 80,
        isGenerating: false,
        metadata: {
          'type': 'welcome',
          'style': 'friendly',
          'timestamp': now.toIso8601String(),
        },
      ),
    ];
  }
}
