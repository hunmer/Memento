[根目录](../../../CLAUDE.md) > [lib](../../) > [plugins](../) > **chat**

---

# 聊天插件 (Chat Plugin) - 模块文档

## 模块职责

聊天插件是 Memento 的核心功能模块之一，提供：

- **多频道管理**：创建多个独立的聊天频道（类似微信文件助手）
- **丰富消息类型**：文本、图片、视频、音频、文件、Markdown
- **AI 对话集成**：通过 @AI 触发上下文对话
- **时间线视图**：跨频道的消息时间线与搜索
- **用户系统**：支持多用户（自己 + AI 助手）
- **消息管理**：收藏、固定、回复、删除等操作

---

## 入口与启动

### 插件主类

**文件**: `chat_plugin.dart`

```dart
class ChatPlugin extends BasePlugin with ChangeNotifier {
    @override
    String get id => 'chat';

    @override
    Future<void> initialize() async {
        // 初始化服务层
        settingsService = SettingsService(this);
        userService = UserService(this);
        channelService = ChannelService(this);
        messageService = MessageService(this);
        uiService = UIService(settingsService, userService, this);

        // 依次初始化各服务
        await settingsService.initialize();
        await userService.initialize();
        await channelService.initialize();
        await messageService.initialize();
        await uiService.initialize();
    }

    @override
    Widget buildMainView(BuildContext context) {
        return ChatMainView();
    }
}
```

### 主界面入口

**文件**: `screens/chat_screen/chat_screen.dart`

**路由**: `Navigator.pushNamed(context, '/chat')`

---

## 对外接口

### 服务层架构

插件采用 **Service 层模式**，业务逻辑与 UI 分离：

| 服务 | 文件 | 职责 |
|------|------|------|
| `ChannelService` | `services/channel_service.dart` | 频道增删改查、消息加载 |
| `MessageService` | `services/message_service.dart` | 消息发送、编辑、删除、收藏 |
| `UserService` | `services/user_service.dart` | 用户管理（自己 + AI 用户） |
| `SettingsService` | `services/settings_service.dart` | 插件配置（主题、排序等） |
| `UIService` | `services/ui_service.dart` | UI 组件构建（卡片视图、设置界面） |
| `FileService` | `services/file_service.dart` | 文件上传、预览 |

### 核心 API

#### ChannelService

```dart
// 获取所有频道
Future<List<Channel>> getChannels();

// 创建频道
Future<Channel> createChannel(String name, {String? avatar, Color? color});

// 删除频道
Future<void> deleteChannel(String channelId);

// 加载频道消息
Future<List<Message>> getChannelMessages(String channelId, {int? limit});

// 根据消息ID获取消息
Future<Message?> getMessageById(String messageId);
```

#### MessageService

```dart
// 发送文本消息
Future<Message> sendTextMessage(String channelId, String content, {String? replyToId});

// 发送文件消息
Future<Message> sendFileMessage(String channelId, String filePath, FileType fileType);

// 删除消息
Future<void> deleteMessage(String channelId, String messageId);

// 收藏/取消收藏
Future<void> toggleFavorite(String channelId, String messageId);

// 固定/取消固定
Future<void> togglePinned(String channelId, String messageId);
```

#### UserService

```dart
// 获取当前用户
User getCurrentUser();

// 获取AI用户
User getAIUser();

// 更新用户信息
Future<void> updateUser(User user);
```

---

## 关键依赖与配置

### 外部依赖

- `image_picker`: 图片/视频选择
- `file_picker`: 文件选择
- `audioplayers`: 音频播放
- `record`: 音频录制
- `flutter_quill`: Markdown 渲染
- `photo_view`: 图片查看器
- `media_kit`: 视频播放

### 插件依赖

- **OpenAI Plugin**: AI 对话功能
- **Core Event System**: 消息事件广播

### 配置键

**路径**: `configs/chat/settings.json`

```json
{
  "showTimestamp": true,
  "messageGrouping": "byDate",
  "defaultAvatar": "assets/icon/default_user.png"
}
```

---

## 数据模型

