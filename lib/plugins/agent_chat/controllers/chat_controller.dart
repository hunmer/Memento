import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';
import '../../../core/plugin_manager.dart';
import '../../openai/openai_plugin.dart';
import '../../openai/models/ai_agent.dart';
import '../../openai/services/request_service.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../models/file_attachment.dart';
import '../models/tool_call_step.dart';
import '../services/message_service.dart';
import '../services/conversation_service.dart';
import '../services/token_counter_service.dart';
import '../services/tool_service.dart';
import '../../../utils/file_picker_helper.dart';

/// 聊天控制器
///
/// 管理单个会话的聊天功能
class ChatController extends ChangeNotifier {
  final Conversation conversation;
  final MessageService messageService;
  final ConversationService conversationService;

  /// 当前Agent
  AIAgent? _currentAgent;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在发送消息
  bool _isSending = false;

  /// 选中的文件附件
  List<File> _selectedFiles = [];

  /// 当前输入的文本
  String _inputText = '';

  ChatController({
    required this.conversation,
    required this.messageService,
    required this.conversationService,
  });

  // ========== Getters ==========

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  AIAgent? get currentAgent => _currentAgent;
  List<File> get selectedFiles => _selectedFiles;
  String get inputText => _inputText;

  List<ChatMessage> get messages {
    return messageService.currentMessages;
  }

  /// 获取上下文消息数量
  int get contextMessageCount {
    return conversation.contextMessageCount ?? 10;
  }

  /// 当前输入的token数（估算）
  int get inputTokenCount {
    int total = TokenCounterService.estimateTokenCount(_inputText);

    // 加上附件的token
    for (var file in _selectedFiles) {
      if (FilePickerHelper.isImageFile(file)) {
        total += TokenCounterService.estimateImageTokens();
      }
    }

    return total;
  }

  // ========== 初始化 ==========

