import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:memento_foreground_service/memento_foreground_service.dart';
import 'package:Memento/core/services/foreground_task_manager.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/agent_chat/models/conversation.dart';
import 'package:Memento/plugins/agent_chat/models/chat_message.dart';
import 'package:Memento/plugins/agent_chat/models/agent_chain_node.dart';
import 'package:Memento/plugins/agent_chat/models/file_attachment.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/plugins/agent_chat/models/saved_tool_template.dart';
import 'package:Memento/plugins/agent_chat/services/message_service.dart';
import 'package:Memento/plugins/agent_chat/services/conversation_service.dart';
import 'package:Memento/plugins/agent_chat/services/token_counter_service.dart';
import 'package:Memento/plugins/agent_chat/services/tool_template_service.dart';
import 'package:Memento/plugins/agent_chat/services/message_detail_service.dart';
import 'package:Memento/plugins/agent_chat/services/chat_task_handler.dart';
export '../services/tool_service.dart' show TemplateMatch, ReplacementRule, TemplateStrategy;
import 'package:Memento/utils/file_picker_helper.dart';
import 'managers/managers.dart';

/// 聊天控制器 (重构版)
///
/// 使用管理器模式重构，将职责拆分为多个专业管理器：
/// - AgentManager: Agent 加载和配置
/// - MessageSender: 消息发送和附件处理
/// - AIRequestHandler: AI 请求处理
/// - AgentChainExecutor: Agent 链执行
/// - ToolExecutor: 工具调用执行
/// - TemplateExecutor: 工具模板管理
/// - ForegroundServiceManager: 前台服务管理
///
/// 遵循单一职责原则 (SRP)，提高代码可维护性和可测试性
class ChatController extends ChangeNotifier {
  final Conversation conversation;
  final MessageService messageService;
  final ConversationService conversationService;
  final MessageDetailService messageDetailService;
  final ToolTemplateService? templateService;
  final Map<String, dynamic> Function()? getSettings; // 获取插件设置的回调

  // ========== 管理器实例 ==========

  /// 共享上下文
  late final ManagerContext _context;

  /// Agent 管理器
  late final AgentManager _agentManager;

  /// 消息发送器
  late final MessageSender _messageSender;

  /// AI 请求处理器
  late final AIRequestHandler _aiRequestHandler;

  /// Agent 链执行器
  late final AgentChainExecutor _agentChainExecutor;

  /// 工具执行器
  late final ToolExecutor _toolExecutor;

  /// 模板执行器
  late final TemplateExecutor _templateExecutor;

  /// 前台服务管理器
  late final ChatForegroundServiceManager _foregroundServiceManager;

  // ========== 内部状态 ==========

  /// 前台服务管理器（仅 Android）
  final ForegroundTaskManager _foregroundTaskManager = ForegroundTaskManager();

  /// 是否正在加载
  bool _isLoading = false;

  /// 是否正在发送消息
  bool _isSending = false;

  /// 是否正在取消发送
  bool _isCancelling = false;

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

  /// 当前 Agent (通过 AgentManager 获取)
  AIAgent? get currentAgent => _agentManager.currentAgent;

  /// Agent 链 (通过 AgentManager 获取)
  List<AIAgent> get agentChain => _agentManager.agentChain;

  /// 是否链式模式 (通过 AgentManager 获取)
  bool get isChainMode => _agentManager.isChainMode;

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

  /// 当前输入的 token 数（估算）
  int get inputTokenCount {
    return _messageSender.inputTokenCount;
  }

  /// 选中的文件附件
  List<File> get selectedFiles => _messageSender.selectedFiles;

  /// 选中的工具模板
  SavedToolTemplate? get selectedToolTemplate => _messageSender.selectedToolTemplate;

  /// 当前输入文本
  String get inputText => _messageSender.inputText;

  /// 已选工具列表
  List<Map<String, String>> get selectedTools {
    final currentConv = _agentManager.currentConversation ?? conversation;
    final metadata = currentConv.metadata;
    if (metadata == null) return [];
    final tools = metadata['selectedTools'];
    if (tools is List) {
      return tools.map((e) => Map<String, String>.from(e as Map)).toList();
    }
    return [];
  }

