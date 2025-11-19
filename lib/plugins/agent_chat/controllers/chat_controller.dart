import 'dart:async';
import 'dart:convert';
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
import '../services/message_detail_service.dart';
import '../../../utils/file_picker_helper.dart';

/// 聊天控制器
///
/// 管理单个会话的聊天功能
class ChatController extends ChangeNotifier {
  final Conversation conversation;
  final MessageService messageService;
  final ConversationService conversationService;
  final MessageDetailService messageDetailService;
  final ToolTemplateService? templateService;
  bool _conversationServiceInitialized = false;

  /// 当前会话（可变，用于存储最新的会话数据）
  Conversation? _currentConversation;

  /// 当前Agent
  AIAgent? _currentAgent;

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在发送消息
  bool _isSending = false;

  /// 是否正在取消发送
  bool _isCancelling = false;

  /// 选中的文件附件
  final List<File> _selectedFiles = [];

  /// 当前输入的文本
  String _inputText = '';

  /// 选中的工具模板
  SavedToolTemplate? _selectedToolTemplate;

  /// 消息ID到上下文消息的映射（用于保存详细数据）
  final Map<String, List<ChatCompletionMessage>> _contextMessagesCache = {};

  ChatController({
    required this.conversation,
    required this.messageService,
    required this.conversationService,
    required this.messageDetailService,
    this.templateService,
  });

  // ========== Getters ==========

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isCancelling => _isCancelling;
  AIAgent? get currentAgent => _currentAgent;
  List<File> get selectedFiles => _selectedFiles;
  String get inputText => _inputText;
  SavedToolTemplate? get selectedToolTemplate => _selectedToolTemplate;

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
      _currentConversation = conversation;
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
        final currentConv = _currentConversation ?? conversation;
        final updatedConversation = currentConv.copyWith(agentId: agentId);
        await conversationService.updateConversation(updatedConversation);

        // 更新本地引用
        _currentConversation = updatedConversation;

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

  /// 取消正在发送的消息
  void cancelSending() {
    if (!_isSending) return;

    _isCancelling = true;
    notifyListeners();
    debugPrint('🛑 用户请求取消发送消息');
  }

