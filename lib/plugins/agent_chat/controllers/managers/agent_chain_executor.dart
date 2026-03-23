import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:uuid/uuid.dart';
import '../../models/conversation.dart';
import '../../models/agent_chain_node.dart';
import '../../models/chat_message.dart';
import '../../models/tool_call_step.dart';
import '../../models/saved_tool_template.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import '../../services/tool_service.dart';
import 'package:Memento/utils/file_picker_helper.dart';
import 'package:Memento/plugins/openai/services/request_service.dart';
import 'shared/manager_context.dart';
import 'tool_executor.dart';
import 'tool_orchestrator.dart';

const _uuid = Uuid();

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
  final Future<AIAgent?> Function(
    ToolAgentConfig?, {
    bool enableFunctionCalling,
  })?
  getToolAgent;

  /// 是否正在取消
  final bool Function() isCancelling;

  /// 工具执行器（链式调用专用，不调用续写回调）
  late final ToolExecutor _toolExecutor;

  /// 工具调用编排器 - 公共组件
  late final ToolOrchestrator _toolOrchestrator;

  AgentChainExecutor({
    required this.context,
    required this.conversation,
    required this.getAgentChain,
    this.getToolAgent,
    required this.isCancelling,
  }) {
    // 创建专用的工具执行器，不传递续写回调
    // 链式调用有自己的逻辑来处理工具执行后的总结
    _toolExecutor = ToolExecutor(
      context: context,
      onContinueWithToolResult: null, // 不调用续写回调
    );

    // 初始化工具调用编排器
    _toolOrchestrator = ToolOrchestrator(
      context: context,
      conversation: conversation,
      getToolAgent: getToolAgent,
      isCancelling: isCancelling,
    );
  }

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

    // 生成本次链式执行的统一ID
    final chainExecutionId = _uuid.v4();
    debugPrint('🆔 链式执行ID: $chainExecutionId');

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
    // 注意：在执行过程中，链可能会动态扩展（插入工具调用agent）
    int i = 0;
    while (i < sortedNodes.length) {
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
        chainExecutionId: chainExecutionId,
      );
      await context.messageService.addMessage(aiMessage);
      chainMessages.add(aiMessage);

      try {
        // 根据上下文模式构建消息列表
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
          userInput: userInput,
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

      i++;
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

    // 添加预设消息（在 system prompt 之后）
    if (agent.messages != null && agent.messages!.isNotEmpty) {
      debugPrint(
        '📋 [链式调用] Agent ${agent.name} 开始添加预设消息，共 ${agent.messages!.length} 条',
      );
      for (final prompt in agent.messages!) {
        debugPrint(
          '  - 类型: ${prompt.type}, 内容: ${prompt.content.substring(0, prompt.content.length > 30 ? 30 : prompt.content.length)}${prompt.content.length > 30 ? '...' : ''}',
        );
        switch (prompt.type) {
          case 'user':
            messages.add(
              ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.string(
                  prompt.content,
                ),
              ),
            );
            break;
          case 'assistant':
            messages.add(
              ChatCompletionMessage.assistant(content: prompt.content),
            );
            break;
          case 'system':
            // System 类型的消息已经添加过了，跳过
            debugPrint('  ⚠️ 跳过system类型的消息');
            continue;
        }
      }
      debugPrint('✅ [链式调用] Agent ${agent.name} 预设消息添加完成');
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
        // 先添加前序 agent 的输出（按时间顺序）
        for (int i = 0; i < stepIndex; i++) {
          final prevMsg = previousMessages[i];
          if (prevMsg.content.isNotEmpty) {
            final prevAgent = agentChain[i];
            // 防护：确保 prevAgent 是有效的 AIAgent 对象
            if (prevAgent != null && prevAgent.name.isNotEmpty) {
              messages.add(
                ChatCompletionMessage.assistant(
                  content: '[${prevAgent.name}]: ${prevMsg.content}',
                ),
              );
            }
          }
        }

        // 最后添加当前用户输入
        messages.add(
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(userInput),
          ),
        );
        break;

      case AgentContextMode.previousOnly:
        // 仅传递上一个 agent 的输出
        if (stepIndex == 0) {
          // 第一个 agent：使用用户原始输入
          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(userInput),
            ),
          );
        } else {
          // 后续 agent：仅使用上一个 agent 的输出，并标明来源
          final prevAgent = agentChain[stepIndex - 1];
          final prevContent = previousMessages[stepIndex - 1].content;

          // 防护：确保 prevAgent 是有效的 AIAgent 对象
          final agentName =
              prevAgent != null && prevAgent.name.isNotEmpty
                  ? prevAgent.name
                  : '未知 Agent';

          messages.add(
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '来自前一步骤 [$agentName] 的输出：\n\n$prevContent\n\n请基于以上内容继续处理。',
              ),
            ),
          );
        }
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
    final thinkingBuffer = StringBuffer(); // 单独收集思考内容
    int tokenCount = 0;
    bool isCollectingToolCall = false;

    // 使用 Completer 确保等待所有操作完成（包括 onComplete 中的异步操作）
    final operationCompleter = Completer<void>();

    try {
      // 处理图片文件
      final imageFiles =
          files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      // 使用公共的工具调用编排器处理第一阶段和第二阶段
      final needsToolCall = await _toolOrchestrator.processTwoPhaseToolCall(
        agent: agent,
        aiMessageId: aiMessageId,
        contextMessages: contextMessages,
        files: imageFiles,
        userInput: userInput ?? '',
        enableToolCalling: enableToolCalling,
        buffer: buffer,
        tokenCount: tokenCount,
        isCollectingToolCall: isCollectingToolCall,
        onUpdateMessage: (content, count) {
          context.messageService.updateAIMessageContent(
            context.conversationId,
            aiMessageId,
            content,
            count,
          );
        },
        onThinking: (thinking) {
          debugPrint('🧠 [链式调用-Agent ${agent.name}] 收到思考内容: ${thinking.length} 字符');
          thinkingBuffer.write(thinking);
          // 实时更新消息的 thinkingContent 字段
          context.messageService.updateAIMessageThinking(
            context.conversationId,
            aiMessageId,
            thinkingBuffer.toString(),
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

          // 完成操作
          if (!operationCompleter.isCompleted) {
            operationCompleter.complete();
          }
        },
        onFirstPhaseComplete: (toolCallCode) async {
          // 使用内部的方法处理链式调用的完成逻辑
          await _handleChainAgentComplete(
            agent: agent,
            aiMessageId: aiMessageId,
            contextMessages: contextMessages,
            firstResponse: buffer.toString(),
            enableToolCalling: enableToolCalling,
            userInput: userInput,
            operationCompleter: operationCompleter,
            toolCallCode: toolCallCode,
          );
        },
      );

      // 如果不需要工具调用，直接完成消息
      if (!needsToolCall) {
        context.messageService.completeAIMessage(
          context.conversationId,
          aiMessageId,
        );
        debugPrint('✅ Agent ${agent.name} 生成完成（无工具调用）');

        if (!operationCompleter.isCompleted) {
          operationCompleter.complete();
        }
      } else {
        // 等待所有操作完成（包括工具调用）
        await operationCompleter.future;
      }
    } catch (e) {
      debugPrint('❌ 请求 Agent 响应失败: $e');
      if (!operationCompleter.isCompleted) {
        operationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// 处理链式调用中 Agent 完成后的逻辑
  /// [toolCallCode] - 由 ToolOrchestrator 生成的工具调用代码（可能为 null）
  Future<void> _handleChainAgentComplete({
    required AIAgent agent,
    required String aiMessageId,
    required List<ChatCompletionMessage> contextMessages,
    required String firstResponse,
    required bool enableToolCalling,
    String? userInput,
    required Completer<void> operationCompleter,
    String? toolCallCode,
  }) async {
    try {
      // 如果 ToolOrchestrator 已经生成了工具调用代码，直接处理
      if (toolCallCode != null && toolCallCode.isNotEmpty) {
        debugPrint('🔍 [链式调用] 使用 ToolOrchestrator 生成的工具调用代码');
        await _handleSecondPhaseComplete(
          agent: agent,
          aiMessageId: aiMessageId,
          secondResponse: toolCallCode,
          completer: operationCompleter,
        );
      } else if (enableToolCalling &&
          agent.enableFunctionCalling &&
          ToolService.containsToolCall(firstResponse)) {
        // 直接包含工具调用（跳过第一阶段）
        await _toolExecutor.handleToolCall(aiMessageId, firstResponse);
        operationCompleter.complete();
      } else {
        // 无需工具，直接完成
        context.messageService.completeAIMessage(
          context.conversationId,
          aiMessageId,
        );
        debugPrint('✅ Agent ${agent.name} 生成完成');
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
  /// [agent] - 当前执行的agent
  /// [aiMessageId] - 消息ID
  /// [secondResponse] - 第二阶段响应
  /// [completer] - 完成器
  Future<void> _handleSecondPhaseComplete({
    required AIAgent agent,
    required String aiMessageId,
    required String secondResponse,
    required Completer<void> completer,
  }) async {
    try {
      // 执行工具调用
      if (ToolService.containsToolCall(secondResponse)) {
        // 使用内部的工具执行器（不会调用续写回调）
        await _toolExecutor.handleToolCall(aiMessageId, secondResponse);

        // 先标记原消息为完成状态（在生成总结之前）
        // 这样UI可以正确显示步骤已完成
        context.messageService.completeAIMessage(
          context.conversationId,
          aiMessageId,
        );
        debugPrint('✅ [链式调用] 工具执行完成');

        // 工具执行完成后，创建一个临时的"总结agent"（关闭工具调用）
        // 来基于工具结果生成最终回复
        if (agent.enableFunctionCalling) {
          debugPrint('🔧 [链式调用] 创建总结Agent（关闭工具调用）');

          // 获取当前消息（包含工具执行结果）
          final currentMessage = context.messageService.getMessage(
            context.conversationId,
            aiMessageId,
          );

          if (currentMessage != null) {
            // 克隆agent并关闭工具调用
            final summaryAgent = agent.copyWith(enableFunctionCalling: false);

            // 创建新的AI消息用于总结
            // 设置相同的chainExecutionId和isFinalSummary标记
            final summaryMessage = ChatMessage.ai(
              conversationId: context.conversationId,
              content: '',
              isGenerating: true,
              generatedByAgentId: summaryAgent.id,
              chainExecutionId: currentMessage.chainExecutionId,
              isFinalSummary: true, // 标记为最终总结
            );
            await context.messageService.addMessage(summaryMessage);

            // 使用总结agent基于工具结果生成回复
            await _generateSummaryResponse(
              agent: summaryAgent,
              summaryMessageId: summaryMessage.id,
              toolResultMessage: currentMessage,
            );
          }
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

  /// 生成总结回复
  /// [agent] - 总结agent（已关闭工具调用）
  /// [summaryMessageId] - 总结消息ID
  /// [toolResultMessage] - 包含工具执行结果的消息
  Future<void> _generateSummaryResponse({
    required AIAgent agent,
    required String summaryMessageId,
    required ChatMessage toolResultMessage,
  }) async {
    try {
      debugPrint('🤖 [链式调用] 开始生成总结回复');

      // 构建干净的工具结果消息（只包含执行结果，不包含代码）
      final cleanToolResult = _buildCleanToolResult(
        toolResultMessage.toolCall?.steps ?? [],
      );

      // 构建context messages：用户输入 + 干净的工具执行结果
      final summaryContextMessages = <ChatCompletionMessage>[
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(
            '$cleanToolResult\n\n请基于以上工具执行结果，给出简洁明了的总结和建议。',
          ),
        ),
      ];

      final buffer = StringBuffer();
      final thinkingBuffer = StringBuffer(); // 单独收集思考内容
      int tokenCount = 0;

      // 流式请求总结回复（带重试机制，最多10次重试）
      await RequestService.streamResponseWithRetry(
        agent: agent,
        prompt: null,
        contextMessages: summaryContextMessages,
        shouldCancel: isCancelling,
        onToken: (token) {
          buffer.write(token);
          tokenCount++;

          // 实时更新 UI
          context.messageService.updateAIMessageContent(
            context.conversationId,
            summaryMessageId,
            buffer.toString(),
            tokenCount,
          );
        },
        onThinking: (thinking) {
          debugPrint('🧠 [链式调用-总结] 收到思考内容: ${thinking.length} 字符');
          thinkingBuffer.write(thinking);
          // 实时更新消息的 thinkingContent 字段
          context.messageService.updateAIMessageThinking(
            context.conversationId,
            summaryMessageId,
            thinkingBuffer.toString(),
          );
        },
        onComplete: () {
          // 标记消息为完成状态
          context.messageService.completeAIMessage(
            context.conversationId,
            summaryMessageId,
          );
          debugPrint('✅ [链式调用] 总结回复生成完成');
        },
        onError: (error) {
          debugPrint('❌ [链式调用] 总结回复生成失败: $error');

          final errorMessage =
              error == '已取消发送' ? '🛑 用户已取消操作' : '❌ 生成总结时出错: $error';
          context.messageService.updateAIMessageContent(
            context.conversationId,
            summaryMessageId,
            errorMessage,
            0,
          );
          context.messageService.completeAIMessage(
            context.conversationId,
            summaryMessageId,
          );
        },
        maxRetries: 10,
        retryDelay: 1000,
      );
    } catch (e) {
      debugPrint('❌ [链式调用] 生成总结回复失败: $e');
      rethrow;
    }
  }

  /// 构建干净的工具执行结果（只包含结果，不包含代码）
  /// 用于链式调用的最终总结阶段
  String _buildCleanToolResult(List<ToolCallStep> steps) {
    if (steps.isEmpty) {
      return '无工具执行结果';
    }

    final buffer = StringBuffer();
    buffer.writeln('工具执行结果：');
    buffer.writeln();

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      // 只添加步骤标题和结果，不添加代码（data字段）
      buffer.writeln('步骤 ${i + 1}: ${step.title}');

      if (step.result != null) {
        buffer.writeln('结果: ${step.result}');
      } else if (step.error != null) {
        buffer.writeln('错误: ${step.error}');
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
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
