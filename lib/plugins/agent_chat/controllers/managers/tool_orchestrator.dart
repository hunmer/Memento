import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../models/conversation.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import '../../services/tool_service.dart';
import 'package:Memento/plugins/openai/services/request_service.dart';
import 'shared/manager_context.dart';

/// 工具调用编排器 - 公共组件
///
/// 负责处理工具调用的两个阶段：
/// - 第一阶段：工具需求识别
/// - 第二阶段：工具执行代码生成
/// 这个类被 AIRequestHandler 和 AgentChainExecutor 共用
class ToolOrchestrator {
  final ManagerContext context;
  final Conversation conversation;

  /// 获取工具专用 Agent
  final Future<AIAgent?> Function(
    ToolAgentConfig?, {
    bool enableFunctionCalling,
  })?
  getToolAgent;

  /// 是否正在取消
  final bool Function() isCancelling;

  ToolOrchestrator({
    required this.context,
    required this.conversation,
    this.getToolAgent,
    required this.isCancelling,
  });

  /// 处理两阶段工具调用
  /// 返回 true 表示需要执行工具调用，false 表示正常回复
  Future<bool> processTwoPhaseToolCall({
    required AIAgent agent,
    required String aiMessageId,
    required List<ChatCompletionMessage> contextMessages,
    required List<File> files,
    required String userInput,
    required bool enableToolCalling,
    required StringBuffer buffer,
    required int tokenCount,
    required bool isCollectingToolCall,
    required Function(String content, int count) onUpdateMessage,
    required Function(String error) onError,
    required Function(String firstResponse) onFirstPhaseComplete,
  }) async {
    // 第一阶段：工具需求识别
    final toolRequest = await _executeFirstPhase(
      agent: agent,
      contextMessages: contextMessages,
      files: files,
      enableToolCalling: enableToolCalling,
      buffer: buffer,
      tokenCount: tokenCount,
      isCollectingToolCall: isCollectingToolCall,
      onUpdateMessage: onUpdateMessage,
      onError: onError,
    );

    // 如果第一阶段返回空，表示没有工具需求或出错
    if (toolRequest == null || toolRequest.isEmpty) {
      return false;
    }

    debugPrint('🔍 识别到工具需求: ${toolRequest.join(", ")}');

    // 第二阶段：生成工具调用代码
    final toolCallCode = await _executeSecondPhase(
      agent: agent,
      toolRequest: toolRequest,
      userInput: userInput,
      firstResponse: buffer.toString(),
      aiMessageId: aiMessageId,
      files: files,
      onUpdateMessage: onUpdateMessage,
      onError: onError,
    );

    // 如果第二阶段成功生成工具调用代码，通知调用者
    if (toolCallCode != null && toolCallCode.isNotEmpty) {
      onFirstPhaseComplete(toolCallCode);
      return true;
    }

    return false;
  }