### Channel (频道)

**文件**: `models/channel.dart`

```dart
class Channel {
  String id;                    // UUID
  String name;                  // 频道名称
  String? avatar;               // 头像路径
  Color? color;                 // 主题色
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
  Message? lastMessage;         // 最后一条消息
  int unreadCount;              // 未读数量

  // 序列化
  Map<String, dynamic> toJson();
  factory Channel.fromJson(Map<String, dynamic> json);
}
```

**存储路径**: `chat/channels/<channelId>.json`

---

### Message (消息)

**文件**: `models/message.dart`

```dart
class Message {
  String id;                    // UUID
  String channelId;             // 所属频道
  String content;               // 消息内容
  String userId;                // 发送者ID
  MessageType type;             // 消息类型
  DateTime timestamp;           // 发送时间
  bool isFavorite;              // 是否收藏
  bool isPinned;                // 是否固定
  String? replyToId;            // 回复的消息ID
  Map<String, dynamic>? metadata; // 额外元数据

  // 序列化
  Map<String, dynamic> toJson();
  factory Message.fromJson(Map<String, dynamic> json);
}

enum MessageType {
  text,      // 文本
  image,     // 图片
  video,     // 视频
  audio,     // 音频
  file,      // 文件
  markdown,  // Markdown
}
```

**存储路径**: `chat/messages/<channelId>/<messageId>.json`

---

### User (用户)

**文件**: `models/user.dart`

```dart
class User {
  String id;                    // UUID
  String name;                  // 用户名
  String? avatar;               // 头像路径
  bool isAI;                    // 是否为AI

  // 序列化
  Map<String, dynamic> toJson();
  factory User.fromJson(Map<String, dynamic> json);
}
```

**存储路径**: `chat/users/<userId>.json`

---

## 界面层结构

### 主界面组件树

```
ChatMainView
└── ChatScreen
    ├── ChatAppBar (顶栏)
    │   ├── 频道切换器
    │   ├── 搜索按钮
    │   └── 更多菜单
    ├── MessageListView (消息列表)
    │   ├── DateSeparator (日期分隔符)
    │   └── MessageBubble (消息气泡)
    │       ├── Avatar (头像)
    │       ├── MessageContent (内容)
    │       │   ├── TextMessage
    │       │   ├── ImageMessage
    │       │   ├── VideoMessage
    │       │   ├── AudioMessage
    │       │   └── FileMessage
    │       ├── MessageActions (操作按钮)
    │       └── MessageTimestamp (时间戳)
    └── MessageInput (输入框)
        ├── InputField (文本输入)
        ├── SendButton (发送按钮)
        └── MessageInputActions (附件按钮)
            ├── ImagePicker
            ├── VideoPicker
            ├── AudioRecorder
            ├── FilePicker
            └── MarkdownEditor
```

### 关键界面文件

| 文件路径 | 职责 |
|---------|------|
| `screens/chat_screen/chat_screen.dart` | 聊天主界面 |
| `screens/chat_screen/widgets/message_bubble.dart` | 消息气泡组件 |
| `screens/chat_screen/widgets/message_input/` | 输入框相关 |
| `screens/chat_screen/widgets/message_input_actions/` | 附件操作 |
| `screens/timeline/timeline_screen.dart` | 时间线视图 |
| `screens/channel_list/` | 频道列表 |

---

## 时间线功能

### 时间线控制器

**文件**: `screens/timeline/controllers/timeline_controller.dart`

**特性**：
- 跨频道消息聚合
- 按时间排序
- 分页加载（每页 20 条）
- 全文搜索
- 筛选器（频道、用户、消息类型）

### 时间线使用示例

```dart
// 获取时间线消息
final messages = await timelineController.loadMessages(
  limit: 50,
  offset: 0,
  filters: TimelineFilter(
    channelIds: ['channel1', 'channel2'],
    searchQuery: 'keyword',
  ),
);

// 搜索消息
await timelineController.searchMessages('keyword');
```

---

## AI 对话集成

### 触发方式

在消息中输入 `@AI` 或 `@助手名称`，系统会：

