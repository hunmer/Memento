import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../models/conversation.dart';
import '../../models/agent_chain_node.dart';
import '../../models/chat_message.dart';
import '../../models/saved_tool_template.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import '../../services/tool_service.dart';
import 'package:Memento/utils/file_picker_helper.dart';
import 'package:Memento/plugins/openai/services/request_service.dart';
import 'shared/manager_context.dart';

/// Agent 链执行管理器
///
/// 负责 Agent 链式调用的编排和执行
/// 支持三种上下文模式：conversationContext / chainContext / previousOnly
/// 遵循单一职责原则 (SRP)
class AgentChainExecutor {
  final ManagerContext context;
  final Conversation conversation;

  /// Agent 链 getter
  final List<AIAgent> Function() getAgentChain;

  /// 获取工具专用 Agent
  /// 参数：config - Agent配置, enableFunctionCalling - 是否启用工具调用
  final Future<AIAgent?> Function(ToolAgentConfig?, {bool enableFunctionCalling})? getToolAgent;

  /// 是否正在取消
  final bool Function() isCancelling;

  /// 工具调用处理回调
  final Future<void> Function(String messageId, String aiResponse)?
  onHandleToolCall;

  /// 工具结果续写回调
  final Future<void> Function(
    String messageId,
    String toolResult,
    String currentContent,
  )?
  onContinueWithToolResult;

  AgentChainExecutor({
    required this.context,
    required this.conversation,
    required this.getAgentChain,
    this.getToolAgent,
    required this.isCancelling,
    this.onHandleToolCall,
    this.onContinueWithToolResult,
  });

  // ========== 核心方法 ==========

  /// 执行 Agent 链式调用
  /// 支持真正的链式调用和单agent模式（单agent被视为长度为1的链）
  Future<void> executeChain({
    required String userInput,
    required List<File> files,
    SavedToolTemplate? selectedTemplate,
  }) async {
    // 从服务中获取最新的会话数据，避免使用过时的快照
    final latestConversation = context.conversationService.getConversation(
      conversation.id,
    );
    if (latestConversation == null) {
      debugPrint('❌ 未找到会话: ${conversation.id}');
      return;
    }

    // 获取 agent 链（单agent模式下会返回长度为1的链）
    final agentChain = getAgentChain();
    if (agentChain.isEmpty) {
      debugPrint('❌ Agent 链为空，无法执行');
      return;
    }

    debugPrint(
      '🔗 开始执行 Agent 链，共 ${agentChain.length} 个 agent (${latestConversation.isChainMode ? "链式模式" : "单agent模式"})',
    );

    // 获取链节点配置（如果是真正的链式模式）
    // 单agent模式下 chainNodes 为空，我们会临时构造
    final chainNodes = latestConversation.agentChain ?? [];
    List<AgentChainNode> sortedNodes;

    if (chainNodes.isNotEmpty) {
      // 真正的链式模式：使用配置的链节点
      sortedNodes = List<AgentChainNode>.from(chainNodes)
        ..sort((a, b) => a.order.compareTo(b.order));
    } else {
      // 单agent模式：临时构造一个链节点
      sortedNodes = [
        AgentChainNode(
          agentId: agentChain.first.id,
          order: 0,
          contextMode: AgentContextMode.conversationContext,
        ),
      ];
    }

    // 存储每个 agent 的输出消息
    final chainMessages = <ChatMessage>[];

    // 遍历执行每个 agent
    for (int i = 0; i < sortedNodes.length; i++) {
      final node = sortedNodes[i];
      final agent = agentChain[i];

      debugPrint(
        '🔗 [链式调用 ${i + 1}/${sortedNodes.length}] 开始执行 Agent: ${agent.name}',
      );

      // 创建此 agent 的 AI 消息占位符
      final aiMessage = ChatMessage.ai(
        conversationId: latestConversation.id,
        content: '',
        isGenerating: true,
        generatedByAgentId: agent.id,
        chainStepIndex: i,
      );
      await context.messageService.addMessage(aiMessage);
      chainMessages.add(aiMessage);

      try {
        // 根据上下文模式构建消息列表（包含工具列表，如果启用）
        final contextMessages = buildChainContextMessages(
          node: node,
          stepIndex: i,
          userInput: userInput,
          previousMessages: chainMessages,
          enableToolCalling: agent.enableFunctionCalling,
          conv: latestConversation,
        );

        // 调用当前 agent
        await _requestAgentInChain(
          agent: agent,
          aiMessageId: aiMessage.id,
          contextMessages: contextMessages,
          files: i == 0 ? files : [], // 只有第一个 agent 处理文件
          enableToolCalling: agent.enableFunctionCalling,
          userInput: userInput, // 传递用户输入用于工具调用第二阶段
        );

        // 检查是否被取消
        if (isCancelling()) {
          debugPrint('🛑 链式调用被用户取消');
          break;
        }

        // 更新 chainMessages 中的消息为最新版本
        final updatedMessage = context.messageService.getMessage(
          latestConversation.id,
          aiMessage.id,
        );
        if (updatedMessage != null) {
          chainMessages[i] = updatedMessage;
        }

        debugPrint(
          '✅ [链式调用 ${i + 1}/${sortedNodes.length}] Agent ${agent.name} 执行完成',
        );
      } catch (e) {
        debugPrint(
          '❌ [链式调用 ${i + 1}/${sortedNodes.length}] Agent ${agent.name} 执行失败: $e',
        );

        // 错误处理：标记消息并停止链式调用
        final errorMessage = context.messageService.getMessage(
          latestConversation.id,
          aiMessage.id,
        );
        if (errorMessage != null) {
          final updated = errorMessage.copyWith(
            content: '❌ 执行失败: $e',
            isGenerating: false,
          );
          await context.messageService.updateMessage(updated);
        }

        // 停止后续 agent 的执行
        break;
      }
    }

    debugPrint('🏁 链式调用完成');
  }

