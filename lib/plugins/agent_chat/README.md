# Agent Chat 插件 - 功能总结

## 概述

Agent Chat是一个独立的AI聊天插件，支持多会话管理、文件附件、Agent选择和上下文配置。

## ✅ 已完成功能

### 核心架构
- ✅ **插件系统集成** - 已在main.dart中注册
- ✅ **数据模型** - Conversation、ChatMessage、FileAttachment、ConversationGroup
- ✅ **服务层** - ConversationService、MessageService、TokenCounterService
- ✅ **控制器** - ConversationController、ChatController
- ✅ **存储管理** - 基于StorageManager的持久化

### 会话管理
- ✅ **会话列表** - 显示所有会话，支持时间排序
- ✅ **会话创建** - 支持标题、Agent选择、分组
- ✅ **会话编辑** - 修改标题和分组
- ✅ **会话删除** - 带确认对话框
- ✅ **会话置顶** - 置顶会话显示在列表顶部
- ✅ **未读计数** - 显示未读消息数量

### 聊天功能
- ✅ **消息发送** - 文本消息发送
- ✅ **文件附件** - 支持图片和文档
  - 图片：jpg, jpeg, png, gif, bmp, webp
  - 文档：pdf, doc, docx, txt, xls, xlsx
- ✅ **文件预览** - 显示已选择的文件芯片
- ✅ **Markdown渲染** - 使用flutter_markdown显示格式化内容
- ✅ **流式响应** - AI回复实时显示（打字机效果）
- ✅ **消息气泡** - 极简设计，区分用户和AI消息

### 消息操作
- ✅ **复制消息** - 复制到剪贴板
- ✅ **编辑消息** - 用户消息可编辑
- ✅ **删除消息** - 带确认对话框
- ✅ **重新生成** - 重新生成AI回复

### Token管理
- ✅ **实时Token估算** - 输入框显示当前输入的token数
- ✅ **消息Token统计** - 每条消息显示token数
- ✅ **总Token统计** - 显示会话总token和上下文token
- ✅ **上下文配置** - 全局默认+会话级别自定义（1-50条消息）

### AI集成
- ✅ **OpenAI插件集成** - 读取Agent配置
- ✅ **多模型支持** - 通过RequestService支持不同模型
- ✅ **Vision模式** - 支持图片理解
- ✅ **上下文管理** - 自动构建消息历史
- ✅ **Thinking标签处理** - 自动处理<thinking>标签

### UI/UX
- ✅ **极简设计** - 清爽的界面风格
- ✅ **响应式布局** - 适配不同屏幕尺寸
- ✅ **加载状态** - 发送消息时显示加载指示器
- ✅ **错误处理** - SnackBar显示错误信息
- ✅ **自动滚动** - 新消息自动滚动到底部
- ✅ **时间显示** - 相对时间（刚刚、X分钟前）和绝对时间

## 📋 待实现功能

### 高优先级
- ⏳ **Agent选择** - 创建会话时选择Agent（当前为TODO）
- ⏳ **搜索功能** - 会话列表搜索（当前为TODO）
- ⏳ **分组功能** - 会话分组和过滤
- ⏳ **设置页面** - 全局配置（默认上下文数量等）

### 中优先级
- ⏳ **国际化** - 中英双语支持
- ⏳ **文档文件内容提取** - 支持读取PDF、DOCX等内容
- ⏳ **多图片支持** - 当前只支持第一张图片
- ⏳ **消息导出** - 导出会话历史

### 低优先级
- ⏳ **语音输入** - 支持语音转文字
- ⏳ **代码高亮** - Markdown代码块语法高亮
- ⏳ **消息引用** - 回复特定消息
- ⏳ **草稿保存** - 自动保存未发送的消息

## 📁 文件结构

```
lib/plugins/agent_chat/
├── agent_chat_plugin.dart           # 插件主类
├── models/                          # 数据模型
│   ├── conversation.dart            # 会话模型
│   ├── chat_message.dart            # 消息模型
│   ├── file_attachment.dart         # 附件模型
│   └── conversation_group.dart      # 分组模型
├── services/                        # 业务逻辑层
│   ├── conversation_service.dart    # 会话服务
│   ├── message_service.dart         # 消息服务
│   └── token_counter_service.dart   # Token统计服务
├── controllers/                     # 控制器层
│   ├── conversation_controller.dart # 会话控制器
│   └── chat_controller.dart         # 聊天控制器
└── screens/                         # 界面层
    ├── conversation_list_screen/    # 会话列表页面
    │   └── conversation_list_screen.dart
    └── chat_screen/                 # 聊天页面
        ├── chat_screen.dart         # 主页面
        └── components/              # 组件
            ├── markdown_content.dart     # Markdown渲染
            ├── message_bubble.dart       # 消息气泡
            └── message_input.dart        # 输入框
```