1. 解析 @mention
2. 查找对应的 AI 助手（通过 OpenAI 插件）
3. 构建上下文（最近 10 条消息）
4. 调用 AI API
5. 将 AI 回复作为新消息插入

### 实现逻辑

**文件**: `services/message_service.dart`

```dart
Future<void> handleAIMention(Message message) async {
  // 1. 解析 @AI
  final mentions = parseAIMentions(message.content);
  if (mentions.isEmpty) return;

  // 2. 获取上下文
  final context = await getRecentMessages(message.channelId, limit: 10);

  // 3. 调用 OpenAI 插件
  final openAIPlugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
  final response = await openAIPlugin.sendMessage(
    agentId: mentions.first.agentId,
    message: message.content,
    context: context,
  );

  // 4. 插入 AI 回复
  await sendTextMessage(message.channelId, response, replyToId: message.id);
}
```

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **已知问题**:
  - 大量消息时滚动性能待优化
  - 图片/视频缓存机制待完善

### 测试建议

1. **高优先级**：
   - `ChannelService` 的 CRUD 操作
   - `MessageService` 的消息发送与删除
   - AI mention 解析逻辑

2. **中优先级**：
   - 时间线分页加载
   - 搜索功能准确性
   - 消息序列化/反序列化

3. **低优先级**：
   - UI 响应速度
   - 大文件上传稳定性

---

## 常见问题 (FAQ)

### Q1: 如何添加新的消息类型？

1. 在 `models/message.dart` 的 `MessageType` 枚举中添加类型
2. 在 `MessageContent` 组件中添加渲染逻辑
3. 在 `MessageInputActions` 中添加触发按钮

### Q2: 如何自定义消息气泡样式？

修改 `screens/chat_screen/widgets/message_bubble.dart`：

```dart
Container(
  decoration: BoxDecoration(
    color: isMe ? Colors.blue[100] : Colors.grey[200],
    borderRadius: BorderRadius.circular(16),
  ),
  child: MessageContent(message: message),
)
```

### Q3: 如何导出聊天记录？

当前未实现，建议添加：

```dart
Future<File> exportChannelMessages(String channelId) async {
  final messages = await getChannelMessages(channelId);
  final jsonData = messages.map((m) => m.toJson()).toList();
  final file = File('${channelId}_export.json');
  await file.writeAsString(jsonEncode(jsonData));
  return file;
}
```

### Q4: 消息数量过多导致卡顿怎么办？

优化方向：
1. 实现虚拟滚动（`ListView.builder` 已部分实现）
2. 限制内存中的消息数量（当前加载所有消息）
3. 添加消息归档功能（30天后自动归档）

---

## 相关文件清单

### 核心服务 (7个)
- `services/channel_service.dart` - 频道管理
- `services/message_service.dart` - 消息管理
- `services/user_service.dart` - 用户管理
- `services/settings_service.dart` - 配置管理
- `services/ui_service.dart` - UI构建
- `services/file_service.dart` - 文件处理

### 数据模型 (5个)
- `models/channel.dart` - 频道模型
- `models/message.dart` - 消息模型
- `models/user.dart` - 用户模型
- `models/file_message.dart` - 文件消息
- `models/serializers.dart` - 序列化工具

### 界面组件 (30+)
- `screens/chat_screen/` - 聊天界面（10+文件）
- `screens/timeline/` - 时间线（8+文件）
- `screens/channel_list/` - 频道列表（2个文件）

### 国际化
- `l10n/chat_localizations.dart`
- `l10n/chat_localizations_zh.dart`
- `l10n/chat_localizations_en.dart`

### 工具类
- `utils/date_formatter.dart` - 日期格式化
- `events/user_events.dart` - 用户事件

---

## 变更记录 (Changelog)

- **2025-11-13T04:06:10+00:00**: 初始化聊天插件文档，识别 7 个服务、5 个模型、30+ 界面组件

---

**上级目录**: [返回插件目录](../../../CLAUDE.md#模块索引) | [返回根文档](../../../CLAUDE.md)