  // ========== 工具管理 ==========

  /// 获取工具模板列表
  Future<List<SavedToolTemplate>> fetchToolTemplates({String? keyword}) async {
    if (templateService == null) return [];
    return templateService!.fetchTemplates(query: keyword);
  }

  /// 设置选中的工具模板
  void setSelectedToolTemplate(SavedToolTemplate? template) {
    _messageSender.setSelectedToolTemplate(template);
    notifyListeners();
  }

  /// 清除选中的工具模板
  void clearSelectedToolTemplate() {
    _messageSender.clearSelectedToolTemplate();
    notifyListeners();
  }

  /// 移除文件
  void removeFile(int index) {
    _messageSender.removeFile(index);
    notifyListeners();
  }

  /// 设置初始文件（用于 Shortcuts 等外部调用）
  void setInitialFiles(List<File> files) {
    _messageSender.selectedFiles.clear();
    _messageSender.selectedFiles.addAll(files);
    notifyListeners();
  }

  // ========== 初始化 ==========

  /// 初始化聊天控制器
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 创建共享上下文
      _context = ManagerContext(
        conversationId: conversation.id,
        messageService: messageService,
        conversationService: conversationService,
        messageDetailService: messageDetailService,
        templateService: templateService,
        getSettings: getSettings,
        notifyListeners: notifyListeners,
      );

      // 初始化所有管理器
      _agentManager = AgentManager(
        context: _context,
        conversationService: conversationService,
      );

      _messageSender = MessageSender(
        context: _context,
        conversation: conversation,
      );

      _toolExecutor = ToolExecutor(
        context: _context,
        onContinueWithToolResult: _continueWithToolResult,
      );

      _templateExecutor = TemplateExecutor(
        context: _context,
        getCurrentAgent: () => _agentManager.currentAgent,
        executeToolSteps: _executeToolSteps,
      );

      _aiRequestHandler = AIRequestHandler(
        context: _context,
        conversation: conversation,
        getCurrentAgent: () => _agentManager.currentAgent,
        getToolAgent: _agentManager.getToolAgent,
        isCancelling: () => _isCancelling,
      );

      _agentChainExecutor = AgentChainExecutor(
        context: _context,
        conversation: conversation,
        getAgentChain: () => _agentManager.agentChain,
        getToolAgent: _agentManager.getToolAgent,
        isCancelling: () => _isCancelling,
      );

      _foregroundServiceManager = ChatForegroundServiceManager(
        context: _context,
        isSendingGetter: () => _isSending,
        onCancelRequested: cancelSending,
      );

      debugPrint('📝 初始化管理器完成');

      // 初始化 AgentManager
      await _agentManager.initialize(conversation);

      // 初始化前台服务管理器
      await _foregroundServiceManager.initialize();

      // 加载消息
      await messageService.setCurrentConversation(conversation.id);