## 🔑 关键技术点

### 1. 流式响应实现
```dart
// ChatController中实现
await RequestService.streamResponse(
  onToken: (token) {
    buffer.write(token);
    messageService.updateAIMessageContent(
      conversation.id,
      aiMessageId,
      buffer.toString(),
      tokenCount
    );
  },
);

// MessageService触发通知
await updateMessage(updated); // 内部调用notifyListeners()

// ChatScreen监听变化
_controller.messageService.addListener(_onControllerChanged);
```

### 2. Token估算算法
```dart
// 中文：~1.4字符/token
// 英文单词：~1单词/token
// 混合文本考虑标点和特殊字符
static int estimateTokenCount(String text) {
  final chineseCount = chinesePattern.allMatches(text).length;
  final englishWords = text.split(RegExp(r'\s+')).length;
  return (chineseCount * 0.7).ceil() + englishWords;
}
```

### 3. 上下文管理
```dart
// 构建上下文消息
List<ChatCompletionMessage> _buildContextMessages(String currentInput) {
  final messages = <ChatCompletionMessage>[];

  // 1. 系统提示词
  messages.add(ChatCompletionMessage.system(
    content: _currentAgent!.systemPrompt,
  ));

  // 2. 历史消息（最后N条）
  final historyMessages = messageService.getLastMessages(
    conversation.id,
    contextMessageCount
  );

  // 3. 当前输入
  messages.add(ChatCompletionMessage.user(
    content: ChatCompletionUserMessageContent.string(currentInput),
  ));

  return messages;
}
```

### 4. 文件附件处理
```dart
// 存储相对路径而非绝对路径，支持跨设备同步
FileAttachment.image(
  filePath: file.path,  // 完整路径用于本地访问
  fileName: fileName,
  fileSize: size,
)

// Vision模式发送
final imageFiles = files.where((f) => FilePickerHelper.isImageFile(f));
await RequestService.streamResponse(
  vision: imageFiles.isNotEmpty,
  filePath: imageFiles.first.path,
);
```

## 🧪 测试检查清单

### 基础功能测试
- [ ] 创建新会话
- [ ] 发送文本消息
- [ ] 接收AI回复（验证流式显示）
- [ ] 编辑用户消息
- [ ] 删除消息
- [ ] 重新生成AI回复

### 附件功能测试
- [ ] 选择图片文件
- [ ] 选择文档文件
- [ ] 多文件选择
- [ ] 移除已选文件
- [ ] 发送带图片的消息（Vision模式）

### Token测试
- [ ] 输入框实时显示token
- [ ] 消息气泡显示token
- [ ] Token统计对话框
- [ ] 上下文设置（全局/会话级别）

### UI/UX测试
- [ ] 消息自动滚动
- [ ] 加载状态显示
- [ ] 错误提示
- [ ] 会话列表排序（置顶+时间）
- [ ] 未读计数更新

### 边界情况测试
- [ ] 空消息不能发送
- [ ] 发送中不能重复发送
- [ ] Agent未选择的错误提示
- [ ] 超长消息显示
- [ ] 大量消息的性能

## 📝 使用说明

### 创建新会话
1. 点击会话列表右上角"+"按钮
2. 输入会话标题
3. 选择Agent（TODO：当前需要手动实现）
4. （可选）添加分组

### 发送消息
1. 在输入框输入文本
2. （可选）点击附件按钮添加图片或文档
3. 点击发送按钮或按Enter

### 管理会话
- **置顶**：长按会话卡片，选择"置顶"
- **编辑**：长按会话卡片，选择"编辑"
- **删除**：长按会话卡片，选择"删除"

### 配置上下文
1. 进入聊天界面
2. 点击右上角设置图标
3. 选择"使用全局设置"或自定义数量（1-50）

## 🐛 已知问题

1. **RadioListTile deprecation** - Flutter 3.32后groupValue和onChanged已弃用，但仍可正常工作
2. **多图片支持** - 当前Vision模式只支持发送第一张图片
3. **文档内容提取** - PDF、DOCX等文件当前只发送元数据，不提取内容

## 🔄 版本历史

### v1.0.0 (当前)
- 初始版本
- 完成核心聊天功能
- 支持文件附件
- 实现流式响应
- Token统计和上下文管理

## 📚 相关依赖

- `flutter_markdown: ^0.7.4` - Markdown渲染
- `file_picker` - 文件选择（项目已有）
- `openai_dart` - OpenAI API集成（通过openai插件）
- `timeago` - 相对时间显示

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

---

**最后更新**: 2025-01-16
**开发状态**: ✅ 核心功能完成，可用于基础测试
