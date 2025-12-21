import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:memento_foreground_service/memento_foreground_service.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/foreground_task_manager.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/services/request_service.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/models/agent_chain_node.dart';
import 'package:Memento/plugins/agent_chat/models/file_attachment.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/plugins/agent_chat/models/saved_tool_template.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/token_counter_service.dart';
import 'package:Memento/plugins/agent_chat/services/tool_service.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_detail_service.dart';
import 'package:Memento/plugins/agent_chat/services/chat_task_handler.dart';
export '../services/tool_service.dart' show TemplateMatch, ReplacementRule, TemplateStrategy;
import 'package:Memento/utils/file_picker_helper.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';

/// 聊天控制器
///
/// 管理单个会话的聊天功能
class ChatController extends ChangeNotifier {
  final Conversation conversation;
  final MessageService messageService;
  final ConversationService conversationService;
  final MessageDetailService messageDetailService;
  final ToolTemplateService? templateService;
  final Map<String, dynamic> Function()? getSettings; // 获取插件设置的回调
  bool _conversationServiceInitialized = false;

  /// 前台服务管理器（仅 Android）
  final ForegroundTaskManager _foregroundTaskManager = ForegroundTaskManager();

  /// 当前会话（可变，用于存储最新的会话数据）
  Conversation? _currentConversation;

  /// 当前Agent（单 agent 模式）
  AIAgent? _currentAgent;