      debugPrint('✅ ChatController 初始化完成');
    } catch (e, stackTrace) {
      debugPrint('❌ ChatController 初始化失败: $e\n$stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 工具步骤回调 ==========

  /// 执行工具步骤
  Future<void> _executeToolSteps(String messageId, List<ToolCallStep> steps) async {
    debugPrint('🔧 执行工具步骤: $messageId, 共 ${steps.length} 步');

    try {
      for (var step in steps) {
        debugPrint('  - 执行步骤: ${step.title}');
        // 这里应该执行具体的工具步骤
      }
    } catch (e) {
      debugPrint('❌ 执行工具步骤失败: $e');
      rethrow;
    }
  }

  /// 工具结果续写
  Future<void> _continueWithToolResult(String messageId, String toolResult, String currentContent) async {
    debugPrint('🔄 工具结果续写: $messageId');

    try {
      // 让 AI 基于工具结果继续生成回复
      final aiMessage = messageService.getMessage(conversation.id, messageId);
      if (aiMessage != null) {
        await _aiRequestHandler.request(
          aiMessageId: messageId,
          userInput: toolResult,
          files: [],
          enableToolCalling: true,
        );
      }
    } catch (e) {
      debugPrint('❌ 工具结果续写失败: $e');
      rethrow;
    }
  }

  /// 执行工具模板并回复
  Future<void> _executeToolTemplateAndRespond({
    required String aiMessageId,
    required ChatMessage userMessage,
    required SavedToolTemplate template,
  }) async {
    debugPrint('🔧 执行工具模板: ${template.name}');

    try {
      // 1. 执行工具模板（在 aiMessage 上）
      final resultSummary = await _templateExecutor.executeWithSmartReplacement(
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
    } catch (e) {
      debugPrint('❌ 执行工具模板失败: $e');
      rethrow;
    }
  }

  // ========== 公共方法 ==========

  /// 发送消息
  Future<void> sendMessage() async {
    // 如果正在发送，直接返回
    if (_isSending) return;

    // 检查输入内容
    final text = _messageSender.inputText.trim();
    if (text.isEmpty &&
        _messageSender.selectedToolTemplate == null &&
        _messageSender.selectedFiles.isEmpty) {
      debugPrint('⚠️ 消息内容为空');
      return;
    }

    // 检查是否配置了 agent
    // agentChain getter 会在单agent模式下返回 [currentAgent]，统一处理
    if (_agentManager.agentChain.isEmpty) {
      throw Exception('未选择 Agent');
    }

    _isSending = true;
    _isCancelling = false; // 重置取消标志
    notifyListeners();

    try {
      // 构建 metadata
      final metadata = <String, dynamic>{};
      if (_messageSender.selectedToolTemplate != null) {
        metadata['toolTemplate'] = {
          'id': _messageSender.selectedToolTemplate!.id,
          'name': _messageSender.selectedToolTemplate!.name,
          if (_messageSender.selectedToolTemplate!.description?.isNotEmpty ?? false)
            'description': _messageSender.selectedToolTemplate!.description,
        };
      }

      // 创建用户消息
      final userMessage = ChatMessage.user(
        conversationId: conversation.id,
        content: text,
        tokenCount: TokenCounterService.estimateTokenCount(text),
        attachments: await _processAttachments(),
      ).copyWith(metadata: metadata.isNotEmpty ? metadata : null);

      // 保存用户消息
      await messageService.addMessage(userMessage);

      // 更新会话的最后消息
      await conversationService.updateLastMessage(
        conversation.id,
        text,
      );

      // 清空输入
      final userInput = text;
      final files = List<File>.from(_messageSender.selectedFiles);
      final selectedTemplate = _messageSender.selectedToolTemplate;
      _messageSender.setInputText('');
      _messageSender.clearFiles();
      _messageSender.clearSelectedToolTemplate();
      notifyListeners();

      // 启动前台服务（仅 Android，且用户启用了后台服务）
      final settings = getSettings?.call() ?? {};
      final enableBackgroundService =
          settings['enableBackgroundService'] as bool? ?? true;

      if (!kIsWeb && Platform.isAndroid && enableBackgroundService) {
        // 使用第一个 agent 的消息 ID
        final firstMessageId = '${conversation.id}_chain_0';
        await _startAIChatService(conversation.id, firstMessageId);
      }

      // 工具模板是特殊的执行路径
      // 如果用户选择了工具模板，需要单独处理
      if (selectedTemplate != null) {
        // 创建 AI 消息占位符
        final aiMessage = ChatMessage.ai(
          conversationId: conversation.id,
          content: '',
          isGenerating: true,
        );
        await messageService.addMessage(aiMessage);

        // 执行工具模板并回复
        await _executeToolTemplateAndRespond(
          aiMessageId: aiMessage.id,
          userMessage: userMessage,
          template: selectedTemplate,
        );
      } else {
        // 统一使用链式调用逻辑
        // 单agent会被 AgentManager 包装成长度为1的链，确保工具调用正常触发
        await _agentChainExecutor.executeChain(
          userInput: userInput,
          files: files,
          selectedTemplate: null, // 工具模板已单独处理
        );
      }
    } catch (e) {
      debugPrint('❌ 发送消息失败: $e');
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// 取消发送
  void cancelSending() {
    if (!_isSending) return;

    _isCancelling = true;
    notifyListeners();

    // 停止当前正在生成的消息
    final generatingMessages = messageService.currentMessages
        .where((msg) => msg.isGenerating && !msg.isUser)
        .toList();

    for (var msg in generatingMessages) {
      final updatedMsg = msg.copyWith(isGenerating: false);
      messageService.updateMessage(updatedMsg);
    }

    _isSending = false;
    _isCancelling = false;
    notifyListeners();

    debugPrint('🛑 已取消当前生成');
  }

  /// 处理附件
  Future<List<FileAttachment>> _processAttachments() async {
    final attachments = <FileAttachment>[];

    for (var file in _messageSender.selectedFiles) {
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

  /// 启动 AI 聊天前台服务（仅 Android）
  Future<void> _startAIChatService(String conversationId, String messageId) async {
    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('ℹ️ [ChatController] 非 Android 平台，跳过前台服务');
      return;
    }

    try {
      final isRunning = await _foregroundTaskManager.isServiceRunning();

      if (!isRunning) {
        debugPrint('🚀 [ChatController] 启动 AI 聊天前台服务');

        await _foregroundTaskManager.startService(
          serviceId: 257, // 唯一 ID（与 TimerService 区分）
          notificationTitle: 'AI 助手运行中',
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

  /// 选择图片
  Future<void> pickImages() async {
    await _messageSender.pickImages();
    notifyListeners();
  }

  /// 选择文档
  Future<void> pickDocuments() async {
    await _messageSender.pickDocuments();
    notifyListeners();
  }

  /// 设置输入文本
  void setInputText(String text) {
    _messageSender.setInputText(text);
    notifyListeners();
  }

  /// 添加文件
  void addFiles(List<File> files) {
    // 使用 MessageSender 的 getter 获取列表并添加
    final selectedFiles = _messageSender.selectedFiles;
    selectedFiles.addAll(files);
    notifyListeners();
  }

  /// 清除选中的文件
  void clearSelectedFiles() {
    _messageSender.clearFiles();
    notifyListeners();
  }

  /// 选择工具模板
  void selectToolTemplate(SavedToolTemplate? template) {
    _messageSender.setSelectedToolTemplate(template);
    notifyListeners();
  }

  /// 选择并加载 Agent
  Future<void> selectAgent(String agentId) async {
    await _agentManager.selectAgent(agentId);
  }

  /// 选择并配置 Agent 链
  Future<void> selectAgentChain(List<AgentChainNode> chainNodes) async {
    await _agentManager.selectAgentChain(chainNodes);
  }

  /// 配置工具调用专用 Agent
  Future<void> configureToolAgents({
    ToolAgentConfig? toolDetectionConfig,
    ToolAgentConfig? toolExecutionConfig,
  }) async {
    await _agentManager.configureToolAgents(
      toolDetectionConfig: toolDetectionConfig,
      toolExecutionConfig: toolExecutionConfig,
    );
  }

  /// 切换回单 Agent 模式
  Future<void> switchToSingleAgent(String agentId) async {
    await _agentManager.switchToSingleAgent(agentId);
  }

  /// 获取可用的 Agent 列表
  Future<List<AIAgent>> getAvailableAgents() async {
    return await _agentManager.getAvailableAgents();
  }

  /// 重新生成 AI 回复
  Future<void> regenerateResponse(String messageId) async {
    debugPrint('🔄 重新生成消息: $messageId');

    try {
      final message = messageService.getMessage(conversation.id, messageId);
      if (message != null && message.parentId != null) {
        // 获取父消息（用户消息）
        final parentMessage = messageService.getMessage(conversation.id, message.parentId!);
        if (parentMessage != null) {
          // 删除当前消息，重新生成
          await messageService.deleteMessage(conversation.id, messageId);
          // 重新发送父消息
          await sendMessage();
        }
      }
    } catch (e) {
      debugPrint('❌ 重新生成失败: $e');
      rethrow;
    }
  }

  /// 编辑消息
  Future<void> editMessage(String messageId, String newContent) async {
    debugPrint('✏️ 编辑消息: $messageId');

    try {
      final message = messageService.getMessage(conversation.id, messageId);
      if (message != null) {
        final updatedMessage = message.copyWith(content: newContent);
        await messageService.updateMessage(updatedMessage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ 编辑消息失败: $e');
      rethrow;
    }
  }

  /// 删除消息
  Future<void> deleteMessage(String messageId) async {
    debugPrint('🗑️ 删除消息: $messageId');

    try {
      await messageService.deleteMessage(conversation.id, messageId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 删除消息失败: $e');
      rethrow;
    }
  }

  /// 清除所有消息
  Future<void> clearAllMessages() async {
    debugPrint('🧹 清除所有消息');

    try {
      await messageService.clearAllMessages(conversation.id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 清除消息失败: $e');
      rethrow;
    }
  }

  /// 创建新会话
  Future<void> createNewSession() async {
    debugPrint('📝 创建新会话');

    try {
      // 直接调用 conversationService 的 createConversation 方法
      final newConversation = await conversationService.createConversation(
        title: '新会话',
      );
      debugPrint('✅ 新会话创建成功: ${newConversation.id}');
    } catch (e) {
      debugPrint('❌ 创建新会话失败: $e');
      rethrow;
    }
  }

  /// 清空已选工具
  Future<void> clearSelectedTools() async {
    final currentConv = _agentManager.currentConversation ?? conversation;
    final updatedConv = currentConv.copyWith(metadata: {});
    await conversationService.updateConversation(updatedConv);
    _agentManager.updateConversation(updatedConv);
    notifyListeners();
  }

  /// 添加工具到会话
  Future<void> addToolToConversation(
    String pluginId,
    String toolId,
    String toolName,
  ) async {
    final currentConv = _agentManager.currentConversation ?? conversation;
    final metadata = Map<String, dynamic>.from(currentConv.metadata ?? {});
    final tools = List<Map<String, String>>.from(selectedTools);

    // 检查工具是否已存在
    if (!tools.any((tool) => tool['id'] == toolId)) {
      tools.add({
        'pluginId': pluginId,
        'id': toolId,
        'name': toolName,
      });
      metadata['selectedTools'] = tools;

      final updatedConv = currentConv.copyWith(metadata: metadata);
      await conversationService.updateConversation(updatedConv);
      _agentManager.updateConversation(updatedConv);
      notifyListeners();
    }
  }

  /// 从会话中移除工具
  Future<void> removeToolFromConversation(String toolId) async {
    final currentConv = _agentManager.currentConversation ?? conversation;
    final metadata = Map<String, dynamic>.from(currentConv.metadata ?? {});
    final tools = List<Map<String, String>>.from(selectedTools)
      ..removeWhere((tool) => tool['id'] == toolId);
    metadata['selectedTools'] = tools;

    final updatedConv = currentConv.copyWith(metadata: metadata);
    await conversationService.updateConversation(updatedConv);
    _agentManager.updateConversation(updatedConv);
    notifyListeners();
  }

  /// 执行匹配的模板
  Future<void> executeMatchedTemplate(
    String aiMessageId,
    SavedToolTemplate template,
  ) async {
    await _templateExecutor.executeMatched(aiMessageId, template.id);
  }

  /// 重新运行工具调用
  Future<void> rerunToolCall(String messageId) async {
    await _toolExecutor.rerunAll(messageId);
  }

  /// 重新运行单个步骤
  Future<void> rerunSingleStep(String messageId, int stepIndex) async {
    await _toolExecutor.rerunSingle(messageId, stepIndex);
  }

  /// 获取总 Token 数
  int getTotalTokens() {
    return messageService.getTotalTokens(conversation.id);
  }

  /// 获取上下文 Token 数
  int getContextTokens() {
    return messageService.getContextTokens(
      conversation.id,
      contextMessageCount,
    );
  }

  /// 判断最后一条消息是否为会话分隔符
  bool get isLastMessageSessionDivider {
    final messages = messageService.currentMessages;
    if (messages.isEmpty) return false;

    final lastMessage = messages.last;
    return lastMessage.content.trim() == '---';
  }

  @override
  void dispose() {
    // 释放所有管理器资源
    _foregroundServiceManager.dispose();

    // 移除前台服务数据回调
    if (!kIsWeb && Platform.isAndroid) {
      _foregroundTaskManager.removeDataCallback(_onReceiveBackgroundData);
      debugPrint('📝 已移除前台服务数据回调');
    }

    debugPrint('🔌 ChatController 已释放');

    super.dispose();
  }
}