  /// 发送消息
  Future<void> sendMessage() async {
    if (_inputText.trim().isEmpty || _isSending) return;
    if (_currentAgent == null) {
      throw Exception('未选择Agent');
    }

    _isSending = true;
    _isCancelling = false; // 重置取消标志
    notifyListeners();

    try {
      // 构建metadata
      final metadata = <String, dynamic>{};
      if (_selectedToolTemplate != null) {
        metadata['toolTemplate'] = {
          'id': _selectedToolTemplate!.id,
          'name': _selectedToolTemplate!.name,
          if (_selectedToolTemplate!.description?.isNotEmpty ?? false)
            'description': _selectedToolTemplate!.description,
        };
      }

      // 创建用户消息
      final userMessage = ChatMessage.user(
        conversationId: conversation.id,
        content: _inputText.trim(),
        tokenCount: TokenCounterService.estimateTokenCount(_inputText),
        attachments: await _processAttachments(),
      ).copyWith(
        metadata: metadata.isNotEmpty ? metadata : null,
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
      final selectedTemplate = _selectedToolTemplate;
      _inputText = '';
      _selectedFiles.clear();
      _selectedToolTemplate = null;
      notifyListeners();

      // 优先执行工具模板，获取结果上下文
      if (selectedTemplate != null) {
        await _executeToolTemplateBeforeAI(userMessage, selectedTemplate);
      }

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
        enableToolCalling: selectedTemplate == null,
      );
    } catch (e) {
      debugPrint('发送消息失败: $e');
      rethrow;
    } finally {
      _isSending = false;
      _isCancelling = false;
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

      // 保存上下文消息（用于后续保存详细数据）
      _contextMessagesCache[aiMessageId] = List.from(contextMessages);

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
        // 如果启用工具调用,使用 JSON Schema 强制返回工具请求格式
        responseFormat: enableToolCalling && _currentAgent!.enableFunctionCalling
            ? ResponseFormat.jsonSchema(
                jsonSchema: JsonSchemaObject(
                  name: 'ToolRequest',
                  description: '工具需求请求',
                  strict: true,
                  schema: ToolService.toolRequestSchema,
                ),
              )
            : null,
        shouldCancel: () => _isCancelling, // 传递取消检查函数
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
                // 使用 JSON Schema 强制返回工具调用格式
                responseFormat: ResponseFormat.jsonSchema(
                  jsonSchema: JsonSchemaObject(
                    name: 'ToolCall',
                    description: '工具调用步骤',
                    strict: true,
                    schema: ToolService.toolCallSchema,
                  ),
                ),
                shouldCancel: () => _isCancelling, // 传递取消检查函数
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
      String systemPrompt = _currentAgent!.systemPrompt;

      // 如果有选中的工具，添加工具提示
      final tools = selectedTools;
      if (tools.isNotEmpty) {
        final toolNames = tools.map((t) => t['toolName'] ?? t['toolId']).join('、');
        systemPrompt += '\n\n用户希望使用以下工具: $toolNames';
      }

      messages.add(
        ChatCompletionMessage.system(content: systemPrompt),
      );
    }

    // 获取历史消息（排除正在生成的消息，保留子消息以避免丢失工具结果）
    final allMessages = messageService.currentMessages;
    final historyMessages =
        allMessages.where((msg) => !msg.isGenerating).toList();

    // 找到最后一个会话分隔符的索引
    int lastDividerIndex = -1;
    for (int i = historyMessages.length - 1; i >= 0; i--) {
      if (historyMessages[i].isSessionDivider) {
        lastDividerIndex = i;
        break;
      }
    }

    // 如果找到分隔符，只获取分隔符之后的消息
    final messagesAfterDivider = lastDividerIndex >= 0
        ? historyMessages.sublist(lastDividerIndex + 1)
        : historyMessages;

    // 获取最后 N 条消息（从分隔符之后的消息中选取）
    final contextMessages =
        messagesAfterDivider.length > contextMessageCount
            ? messagesAfterDivider.sublist(
              messagesAfterDivider.length - contextMessageCount,
            )
            : messagesAfterDivider;

    // 转换历史消息为API格式（排除会话分隔符）
    for (var msg in contextMessages) {
      if (msg.isSessionDivider) continue; // 跳过会话分隔符

      if (msg.isUser) {
        // 检查消息是否包含图片附件
        final imageAttachments = msg.attachments.where((a) => a.isImage).toList();

        if (imageAttachments.isNotEmpty) {
          // 包含图片：使用 parts 格式
          final parts = <ChatCompletionMessageContentPart>[];

          // 添加文本内容
          if (msg.content.isNotEmpty) {
            parts.add(ChatCompletionMessageContentPart.text(text: msg.content));
          }

          // 添加图片附件
          for (var attachment in imageAttachments) {
            try {
              final file = File(attachment.filePath);
              if (file.existsSync()) {
                final bytes = file.readAsBytesSync();
                final base64Image = base64Encode(bytes);
                parts.add(
                  ChatCompletionMessageContentPart.image(
                    imageUrl: ChatCompletionMessageImageUrl(
                      url: 'data:image/jpeg;base64,$base64Image',
                    ),
                  ),
                );
              }
            } catch (e) {
              debugPrint('读取图片附件失败: ${attachment.filePath}, 错误: $e');
            }
          }

          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts(parts),
            ),
          );
        } else {
          // 不包含图片：使用字符串格式
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(msg.content),
            ),
          );
        }

        final templateResult = _extractTemplateResult(msg.metadata);
        if (templateResult != null && templateResult.isNotEmpty) {
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(templateResult),
            ),
          );
        }
      } else {
        messages.add(ChatCompletionMessage.assistant(content: msg.content));
      }
    }

    return messages;
  }

  String? _extractTemplateResult(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final templateMeta = metadata['toolTemplate'];
    if (templateMeta is Map<String, dynamic>) {
      final result = templateMeta['resultSummary'];
      if (result is String && result.isNotEmpty) {
        return result;
      }
    }
    return null;
  }

  List<ToolCallStep> _cloneTemplateSteps(SavedToolTemplate template) {
    if (templateService != null) {
      return templateService!.cloneTemplateSteps(template);
    }
    return template.steps.map((s) => s.withoutRuntimeState()).toList();
  }

  /// 获取工具模板列表
  Future<List<SavedToolTemplate>> fetchToolTemplates({String? keyword}) async {
    if (templateService == null) return [];
    return templateService!.fetchTemplates(query: keyword);
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

  /// 设置选中的工具模板
  void setSelectedToolTemplate(SavedToolTemplate? template) {
    _selectedToolTemplate = template;
    notifyListeners();
  }

  /// 清除选中的工具模板
  void clearSelectedToolTemplate() {
    _selectedToolTemplate = null;
    notifyListeners();
  }

  // ========== 选中工具管理 ==========

  /// 获取选中的工具列表
  List<Map<String, String>> get selectedTools {
    final currentConv = _currentConversation ?? conversation;
    final metadata = currentConv.metadata;
    if (metadata == null) return [];
    final tools = metadata['selectedTools'];
    if (tools is List) {
      return tools.map((e) => Map<String, String>.from(e as Map)).toList();
    }
    return [];
  }

  /// 添加工具到会话
  Future<void> addToolToConversation(
    String pluginId,
    String toolId,
    String toolName,
  ) async {
    await _ensureConversationServiceReady();

    final currentTools = selectedTools;

    // 检查是否已存在
    final exists = currentTools.any(
      (tool) => tool['pluginId'] == pluginId && tool['toolId'] == toolId,
    );

    if (!exists) {
      currentTools.add({
        'pluginId': pluginId,
        'toolId': toolId,
        'toolName': toolName,
      });

      final currentConv = _currentConversation ?? conversation;
      final metadata = Map<String, dynamic>.from(currentConv.metadata ?? {});
      metadata['selectedTools'] = currentTools;

      final updatedConversation = currentConv.copyWith(metadata: metadata);
      await conversationService.updateConversation(updatedConversation);

      // 更新本地引用
      _currentConversation = updatedConversation;

      notifyListeners();
    }
  }

  /// 移除选中的工具
  Future<void> removeToolFromConversation(String pluginId, String toolId) async {
    await _ensureConversationServiceReady();

    final currentTools = selectedTools;
    currentTools.removeWhere(
      (tool) => tool['pluginId'] == pluginId && tool['toolId'] == toolId,
    );

    final currentConv = _currentConversation ?? conversation;
    final metadata = Map<String, dynamic>.from(currentConv.metadata ?? {});
    metadata['selectedTools'] = currentTools;

    final updatedConversation = currentConv.copyWith(metadata: metadata);
    await conversationService.updateConversation(updatedConversation);

    // 更新本地引用
    _currentConversation = updatedConversation;

    notifyListeners();
  }

  /// 清空选中的工具
  Future<void> clearSelectedTools() async {
    await _ensureConversationServiceReady();

    final currentConv = _currentConversation ?? conversation;
    final metadata = Map<String, dynamic>.from(currentConv.metadata ?? {});
    metadata.remove('selectedTools');

    final updatedConversation = currentConv.copyWith(metadata: metadata);
    await conversationService.updateConversation(updatedConversation);

    // 更新本地引用
    _currentConversation = updatedConversation;

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

    // 同时清空会话的最后消息预览
    await conversationService.updateLastMessage(conversation.id, '');

    notifyListeners();
  }

  /// 创建新会话（插入会话分隔符）
  Future<void> createNewSession() async {
    // 检查最后一条消息是否已经是会话分隔符
    final allMessages = messages;
    if (allMessages.isNotEmpty && allMessages.last.isSessionDivider) {
      // 最后一条消息已经是会话分隔符，不需要再创建
      return;
    }

    // 创建会话分隔符消息
    final dividerMessage = ChatMessage.sessionDivider(
      conversationId: conversation.id,
    );

    await messageService.addMessage(dividerMessage);
    notifyListeners();
  }

  /// 检查最后一条消息是否为会话分隔符
  bool get isLastMessageSessionDivider {
    final allMessages = messages;
    return allMessages.isNotEmpty && allMessages.last.isSessionDivider;
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

        // 更新步骤为执行中（创建新的列表以触发UI更新）
        step.status = ToolCallStatus.running;
        final updatedSteps = List<ToolCallStep>.from(toolCall.steps);
        updatedMessage = updatedMessage.copyWith(
          toolCall: ToolCallResponse(steps: updatedSteps),
        );
        await messageService.updateMessage(updatedMessage);
        notifyListeners(); // 立即通知UI更新

        // 执行工具调用
        if (step.method == 'run_js') {
          try {
            final result = await ToolService.executeJsCode(step.data);
            debugPrint('  ✅ 步骤 ${i + 1} 执行成功');

            // 更新步骤为成功（创建新的列表以触发UI更新）
            step.result = result;
            step.status = ToolCallStatus.success;
            final successSteps = List<ToolCallStep>.from(toolCall.steps);
            updatedMessage = updatedMessage.copyWith(
              toolCall: ToolCallResponse(steps: successSteps),
            );
            await messageService.updateMessage(updatedMessage);
            notifyListeners(); // 立即通知UI更新

            // 收集工具结果到buffer
            toolResultsBuffer.writeln('步骤 ${i + 1}: ${step.title}');
            toolResultsBuffer.writeln('结果: $result');
            toolResultsBuffer.writeln();
          } catch (e) {
            // 更新步骤为失败（创建新的列表以触发UI更新）
            step.error = e.toString();
            step.status = ToolCallStatus.failed;
            final failedSteps = List<ToolCallStep>.from(toolCall.steps);
            updatedMessage = updatedMessage.copyWith(
              toolCall: ToolCallResponse(steps: failedSteps),
            );
            await messageService.updateMessage(updatedMessage);
            notifyListeners(); // 立即通知UI更新

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
      } else if (step.error != null) {
        buffer.writeln('错误: ${step.error}');
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

        // 保存消息详细数据
        await _saveMessageDetail(
          messageId: originalMessageId,
          aiMessage: updatedParent,
          finalReply: newAiMessageFinal.content,
        );
      } else {
        debugPrint('❌ 未找到父消息: $originalMessageId');
      }
    } else {
      debugPrint('⚠️ AI回复还在生成中或未找到');
    }
  }

  /// 保存消息详细数据（用于工具调用详情查看）
  Future<void> _saveMessageDetail({
    required String messageId,
    required ChatMessage aiMessage,
    required String finalReply,
  }) async {
    try {
      // 查找对应的用户消息（往前查找最近的用户消息）
      final allMessages = messageService.currentMessages;
      final aiIndex = allMessages.indexWhere((m) => m.id == messageId);

      String userPrompt = '';
      if (aiIndex > 0) {
        // 从AI消息往前查找最近的用户消息
        for (int i = aiIndex - 1; i >= 0; i--) {
          if (allMessages[i].isUser && allMessages[i].parentId == null) {
            userPrompt = allMessages[i].content;
            break;
          }
        }
      }

      // 提取思考过程（去除工具调用JSON、工具结果和最终回复部分）
      String thinkingProcess = aiMessage.content;

      // 1. 去除工具执行结果之后的内容
      final toolResultIndex = thinkingProcess.indexOf('[工具执行结果]');
      if (toolResultIndex != -1) {
        thinkingProcess = thinkingProcess.substring(0, toolResultIndex).trim();
      }

      // 2. 去除工具调用JSON（{"steps": ...} 或 ```json...```）
      // 匹配 ```json ... ``` 代码块
      thinkingProcess = thinkingProcess.replaceAll(
        RegExp(r'```json\s*\{[\s\S]*?\}\s*```', multiLine: true),
        '',
      );

      // 匹配直接的 {"steps": [...]} JSON
      thinkingProcess = thinkingProcess.replaceAll(
        RegExp(r'\{\s*"steps"\s*:\s*\[[\s\S]*?\]\s*\}', multiLine: true),
        '',
      );

      // 清理多余的空行
      thinkingProcess = thinkingProcess.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

      // 格式化完整AI输入
      final fullAIInput = _formatContextMessages(messageId);

      // 保存详细数据
      await messageDetailService.saveDetail(
        messageId: messageId,
        conversationId: conversation.id,
        userPrompt: userPrompt,
        fullAIInput: fullAIInput,
        thinkingProcess: thinkingProcess,
        toolCallData: aiMessage.toolCall?.toJson(),
        finalReply: finalReply,
      );

      // 清除缓存的上下文消息
      _contextMessagesCache.remove(messageId);

      debugPrint('💾 消息详细数据已保存: ${messageId.substring(0, 8)}');
    } catch (e) {
      debugPrint('❌ 保存消息详细数据失败: $e');
    }
  }

  /// 格式化上下文消息为可读字符串
  String _formatContextMessages(String messageId) {
    final contextMessages = _contextMessagesCache[messageId];
    if (contextMessages == null || contextMessages.isEmpty) {
      return '(无上下文消息)';
    }

    final buffer = StringBuffer();
    buffer.writeln('# AI完整输入上下文\n');

    for (int i = 0; i < contextMessages.length; i++) {
      final msg = contextMessages[i];
      final role = msg.role.toString().split('.').last; // 从枚举获取字符串

      buffer.writeln('## 消息 ${i + 1}: $role');
      buffer.writeln();

      // 提取消息内容
      final content = msg.content;
      if (content is String) {
        buffer.writeln(content);
      } else if (content is ChatCompletionUserMessageContent) {
        // 处理用户消息内容（可能包含图片等）
        buffer.writeln(content.toString());
      } else {
        buffer.writeln('(复杂消息类型: ${content.runtimeType})');
      }

      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ========== 工具模板执行 ==========

  /// 在请求 AI 之前先执行选中的工具模板
  Future<void> _executeToolTemplateBeforeAI(
    ChatMessage userMessage,
    SavedToolTemplate template,
  ) async {
    final steps = _cloneTemplateSteps(template);

    // 标记模板使用
    if (templateService != null) {
      await templateService!.markTemplateAsUsed(template.id);
    }

    // 创建工具执行消息，作为用户消息的子消息
    final toolMessage = ChatMessage.ai(
      conversationId: conversation.id,
      content: '正在执行工具: ${template.name}',
      isGenerating: true,
    ).copyWith(
      parentId: userMessage.id,
      toolCall: ToolCallResponse(steps: steps),
    );
    await messageService.addMessage(toolMessage);

    // 执行步骤
    await _executeToolSteps(toolMessage.id, steps);

    // 汇总执行结果
    final summary = _buildToolResultMessage(steps);
    final latestToolMessage =
        messageService.getMessage(conversation.id, toolMessage.id);
    if (latestToolMessage != null) {
      await messageService.updateMessage(
        latestToolMessage.copyWith(content: summary),
      );
    }

    // 更新用户消息的模板元数据，附加执行结果
    final metadata = Map<String, dynamic>.from(userMessage.metadata ?? {});
    final templateMeta = Map<String, dynamic>.from(
      (metadata['toolTemplate'] as Map<String, dynamic>?) ?? {},
    );
    templateMeta
      ..['id'] = template.id
      ..['name'] = template.name;
    if (template.description?.isNotEmpty ?? false) {
      templateMeta['description'] = template.description;
    }
    templateMeta['resultSummary'] = summary;
    metadata['toolTemplate'] = templateMeta;

    final updatedUserMessage = userMessage.copyWith(metadata: metadata);
    await messageService.updateMessage(updatedUserMessage);
  }

  /// 执行工具调用步骤
  Future<void> _executeToolSteps(
    String messageId,
    List<ToolCallStep> steps,
  ) async {
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];

      // 更新步骤状态为运行中（创建新的列表以触发UI更新）
      step.status = ToolCallStatus.running;
      final runningSteps = List<ToolCallStep>.from(steps);
      await _updateMessageToolSteps(messageId, runningSteps);
      notifyListeners(); // 立即通知UI更新

      try {
        // 执行步骤
        final result = await ToolService.executeToolStep(step);

        // 更新步骤状态为成功（创建新的列表以触发UI更新）
        step.status = ToolCallStatus.success;
        step.result = result;
        final successSteps = List<ToolCallStep>.from(steps);
        await _updateMessageToolSteps(messageId, successSteps);
        notifyListeners(); // 立即通知UI更新
      } catch (e) {
        // 更新步骤状态为失败（创建新的列表以触发UI更新）
        step.status = ToolCallStatus.failed;
        step.error = e.toString();
        final failedSteps = List<ToolCallStep>.from(steps);
        await _updateMessageToolSteps(messageId, failedSteps);
        notifyListeners(); // 立即通知UI更新
        break; // 停止执行后续步骤
      }
    }

    // 完成消息生成
    final message = messageService.getMessage(conversation.id, messageId);
    if (message != null) {
      final completedMessage = message.copyWith(
        isGenerating: false,
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

  /// 重新执行工具调用
  Future<void> rerunToolCall(String messageId) async {
    try {
      // 获取消息
      final message = messageService.getMessage(conversation.id, messageId);
      if (message == null) {
        throw Exception('消息不存在');
      }

      // 检查是否有工具调用
      if (message.toolCall == null || message.toolCall!.steps.isEmpty) {
        throw Exception('该消息不包含工具调用');
      }

      debugPrint('🔄 开始重新执行工具调用, messageId=${messageId.substring(0, 8)}');

      // 重置所有步骤状态
      final resetSteps = message.toolCall!.steps.map((step) {
        return step.withoutRuntimeState(state: ToolCallStatus.pending);
      }).toList();

      // 更新消息
      var updatedMessage = message.copyWith(
        toolCall: ToolCallResponse(steps: resetSteps),
      );
      await messageService.updateMessage(updatedMessage);
      notifyListeners();

      debugPrint('✅ 步骤状态已重置, 开始重新执行 ${resetSteps.length} 个步骤');

      // 重新执行所有步骤
      await _executeToolSteps(messageId, resetSteps);

      debugPrint('✅ 工具调用重新执行完成');
    } catch (e) {
      debugPrint('❌ 重新执行工具调用失败: $e');
      rethrow;
    }
  }

  /// 重新执行单个工具调用步骤
  Future<void> rerunSingleStep(String messageId, int stepIndex) async {
    try {
      // 获取消息
      final message = messageService.getMessage(conversation.id, messageId);
      if (message == null) {
        throw Exception('消息不存在');
      }

      // 检查是否有工具调用
      if (message.toolCall == null || message.toolCall!.steps.isEmpty) {
        throw Exception('该消息不包含工具调用');
      }

      if (stepIndex < 0 || stepIndex >= message.toolCall!.steps.length) {
        throw Exception('步骤索引超出范围');
      }

      debugPrint(
        '🔄 开始重新执行步骤 $stepIndex, messageId=${messageId.substring(0, 8)}',
      );

      final steps = List<ToolCallStep>.from(message.toolCall!.steps);
      final targetStep = steps[stepIndex];

      // 重置该步骤状态
      steps[stepIndex] = targetStep.withoutRuntimeState(
        state: ToolCallStatus.pending,
      );

      // 更新消息
      var updatedMessage = message.copyWith(
        toolCall: ToolCallResponse(steps: steps),
      );
      await messageService.updateMessage(updatedMessage);
      notifyListeners();

      debugPrint('✅ 步骤 $stepIndex 状态已重置, 开始执行');

      // 重新执行该步骤
      steps[stepIndex].status = ToolCallStatus.running;
      await _updateMessageToolSteps(messageId, steps);
      notifyListeners();

      try {
        // 执行步骤
        final result = await ToolService.executeToolStep(steps[stepIndex]);

        // 更新步骤状态为成功
        steps[stepIndex].status = ToolCallStatus.success;
        steps[stepIndex].result = result;
        steps[stepIndex].error = null; // 清除之前的错误
        await _updateMessageToolSteps(messageId, steps);
        notifyListeners();

        debugPrint('✅ 步骤 $stepIndex 重新执行成功');
      } catch (e) {
        // 更新步骤状态为失败
        steps[stepIndex].status = ToolCallStatus.failed;
        steps[stepIndex].error = e.toString();
        await _updateMessageToolSteps(messageId, steps);
        notifyListeners();

        debugPrint('❌ 步骤 $stepIndex 重新执行失败: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ 重新执行单个步骤失败: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}