  /// 初始化聊天控制器
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 加载消息
      await messageService.setCurrentConversation(conversation.id);
    } catch (e) {
      debugPrint('初始化聊天控制器失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // 在消息加载完成后，异步加载 agent（不阻塞界面）
    if (conversation.agentId != null) {
      _loadAgentInBackground(conversation.agentId!);
    }
  }

  /// 在后台加载 Agent（不影响 loading 状态）
  Future<void> _loadAgentInBackground(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('后台加载Agent失败: $e');
      // 加载失败不影响界面显示
    }
  }

  /// 选择并加载Agent
  Future<void> selectAgent(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);

        // 更新会话的 agentId
        final updatedConversation = conversation.copyWith(agentId: agentId);
        await conversationService.updateConversation(updatedConversation);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载Agent失败: $e');
      rethrow;
    }
  }

  /// 获取可用的Agent列表
  Future<List<AIAgent>> getAvailableAgents() async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        return await openAIPlugin.controller.loadAgents();
      }
      return [];
    } catch (e) {
      debugPrint('获取Agent列表失败: $e');
      return [];
    }
  }

  // ========== 消息操作 ==========

  /// 发送消息
  Future<void> sendMessage() async {
    if (_inputText.trim().isEmpty || _isSending) return;
    if (_currentAgent == null) {
      throw Exception('未选择Agent');
    }

    _isSending = true;
    notifyListeners();

    try {
      // 创建用户消息
      final userMessage = ChatMessage.user(
        conversationId: conversation.id,
        content: _inputText.trim(),
        tokenCount: TokenCounterService.estimateTokenCount(_inputText),
        attachments: await _processAttachments(),
      );

      // 保存用户消息
      await messageService.addMessage(userMessage);

      // 更新会话的最后消息
      await conversationService.updateLastMessage(
        conversation.id,
        _inputText.trim(),
      );

      // 清空输入
      final userInput = _inputText;
      final files = List<File>.from(_selectedFiles);
      _inputText = '';
      _selectedFiles.clear();
      notifyListeners();

      // 创建AI消息占位符
      final aiMessage = ChatMessage.ai(
        conversationId: conversation.id,
        content: '',
        isGenerating: true,
      );
      await messageService.addMessage(aiMessage);

      // 流式请求AI回复
      await _requestAIResponse(
        aiMessage.id,
        userInput,
        files,
      );
    } catch (e) {
      debugPrint('发送消息失败: $e');
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// 处理附件
  Future<List<FileAttachment>> _processAttachments() async {
    final attachments = <FileAttachment>[];

    for (var file in _selectedFiles) {
      final size = await FilePickerHelper.getFileSize(file);
      final fileName = FilePickerHelper.getFileName(file);

      if (FilePickerHelper.isImageFile(file)) {
        attachments.add(FileAttachment.image(
          filePath: file.path,
          fileName: fileName,
          fileSize: size,
        ));
      } else {
        attachments.add(FileAttachment.document(
          filePath: file.path,
          fileName: fileName,
          fileSize: size,
        ));
      }
    }

    return attachments;
  }

  /// 请求AI回复
  Future<void> _requestAIResponse(
    String aiMessageId,
    String userInput,
    List<File> files, {
    bool enableToolCalling = true, // 是否启用工具调用
  }) async {
    if (_currentAgent == null) return;

    final buffer = StringBuffer();
    int tokenCount = 0;
    bool isCollectingToolCall = false;

    try {
      // 构建上下文消息
      final contextMessages = _buildContextMessages(userInput);

      // 如果启用工具调用,添加工具列表到 system prompt
      if (enableToolCalling && _currentAgent!.enableFunctionCalling && contextMessages.isNotEmpty) {
        final toolsPrompt = ToolService.getToolListPrompt();
        final originalSystemPrompt = contextMessages[0].content;

        contextMessages[0] = ChatCompletionMessage.system(
          content: originalSystemPrompt is String
              ? originalSystemPrompt + toolsPrompt
              : toolsPrompt,
        );
      }

      // 处理文件（仅支持图片vision模式）
      final imageFiles = files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      await RequestService.streamResponse(
        agent: _currentAgent!,
        prompt: null, // 使用contextMessages
        contextMessages: contextMessages,
        vision: imageFiles.isNotEmpty,
        filePath: imageFiles.isNotEmpty ? imageFiles.first.path : null,
        onToken: (token) {
          buffer.write(token);
          tokenCount++;

          final content = buffer.toString();

          // 检测工具调用
          if (_currentAgent!.enableFunctionCalling &&
              ToolService.containsToolCall(content)) {
            isCollectingToolCall = true;
            // 显示收集中状态
            final displayContent = '$content\n\n⚙️ 正在准备工具调用...';
            messageService.updateAIMessageContent(
              conversation.id,
              aiMessageId,
              displayContent,
              tokenCount,
            );
          } else if (!isCollectingToolCall) {
            // 正常流式显示
            final processedContent =
                RequestService.processThinkingContent(content);

            // 更新AI消息
            messageService.updateAIMessageContent(
              conversation.id,
              aiMessageId,
              processedContent,
              tokenCount,
            );
          }
        },
        onError: (error) {
          debugPrint('AI响应错误: $error');

          // 更新为错误消息
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
            // 完成生成
            messageService.completeAIMessage(conversation.id, aiMessageId);

            // 更新会话的最后消息
            final finalContent = RequestService.processThinkingContent(
              buffer.toString(),
            );
            conversationService.updateLastMessage(
              conversation.id,
              finalContent.length > 50
                  ? '${finalContent.substring(0, 50)}...'
                  : finalContent,
            );
          }
        },
        replacePrompt: false, // 不替换prompt
      );
    } catch (e) {
      debugPrint('请求AI回复失败: $e');

      // 更新为错误消息
      messageService.updateAIMessageContent(
        conversation.id,
        aiMessageId,
        '抱歉，生成回复时出现错误：$e',
        0,
      );

      messageService.completeAIMessage(conversation.id, aiMessageId);
    }
  }

  /// 构建上下文消息列表
  List<ChatCompletionMessage> _buildContextMessages(String currentInput) {
    final messages = <ChatCompletionMessage>[];

    // 添加系统提示词
    if (_currentAgent != null) {
      messages.add(
        ChatCompletionMessage.system(
          content: _currentAgent!.systemPrompt,
        ),
      );
    }

    // 获取历史消息（排除正在生成的消息）
    final allMessages = messageService.currentMessages;
    final historyMessages = allMessages
        .where((msg) => !msg.isGenerating) // 排除正在生成的消息
        .toList();

    // 获取最后 N 条消息
    final contextMessages = historyMessages.length > contextMessageCount
        ? historyMessages.sublist(historyMessages.length - contextMessageCount)
        : historyMessages;

    // 转换历史消息为API格式
    for (var msg in contextMessages) {
      if (msg.isUser) {
        messages.add(
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(msg.content),
          ),
        );
      } else {
        messages.add(
          ChatCompletionMessage.assistant(
            content: msg.content,
          ),
        );
      }
    }

    return messages;
  }

  // ========== 输入管理 ==========

  /// 设置输入文本
  void setInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  /// 选择图片
  Future<void> pickImages() async {
    final files = await FilePickerHelper.pickImages(multiple: true);
    _selectedFiles.addAll(files);
    notifyListeners();
  }

  /// 选择文档
  Future<void> pickDocuments() async {
    final files = await FilePickerHelper.pickDocuments(multiple: true);
    _selectedFiles.addAll(files);
    notifyListeners();
  }

  /// 移除文件
  void removeFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      _selectedFiles.removeAt(index);
      notifyListeners();
    }
  }

  /// 清空文件
  void clearFiles() {
    _selectedFiles.clear();
    notifyListeners();
  }

  // ========== 消息编辑 ==========

  /// 编辑消息
  Future<void> editMessage(String messageId, String newContent) async {
    await messageService.editMessage(
      conversation.id,
      messageId,
      newContent,
    );
  }

  /// 删除消息
  Future<void> deleteMessage(String messageId) async {
    await messageService.deleteMessage(conversation.id, messageId);
  }

  /// 清空所有消息
  Future<void> clearAllMessages() async {
    await messageService.clearAllMessages(conversation.id);
    notifyListeners();
  }

  /// 重新生成AI回复
  /// 参数 messageId 可以是用户消息ID或AI消息ID
  Future<void> regenerateResponse(String messageId) async {
    if (_isSending) return;

    try {
      _isSending = true;
      notifyListeners();

      // 获取消息
      final message = messageService.getMessage(conversation.id, messageId);
      if (message == null) {
        throw Exception('消息不存在');
      }

      // 如果传入的是AI消息，找到前一条用户消息
      ChatMessage? userMessage;
      if (message.isUser) {
        userMessage = message;
      } else {
        // 找到这条AI消息之前的用户消息
        final messages = messageService.currentMessages;
        final currentIndex = messages.indexWhere((m) => m.id == messageId);
        if (currentIndex > 0) {
          // 向前查找最近的用户消息
          for (int i = currentIndex - 1; i >= 0; i--) {
            if (messages[i].isUser) {
              userMessage = messages[i];
              break;
            }
          }
        }
      }

      if (userMessage == null) {
        throw Exception('未找到对应的用户消息');
      }

      // 删除之后的AI回复
      await messageService.prepareRegenerate(conversation.id, userMessage.id);

      // 创建新的AI消息
      final aiMessage = ChatMessage.ai(
        conversationId: conversation.id,
        content: '',
        isGenerating: true,
      );
      await messageService.addMessage(aiMessage);

      // 重新请求AI回复
      await _requestAIResponse(
        aiMessage.id,
        userMessage.content,
        userMessage.attachments
            .map((a) => File(a.filePath))
            .toList(),
      );
    } catch (e) {
      debugPrint('重新生成回复失败: $e');
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ========== Token统计 ==========

  /// 获取会话总token数
  int getTotalTokens() {
    return messageService.getTotalTokens(conversation.id);
  }

  /// 获取上下文token数
  int getContextTokens() {
    return messageService.getContextTokens(conversation.id, contextMessageCount);
  }

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
      var displayContent = '$aiResponse\n\n';

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
          TokenCounterService.estimateTokenCount(displayContent),
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
              TokenCounterService.estimateTokenCount(displayContent),
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
              TokenCounterService.estimateTokenCount(displayContent),
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
      final errorContent = '$aiResponse\n\n❌ 工具调用处理失败: $e';
      messageService.updateAIMessageContent(
        conversation.id,
        messageId,
        errorContent,
        TokenCounterService.estimateTokenCount(errorContent),
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

    buffer.writeln('---');
    buffer.writeln('请根据以上工具执行结果直接回答用户的问题，不要再次调用工具。');

    return buffer.toString();
  }

  /// 使用工具结果继续对话
  Future<void> _continueWithToolResult(
    String originalMessageId,
    String toolResult,
  ) async {
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

    // 继续请求 AI（禁用工具调用，避免无限循环）
    await _requestAIResponse(
      newAiMessage.id,
      '',
      [],
      enableToolCalling: false,
    );
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}
