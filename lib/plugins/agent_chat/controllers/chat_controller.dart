import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../../core/plugin_manager.dart';
import '../../openai/openai_plugin.dart';
import '../../openai/models/ai_agent.dart';
import '../../openai/services/request_service.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../models/file_attachment.dart';
import '../services/message_service.dart';
import '../services/conversation_service.dart';
import '../services/token_counter_service.dart';
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

      // 加载Agent
      await _loadAgent();
    } catch (e) {
      debugPrint('初始化聊天控制器失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载Agent
  Future<void> _loadAgent() async {
    try {
      final openAIPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;

      if (openAIPlugin != null) {
        _currentAgent =
            await openAIPlugin.controller.getAgent(conversation.agentId);
      }
    } catch (e) {
      debugPrint('加载Agent失败: $e');
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
    List<File> files,
  ) async {
    if (_currentAgent == null) return;

    final buffer = StringBuffer();
    int tokenCount = 0;

    try {
      // 构建上下文消息
      final contextMessages = _buildContextMessages(userInput);

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

          // 处理thinking标签
          final processedContent =
              RequestService.processThinkingContent(buffer.toString());

          // 更新AI消息
          messageService.updateAIMessageContent(
            conversation.id,
            aiMessageId,
            processedContent,
            tokenCount,
          );
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
        onComplete: () {
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

    // 获取历史消息
    final historyMessages =
        messageService.getLastMessages(conversation.id, contextMessageCount);

    // 转换历史消息
    for (var msg in historyMessages) {
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

    // 添加当前用户消息
    messages.add(
      ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(currentInput),
      ),
    );

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

  /// 重新生成AI回复
  Future<void> regenerateResponse(String userMessageId) async {
    if (_isSending) return;

    try {
      _isSending = true;
      notifyListeners();

      // 获取用户消息
      final userMessage =
          messageService.getMessage(conversation.id, userMessageId);
      if (userMessage == null || !userMessage.isUser) {
        throw Exception('无效的消息ID');
      }

      // 删除之后的AI回复
      await messageService.prepareRegenerate(conversation.id, userMessageId);

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

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}
