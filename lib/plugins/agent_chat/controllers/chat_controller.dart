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
import '../models/saved_tool_template.dart';
import '../services/message_service.dart';
import '../services/conversation_service.dart';
import '../services/token_counter_service.dart';
import '../services/tool_service.dart';
import '../services/tool_template_service.dart';
import '../../../utils/file_picker_helper.dart';

/// 聊天控制器
///
/// 管理单个会话的聊天功能
class ChatController extends ChangeNotifier {
  final Conversation conversation;
  final MessageService messageService;
  final ConversationService conversationService;
  final ToolTemplateService? templateService;
  bool _conversationServiceInitialized = false;

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
    this.templateService,
  });

  // ========== Getters ==========

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  AIAgent? get currentAgent => _currentAgent;
  List<File> get selectedFiles => _selectedFiles;
  String get inputText => _inputText;

  List<ChatMessage> get messages {
    // 只返回顶级消息（没有父消息ID的消息）
    final allMessages = messageService.currentMessages;
    final topLevel = allMessages.where((msg) => msg.parentId == null).toList();

    return topLevel;
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
      await _ensureConversationServiceReady();
      debugPrint(
        '📝 初始化会话: ${conversation.id}, AgentID: ${conversation.agentId}',
      );

      // 先加载agent（如果有）
      if (conversation.agentId != null) {
        await _loadAgentInBackground(conversation.agentId!);
        debugPrint('📝 Agent加载完成，当前Agent: ${_currentAgent?.name}');
      } else {
        debugPrint('⚠️ 会话没有绑定Agent');
      }

      // 再加载消息
      await messageService.setCurrentConversation(conversation.id);
      debugPrint('📝 消息加载完成，共 ${messageService.currentMessages.length} 条');
    } catch (e) {
      debugPrint('❌ 初始化聊天控制器失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureConversationServiceReady() async {
    if (_conversationServiceInitialized) return;
    await conversationService.initialize();
    _conversationServiceInitialized = true;
  }

  /// 在后台加载 Agent（不影响 loading 状态）
  Future<void> _loadAgentInBackground(String agentId) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);
        debugPrint('✅ Agent加载成功: ${_currentAgent?.name} (ID: $agentId)');
        notifyListeners();
      } else {
        debugPrint('❌ OpenAI插件未找到，无法加载Agent');
      }
    } catch (e) {
      debugPrint('❌ 后台加载Agent失败: $e');
      // 加载失败不影响界面显示
    }
  }

  /// 选择并加载Agent
  Future<void> selectAgent(String agentId) async {
    try {
      await _ensureConversationServiceReady();
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
      await _requestAIResponse(aiMessage.id, userInput, files);
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
        attachments.add(
          FileAttachment.image(
            filePath: file.path,
            fileName: fileName,
            fileSize: size,
          ),
        );
      } else {
        attachments.add(
          FileAttachment.document(
            filePath: file.path,
            fileName: fileName,
            fileSize: size,
          ),
        );
      }
    }

    return attachments;
  }

  /// 请求AI回复（两阶段工具调用）
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

      // ========== 第一阶段：发送简要索引 ==========
      if (enableToolCalling &&
          _currentAgent!.enableFunctionCalling &&
          contextMessages.isNotEmpty) {
        final toolBriefPrompt = ToolService.getToolBriefPrompt();
        final originalSystemPrompt = contextMessages[0].content;

        contextMessages[0] = ChatCompletionMessage.system(
          content: originalSystemPrompt is String
              ? originalSystemPrompt + toolBriefPrompt
              : toolBriefPrompt,
        );
      }

      // 处理文件（仅支持图片vision模式）
      final imageFiles =
          files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      // 第一阶段：流式接收 AI 回复
      await RequestService.streamResponse(
        agent: _currentAgent!,
        prompt: null,
        contextMessages: contextMessages,
        vision: imageFiles.isNotEmpty,
        filePath: imageFiles.isNotEmpty ? imageFiles.first.path : null,
        onToken: (token) {
          buffer.write(token);
          tokenCount++;

          final content = buffer.toString();

          // 检测是否为工具需求（第一阶段）或工具调用（第二阶段）
          final toolRequest = ToolService.parseToolRequest(content);
          final containsToolCall = ToolService.containsToolCall(content);

          if (_currentAgent!.enableFunctionCalling &&
              (toolRequest != null || containsToolCall)) {
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
            final processedContent = RequestService.processThinkingContent(
              content,
            );

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

          messageService.updateAIMessageContent(
            conversation.id,
            aiMessageId,
            '抱歉，生成回复时出现错误：$error',
            0,
          );

          messageService.completeAIMessage(conversation.id, aiMessageId);
        },
        onComplete: () async {
          final firstResponse = buffer.toString();

          // ========== 检测工具需求（第一阶段响应）==========
          final toolRequest = ToolService.parseToolRequest(firstResponse);

          if (_currentAgent!.enableFunctionCalling &&
              toolRequest != null &&
              toolRequest.isNotEmpty) {
            debugPrint('🔍 AI 请求工具: ${toolRequest.join(", ")}');

            // ========== 第二阶段：追加详细文档 ==========
            try {
              final detailPrompt =
                  await ToolService.getToolDetailPrompt(toolRequest);

              // 添加 AI 第一次回复到上下文
              contextMessages.add(
                ChatCompletionMessage.assistant(content: firstResponse),
              );

              // 添加详细文档请求
              contextMessages.add(
                ChatCompletionMessage.user(
                  content: ChatCompletionUserMessageContent.string(
                    '$detailPrompt\n\n请根据文档生成工具调用代码。',
                  ),
                ),
              );

              // 清空 buffer，准备接收第二阶段响应
              buffer.clear();
              tokenCount = 0;
              isCollectingToolCall = false;

              // 第二阶段：请求生成工具调用代码
              await RequestService.streamResponse(
                agent: _currentAgent!,
                prompt: null,
                contextMessages: contextMessages,
                vision: false,
                onToken: (token) {
                  buffer.write(token);
                  tokenCount++;

                  final content = buffer.toString();

                  if (_currentAgent!.enableFunctionCalling &&
                      ToolService.containsToolCall(content)) {
                    isCollectingToolCall = true;
                    final displayContent = '$content\n\n⚙️ 正在准备执行工具...';
                    messageService.updateAIMessageContent(
                      conversation.id,
                      aiMessageId,
                      displayContent,
                      tokenCount,
                    );
                  } else if (!isCollectingToolCall) {
                    final processedContent =
                        RequestService.processThinkingContent(content);
                    messageService.updateAIMessageContent(
                      conversation.id,
                      aiMessageId,
                      processedContent,
                      tokenCount,
                    );
                  }
                },
                onError: (error) {
                  debugPrint('第二阶段 AI 响应错误: $error');
                  messageService.updateAIMessageContent(
                    conversation.id,
                    aiMessageId,
                    '抱歉，生成工具调用时出现错误：$error',
                    0,
                  );
                  messageService.completeAIMessage(conversation.id, aiMessageId);
                },
                onComplete: () async {
                  final secondResponse = buffer.toString();

                  // 执行工具调用
                  if (ToolService.containsToolCall(secondResponse)) {
                    await _handleToolCall(aiMessageId, secondResponse);
                  } else {
                    // 没有生成工具调用，直接完成
                    _processNormalResponse(aiMessageId, secondResponse);
                  }
                },
                replacePrompt: false,
              );
            } catch (e) {
              debugPrint('第二阶段请求失败: $e');
              messageService.updateAIMessageContent(
                conversation.id,
                aiMessageId,
                '抱歉，获取工具文档时出现错误：$e',
                0,
              );
              messageService.completeAIMessage(conversation.id, aiMessageId);
            }
          } else if (_currentAgent!.enableFunctionCalling &&
              ToolService.containsToolCall(firstResponse)) {
            // 直接包含工具调用（跳过第一阶段）
            await _handleToolCall(aiMessageId, firstResponse);
          } else {
            // 无需工具，直接完成
            _processNormalResponse(aiMessageId, firstResponse);
          }
        },
        replacePrompt: false,
      );
    } catch (e) {
      debugPrint('请求AI回复失败: $e');

      messageService.updateAIMessageContent(
        conversation.id,
        aiMessageId,
        '抱歉，生成回复时出现错误：$e',
        0,
      );

      messageService.completeAIMessage(conversation.id, aiMessageId);
    }
  }

  /// 处理正常回复（无需工具调用）
  void _processNormalResponse(String messageId, String content) {
    final processedContent = RequestService.processThinkingContent(content);

    messageService.updateAIMessageContent(
      conversation.id,
      messageId,
      processedContent,
      TokenCounterService.estimateTokenCount(content),
    );

    messageService.completeAIMessage(conversation.id, messageId);

    // 更新会话的最后消息
    conversationService.updateLastMessage(
      conversation.id,
      processedContent.length > 50
          ? '${processedContent.substring(0, 50)}...'
          : processedContent,
    );
  }

  /// 构建上下文消息列表
  List<ChatCompletionMessage> _buildContextMessages(String currentInput) {
    final messages = <ChatCompletionMessage>[];

    // 添加系统提示词
    if (_currentAgent != null) {
      messages.add(
        ChatCompletionMessage.system(content: _currentAgent!.systemPrompt),
      );
    }

    // 获取历史消息（排除正在生成的消息，保留子消息以避免丢失工具结果）
    final allMessages = messageService.currentMessages;
    final historyMessages =
        allMessages.where((msg) => !msg.isGenerating).toList();

    // 获取最后 N 条消息
    final contextMessages =
        historyMessages.length > contextMessageCount
            ? historyMessages.sublist(
              historyMessages.length - contextMessageCount,
            )
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
        messages.add(ChatCompletionMessage.assistant(content: msg.content));
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
    await messageService.editMessage(conversation.id, messageId, newContent);
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
        userMessage.attachments.map((a) => File(a.filePath)).toList(),
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
    return messageService.getContextTokens(
      conversation.id,
      contextMessageCount,
    );
  }

  /// 处理工具调用
  Future<void> _handleToolCall(String messageId, String aiResponse) async {
    debugPrint('🔧 开始处理工具调用, messageId=${messageId.substring(0, 8)}');

    try {
      // 1. 解析工具调用
      final toolCall = ToolService.parseToolCallFromResponse(aiResponse);
      if (toolCall == null) {
        debugPrint('❌ 工具调用解析失败');
        // 解析失败，直接完成消息
        messageService.completeAIMessage(conversation.id, messageId);
        return;
      }

      debugPrint('✅ 解析到 ${toolCall.steps.length} 个工具步骤');

      // 2. 更新消息，将toolCall保存到消息中
      final message = messageService.getMessage(conversation.id, messageId);
      if (message == null) {
        debugPrint('❌ 未找到消息: $messageId');
        return;
      }

      // 提取AI的思考内容（去除工具调用JSON）
      final thinkingContent = RequestService.processThinkingContent(aiResponse);
      debugPrint('💭 思考内容长度: ${thinkingContent.length}');

      var updatedMessage = message.copyWith(
        content: thinkingContent,
        toolCall: toolCall,
      );
      await messageService.updateMessage(updatedMessage);

      // 3. 逐步执行工具调用
      final toolResultsBuffer = StringBuffer();
      debugPrint('🚀 开始执行 ${toolCall.steps.length} 个步骤');

      for (int i = 0; i < toolCall.steps.length; i++) {
        final step = toolCall.steps[i];
        debugPrint('  步骤 ${i + 1}: ${step.title}');

        // 更新步骤为执行中
        step.status = ToolCallStatus.running;
        updatedMessage = updatedMessage.copyWith(toolCall: toolCall);
        await messageService.updateMessage(updatedMessage);

        // 执行工具调用
        if (step.method == 'run_js') {
          try {
            final result = await ToolService.executeJsCode(step.data);
            debugPrint('  ✅ 步骤 ${i + 1} 执行成功');

            // 更新步骤为成功
            step.result = result;
            step.status = ToolCallStatus.success;
            updatedMessage = updatedMessage.copyWith(toolCall: toolCall);
            await messageService.updateMessage(updatedMessage);

            // 收集工具结果到buffer
            toolResultsBuffer.writeln('步骤 ${i + 1}: ${step.title}');
            toolResultsBuffer.writeln('结果: $result');
            toolResultsBuffer.writeln();
          } catch (e) {
            // 更新步骤为失败
            step.error = e.toString();
            step.status = ToolCallStatus.failed;
            updatedMessage = updatedMessage.copyWith(toolCall: toolCall);
            await messageService.updateMessage(updatedMessage);

            // 收集错误到buffer
            toolResultsBuffer.writeln('步骤 ${i + 1}: ${step.title}');
            toolResultsBuffer.writeln('错误: $e');
            toolResultsBuffer.writeln();

            // 将工具结果追加到content（即使失败）
            final contentWithToolResult =
                '$thinkingContent\n\n[工具执行结果]\n${toolResultsBuffer.toString()}';
            updatedMessage = updatedMessage.copyWith(
              content: contentWithToolResult,
            );
            await messageService.updateMessage(updatedMessage);

            // 完成消息生成（失败）
            messageService.completeAIMessage(conversation.id, messageId);
            return; // 中断流程
          }
        }
      }

      // 4. 将工具结果追加到content
      final contentWithToolResult =
          '$thinkingContent\n\n[工具执行结果]\n${toolResultsBuffer.toString()}';
      updatedMessage = updatedMessage.copyWith(content: contentWithToolResult);
      await messageService.updateMessage(updatedMessage);
      debugPrint('📝 已将工具结果追加到content, 总长度: ${contentWithToolResult.length}');

      // 5. 所有工具调用成功，将结果发送给 AI 继续生成
      final toolResultMessage = _buildToolResultMessage(toolCall.steps);
      debugPrint('🤖 准备让AI继续生成回复');
      await _continueWithToolResult(
        messageId,
        toolResultMessage,
        contentWithToolResult,
      );
    } catch (e) {
      // 解析失败
      final errorContent = '❌ 工具调用处理失败: $e';
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
    String currentContent, // 当前已包含工具结果的content
  ) async {
    debugPrint('📨 创建子消息: 工具结果消息');

    // 将工具结果作为系统消息添加（设置为子消息）
    final resultMessage = ChatMessage(
      id: const Uuid().v4(),
      conversationId: conversation.id,
      content: toolResult,
      isUser: false,
      timestamp: DateTime.now(),
      metadata: {'isToolResult': true},
      parentId: originalMessageId, // 设置父消息ID
    );
    await messageService.addMessage(resultMessage);
    debugPrint(
      '  ✅ 工具结果子消息已创建: ${resultMessage.id.substring(0, 8)}, parentId=${originalMessageId.substring(0, 8)}',
    );

    // 创建新的 AI 消息继续生成（设置为子消息）
    final newAiMessage = ChatMessage.ai(
      conversationId: conversation.id,
      isGenerating: true,
    ).copyWith(
      parentId: originalMessageId, // 设置父消息ID
    );
    await messageService.addMessage(newAiMessage);
    debugPrint(
      '  ✅ AI继续生成子消息已创建: ${newAiMessage.id.substring(0, 8)}, parentId=${originalMessageId.substring(0, 8)}',
    );

    // 继续请求 AI（禁用工具调用，避免无限循环）
    debugPrint('🤖 开始请求AI继续生成...');
    await _requestAIResponse(newAiMessage.id, '', [], enableToolCalling: false);

    // AI回复完成后，将最终回复追加到父消息
    final newAiMessageFinal = messageService.getMessage(
      conversation.id,
      newAiMessage.id,
    );
    debugPrint(
      '🔍 检查AI回复状态: found=${newAiMessageFinal != null}, isGenerating=${newAiMessageFinal?.isGenerating}',
    );

    if (newAiMessageFinal != null && !newAiMessageFinal.isGenerating) {
      final parentMessage = messageService.getMessage(
        conversation.id,
        originalMessageId,
      );
      if (parentMessage != null) {
        // 将AI的最终回复追加到父消息的content
        final updatedParent = parentMessage.copyWith(
          content: '$currentContent\n\n[AI最终回复]\n${newAiMessageFinal.content}',
        );
        await messageService.updateMessage(updatedParent);
        messageService.completeAIMessage(conversation.id, originalMessageId);
        debugPrint(
          '✅ AI最终回复已追加到父消息, 最终content长度: ${updatedParent.content.length}',
        );
      } else {
        debugPrint('❌ 未找到父消息: $originalMessageId');
      }
    } else {
      debugPrint('⚠️ AI回复还在生成中或未找到');
    }
  }

  // ========== 工具模板执行 ==========

  /// 执行工具模板
  Future<void> executeToolTemplate(String templateName) async {
    if (templateService == null) {
      throw Exception('工具模板服务未初始化');
    }

    // 查找模板
    final template = templateService!.getTemplateByName(templateName);
    if (template == null) {
      throw Exception('未找到工具模板: $templateName');
    }

    // 标记模板为已使用
    await templateService!.markTemplateAsUsed(template.id);

    // 创建AI消息占位符
    final aiMessage = ChatMessage.ai(
      conversationId: conversation.id,
      content: '正在执行工具: ${template.name}',
      isGenerating: true,
    );

    // 设置工具调用步骤
    final toolCall = ToolCallResponse(steps: template.steps);
    final messageWithToolCall = aiMessage.copyWith(toolCall: toolCall);

    await messageService.addMessage(messageWithToolCall);

    // 执行工具调用步骤
    await _executeToolSteps(messageWithToolCall.id, template.steps);
  }

  /// 执行工具调用步骤
  Future<void> _executeToolSteps(
    String messageId,
    List<ToolCallStep> steps,
  ) async {
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];

      // 更新步骤状态为运行中
      step.status = ToolCallStatus.running;
      await _updateMessageToolSteps(messageId, steps);

      try {
        // 执行步骤
        final result = await ToolService.executeToolStep(step);

        // 更新步骤状态为成功
        step.status = ToolCallStatus.success;
        step.result = result;
        await _updateMessageToolSteps(messageId, steps);
      } catch (e) {
        // 更新步骤状态为失败
        step.status = ToolCallStatus.failed;
        step.error = e.toString();
        await _updateMessageToolSteps(messageId, steps);
        break; // 停止执行后续步骤
      }
    }

    // 完成消息生成
    final message = messageService.getMessage(conversation.id, messageId);
    if (message != null) {
      final completedMessage = message.copyWith(
        isGenerating: false,
        content: '工具执行完成',
      );
      await messageService.updateMessage(completedMessage);
    }

    notifyListeners();
  }

  /// 更新消息的工具调用步骤
  Future<void> _updateMessageToolSteps(
    String messageId,
    List<ToolCallStep> steps,
  ) async {
    final message = messageService.getMessage(conversation.id, messageId);
    if (message != null) {
      final updatedMessage = message.copyWith(
        toolCall: ToolCallResponse(steps: steps),
      );
      await messageService.updateMessage(updatedMessage);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}