  /// Agent 链（链式模式）
  List<AIAgent>? _agentChain;

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
    this.getSettings,
  });

  // ========== Getters ==========

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isCancelling => _isCancelling;
  AIAgent? get currentAgent => _currentAgent;
  List<AIAgent> get agentChain => _agentChain ?? [];
  bool get isChainMode => conversation.isChainMode;
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

      // 先加载 agent（单个或链式）
      if (conversation.isChainMode) {
        await _loadAgentChain(conversation.agentChain!);
        debugPrint('📝 Agent链加载完成，共 ${_agentChain?.length ?? 0} 个 agent');
      } else if (conversation.agentId != null) {
        await _loadAgentInBackground(conversation.agentId!);
        debugPrint('📝 Agent加载完成，当前Agent: ${_currentAgent?.name}');
      } else {
        debugPrint('⚠️ 会话没有绑定Agent');
      }

      // 再加载消息
      await messageService.setCurrentConversation(conversation.id);
      debugPrint('📝 消息加载完成，共 ${messageService.currentMessages.length} 条');

      // 注册前台服务数据回调（仅 Android）
      if (!kIsWeb && Platform.isAndroid) {
        _foregroundTaskManager.addDataCallback(_onReceiveBackgroundData);
        debugPrint('📝 已注册前台服务数据回调');
      }
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

  /// 加载 Agent 链
  Future<void> _loadAgentChain(List<AgentChainNode> chainNodes) async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin == null) {
        debugPrint('❌ OpenAI插件未找到');
        return;
      }

      _agentChain = [];
      // 按 order 排序
      final sortedNodes = List<AgentChainNode>.from(chainNodes)
        ..sort((a, b) => a.order.compareTo(b.order));

      for (final node in sortedNodes) {
        final agent = await openAIPlugin.controller.getAgent(node.agentId);
        if (agent != null) {
          _agentChain!.add(agent);
          debugPrint('✅ 加载 Agent 链节点 ${node.order}: ${agent.name}');
        } else {
          debugPrint('⚠️ Agent ${node.agentId} 未找到');
        }
      }

      // 设置当前 agent 为第一个
      if (_agentChain!.isNotEmpty) {
        _currentAgent = _agentChain!.first;
      }

      debugPrint('✅ Agent链加载完成，共 ${_agentChain!.length} 个 agent');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载Agent链失败: $e');
    }
  }

  /// 获取工具调用专用 Agent
  /// 如果配置了专用 Agent 则返回，否则返回 null
  Future<AIAgent?> _getToolAgent(String? agentId) async {
    if (agentId == null) return null;

    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin == null) return null;

      return await openAIPlugin.controller.getAgent(agentId);
    } catch (e) {
      debugPrint('⚠️ 加载工具 Agent 失败: $e');
      return null;
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

  /// 选择并配置 Agent 链
  Future<void> selectAgentChain(List<AgentChainNode> chainNodes) async {
    try {
      await _ensureConversationServiceReady();

      // 加载所有 agent
      await _loadAgentChain(chainNodes);

      // 更新会话配置
      final currentConv = _currentConversation ?? conversation;
      final updatedConversation = currentConv.copyWith(
        agentChain: chainNodes,
        clearAgentChain: false,
      );
      await conversationService.updateConversation(updatedConversation);

      _currentConversation = updatedConversation;
      notifyListeners();

      debugPrint('✅ Agent链配置成功，共 ${chainNodes.length} 个节点');
    } catch (e) {
      debugPrint('❌ 配置Agent链失败: $e');
      rethrow;
    }
  }

  /// 配置工具调用专用 Agent（适用于单 Agent 和 Agent 链模式）
  Future<void> configureToolAgents({
    String? toolDetectionAgentId,
    String? toolExecutionAgentId,
  }) async {
    try {
      await _ensureConversationServiceReady();

      final currentConv = _currentConversation ?? conversation;
      final updatedConversation = currentConv.copyWith(
        toolDetectionAgentId: toolDetectionAgentId,
        toolExecutionAgentId: toolExecutionAgentId,
      );
      await conversationService.updateConversation(updatedConversation);

      _currentConversation = updatedConversation;
      notifyListeners();

      debugPrint('✅ 工具 Agent 配置成功');
      if (toolDetectionAgentId != null) {
        debugPrint('  工具需求识别 Agent: $toolDetectionAgentId');
      } else {
        debugPrint('  工具需求识别：使用默认 prompt');
      }
      if (toolExecutionAgentId != null) {
        debugPrint('  工具执行 Agent: $toolExecutionAgentId');
      } else {
        debugPrint('  工具执行：使用默认 prompt');
      }
    } catch (e) {
      debugPrint('❌ 配置工具 Agent 失败: $e');
      rethrow;
    }
  }

  /// 切换回单 Agent 模式
  Future<void> switchToSingleAgent(String agentId) async {
    try {
      await _ensureConversationServiceReady();

      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openAIPlugin != null) {
        _currentAgent = await openAIPlugin.controller.getAgent(agentId);
        _agentChain = null;

        final currentConv = _currentConversation ?? conversation;
        final updatedConversation = currentConv.copyWith(
          agentId: agentId,
          clearAgentChain: true, // 清除链配置
        );
        await conversationService.updateConversation(updatedConversation);

        _currentConversation = updatedConversation;
        notifyListeners();

        debugPrint('✅ 已切换到单Agent模式: ${_currentAgent?.name}');
      }
    } catch (e) {
      debugPrint('❌ 切换单Agent失败: $e');
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
    // 如果正在发送，直接返回
    if (_isSending) return;

    // 如果没有工具模板且输入为空，则返回
    if (_inputText.trim().isEmpty && _selectedToolTemplate == null) return;

    // 检查是否配置了 agent（单个或链式）
    if (!isChainMode && _currentAgent == null) {
      throw Exception('未选择Agent');
    }
    if (isChainMode && (_agentChain == null || _agentChain!.isEmpty)) {
      throw Exception('Agent链为空');
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
      ).copyWith(metadata: metadata.isNotEmpty ? metadata : null);

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

      // 启动前台服务（仅 Android，且用户启用了后台服务）
      final settings = getSettings?.call() ?? {};
      final enableBackgroundService =
          settings['enableBackgroundService'] as bool? ?? true;

      if (!kIsWeb && Platform.isAndroid && enableBackgroundService) {
        // 链式模式下，使用第一个 agent 的消息 ID
        final firstMessageId = '${conversation.id}_chain_0';
        await _startAIChatService(conversation.id, firstMessageId);
      }

      // 判断是单 agent 还是链式调用
      if (isChainMode) {
        // 链式调用所有 agent
        await _executeAgentChain(userInput, files, selectedTemplate);
      } else {
        // 单 agent 模式（现有逻辑）
        final aiMessage = ChatMessage.ai(
          conversationId: conversation.id,
          content: '',
          isGenerating: true,
        );
        await messageService.addMessage(aiMessage);

        if (selectedTemplate != null) {
          await _executeToolTemplateAndRespond(
            aiMessageId: aiMessage.id,
            userMessage: userMessage,
            template: selectedTemplate,
          );
        } else {
          await _requestAIResponse(
            aiMessage.id,
            userInput,
            files,
            enableToolCalling: true,
          );
        }
      }
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

  // ========== Agent 链式执行 ==========

  /// 执行 Agent 链式调用
  Future<void> _executeAgentChain(
    String userInput,
    List<File> files,
    SavedToolTemplate? selectedTemplate,
  ) async {
    final chainNodes = conversation.agentChain!;
    final sortedNodes = List<AgentChainNode>.from(chainNodes)
      ..sort((a, b) => a.order.compareTo(b.order));

    // 存储每个 agent 的输出消息
    final chainMessages = <ChatMessage>[];

    // 遍历执行每个 agent
    for (int i = 0; i < sortedNodes.length; i++) {
      final node = sortedNodes[i];
      final agent = _agentChain![i];

      debugPrint('🔗 [链式调用 ${i + 1}/${sortedNodes.length}] 开始执行 Agent: ${agent.name}');

      // 创建此 agent 的 AI 消息占位符
      final aiMessage = ChatMessage.ai(
        conversationId: conversation.id,
        content: '',
        isGenerating: true,
        generatedByAgentId: agent.id,
        chainStepIndex: i,
      );
      await messageService.addMessage(aiMessage);
      chainMessages.add(aiMessage);

      try {
        // 根据上下文模式构建消息列表
        final contextMessages = _buildChainContextMessages(
          node: node,
          stepIndex: i,
          userInput: userInput,
          previousMessages: chainMessages,
        );

        // 调用当前 agent
        await _requestAgentInChain(
          agent: agent,
          aiMessageId: aiMessage.id,
          contextMessages: contextMessages,
          files: i == 0 ? files : [], // 只有第一个 agent 处理文件
          enableToolCalling: agent.enableFunctionCalling,
        );

        // 检查是否被取消
        if (_isCancelling) {
          debugPrint('🛑 链式调用被用户取消');
          break;
        }

        // 更新 chainMessages 中的消息为最新版本
        final updatedMessage =
            messageService.getMessage(conversation.id, aiMessage.id);
        if (updatedMessage != null) {
          chainMessages[i] = updatedMessage;
        }

        debugPrint('✅ [链式调用 ${i + 1}/${sortedNodes.length}] Agent ${agent.name} 执行完成');
      } catch (e) {
        debugPrint('❌ [链式调用 ${i + 1}/${sortedNodes.length}] Agent ${agent.name} 执行失败: $e');

        // 错误处理：标记消息并停止链式调用
        final errorMessage =
            messageService.getMessage(conversation.id, aiMessage.id);
        if (errorMessage != null) {
          final updated = errorMessage.copyWith(
            content: '❌ 执行失败: $e',
            isGenerating: false,
          );
          await messageService.updateMessage(updated);
        }

        // 停止后续 agent 的执行
        break;
      }
    }

    debugPrint('🏁 链式调用完成');
  }

  /// 根据节点的上下文模式构建消息列表
  List<ChatCompletionMessage> _buildChainContextMessages({
    required AgentChainNode node,
    required int stepIndex,
    required String userInput,
    required List<ChatMessage> previousMessages,
  }) {
    final messages = <ChatCompletionMessage>[];

    // 获取对应的 agent
    final agent = _agentChain![stepIndex];

    // 添加系统提示词
    if (agent.systemPrompt.isNotEmpty) {
      messages.add(ChatCompletionMessage.system(content: agent.systemPrompt));
    }

    switch (node.contextMode) {
      case AgentContextMode.conversationContext:
        // 使用会话的历史上下文（遵循 contextMessageCount）
        final historyMessages = _buildContextMessages(userInput);
        messages.addAll(historyMessages);
        break;

      case AgentContextMode.chainContext:
        // 传递链中所有前序 agent 的输出
        messages.add(ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(userInput),
        ));

        for (int i = 0; i < stepIndex; i++) {
          final prevMsg = previousMessages[i];
          if (prevMsg.content.isNotEmpty) {
            final prevAgent = _agentChain![i];
            messages.add(ChatCompletionMessage.assistant(
              content: '[${prevAgent.name}]: ${prevMsg.content}',
            ));
          }
        }
        break;

      case AgentContextMode.previousOnly:
        // 仅传递上一个 agent 的输出
        final inputContent = stepIndex == 0
            ? userInput
            : previousMessages[stepIndex - 1].content;

        messages.add(ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(inputContent),
        ));
        break;
    }

    return messages;
  }

  /// 在链式调用中请求单个 Agent 的响应
  Future<void> _requestAgentInChain({
    required AIAgent agent,
    required String aiMessageId,
    required List<ChatCompletionMessage> contextMessages,
    required List<File> files,
    required bool enableToolCalling,
  }) async {
    final buffer = StringBuffer();
    int tokenCount = 0;

    try {
      // 处理图片文件
      final imageFiles =
          files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      // 流式请求 AI 回复
      await RequestService.streamResponse(
        agent: agent,
        prompt: null,
        contextMessages: contextMessages,
        vision: imageFiles.isNotEmpty,
        filePath: imageFiles.isNotEmpty ? imageFiles.first.path : null,
        shouldCancel: () => _isCancelling,
        onToken: (token) {
          buffer.write(token);
          tokenCount++;

          // 实时更新 UI
          messageService.updateAIMessageContent(
            conversation.id,
            aiMessageId,
            buffer.toString(),
            tokenCount,
          );
        },
        onComplete: () async {
          // 完成生成
          messageService.completeAIMessage(conversation.id, aiMessageId);
          debugPrint('✅ Agent ${agent.name} 生成完成，Token: $tokenCount');
        },
        onError: (error) {
          debugPrint('❌ Agent ${agent.name} 响应错误: $error');

          if (error == '已取消发送') {
            messageService.updateAIMessageContent(
              conversation.id,
              aiMessageId,
              '🛑 用户已取消操作',
              0,
            );
          } else {
            messageService.updateAIMessageContent(
              conversation.id,
              aiMessageId,
              '❌ 错误: $error',
              0,
            );
          }

          messageService.completeAIMessage(conversation.id, aiMessageId);
        },
      );

      // 保存上下文消息（用于详情查看）
      _contextMessagesCache[aiMessageId] = List.from(contextMessages);
    } catch (e) {
      debugPrint('❌ 请求Agent响应失败: $e');
      rethrow;
    }
  }

  // ========== 单 Agent 模式 ==========

  /// 请求AI回复（三阶段工具调用：模版匹配 → 工具需求 → 工具调用）
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

      // ========== 第零阶段：工具模版匹配（可选）==========
      final settings = getSettings?.call() ?? {};
      final preferToolTemplates =
          settings['preferToolTemplates'] as bool? ?? false;

      if (preferToolTemplates &&
          enableToolCalling &&
          _currentAgent!.enableFunctionCalling &&
          templateService != null) {
        debugPrint('🔍 [第零阶段] 开始工具模版匹配...');

        // 获取所有工具模版
        final templates = await templateService!.fetchTemplates();

        if (templates.isNotEmpty) {
          debugPrint('🔍 [第零阶段] 找到 ${templates.length} 个工具模版');

          // 优先尝试精确匹配：使用用户输入标题直接匹配模版名称
          final exactMatchTemplate = templateService!.getTemplateByName(
            userInput.trim(),
          );

          if (exactMatchTemplate != null) {
            debugPrint(
              '✅ [第零阶段-精确匹配] 找到完全匹配的模版: ${exactMatchTemplate.name} (ID: ${exactMatchTemplate.id})',
            );

            // 直接使用该模版，跳过 AI 调用
            final message = messageService.getMessage(
              conversation.id,
              aiMessageId,
            );
            if (message != null) {
              final updatedMessage = message.copyWith(
                matchedTemplateIds: [exactMatchTemplate.id],
                content: '我找到了完全匹配的工具模版「${exactMatchTemplate.name}」，请选择是否执行：',
                isGenerating: false,
              );
              await messageService.updateMessage(updatedMessage);
            }

            debugPrint('✅ [第零阶段-精确匹配] 已保存匹配结果，等待用户选择');
            return; // 直接返回，跳过后续的 AI 调用和第一阶段
          }

          debugPrint('ℹ️ [第零阶段-精确匹配] 未找到精确匹配，继续 AI 匹配流程');

          // 生成模版列表 Prompt
          final templatePrompt = ToolService.getToolTemplatePrompt(templates);

          // 清空 buffer
          buffer.clear();
          tokenCount = 0;

          // 使用 Completer 等待 onComplete 完成
          final completer = Completer<bool>();

          // 第零阶段：请求 AI 匹配模版（使用占位符方式）
          await RequestService.streamResponse(
            agent: _currentAgent!,
            prompt: null,
            contextMessages: contextMessages,
            vision: false,
            responseFormat: ResponseFormat.jsonSchema(
              jsonSchema: JsonSchemaObject(
                name: 'ToolTemplateMatch',
                description: '工具模版匹配结果',
                strict: true,
                schema: ToolService.toolTemplateMatchSchema,
              ),
            ),
            additionalPrompts: {'tool_templates': templatePrompt},
            shouldCancel: () => _isCancelling,
            onToken: (token) {
              buffer.write(token);
              tokenCount++;
            },
            onComplete: () async {
              try {
                final matchResponse = buffer.toString();
                debugPrint('🔍 [第零阶段] AI 响应: $matchResponse');

                // 解析匹配结果
                final matches = ToolService.parseToolTemplateMatch(
                  matchResponse,
                );

                if (matches != null && matches.isNotEmpty) {
                  debugPrint(
                    '✅ [第零阶段] 匹配到 ${matches.length} 个模版',
                  );

                  // 过滤出存在的模版，并保存替换规则
                  final validMatches = <TemplateMatch>[];
                  for (final match in matches) {
                    try {
                      final template = templateService!.getTemplateById(match.id);
                      if (template != null) {
                        validMatches.add(match);
                        if (match.replacements != null && match.replacements!.isNotEmpty) {
                          debugPrint(
                            '  - ${template.name}: ${match.replacements!.length} 个参数替换',
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('⚠️ [第零阶段] 模版 ${match.id} 不存在或加载失败: $e');
                    }
                  }

                  if (validMatches.isNotEmpty) {
                    // 保存匹配的模版ID和替换规则到消息元数据
                    final message = messageService.getMessage(
                      conversation.id,
                      aiMessageId,
                    );
                    if (message != null) {
                      // 构建元数据，包含替换规则
                      final metadata = <String, dynamic>{
                        'templateMatches': validMatches.map((m) {
                          final matchData = <String, dynamic>{'id': m.id};
                          if (m.replacements != null && m.replacements!.isNotEmpty) {
                            matchData['replacements'] = m.replacements!.map((r) => {
                              'from': r.from,
                              'to': r.to,
                            }).toList();
                          }
                          return matchData;
                        }).toList(),
                      };

                      final updatedMessage = message.copyWith(
                        matchedTemplateIds: validMatches.map((m) => m.id).toList(),
                        content:
                            '我找到了 ${validMatches.length} 个相关的工具模版，请选择要执行的模版：',
                        isGenerating: false,
                        metadata: metadata,
                      );
                      await messageService.updateMessage(updatedMessage);
                    }

                    debugPrint('✅ [第零阶段] 已保存匹配结果，等待用户选择');
                    completer.complete(true); // 完成，标记为匹配到模版
                    return;
                  }
                }

                debugPrint('ℹ️ [第零阶段] 未匹配到模版或模版为空，继续第一阶段');
                completer.complete(false); // 完成，标记为未匹配
              } catch (e) {
                debugPrint('❌ [第零阶段] 处理匹配结果时出错: $e');
                completer.complete(false);
              }
            },
            onError: (String error) {
              debugPrint('❌ [第零阶段] AI响应错误: $error');

              // 如果是用户取消操作，直接更新消息并完成
              if (error == '已取消发送') {
                messageService.updateAIMessageContent(
                  conversation.id,
                  aiMessageId,
                  '用户已取消操作',
                  0,
                );
                messageService.completeAIMessage(conversation.id, aiMessageId);
                completer.complete(true); // 标记为已完成，阻止继续执行
              } else {
                completer.complete(false);
              }
            },
          );

          // ⚠️ 关键修复：等待 onComplete 完成并检查结果
          final templateMatched = await completer.future;
          if (templateMatched) {
            debugPrint('🛑 [第零阶段] 已匹配模版，跳过后续阶段');
            return;
          }

          // 如果没有匹配，继续执行下面的第一阶段
          debugPrint('➡️ [第零阶段] 未匹配到模版，继续执行第一阶段');
        }
      }

      // 保存上下文消息（用于后续保存详细数据）
      _contextMessagesCache[aiMessageId] = List.from(contextMessages);

      // 处理文件（仅支持图片vision模式）
      final imageFiles =
          files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      // 准备工具需求识别阶段的 Agent 和 Prompt
      AIAgent? toolDetectionAgent;
      List<ChatCompletionMessage> toolDetectionMessages = contextMessages;
      String toolBriefPrompt = '';

      if (enableToolCalling && _currentAgent!.enableFunctionCalling) {
        // 尝试加载工具需求识别专用 Agent
        toolDetectionAgent = await _getToolAgent(
          conversation.toolDetectionAgentId,
        );

        if (toolDetectionAgent != null) {
          // 使用专用 Agent，它有自己的 system prompt
          debugPrint('🔧 [工具需求识别] 使用专用 Agent: ${toolDetectionAgent.name}');
        } else {
          // 未配置专用 Agent，使用默认 prompt 替换当前 agent 的 system prompt
          toolDetectionAgent = _currentAgent;
          toolBriefPrompt = ToolService.getToolBriefPrompt();

          // 构建新的 context messages，替换 system prompt
          final messagesWithoutSystem = contextMessages
              .where((m) => m.role != ChatCompletionMessageRole.system)
              .toList();

          toolDetectionMessages = [
            // 使用工具 brief prompt 作为 system prompt
            ChatCompletionMessage.system(content: toolBriefPrompt),
            ...messagesWithoutSystem,
          ];

          debugPrint('🔧 [工具需求识别] 使用默认 prompt 替换 system prompt');
        }
      } else {
        toolDetectionAgent = _currentAgent;
      }

      // 第一阶段：流式接收 AI 回复（工具需求识别）
      await RequestService.streamResponse(
        agent: toolDetectionAgent!,
        prompt: null,
        contextMessages: toolDetectionMessages,
        vision: imageFiles.isNotEmpty,
        filePath: imageFiles.isNotEmpty ? imageFiles.first.path : null,
        // 如果启用工具调用,使用 JSON Schema 强制返回工具请求格式
        responseFormat:
            enableToolCalling && _currentAgent!.enableFunctionCalling
                ? ResponseFormat.jsonSchema(
                  jsonSchema: JsonSchemaObject(
                    name: 'ToolRequest',
                    description: '工具需求请求',
                    strict: true,
                    schema: ToolService.toolRequestSchema,
                  ),
                )
                : null,
        // 不再使用 additionalPrompts，因为已经在 contextMessages 中替换了 system prompt
        additionalPrompts: null,
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

          // 检测是否为用户取消操作
          final errorMessage =
              error == '已取消发送' ? '用户已取消操作' : '抱歉，生成回复时出现错误：$error';

          messageService.updateAIMessageContent(
            conversation.id,
            aiMessageId,
            errorMessage,
            0,
          );

          messageService.completeAIMessage(conversation.id, aiMessageId);

          // 通知后台服务生成错误
          if (!kIsWeb && Platform.isAndroid) {
            _notifyGenerationError(errorMessage, messageId: aiMessageId);
            // 延迟停止服务
            Future.delayed(const Duration(seconds: 3), () {
              _stopAIChatServiceIfIdle();
            });
          }
        },
        onComplete: () async {
          final firstResponse = buffer.toString();

          // 通知后台服务AI响应完成（第一阶段）
          if (!kIsWeb && Platform.isAndroid) {
            _notifyGenerationProgress('AI思考完成，准备执行...');
          }

          // ========== 检测工具需求（第一阶段响应）==========
          final toolRequest = ToolService.parseToolRequest(firstResponse);

          if (_currentAgent!.enableFunctionCalling &&
              toolRequest != null &&
              toolRequest.isNotEmpty) {
            debugPrint('🔍 AI 请求工具: ${toolRequest.join(", ")}');

            // ========== 第二阶段：追加详细文档 ==========
            try {
              final detailPrompt = await ToolService.getToolDetailPrompt(
                toolRequest,
              );

              // 准备工具执行阶段的 Agent 和 Context Messages
              AIAgent? toolExecutionAgent = await _getToolAgent(
                conversation.toolExecutionAgentId,
              );

              List<ChatCompletionMessage> toolExecutionMessages;

              if (toolExecutionAgent != null) {
                // 使用专用 Agent，它有自己的 system prompt
                debugPrint('🔧 [工具执行] 使用专用 Agent: ${toolExecutionAgent.name}');

                // 构建新的 context，使用专用 agent 的 system prompt
                toolExecutionMessages = [
                  // 专用 agent 的 system prompt 会自动添加
                  ChatCompletionMessage.user(
                    content: ChatCompletionUserMessageContent.string(
                      '原始用户输入：\n$userInput\n\n第一阶段识别的工具：${toolRequest.join(", ")}\n\n工具详细文档：\n$detailPrompt\n\n请根据文档生成工具调用代码。',
                    ),
                  ),
                ];
              } else {
                // 未配置专用 Agent，使用默认 prompt 替换 system prompt
                toolExecutionAgent = _currentAgent;
                debugPrint('🔧 [工具执行] 使用默认 prompt 替换 system prompt');

                // 移除 system prompt，用 tool detail prompt 替换
                final messagesWithoutSystem = contextMessages
                    .where((m) => m.role != ChatCompletionMessageRole.system)
                    .toList();

                toolExecutionMessages = [
                  // 使用工具详细文档作为 system prompt
                  ChatCompletionMessage.system(content: detailPrompt),
                  ...messagesWithoutSystem,
                  ChatCompletionMessage.assistant(content: firstResponse),
                  ChatCompletionMessage.user(
                    content: ChatCompletionUserMessageContent.string(
                      '请根据文档生成工具调用代码。',
                    ),
                  ),
                ];
              }

              // 清空 buffer，准备接收第二阶段响应
              buffer.clear();
              tokenCount = 0;
              isCollectingToolCall = false;

              // 第二阶段：请求生成工具调用代码
              await RequestService.streamResponse(
                agent: toolExecutionAgent!,
                prompt: null,
                contextMessages: toolExecutionMessages,
                vision: false,
                // 不再使用 additionalPrompts，已在 contextMessages 中处理
                additionalPrompts: null,
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

                  // 检测是否为用户取消操作
                  final errorMessage =
                      error == '已取消发送' ? '用户已取消操作' : '抱歉，生成工具调用时出现错误：$error';

                  messageService.updateAIMessageContent(
                    conversation.id,
                    aiMessageId,
                    errorMessage,
                    0,
                  );
                  messageService.completeAIMessage(
                    conversation.id,
                    aiMessageId,
                  );
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

    // 通知后台服务生成完成
    if (!kIsWeb && Platform.isAndroid) {
      final tokenCount = TokenCounterService.estimateTokenCount(content);
      _notifyGenerationComplete(
        processedContent,
        tokenCount: tokenCount,
        messageId: messageId,
      );
      // 延迟停止服务（给用户时间看通知）
      Future.delayed(const Duration(seconds: 3), () {
        _stopAIChatServiceIfIdle();
      });
    }
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
        final toolNames = tools
            .map((t) => t['toolName'] ?? t['toolId'])
            .join('、');
        systemPrompt += '\n\n用户希望使用以下工具: $toolNames';
      }

      messages.add(ChatCompletionMessage.system(content: systemPrompt));
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
    final messagesAfterDivider =
        lastDividerIndex >= 0
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
        final imageAttachments =
            msg.attachments.where((a) => a.isImage).toList();

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
  Future<void> removeToolFromConversation(
    String pluginId,
    String toolId,
  ) async {
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

      // 初始化工具调用上下文（用于步骤间结果传递）
      final jsBridge = JSBridgeManager.instance;
      jsBridge.initToolCallContext(messageId);

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
            // 设置当前执行上下文（供 JavaScript 中的 setResult/getResult 使用）
            jsBridge.setCurrentExecution(messageId, i);

            final result = await ToolService.executeJsCode(step.data);
            debugPrint('  ✅ 步骤 ${i + 1} 执行成功');

            // 自动将步骤结果保存到上下文（供后续步骤通过索引获取）
            try {
              // 尝试解析结果为 JSON 对象
              final parsedResult = jsonDecode(result);
              jsBridge.setToolCallResult('step_$i', parsedResult);
            } catch (e) {
              // 如果不是 JSON，直接保存原始字符串
              jsBridge.setToolCallResult('step_$i', result);
            }

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

            // 清除工具调用上下文
            jsBridge.clearToolCallContext(messageId);

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

      // 清除工具调用上下文（所有步骤已执行完成）
      jsBridge.clearToolCallContext(messageId);

      await _continueWithToolResult(
        messageId,
        toolResultMessage,
        contentWithToolResult,
      );
    } catch (e) {
      // 解析失败
      final errorContent = '❌ 工具调用处理失败: $e';

      // 清除工具调用上下文
      final jsBridge = JSBridgeManager.instance;
      jsBridge.clearToolCallContext(messageId);

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
        // 将AI的最终回复追加到父消息的content（保留toolCall数据）
        final updatedParent = parentMessage.copyWith(
          content: '$currentContent\n\n[AI最终回复]\n${newAiMessageFinal.content}',
          // 保留toolCall，否则UI无法显示工具调用步骤
          toolCall: parentMessage.toolCall,
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

        // 通知后台服务生成完成（工具调用流程）
        if (!kIsWeb && Platform.isAndroid) {
          final tokenCount = newAiMessageFinal.tokenCount;
          _notifyGenerationComplete(
            newAiMessageFinal.content,
            tokenCount: tokenCount,
            messageId: originalMessageId,
          );
          // 延迟停止服务
          Future.delayed(const Duration(seconds: 3), () {
            _stopAIChatServiceIfIdle();
          });
        }
      } else {
        debugPrint('❌ 未找到父消息: $originalMessageId');
      }
    } else {
      debugPrint('⚠️ AI回复还在生成中或未找到');
    }
  }

  /// 保存工具模板执行的详细数据
  Future<void> _saveToolTemplateDetail({
    required String messageId,
    required ChatMessage aiMessage,
    required SavedToolTemplate template,
    required List<ToolCallStep> steps,
    required String resultSummary,
    String? userInput,
  }) async {
    try {
      // 查找对应的用户消息（往前查找最近的用户消息）
      final allMessages = messageService.currentMessages;
      final aiIndex = allMessages.indexWhere((m) => m.id == messageId);

      String userPrompt = userInput ?? '';
      if (userPrompt.isEmpty && aiIndex > 0) {
        // 从AI消息往前查找最近的用户消息
        for (int i = aiIndex - 1; i >= 0; i--) {
          if (allMessages[i].isUser && allMessages[i].parentId == null) {
            userPrompt = allMessages[i].content;
            break;
          }
        }
      }

      // 构建思考过程（说明工具模板的选择和执行）
      final thinkingProcess = '''
# 工具模板执行

**模板名称**: ${template.name}
${template.description != null && template.description!.isNotEmpty ? '**模板描述**: ${template.description}\n' : ''}
**执行步骤数**: ${steps.length}

## 执行策略

基于用户输入「$userPrompt」，选择执行工具模板「${template.name}」。

## 步骤详情

${steps.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final step = entry.value;
        return '''
### 步骤 $idx: ${step.title}
- **方法**: ${step.method}
- **描述**: ${step.desc}
- **状态**: ${step.status.name}
${step.result != null ? '- **结果**: ${step.result}\n' : ''}${step.error != null ? '- **错误**: ${step.error}\n' : ''}
''';
      }).join('\n')}
''';

      // 构建AI输入上下文（简化版）
      final fullAIInput = '''
# 工具模板执行上下文

**用户请求**: $userPrompt
**选择的模板**: ${template.name}
**执行时间**: ${DateTime.now().toIso8601String()}
''';

      // 保存详细数据
      await messageDetailService.saveDetail(
        messageId: messageId,
        conversationId: conversation.id,
        userPrompt: userPrompt,
        fullAIInput: fullAIInput,
        thinkingProcess: thinkingProcess,
        toolCallData: aiMessage.toolCall?.toJson(),
        finalReply: resultSummary,
      );

      debugPrint('💾 工具模板详细数据已保存: ${messageId.substring(0, 8)}');
    } catch (e) {
      debugPrint('❌ 保存工具模板详细数据失败: $e');
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
      thinkingProcess =
          thinkingProcess.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

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

  /// 执行 AI 匹配的模板（自动匹配路径）
  Future<void> executeMatchedTemplate(
    String aiMessageId,
    String templateId,
  ) async {
    if (templateService == null) {
      debugPrint('⚠️ ToolTemplateService 不可用');
      return;
    }

    try {
      // 加载模版
      final template = templateService!.getTemplateById(templateId);
      if (template == null) {
        debugPrint('⚠️ 模版 $templateId 不存在');
        final message = messageService.getMessage(conversation.id, aiMessageId);
        if (message != null) {
          await messageService.updateMessage(
            message.copyWith(content: '错误：选择的模版不存在', isGenerating: false),
          );
        }
        return;
      }

      debugPrint('✅ 执行匹配的模版: ${template.name}');

      // 从消息元数据中读取 AI 预先分析的策略和数据
      TemplateStrategy strategy = TemplateStrategy.replace;
      List<ReplacementRule>? replacements;
      List<ToolCallStep>? rewrittenSteps;

      final message = messageService.getMessage(conversation.id, aiMessageId);
      if (message?.metadata != null) {
        final templateMatches = message!.metadata!['templateMatches'] as List<dynamic>?;
        if (templateMatches != null) {
          final matchData = templateMatches.firstWhere(
            (m) => m['id'] == templateId,
            orElse: () => null,
          );

          if (matchData != null) {
            // 解析策略
            final strategyStr = matchData['strategy'] as String? ?? 'replace';
            strategy = strategyStr == 'rewrite'
                ? TemplateStrategy.rewrite
                : TemplateStrategy.replace;

            // 解析 replace 策略的替换规则
            if (strategy == TemplateStrategy.replace && matchData['replacements'] != null) {
              final replacementsList = matchData['replacements'] as List<dynamic>;
              replacements = replacementsList.map((r) =>
                ReplacementRule(
                  from: r['from'] as String,
                  to: r['to'] as String,
                )
              ).toList();
            }

            // 解析 rewrite 策略的重写代码
            if (strategy == TemplateStrategy.rewrite && matchData['rewritten_steps'] != null) {
              final stepsList = matchData['rewritten_steps'] as List<dynamic>;
              rewrittenSteps = stepsList.map((s) =>
                ToolCallStep(
                  method: s['method'] as String,
                  title: s['title'] as String,
                  desc: s['desc'] as String,
                  data: s['data'] as String,
                )
              ).toList();
            }
          }
        }
      }

      // ✅ 使用统一的执行入口
      final resultSummary = await _executeTemplateWithSmartReplacement(
        messageId: aiMessageId,
        template: template,
        strategy: strategy,
        replacements: replacements,
        rewrittenSteps: rewrittenSteps,
      );

      // 让AI基于工具执行结果继续生成回复
      debugPrint('🤖 工具模版执行完成，让AI基于结果继续生成回复...');
      await _continueWithToolResult(aiMessageId, resultSummary, resultSummary);
    } catch (e) {
      debugPrint('❌ 执行匹配模版失败: $e');
      final message = messageService.getMessage(conversation.id, aiMessageId);
      if (message != null) {
        await messageService.updateMessage(
          message.copyWith(content: '执行模版时出错: $e', isGenerating: false),
        );
      }
    }
  }

  /// 🔄 统一的模板执行入口（带智能参数替换/重写）
  ///
  /// 参数：
  /// - messageId: 消息ID（用于更新执行状态）
  /// - template: 要执行的模板
  /// - strategy: 修改策略（replace 或 rewrite）
  /// - userInput: 用户输入（可选，用于参数分析）
  /// - replacements: 预先分析的替换规则（strategy=replace时使用）
  /// - rewrittenSteps: 重写后的代码步骤（strategy=rewrite时使用）
  Future<String> _executeTemplateWithSmartReplacement({
    required String messageId,
    required SavedToolTemplate template,
    TemplateStrategy strategy = TemplateStrategy.replace,
    String? userInput,
    List<ReplacementRule>? replacements,
    List<ToolCallStep>? rewrittenSteps,
  }) async {
    List<ToolCallStep> steps;

    // 根据策略选择执行路径
    if (strategy == TemplateStrategy.rewrite && rewrittenSteps != null && rewrittenSteps.isNotEmpty) {
      // 🔄 重写策略：直接使用 AI 生成的新代码
      debugPrint('📝 使用 rewrite 策略，执行 AI 重写的代码');
      debugPrint('  重写步骤数: ${rewrittenSteps.length}');
      steps = rewrittenSteps;
    } else {
      // 🔄 替换策略：克隆模板步骤并应用替换规则
      debugPrint('🔄 使用 replace 策略');
      steps = _cloneTemplateSteps(template);

      // 获取参数替换规则（按优先级）
      List<ReplacementRule>? finalReplacements = replacements;

      // 如果没有预先提供替换规则，且有用户输入，则实时分析
      if (finalReplacements == null &&
          userInput != null &&
          userInput.isNotEmpty &&
          userInput.toLowerCase() != template.name.toLowerCase() &&
          _currentAgent != null &&
          _currentAgent!.enableFunctionCalling) {

        debugPrint('🔄 实时分析模板修改策略');
        debugPrint('  用户输入: "$userInput"');
        debugPrint('  模板名称: "${template.name}"');

        final analysisResult = await _analyzeTemplateModification(
          userInput,
          template,
        );

        if (analysisResult != null) {
          if (analysisResult.strategy == TemplateStrategy.rewrite &&
              analysisResult.rewrittenSteps != null &&
              analysisResult.rewrittenSteps!.isNotEmpty) {
            // 切换到 rewrite 策略
            debugPrint('📝 切换到 rewrite 策略');
            steps = analysisResult.rewrittenSteps!
                .map((s) => ToolCallStep(
                      method: s['method'] as String,
                      title: s['title'] as String,
                      desc: s['desc'] as String,
                      data: s['data'] as String,
                    ))
                .toList();
          } else {
            finalReplacements = analysisResult.replacements;
          }
        }
      }

      // 应用参数替换（仅 replace 策略）
      if (finalReplacements != null && finalReplacements.isNotEmpty) {
        debugPrint('✅ 应用 ${finalReplacements.length} 个参数替换规则');
        for (var rule in finalReplacements) {
          debugPrint('  - "${rule.from}" → "${rule.to}"');
        }
        steps = ToolService.applyReplacements(steps, finalReplacements);
      }
    }

    // 3. 标记模板使用
    if (templateService != null) {
      await templateService!.markTemplateAsUsed(template.id);
    }

    // 4. 更新消息，显示正在执行
    final message = messageService.getMessage(conversation.id, messageId);
    if (message != null) {
      await messageService.updateMessage(
        message.copyWith(
          content: '正在执行工具模版: ${template.name}',
          isGenerating: true,
          toolCall: ToolCallResponse(steps: steps),
          matchedTemplateIds: [], // 清除匹配列表（必须用空列表，null不会清除）
        ),
      );
    }

    // 5. 执行工具步骤
    await _executeToolSteps(messageId, steps);

    // 6. 构建执行结果摘要
    final resultSummary = _buildToolResultMessage(steps);

    // 7. 更新消息内容（保留toolCall数据，确保包含最新的步骤状态）
    final finalMessage = messageService.getMessage(conversation.id, messageId);
    if (finalMessage != null) {
      final updatedMessage = finalMessage.copyWith(
        content: '已执行工具模版: ${template.name}\n\n执行结果：\n$resultSummary',
        // 保留toolCall，确保包含最新的步骤执行状态
        toolCall: ToolCallResponse(steps: steps),
        // 清除matchedTemplateIds，否则UI会优先显示模板选择而不是工具调用步骤
        matchedTemplateIds: [],
        // 保持 isGenerating = true，等待 AI 回复完成后再设置为 false
        // isGenerating 会在 _continueWithToolResult 完成后由 completeAIMessage 设置
      );
      await messageService.updateMessage(updatedMessage);

      // 8. 保存消息详情（用于后续查看工具调用详情）
      await _saveToolTemplateDetail(
        messageId: messageId,
        aiMessage: updatedMessage,
        template: template,
        steps: steps,
        resultSummary: resultSummary,
        userInput: userInput,
      );
    }

    return resultSummary;
  }

  /// 让 AI 分析用户输入和模板之间的差异，返回修改策略
  Future<TemplateMatch?> _analyzeTemplateModification(
    String userInput,
    SavedToolTemplate template,
  ) async {
    if (_currentAgent == null) return null;

    try {
      // 获取模板的完整代码用于分析（支持 rewrite 场景）
      final steps = _cloneTemplateSteps(template);
      final fullCodePreview = steps.map((step) {
        return '### ${step.title}\n```javascript\n${step.data}\n```';
      }).join('\n\n');

      // 获取工具简要列表（用于 rewrite 策略选择工具）
      final toolBriefPrompt = ToolService.getToolBriefPrompt();

      final prompt = '''
分析用户输入和工具模板的差异，选择合适的修改策略。

**模板名称**: ${template.name}
${template.description != null ? '**模板描述**: ${template.description}\n' : ''}
**用户输入**: $userInput

**模板完整代码**:
$fullCodePreview

## 🎯 双策略选择

**策略1: `replace` - 关键词替换**（优先选择）
- 适用：功能相同，只是参数/名称不同
- 示例：模版"签到早起"→用户"签到早睡"，只需替换字符串

**策略2: `rewrite` - 重写代码**
- 适用：逻辑需要修改，简单替换无法满足
- 示例：原记录"个数"，改成记录"时长"（单位和逻辑都变了）
- **选择 rewrite 时，必须指定 needed_tools（需要的工具ID列表）**

## 📝 返回格式

使用 replace 策略：
```json
{
  "strategy": "replace",
  "replacements": [{"from": "代码中实际字符串", "to": "新字符串"}]
}
```

使用 rewrite 策略（第一阶段，仅选择工具）：
```json
{
  "strategy": "rewrite",
  "needed_tools": ["checkin", "tracker"]  // 需要的工具ID列表
}
```

无需修改：
```json
{"strategy": "replace", "replacements": []}
```

⚠️ 注意：
- `strategy` 必填，必须是 "replace" 或 "rewrite"
- 优先使用 replace（能替换解决就不重写）
- replacements 的 `from` 必须是代码中**实际存在**的精确字符串
- rewrite 时必须指定 needed_tools，系统会根据工具ID获取详细API后让你生成代码

---
## 📋 可用工具列表（rewrite 时选择需要的工具）

$toolBriefPrompt
''';

      final buffer = StringBuffer();
      await RequestService.streamResponse(
        agent: _currentAgent!,
        prompt: prompt,
        contextMessages: [],
        responseFormat: ResponseFormat.jsonSchema(
          jsonSchema: JsonSchemaObject(
            name: 'TemplateModification',
            description: '模板修改策略分析结果',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'strategy': {
                  'type': 'string',
                  'enum': ['replace', 'rewrite'],
                  'description': '修改策略',
                },
                'replacements': {
                  'type': 'array',
                  'description': 'replace策略时的替换规则',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'from': {'type': 'string'},
                      'to': {'type': 'string'},
                    },
                    'required': ['from', 'to'],
                    'additionalProperties': false,
                  },
                },
                'needed_tools': {
                  'type': 'array',
                  'description': 'rewrite策略时需要的工具ID列表',
                  'items': {'type': 'string'},
                },
              },
              'required': ['strategy'],
              'additionalProperties': false,
            },
          ),
        ),
        onToken: (token) => buffer.write(token),
        onComplete: () {},
        onError: (error) => debugPrint('AI 参数分析错误: $error'),
      );

      final response = buffer.toString();
      debugPrint('AI 参数分析响应: $response');

      // 使用统一的JSON解析方法
      final json = ToolService.parseJsonFromResponse(response, requiredField: 'strategy');

      if (json == null) {
        debugPrint('⚠️ 解析模板修改策略失败：JSON解析失败');
        return null;
      }
      final strategyStr = json['strategy'] as String? ?? 'replace';
      final strategy = strategyStr == 'rewrite'
          ? TemplateStrategy.rewrite
          : TemplateStrategy.replace;

      debugPrint('AI 分析结果：策略=$strategyStr');

      if (strategy == TemplateStrategy.rewrite) {
        // 第一阶段：获取需要的工具列表
        final neededTools = (json['needed_tools'] as List<dynamic>?)
            ?.map((t) => t as String)
            .toList() ?? [];

        if (neededTools.isEmpty) {
          debugPrint('⚠️ rewrite 策略但没有指定需要的工具');
          return null;
        }

        debugPrint('📋 第一阶段：需要工具 ${neededTools.join(", ")}');

        // 第二阶段：获取工具详细文档，让 AI 生成代码
        final rewrittenSteps = await _generateRewriteCode(
          userInput,
          template,
          fullCodePreview,
          neededTools,
        );

        if (rewrittenSteps == null || rewrittenSteps.isEmpty) {
          debugPrint('⚠️ 第二阶段：生成代码失败');
          return null;
        }

        debugPrint('✅ 第二阶段：生成 ${rewrittenSteps.length} 个步骤');
        return TemplateMatch(
          id: template.id,
          strategy: TemplateStrategy.rewrite,
          rewrittenSteps: rewrittenSteps,
        );
      } else {
        // 解析替换规则
        final replacementsList = json['replacements'] as List<dynamic>? ?? [];
        if (replacementsList.isEmpty) {
          debugPrint('AI 分析结果：无需修改');
          return TemplateMatch(id: template.id, strategy: TemplateStrategy.replace);
        }
        final rules = replacementsList.map((r) => ReplacementRule(
          from: r['from'] as String,
          to: r['to'] as String,
        )).toList();
        debugPrint('AI 分析结果：找到 ${rules.length} 个替换规则');
        return TemplateMatch(
          id: template.id,
          strategy: TemplateStrategy.replace,
          replacements: rules,
        );
      }

    } catch (e) {
      debugPrint('AI 模板修改分析失败: $e');
      return null;
    }
  }

  /// 第二阶段：根据工具详情生成重写代码
  Future<List<Map<String, dynamic>>?> _generateRewriteCode(
    String userInput,
    SavedToolTemplate template,
    String originalCode,
    List<String> neededTools,
  ) async {
    if (_currentAgent == null) return null;

    try {
      // 获取工具详细文档
      final toolDetailPrompt = await ToolService.getToolDetailPrompt(neededTools);

      final prompt = '''
根据用户需求和工具API，重写模板代码。

**用户需求**: $userInput
**原模板名称**: ${template.name}

**原模板代码**（参考结构）:
$originalCode

## 📚 工具详细 API 文档

$toolDetailPrompt

## 📝 返回格式

生成完整的代码步骤：
```json
{
  "steps": [
    {
      "method": "run_js",
      "title": "步骤标题",
      "desc": "步骤描述",
      "data": "JavaScript 代码"
    }
  ]
}
```

⚠️ 要求：
- 代码必须实现用户的需求，不是原模板的功能
- 参考原模板的代码结构和风格
- 使用上方工具 API 文档中的方法
- 禁止硬编码日期时间，使用 Memento.system.getCustomDate()
- 禁止使用占位符，先查询获取真实数据
''';

      final buffer = StringBuffer();
      await RequestService.streamResponse(
        agent: _currentAgent!,
        prompt: prompt,
        contextMessages: [],
        responseFormat: ResponseFormat.jsonSchema(
          jsonSchema: JsonSchemaObject(
            name: 'RewriteCode',
            description: '重写的代码步骤',
            strict: true,
            schema: {
              'type': 'object',
              'properties': {
                'steps': {
                  'type': 'array',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'method': {'type': 'string', 'enum': ['run_js']},
                      'title': {'type': 'string'},
                      'desc': {'type': 'string'},
                      'data': {'type': 'string'},
                    },
                    'required': ['method', 'title', 'desc', 'data'],
                    'additionalProperties': false,
                  },
                },
              },
              'required': ['steps'],
              'additionalProperties': false,
            },
          ),
        ),
        onToken: (token) => buffer.write(token),
        onComplete: () {},
        onError: (error) => debugPrint('AI 代码生成错误: $error'),
      );

      final response = buffer.toString();
      debugPrint('AI 代码生成响应: ${response.substring(0, response.length > 200 ? 200 : response.length)}...');

      // 使用统一的JSON解析方法
      final json = ToolService.parseJsonFromResponse(response, requiredField: 'steps');

      if (json == null) {
        debugPrint('⚠️ 生成重写代码失败：JSON解析失败');
        return null;
      }
      final stepsList = json['steps'] as List<dynamic>?;

      if (stepsList == null || stepsList.isEmpty) {
        return null;
      }

      return stepsList.map((s) => s as Map<String, dynamic>).toList();

    } catch (e) {
      debugPrint('AI 代码生成失败: $e');
      return null;
    }
  }

  
  /// 执行工具模板并让 AI 回复（合并到同一条消息）
  ///
  /// 这个方法会：
  /// 1. 在 aiMessage 上执行工具模板
  /// 2. 设置 toolCall 数据到消息
  /// 3. 让 AI 基于工具执行结果继续生成回复
  Future<void> _executeToolTemplateAndRespond({
    required String aiMessageId,
    required ChatMessage userMessage,
    required SavedToolTemplate template,
  }) async {
    // 1. 执行工具模板（在 aiMessage 上）
    final resultSummary = await _executeTemplateWithSmartReplacement(
      messageId: aiMessageId,
      template: template,
      userInput: userMessage.content.trim(),
    );

    // 2. 更新用户消息的模板元数据
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
    templateMeta['resultSummary'] = resultSummary;
    metadata['toolTemplate'] = templateMeta;

    final updatedUserMessage = userMessage.copyWith(metadata: metadata);
    await messageService.updateMessage(updatedUserMessage);

    // 3. 获取执行后的消息内容（包含工具执行结果）
    final aiMessage = messageService.getMessage(conversation.id, aiMessageId);
    final currentContent = aiMessage?.content ?? resultSummary;

    // 4. 让 AI 基于工具执行结果继续生成回复（在同一条消息上）
    await _continueWithToolResult(aiMessageId, resultSummary, currentContent);
  }

  /// 执行工具调用步骤
  Future<void> _executeToolSteps(
    String messageId,
    List<ToolCallStep> steps,
  ) async {
    // 初始化工具调用上下文（用于步骤间结果传递）
    final jsBridge = JSBridgeManager.instance;
    jsBridge.initToolCallContext(messageId);

    try {
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];

        // 更新步骤状态为运行中（创建新的列表以触发UI更新）
        step.status = ToolCallStatus.running;
        final runningSteps = List<ToolCallStep>.from(steps);
        await _updateMessageToolSteps(messageId, runningSteps);
        notifyListeners(); // 立即通知UI更新

        try {
          // 设置当前执行上下文（供 JavaScript 中的 setResult/getResult 使用）
          jsBridge.setCurrentExecution(messageId, i);

          // 执行步骤
          final result = await ToolService.executeToolStep(step);

          // 自动将步骤结果保存到上下文（供后续步骤通过索引获取）
          jsBridge.setToolCallResult('step_$i', result);

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

      // 注意：不要在这里设置 isGenerating = false
      // 因为可能还需要让 AI 继续生成回复
      // isGenerating 会在 AI 回复完成或 _executeTemplateWithSmartReplacement 结束时设置

      notifyListeners();
    } finally {
      // 清除工具调用上下文
      jsBridge.clearToolCallContext(messageId);
    }
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
      final resetSteps =
          message.toolCall!.steps.map((step) {
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

  // ========== 前台服务管理 ==========

  /// 接收后台服务发送的数据
  void _onReceiveBackgroundData(Object data) {
    debugPrint('📨 [ChatController] 收到后台服务数据: $data');

    if (data is Map<String, dynamic>) {
      final event = data['event'];

      switch (event) {
        case 'cancel_generation':
          // 后台服务请求取消生成
          debugPrint('🛑 [ChatController] 后台服务请求取消生成');
          cancelSending();
          break;

        case 'ai_response_ready':
          // AI 回复完成
          final messageId = data['messageId'] as String?;
          debugPrint('✅ [ChatController] AI 回复完成: $messageId');
          // 刷新消息列表
          notifyListeners();
          break;

        case 'ai_response_error':
          // AI 回复错误
          final error = data['error'] as String?;
          debugPrint('❌ [ChatController] AI 回复错误: $error');
          notifyListeners();
          break;

        default:
          debugPrint('⚠️ [ChatController] 未知事件: $event');
      }
    }
  }

  /// 启动 AI 聊天前台服务（仅 Android）
  Future<void> _startAIChatService(String conversationId, String messageId) async {
    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('ℹ️ [ChatController] 非 Android 平台，跳过前台服务');
      return;
    }

    try {
      final isRunning = await _foregroundTaskManager.isServiceRunning();

      if (!isRunning) {
        debugPrint('🚀 [ChatController] 启动AI聊天前台服务');

        await _foregroundTaskManager.startService(
          serviceId: 257, // 唯一ID（与 TimerService 区分）
          notificationTitle: 'AI助手运行中',
          notificationText: '正在为您生成回复...',
          notificationButtons: [
            const ServiceNotificationButton(key: 'cancel', label: '取消'),
          ],
          notificationInitialRoute: '/chat',
          callback: startAIChatTaskCallback,
        );
      }

      // 发送开始生成的消息到后台服务
      FlutterForegroundTask.sendDataToTask({
        'action': 'start_generation',
        'conversationId': conversationId,
        'messageId': messageId,
      });

      debugPrint('✅ [ChatController] 前台服务启动成功');
    } catch (e) {
      debugPrint('❌ [ChatController] 启动前台服务失败: $e');
    }
  }

  /// 通知后台服务生成完成
  void _notifyGenerationComplete(String content, {int? tokenCount, String? messageId}) {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
      final isInForeground = _isInChatScreen();

      // 获取设置：是否显示token
      final settings = getSettings?.call() ?? {};
      final showToken = settings['showTokenInNotification'] as bool? ?? true;

      FlutterForegroundTask.sendDataToTask({
        'action': 'generation_complete',
        'conversationId': conversation.id,
        'messageId': messageId,
        'preview': preview,
        'isInForeground': isInForeground,
        'showToken': showToken,
        'tokenCount': tokenCount ?? TokenCounterService.estimateTokenCount(content),
      });

      debugPrint('✅ [ChatController] 已通知后台服务生成完成 (token: $tokenCount)');
    } catch (e) {
      debugPrint('❌ [ChatController] 通知生成完成失败: $e');
    }
  }

  /// 通知后台服务生成进度
  void _notifyGenerationProgress(String progress) {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'generation_progress',
        'progress': progress,
      });
    } catch (e) {
      debugPrint('❌ [ChatController] 通知生成进度失败: $e');
    }
  }

  /// 通知后台服务生成错误
  void _notifyGenerationError(String error, {String? messageId}) {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'generation_error',
        'conversationId': conversation.id,
        'messageId': messageId,
        'error': error,
      });

      debugPrint('✅ [ChatController] 已通知后台服务生成错误');
    } catch (e) {
      debugPrint('❌ [ChatController] 通知生成错误失败: $e');
    }
  }

  /// 停止前台服务（如果空闲）
  Future<void> _stopAIChatServiceIfIdle() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      if (!_isSending && await _foregroundTaskManager.isServiceRunning()) {
        await _foregroundTaskManager.stopService();
        debugPrint('✅ [ChatController] 前台服务已停止');
      }
    } catch (e) {
      debugPrint('❌ [ChatController] 停止前台服务失败: $e');
    }
  }

  /// 检查是否在聊天界面
  bool _isInChatScreen() {
    // 方式1: 通过 WidgetsBinding 检查应用状态
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != AppLifecycleState.resumed) {
      return false; // 应用在后台
    }

    // 方式2: 简化实现 - 假设在前台就是在聊天界面
    // TODO: 可以通过路由监听或全局状态更精确判断
    return true;
  }

  @override
  void dispose() {
    // 移除前台服务数据回调
    if (!kIsWeb && Platform.isAndroid) {
      _foregroundTaskManager.removeDataCallback(_onReceiveBackgroundData);
      debugPrint('📝 已移除前台服务数据回调');
    }

    // 清理资源
    super.dispose();
  }
}