  /// 执行第一阶段：工具需求识别
  Future<List<String>?> _executeFirstPhase({
    required AIAgent agent,
    required List<ChatCompletionMessage> contextMessages,
    required List<File> files,
    required bool enableToolCalling,
    required StringBuffer buffer,
    required int tokenCount,
    required bool isCollectingToolCall,
    required Function(String content, int count) onUpdateMessage,
    required Function(String error) onError,
  }) async {
    // 处理图片文件
    final imageFiles =
        files.where((f) => f.path != null && f.path.isNotEmpty).toList();

    // 获取工具识别agent配置
    final toolDetectionConfig = conversation.toolDetectionConfig;

    AIAgent effectiveAgent = agent;
    Map<String, String>? additionalPrompts;

    if (enableToolCalling && agent.enableFunctionCalling) {
      // 准备工具简要列表（用于占位符替换）
      final toolBriefPrompt = ToolService.getToolBriefPrompt();
      if (toolBriefPrompt.isNotEmpty) {
        additionalPrompts = {'tool_brief': toolBriefPrompt};
      }

      if (toolDetectionConfig != null && getToolAgent != null) {
        // 使用专用工具识别agent（启用工具调用，返回JSON格式的工具需求）
        final toolAgent = await getToolAgent!(
          toolDetectionConfig,
          enableFunctionCalling: true,
        );
        if (toolAgent != null) {
          effectiveAgent = toolAgent;
          debugPrint(
            '🔧 [第一阶段] 使用专用工具识别Agent: ${toolDetectionConfig.providerId}/${toolDetectionConfig.modelId}',
          );
        } else {
          debugPrint('⚠️ [第一阶段] 创建工具识别Agent失败，使用原agent');
        }
      } else {
        // 未配置专用agent，使用当前agent + 工具提示词（通过占位符传递）
        debugPrint('🔧 [第一阶段] 未配置专用agent，使用原agent + 工具提示词');
      }
    }

    // 使用 Completer 等待第一阶段完成
    final firstPhaseCompleter = Completer<List<String>?>();

    // 流式请求 AI 回复（第一阶段：工具需求识别）
    await RequestService.streamResponse(
      agent: effectiveAgent,
      prompt: null,
      contextMessages: contextMessages,
      vision: imageFiles.isNotEmpty,
      filePath: imageFiles.isNotEmpty ? imageFiles.first.path : null,
      additionalPrompts: additionalPrompts,
      // 如果启用工具调用，使用 JSON Schema 强制返回工具请求格式
      responseFormat:
          enableToolCalling && agent.enableFunctionCalling
              ? ResponseFormat.jsonSchema(
                jsonSchema: JsonSchemaObject(
                  name: 'ToolRequest',
                  description: '工具需求请求',
                  strict: true,
                  schema: ToolService.toolRequestSchema,
                ),
              )
              : null,
      shouldCancel: isCancelling,
      onToken: (token) {
        buffer.write(token);
        final currentTokenCount = buffer.length; // 使用 buffer 长度作为 token 计数
        final content = buffer.toString();

        // 检测是否为工具需求
        if (enableToolCalling && agent.enableFunctionCalling) {
          final toolRequest = ToolService.parseToolRequest(content);
          final containsToolCall = ToolService.containsToolCall(content);

          if (toolRequest != null || containsToolCall) {
            final displayContent = '$content\n\n⚙️ 正在准备工具调用...';
            onUpdateMessage(displayContent, currentTokenCount);
          } else if (content.isNotEmpty) {
            onUpdateMessage(content, currentTokenCount);
          }
        } else {
          // 实时更新 UI
          onUpdateMessage(content, currentTokenCount);
        }
      },
      onComplete: () {
        // 解析第一阶段响应
        final firstResponse = buffer.toString();
        final toolRequest = ToolService.parseToolRequest(firstResponse);

        firstPhaseCompleter.complete(toolRequest);
      },
      onError: (error) {
        debugPrint('❌ 第一阶段 Agent 响应错误: $error');

        if (error == '已取消发送') {
          onUpdateMessage('🛑 用户已取消操作', 0);
        } else {
          onUpdateMessage('❌ 错误: $error', 0);
        }

        firstPhaseCompleter.complete(null);
      },
    );

    return firstPhaseCompleter.future;
  }

