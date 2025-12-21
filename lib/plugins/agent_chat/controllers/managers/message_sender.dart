import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/conversation.dart';
import '../../models/chat_message.dart';
import '../../models/file_attachment.dart';
import '../../models/saved_tool_template.dart';
import '../../services/token_counter_service.dart';
import 'package:Memento/utils/file_picker_helper.dart';
import 'shared/manager_context.dart';

/// 消息发送管理器
///
/// 负责消息发送的准备、附件处理和协调
/// 遵循单一职责原则 (SRP)
class MessageSender {
  final ManagerContext context;
  final Conversation conversation;

  /// 选中的文件附件
  final List<File> _selectedFiles = [];

  /// 当前输入的文本
  String _inputText = '';

  /// 选中的工具模板
  SavedToolTemplate? _selectedToolTemplate;

  MessageSender({
    required this.context,
    required this.conversation,
  });

  // ========== Getters ==========

  List<File> get selectedFiles => _selectedFiles;
  String get inputText => _inputText;
  SavedToolTemplate? get selectedToolTemplate => _selectedToolTemplate;

  /// 当前输入的 token 数（估算）
  int get inputTokenCount {
    int total = TokenCounterService.estimateTokenCount(_inputText);

    // 加上附件的 token
    for (var file in _selectedFiles) {
      if (FilePickerHelper.isImageFile(file)) {
        total += TokenCounterService.estimateImageTokens();
      }
    }

    return total;
  }

  // ========== 输入管理 ==========

  /// 设置输入文本
  void setInputText(String text) {
    _inputText = text;
    context.notify();
  }

  /// 选择图片
  Future<void> pickImages() async {
    final files = await FilePickerHelper.pickImages(multiple: true);
    _selectedFiles.addAll(files);
    context.notify();
  }

  /// 选择文档
  Future<void> pickDocuments() async {
    final files = await FilePickerHelper.pickDocuments(multiple: true);
    _selectedFiles.addAll(files);
    context.notify();
  }

  /// 移除文件
  void removeFile(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      _selectedFiles.removeAt(index);
      context.notify();
    }
  }

  /// 清空文件
  void clearFiles() {
    _selectedFiles.clear();
    context.notify();
  }

  /// 设置选中的工具模板
  void setSelectedToolTemplate(SavedToolTemplate? template) {
    _selectedToolTemplate = template;
    context.notify();
  }

  /// 清除选中的工具模板
  void clearSelectedToolTemplate() {
    _selectedToolTemplate = null;
    context.notify();
  }

  // ========== 核心方法 ==========

  /// 准备发送消息（创建用户消息并清空输入）
  ///
  /// 返回: (userMessage, userInput, files, template)
  Future<({
    ChatMessage userMessage,
    String userInput,
    List<File> files,
    SavedToolTemplate? template,
  })> prepareSend() async {
    // 构建 metadata
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
    await context.messageService.addMessage(userMessage);

    // 更新会话的最后消息
    await context.conversationService.updateLastMessage(
      conversation.id,
      _inputText.trim(),
    );

    // 保存当前状态
    final userInput = _inputText;
    final files = List<File>.from(_selectedFiles);
    final selectedTemplate = _selectedToolTemplate;

    // 清空输入
    _inputText = '';
    _selectedFiles.clear();
    _selectedToolTemplate = null;
    context.notify();

    return (
      userMessage: userMessage,
      userInput: userInput,
      files: files,
      template: selectedTemplate,
    );
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

  // ========== 选中工具管理 ==========

  /// 获取会话选中的工具列表
  List<Map<String, String>> getSelectedTools(Conversation currentConversation) {
    final metadata = currentConversation.metadata;
    if (metadata == null) return [];
    final tools = metadata['selectedTools'];
    if (tools is List) {
      return tools.map((e) => Map<String, String>.from(e as Map)).toList();
    }
    return [];
  }

  /// 添加工具到会话
  Future<Conversation> addToolToConversation(
    Conversation currentConversation,
    String pluginId,
    String toolId,
    String toolName,
  ) async {
    final currentTools = getSelectedTools(currentConversation);

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

      final metadata = Map<String, dynamic>.from(currentConversation.metadata ?? {});
      metadata['selectedTools'] = currentTools;

      final updatedConversation = currentConversation.copyWith(metadata: metadata);
      await context.conversationService.updateConversation(updatedConversation);

      context.notify();
      return updatedConversation;
    }

    return currentConversation;
  }

  /// 移除选中的工具
  Future<Conversation> removeToolFromConversation(
    Conversation currentConversation,
    String pluginId,
    String toolId,
  ) async {
    final currentTools = getSelectedTools(currentConversation);
    currentTools.removeWhere(
      (tool) => tool['pluginId'] == pluginId && tool['toolId'] == toolId,
    );

    final metadata = Map<String, dynamic>.from(currentConversation.metadata ?? {});
    metadata['selectedTools'] = currentTools;

    final updatedConversation = currentConversation.copyWith(metadata: metadata);
    await context.conversationService.updateConversation(updatedConversation);

    context.notify();
    return updatedConversation;
  }

  /// 清空选中的工具
  Future<Conversation> clearSelectedTools(Conversation currentConversation) async {
    final metadata = Map<String, dynamic>.from(currentConversation.metadata ?? {});
    metadata.remove('selectedTools');

    final updatedConversation = currentConversation.copyWith(metadata: metadata);
    await context.conversationService.updateConversation(updatedConversation);

    context.notify();
    return updatedConversation;
  }
}