  /// 根据节点的上下文模式构建消息列表
  List<ChatCompletionMessage> buildChainContextMessages({
    required AgentChainNode node,
    required int stepIndex,
    required String userInput,
    required List<ChatMessage> previousMessages,
    bool enableToolCalling = false,
    Conversation? conv,
  }) {
    // 使用传入的会话或默认的 conversation
    final targetConversation = conv ?? conversation;

    final messages = <ChatCompletionMessage>[];

    final agentChain = getAgentChain();
    if (stepIndex >= agentChain.length) {
      debugPrint('⚠️ 步骤索引超出范围');
      return messages;
    }

    // 获取对应的 agent
    final agent = agentChain[stepIndex];

    // 构建 system prompt（工具列表不再在这里添加，改为通过 additionalPrompts 传递）
    String systemPrompt = agent.systemPrompt;

    debugPrint(
      '🔧 [链式调用] Agent ${agent.name}: enableToolCalling=$enableToolCalling, agent.enableFunctionCalling=${agent.enableFunctionCalling}',
    );

    // 添加系统提示词
    if (systemPrompt.isNotEmpty) {
      messages.add(ChatCompletionMessage.system(content: systemPrompt));
    }

    switch (node.contextMode) {
      case AgentContextMode.conversationContext:
        // 使用会话的历史上下文（遵循 contextMessageCount）
        final historyMessages = _buildConversationContextMessages(
          userInput,
          targetConversation,
        );
        messages.addAll(historyMessages);
        break;

      case AgentContextMode.chainContext:
        // 传递链中所有前序 agent 的输出
        messages.add(
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(userInput),
          ),
        );

        for (int i = 0; i < stepIndex; i++) {
          final prevMsg = previousMessages[i];
          if (prevMsg.content.isNotEmpty) {
            final prevAgent = agentChain[i];
            messages.add(
              ChatCompletionMessage.assistant(
                content: '[${prevAgent.name}]: ${prevMsg.content}',
              ),
            );
          }
        }
        break;

      case AgentContextMode.previousOnly:
        // 仅传递上一个 agent 的输出
        final inputContent =
            stepIndex == 0
                ? userInput
                : previousMessages[stepIndex - 1].content;

        messages.add(
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(inputContent),
          ),
        );
        break;
    }

    return messages;
  }

  // ========== 私有方法 ==========

  /// 在链式调用中请求单个 Agent 的响应
  /// 使用 Completer 确保等待所有异步操作（包括工具调用）完成
  Future<void> _requestAgentInChain({
    required AIAgent agent,
    required String aiMessageId,
    required List<ChatCompletionMessage> contextMessages,
    required List<File> files,
    required bool enableToolCalling,
    String? userInput,
  }) async {
    final buffer = StringBuffer();
    int tokenCount = 0;
    bool isCollectingToolCall = false;

    // 使用 Completer 确保等待所有操作完成（包括 onComplete 中的异步操作）
    final operationCompleter = Completer<void>();

    try {
      // 处理图片文件
      final imageFiles =
          files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      // ========== 第一阶段：工具需求识别 ==========
      // 从最新会话中获取工具识别agent配置
      final latestConversation = context.conversationService.getConversation(
        conversation.id,
      );
      final toolDetectionConfig = latestConversation?.toolDetectionConfig;

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
              '🔧 [链式调用-第一阶段] 使用专用工具识别Agent: ${toolDetectionConfig.providerId}/${toolDetectionConfig.modelId}',
            );
          } else {
            debugPrint(
              '⚠️ [链式调用-第一阶段] 创建工具识别Agent失败，使用原agent',
            );
          }
        } else {
          // 未配置专用agent，使用当前agent + 工具提示词（通过占位符传递）
          debugPrint(
            '🔧 [链式调用-第一阶段] 未配置专用agent，使用原agent + 工具提示词',
          );
        }
      }

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
          tokenCount++;

          final content = buffer.toString();

          // 检测是否为工具需求
          if (enableToolCalling && agent.enableFunctionCalling) {
            final toolRequest = ToolService.parseToolRequest(content);
            final containsToolCall = ToolService.containsToolCall(content);

            if (toolRequest != null || containsToolCall) {
              isCollectingToolCall = true;
              final displayContent = '$content\n\n⚙️ 正在准备工具调用...';
              context.messageService.updateAIMessageContent(
                context.conversationId,
                aiMessageId,
                displayContent,
                tokenCount,
              );
            } else if (!isCollectingToolCall) {
              context.messageService.updateAIMessageContent(
                context.conversationId,
                aiMessageId,
                content,
                tokenCount,
              );
            }
          } else {
            // 实时更新 UI
            context.messageService.updateAIMessageContent(
              context.conversationId,
              aiMessageId,
              content,
              tokenCount,
            );
          }
        },
        onComplete: () {
          // 注意：这里不能是 async，需要在内部处理异步逻辑
          _handleChainAgentComplete(
            agent: agent,
            aiMessageId: aiMessageId,
            contextMessages: contextMessages,
            firstResponse: buffer.toString(),
            enableToolCalling: enableToolCalling,
            userInput: userInput,
            operationCompleter: operationCompleter,
          );
        },
        onError: (error) {
          debugPrint('❌ Agent ${agent.name} 响应错误: $error');

          if (error == '已取消发送') {
            context.messageService.updateAIMessageContent(
              context.conversationId,
              aiMessageId,
              '🛑 用户已取消操作',
              0,
            );
          } else {
            context.messageService.updateAIMessageContent(
              context.conversationId,
              aiMessageId,
              '❌ 错误: $error',
              0,
            );
          }

          context.messageService.completeAIMessage(
            context.conversationId,
            aiMessageId,
          );
          if (!operationCompleter.isCompleted) {
            operationCompleter.complete();
          }
        },
      );

      // 等待所有操作完成（包括工具调用）
      await operationCompleter.future;
    } catch (e) {
      debugPrint('❌ 请求 Agent 响应失败: $e');
      if (!operationCompleter.isCompleted) {
        operationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// 处理链式调用中 Agent 完成后的逻辑（工具识别 → 工具执行）
  void _handleChainAgentComplete({
    required AIAgent agent,
    required String aiMessageId,
    required List<ChatCompletionMessage> contextMessages,
    required String firstResponse,
    required bool enableToolCalling,
    String? userInput,
    required Completer<void> operationCompleter,
  }) async {
    try {
      // ========== 检测工具需求（第一阶段响应）==========
      final toolRequest = ToolService.parseToolRequest(firstResponse);

      if (enableToolCalling &&
          agent.enableFunctionCalling &&
          toolRequest != null &&
          toolRequest.isNotEmpty) {
        debugPrint(
          '🔍 [链式调用] Agent ${agent.name} 请求工具: ${toolRequest.join(", ")}',
        );

        // ========== 第二阶段：生成工具调用代码 ==========
        // 从最新会话中获取工具执行agent配置
        final latestConversation = context.conversationService.getConversation(
          conversation.id,
        );
        final toolExecutionConfig = latestConversation?.toolExecutionConfig;

        AIAgent executionAgent = agent;

        // 获取用户输入（从 contextMessages 中提取最后一个 user 消息）
        final effectiveUserInput =
            userInput ?? _extractUserInput(contextMessages);

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
              '🔧 [链式调用-第二阶段] 使用专用工具执行Agent: ${toolExecutionConfig.providerId}/${toolExecutionConfig.modelId}',
            );
          } else {
            debugPrint(
              '⚠️ [链式调用-第二阶段] 创建工具执行Agent失败，使用原agent',
            );
          }
        } else {
          // 未配置专用agent，使用当前agent + 工具详细文档（通过占位符传递）
          debugPrint(
            '🔧 [链式调用-第二阶段] 未配置专用agent，使用原agent + 工具详细文档',
          );
        }

        // 构建第二阶段的 context messages（用户输入）
        final toolExecutionMessages = [
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(
              '原始用户输入：\n$effectiveUserInput\n\n第一阶段识别的工具：${toolRequest.join(", ")}\n\n请根据文档生成工具调用代码。',
            ),
          ),
        ];

        // 用于第二阶段的 buffer
        final secondBuffer = StringBuffer();
        int secondTokenCount = 0;
        bool secondIsCollecting = false;

        // 使用 Completer 等待第二阶段完成
        final secondPhaseCompleter = Completer<void>();

        // 第二阶段：请求生成工具调用代码
        await RequestService.streamResponse(
          agent: executionAgent,
          prompt: null,
          contextMessages: toolExecutionMessages,
          vision: false,
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
              context.messageService.updateAIMessageContent(
                context.conversationId,
                aiMessageId,
                displayContent,
                secondTokenCount,
              );
            } else if (!secondIsCollecting) {
              context.messageService.updateAIMessageContent(
                context.conversationId,
                aiMessageId,
                content,
                secondTokenCount,
              );
            }
          },
          onError: (error) {
            debugPrint('❌ [链式调用] 第二阶段 Agent ${agent.name} 响应错误: $error');
            final errorMessage =
                error == '已取消发送' ? '🛑 用户已取消操作' : '❌ 生成工具调用时出错: $error';
            context.messageService.updateAIMessageContent(
              context.conversationId,
              aiMessageId,
              errorMessage,
              0,
            );
            context.messageService.completeAIMessage(
              context.conversationId,
              aiMessageId,
            );
            if (!secondPhaseCompleter.isCompleted) {
              secondPhaseCompleter.complete();
            }
          },
          onComplete: () {
            // 处理第二阶段完成
            _handleSecondPhaseComplete(
              aiMessageId: aiMessageId,
              secondResponse: secondBuffer.toString(),
              completer: secondPhaseCompleter,
            );
          },
        );

        // 等待第二阶段完成
        await secondPhaseCompleter.future;
      } else if (enableToolCalling &&
          agent.enableFunctionCalling &&
          ToolService.containsToolCall(firstResponse)) {
        // 直接包含工具调用（跳过第一阶段）
        if (onHandleToolCall != null) {
          await onHandleToolCall!(aiMessageId, firstResponse);
        }
      } else {
        // 无需工具，直接完成
        context.messageService.completeAIMessage(
          context.conversationId,
          aiMessageId,
        );
        debugPrint('✅ Agent ${agent.name} 生成完成');
      }

      // 完成整个操作
      if (!operationCompleter.isCompleted) {
        operationCompleter.complete();
      }
    } catch (e) {
      debugPrint('❌ [链式调用] 处理 Agent 完成逻辑失败: $e');
      context.messageService.updateAIMessageContent(
        context.conversationId,
        aiMessageId,
        '❌ 处理失败: $e',
        0,
      );
      context.messageService.completeAIMessage(
        context.conversationId,
        aiMessageId,
      );
      if (!operationCompleter.isCompleted) {
        operationCompleter.completeError(e);
      }
    }
  }

  /// 处理第二阶段（工具执行）完成
  void _handleSecondPhaseComplete({
    required String aiMessageId,
    required String secondResponse,
    required Completer<void> completer,
  }) async {
    try {
      // 执行工具调用
      if (ToolService.containsToolCall(secondResponse)) {
        if (onHandleToolCall != null) {
          // 执行工具调用
          await onHandleToolCall!(aiMessageId, secondResponse);

          // 链式调用模式下，工具执行完成后直接标记消息为完成状态
          // 不需要继续生成，因为工具结果已经追加到消息内容中
          context.messageService.completeAIMessage(
            context.conversationId,
            aiMessageId,
          );
          debugPrint('✅ [链式调用] 工具执行完成');
        }
      } else {
        // 没有生成工具调用，直接完成
        _processNormalResponse(aiMessageId, secondResponse);
      }
    } catch (e) {
      debugPrint('❌ [链式调用] 第二阶段处理失败: $e');
      context.messageService.updateAIMessageContent(
        context.conversationId,
        aiMessageId,
        '❌ 工具执行失败: $e',
        0,
      );
      context.messageService.completeAIMessage(
        context.conversationId,
        aiMessageId,
      );
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// 处理正常响应
  void _processNormalResponse(String messageId, String content) {
    final processedContent = RequestService.processThinkingContent(content);

    context.messageService.updateAIMessageContent(
      context.conversationId,
      messageId,
      processedContent,
      0,
    );

    context.messageService.completeAIMessage(context.conversationId, messageId);
  }

  /// 从 contextMessages 中提取用户输入
  String _extractUserInput(List<ChatCompletionMessage> messages) {
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg.role == ChatCompletionMessageRole.user) {
        // 尝试从 content 中提取文本
        final content = msg.content;
        if (content != null) {
          // content 可能是 String 或 ChatCompletionUserMessageContent
          final contentStr = content.toString();
          if (contentStr.isNotEmpty) {
            return contentStr;
          }
        }
      }
    }
    return '';
  }

  /// 构建会话历史上下文消息
  List<ChatCompletionMessage> _buildConversationContextMessages(
    String userInput, [
    Conversation? conv,
  ]) {
    // 使用传入的会话或默认的 conversation
    final targetConversation = conv ?? conversation;

    // 这里复用 AIRequestHandler 的逻辑
    // 为了避免循环依赖，暂时简化实现
    final messages = <ChatCompletionMessage>[];

    // 获取历史消息（排除正在生成的消息）
    final allMessages = context.messageService.currentMessages;
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
    final contextMessageCount = targetConversation.contextMessageCount ?? 10;
    final contextMessages =
        messagesAfterDivider.length > contextMessageCount
            ? messagesAfterDivider.sublist(
              messagesAfterDivider.length - contextMessageCount,
            )
            : messagesAfterDivider;

    // 检查最后一条消息是否为当前用户输入（避免重复添加）
    final lastUserMessage =
        contextMessages.isNotEmpty && contextMessages.last.isUser
            ? contextMessages.last.content
            : null;
    final isCurrentInputAlreadyInHistory = lastUserMessage == userInput;

    // 转换历史消息为 API 格式（排除会话分隔符）
    for (var msg in contextMessages) {
      if (msg.isSessionDivider) continue; // 跳过会话分隔符

      // 如果当前输入已在历史中，跳过最后一条用户消息（避免重复）
      if (isCurrentInputAlreadyInHistory && msg == contextMessages.last) {
        continue;
      }

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

    // 添加当前输入
    messages.add(
      ChatCompletionMessage.user(
        content: ChatCompletionUserMessageContent.string(userInput),
      ),
    );

    return messages;
  }
}