  /// 执行第二阶段：生成工具调用代码
  Future<String?> _executeSecondPhase({
    required AIAgent agent,
    required List<String> toolRequest,
    required String userInput,
    required String firstResponse,
    required String aiMessageId,
    required List<File> files,
    required Function(String content, int count) onUpdateMessage,
    required Function(String error) onError,
  }) async {
    // 从最新会话中获取工具执行agent配置
    final toolExecutionConfig = conversation.toolExecutionConfig;

    AIAgent executionAgent = agent;

    // 获取用户输入
    final effectiveUserInput = userInput;

    // 准备工具详细文档（用于占位符替换）
    final detailPrompt = await ToolService.getToolDetailPrompt(toolRequest);
    Map<String, String>? secondAdditionalPrompts;
    if (detailPrompt.isNotEmpty) {
      secondAdditionalPrompts = {'tool_detail': detailPrompt};
    }

    if (toolExecutionConfig != null && getToolAgent != null) {
      // 使用专用工具执行agent（不启用工具调用，只返回JSON格式的代码）
      final toolAgent = await getToolAgent!(
        toolExecutionConfig,
        enableFunctionCalling: false,
      );
      if (toolAgent != null) {
        executionAgent = toolAgent;
        debugPrint(
          '🔧 [第二阶段] 使用专用工具执行Agent: ${toolExecutionConfig.providerId}/${toolExecutionConfig.modelId}',
        );
      } else {
        debugPrint('⚠️ [第二阶段] 创建工具执行Agent失败，使用原agent');
      }
    } else {
      // 未配置专用agent，使用当前agent + 工具详细文档（通过占位符传递）
      debugPrint('🔧 [第二阶段] 未配置专用agent，使用原agent + 工具详细文档');
    }

    // 构建第二阶段的 context messages（用户输入）
    // ⚠️ 关键修复：如果有图片，需要使用 parts 格式传递图片和文字
    final imageFiles =
        files.where((f) => f.path != null && f.path.isNotEmpty).toList();

    final ChatCompletionMessage userMessage;
    if (imageFiles.isNotEmpty) {
      // 包含图片：使用 parts 格式
      final parts = <ChatCompletionMessageContentPart>[
        ChatCompletionMessageContentPart.text(
          text:
              '原始用户输入：\n$effectiveUserInput\n\n第一阶段识别的工具：${toolRequest.join(", ")}\n\n请根据文档生成工具调用代码。',
        ),
      ];

      // 添加图片
      for (var file in imageFiles) {
        try {
          final fileObj = File(file.path);
          if (fileObj.existsSync()) {
            final bytes = fileObj.readAsBytesSync();
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
          debugPrint('读取图片文件失败: ${file.path}, 错误: $e');
        }
      }

      userMessage = ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.parts(parts),
      );
    } else {
      // 不包含图片：使用字符串格式
      userMessage = ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(
          '原始用户输入：\n$effectiveUserInput\n\n第一阶段识别的工具：${toolRequest.join(", ")}\n\n请根据文档生成工具调用代码。',
        ),
      );
    }

    final toolExecutionMessages = [userMessage];

    // 用于第二阶段的 buffer
    final secondBuffer = StringBuffer();
    int secondTokenCount = 0;
    bool secondIsCollecting = false;

    // 使用 Completer 等待第二阶段完成
    final secondPhaseCompleter = Completer<String?>();

    // 第二阶段：请求生成工具调用代码
    await RequestService.streamResponse(
      agent: executionAgent,
      prompt: null,
      contextMessages: toolExecutionMessages,
      additionalPrompts: secondAdditionalPrompts,
      responseFormat: ResponseFormat.jsonSchema(
        jsonSchema: JsonSchemaObject(
          name: 'ToolCall',
          description: '工具调用步骤',
          strict: true,
          schema: ToolService.toolCallSchema,
        ),
      ),
      shouldCancel: isCancelling,
      onToken: (token) {
        secondBuffer.write(token);
        secondTokenCount++;

        final content = secondBuffer.toString();
        if (ToolService.containsToolCall(content)) {
          secondIsCollecting = true;
          final displayContent = '$content\n\n⚙️ 正在准备执行工具...';
          onUpdateMessage(displayContent, secondTokenCount);
        } else if (!secondIsCollecting && content.isNotEmpty) {
          onUpdateMessage(content, secondTokenCount);
        }
      },
      onError: (error) {
        debugPrint('❌ [第二阶段] Agent 响应错误: $error');
        final errorMessage =
            error == '已取消发送' ? '🛑 用户已取消操作' : '❌ 生成工具调用时出错: $error';
        onUpdateMessage(errorMessage, 0);
        secondPhaseCompleter.complete(null);
      },
      onComplete: () {
        // 返回第二阶段响应
        secondPhaseCompleter.complete(secondBuffer.toString());
      },
    );

    return secondPhaseCompleter.future;
  }
}
