import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';
import '../../models/conversation.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import '../../services/tool_service.dart';
import '../../services/token_counter_service.dart';
import 'package:Memento/utils/file_picker_helper.dart';
import 'package:Memento/plugins/openai/services/request_service.dart';
import 'shared/manager_context.dart';
import 'tool_orchestrator.dart';

/// AI 请求处理管理器
///
/// 负责单 Agent AI 请求的三阶段处理
/// - 第零阶段: 工具模板匹配
/// - 第一阶段: 工具需求识别
/// - 第二阶段: 工具执行代码生成
/// 遵循单一职责原则 (SRP)
class AIRequestHandler {
  final ManagerContext context;
  final Conversation conversation;

  /// 当前 Agent getter
  final AIAgent? Function() getCurrentAgent;

  /// 获取工具 Agent（临时创建）
  final Future<AIAgent?> Function(ToolAgentConfig?) getToolAgent;

  /// 是否正在取消
  final bool Function() isCancelling;

  /// 工具调用处理回调
  final Future<void> Function(String messageId, String aiResponse)?
  onHandleToolCall;

  /// 工具调用编排器 - 公共组件
  late final ToolOrchestrator _toolOrchestrator;

  /// 上下文消息缓存（用于保存详细数据）
  final Map<String, List<ChatCompletionMessage>> _contextMessagesCache = {};

  AIRequestHandler({
    required this.context,
    required this.conversation,
    required this.getCurrentAgent,
    required this.getToolAgent,
    required this.isCancelling,
    this.onHandleToolCall,
  }) {
    // 初始化工具调用编排器
    _toolOrchestrator = ToolOrchestrator(
      context: context,
      conversation: conversation,
      getToolAgent:
          (config, {enableFunctionCalling = false}) => getToolAgent(config),
      isCancelling: isCancelling,
    );
  }

  // ========== 核心方法 ==========

  /// 请求 AI 回复（三阶段工具调用：模板匹配 → 工具需求 → 工具调用）
  Future<void> request({
    required String aiMessageId,
    required String userInput,
    List<File> files = const [],
    bool enableToolCalling = true,
  }) async {
    final currentAgent = getCurrentAgent();
    if (currentAgent == null) return;

    final buffer = StringBuffer();
    int tokenCount = 0;
    bool isCollectingToolCall = false;

    try {
      // 构建上下文消息
      final contextMessages = buildContextMessages(userInput);

      // ========== 第零阶段：工具模板匹配（可选）==========
      final preferToolTemplates = context.getSetting<bool>(
        'preferToolTemplates',
        false,
      );

      if (preferToolTemplates == true &&
          enableToolCalling &&
          currentAgent.enableFunctionCalling == true &&
          context.templateService != null) {
        debugPrint('🔍 [第零阶段] 开始工具模板匹配...');

        // 获取所有工具模板
        final templates = await context.templateService!.fetchTemplates();

        if (templates.isNotEmpty) {
          debugPrint('🔍 [第零阶段] 找到 ${templates.length} 个工具模板');

          // 优先尝试精确匹配：使用用户输入标题直接匹配模板名称
          final exactMatchTemplate = context.templateService!.getTemplateByName(
            userInput.trim(),
          );

          if (exactMatchTemplate != null) {
            debugPrint(
              '✅ [第零阶段-精确匹配] 找到完全匹配的模板: ${exactMatchTemplate.name} (ID: ${exactMatchTemplate.id})',
            );

            // 直接使用该模板，跳过 AI 调用
            final message = context.messageService.getMessage(
              context.conversationId,
              aiMessageId,
            );
            if (message != null) {
              final updatedMessage = message.copyWith(
                matchedTemplateIds: [exactMatchTemplate.id],
                content: '我找到了完全匹配的工具模板「${exactMatchTemplate.name}」，请选择是否执行：',
                isGenerating: false,
              );
              await context.messageService.updateMessage(updatedMessage);
            }

            debugPrint('✅ [第零阶段-精确匹配] 已保存匹配结果，等待用户选择');
            return; // 直接返回，跳过后续的 AI 调用和第一阶段
          }

          debugPrint('ℹ️ [第零阶段-精确匹配] 未找到精确匹配，继续 AI 匹配流程');

          // 生成模板列表 Prompt
          final templatePrompt = ToolService.getToolTemplatePrompt(templates);

          // 清空 buffer
          buffer.clear();
          tokenCount = 0;

          // 使用 Completer 等待 onComplete 完成
          final completer = Completer<bool>();

          // 第零阶段：请求 AI 匹配模板
          await RequestService.streamResponse(
            agent: currentAgent,
            prompt: null,
            contextMessages: contextMessages,
            responseFormat: ResponseFormat.jsonSchema(
              jsonSchema: JsonSchemaObject(
                name: 'ToolTemplateMatch',
                description: '工具模板匹配结果',
                strict: true,
                schema: ToolService.toolTemplateMatchSchema,
              ),
            ),
            additionalPrompts: {'tool_templates': templatePrompt},
            shouldCancel: isCancelling,
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
                  debugPrint('✅ [第零阶段] 匹配到 ${matches.length} 个模板');

                  // 过滤出存在的模板，并保存替换规则
                  final validMatches = <TemplateMatch>[];
                  for (final match in matches) {
                    try {
                      final template = context.templateService!.getTemplateById(
                        match.id,
                      );
                      if (template != null) {
                        validMatches.add(match);
                        if (match.replacements != null &&
                            match.replacements!.isNotEmpty) {
                          debugPrint(
                            '  - ${template.name}: ${match.replacements!.length} 个参数替换',
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('⚠️ [第零阶段] 模板 ${match.id} 不存在或加载失败: $e');
                    }
                  }

                  if (validMatches.isNotEmpty) {
                    // 保存匹配的模板 ID 和替换规则到消息元数据
                    final message = context.messageService.getMessage(
                      context.conversationId,
                      aiMessageId,
                    );
                    if (message != null) {
                      // 构建元数据，包含替换规则
                      final metadata = <String, dynamic>{
                        'templateMatches':
                            validMatches.map((m) {
                              final matchData = <String, dynamic>{'id': m.id};
                              if (m.replacements != null &&
                                  m.replacements!.isNotEmpty) {
                                matchData['replacements'] =
                                    m.replacements!
                                        .map(
                                          (r) => {'from': r.from, 'to': r.to},
                                        )
                                        .toList();
                              }
                              return matchData;
                            }).toList(),
                      };

                      final updatedMessage = message.copyWith(
                        matchedTemplateIds:
                            validMatches.map((m) => m.id).toList(),
                        content:
                            '我找到了 ${validMatches.length} 个相关的工具模板，请选择要执行的模板：',
                        isGenerating: false,
                        metadata: metadata,
                      );
                      await context.messageService.updateMessage(
                        updatedMessage,
                      );
                    }

                    debugPrint('✅ [第零阶段] 已保存匹配结果，等待用户选择');
                    completer.complete(true); // 完成，标记为匹配到模板
                    return;
                  }
                }

                debugPrint('ℹ️ [第零阶段] 未匹配到模板或模板为空，继续第一阶段');
                completer.complete(false); // 完成，标记为未匹配
              } catch (e) {
                debugPrint('❌ [第零阶段] 处理匹配结果时出错: $e');
                completer.complete(false);
              }
            },
            onError: (String error) {
              debugPrint('❌ [第零阶段] AI 响应错误: $error');

              // 如果是用户取消操作，直接更新消息并完成
              if (error == '已取消发送') {
                context.messageService.updateAIMessageContent(
                  context.conversationId,
                  aiMessageId,
                  '用户已取消操作',
                  0,
                );
                context.messageService.completeAIMessage(
                  context.conversationId,
                  aiMessageId,
                );
                completer.complete(true); // 标记为已完成，阻止继续执行
              } else {
                completer.complete(false);
              }
            },
          );

          // ⚠️ 关键修复：等待 onComplete 完成并检查结果
          final templateMatched = await completer.future;
          if (templateMatched) {
            debugPrint('🛑 [第零阶段] 已匹配模板，跳过后续阶段');
            return;
          }

          // 如果没有匹配，继续执行下面的第一阶段
          debugPrint('➡️ [第零阶段] 未匹配到模板，继续执行第一阶段');
        }
      }

      // 保存上下文消息（用于后续保存详细数据）
      _contextMessagesCache[aiMessageId] = List.from(contextMessages);

      // 处理文件（仅支持图片 vision 模式）
      final imageFiles =
          files.where((f) => FilePickerHelper.isImageFile(f)).toList();

      // 使用公共的工具调用编排器处理第一阶段和第二阶段
      final needsToolCall = await _toolOrchestrator.processTwoPhaseToolCall(
        agent: currentAgent,
        aiMessageId: aiMessageId,
        contextMessages: contextMessages,
        files: imageFiles,
        userInput: userInput,
        enableToolCalling: enableToolCalling,
        buffer: buffer,
        tokenCount: tokenCount,
        isCollectingToolCall: isCollectingToolCall,
        onUpdateMessage: (content, count) {
          final processedContent = RequestService.processThinkingContent(
            content,
          );
          context.messageService.updateAIMessageContent(
            context.conversationId,
            aiMessageId,
            processedContent,
            count,
          );
        },
        onError: (error) {
          final errorMessage =
              error == '已取消发送' ? '用户已取消操作' : '抱歉，生成回复时出现错误：$error';
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
        },
        onFirstPhaseComplete: (toolCallCode) async {
          // 执行工具调用
          if (ToolService.containsToolCall(toolCallCode)) {
            if (onHandleToolCall != null) {
              await onHandleToolCall!(aiMessageId, toolCallCode);
            }
          } else {
            // 没有生成工具调用，直接完成
            processNormalResponse(aiMessageId, toolCallCode);
          }
        },
      );

      // 如果不需要工具调用，完成消息
      if (!needsToolCall) {
        context.messageService.completeAIMessage(
          context.conversationId,
          aiMessageId,
        );
      }
    } catch (e) {
      debugPrint('请求 AI 回复失败: $e');

      context.messageService.updateAIMessageContent(
        context.conversationId,
        aiMessageId,
        '抱歉，生成回复时出现错误：$e',
        0,
      );

      context.messageService.completeAIMessage(
        context.conversationId,
        aiMessageId,
      );
    }
  }

  /// 处理正常回复（无需工具调用）
  void processNormalResponse(String messageId, String content) {
    final processedContent = RequestService.processThinkingContent(content);

    context.messageService.updateAIMessageContent(
      context.conversationId,
      messageId,
      processedContent,
      TokenCounterService.estimateTokenCount(content),
    );

    context.messageService.completeAIMessage(context.conversationId, messageId);

    // 更新会话的最后消息
    context.conversationService.updateLastMessage(
      context.conversationId,
      processedContent.length > 50
          ? '${processedContent.substring(0, 50)}...'
          : processedContent,
    );
  }

  /// 构建上下文消息列表
  List<ChatCompletionMessage> buildContextMessages(String currentInput) {
    print('═══════════════════════════════════════════');
    print('🔍 [DEBUG] buildContextMessages 被调用！');
    print('═══════════════════════════════════════════');

    final messages = <ChatCompletionMessage>[];
    final currentAgent = getCurrentAgent();

    // 调试日志
    print('🤖 当前Agent: ${currentAgent?.name ?? 'null'}');
    print('📝 Agent消息数量: ${currentAgent?.messages?.length ?? 0}');
    debugPrint('🤖 当前Agent: ${currentAgent?.name ?? 'null'}');
    debugPrint('📝 Agent消息数量: ${currentAgent?.messages?.length ?? 0}');

    // 添加系统提示词
    if (currentAgent != null) {
      String systemPrompt = currentAgent.systemPrompt;

      // 如果有选中的工具，添加工具提示
      final tools = _getSelectedTools();
      if (tools.isNotEmpty) {
        final toolNames = tools
            .map((t) => t['toolName'] ?? t['toolId'])
            .join('、');
        systemPrompt += '\n\n用户希望使用以下工具: $toolNames';
      }

      messages.add(ChatCompletionMessage.system(content: systemPrompt));

      // 添加预设消息（在 system prompt 之后）
      if (currentAgent.messages != null && currentAgent.messages!.isNotEmpty) {
        print('📋 开始添加预设消息，共 ${currentAgent.messages!.length} 条');
        debugPrint('📋 开始添加预设消息，共 ${currentAgent.messages!.length} 条');
        for (final prompt in currentAgent.messages!) {
          print(
            '  - 类型: ${prompt.type}, 内容: ${prompt.content.substring(0, prompt.content.length > 30 ? 30 : prompt.content.length)}${prompt.content.length > 30 ? '...' : ''}',
          );
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
              print('  ⚠️ 跳过system类型的消息');
              debugPrint('  ⚠️ 跳过system类型的消息');
              continue;
          }
        }
        print('✅ 预设消息添加完成，当前messages列表长度: ${messages.length}');
        debugPrint('✅ 预设消息添加完成');
      } else {
        print('⚠️ 当前Agent没有配置messages或messages为空');
        debugPrint('⚠️ 当前Agent没有配置messages或messages为空');
      }
    } else {
      print('❌ 当前Agent为null');
      debugPrint('❌ 当前Agent为null');
    }

    // 获取历史消息（排除正在生成的消息，保留子消息以避免丢失工具结果）
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
    final contextMessageCount = conversation.contextMessageCount ?? 10;
    final contextMessages =
        messagesAfterDivider.length > contextMessageCount
            ? messagesAfterDivider.sublist(
              messagesAfterDivider.length - contextMessageCount,
            )
            : messagesAfterDivider;

    // 转换历史消息为 API 格式（排除会话分隔符）
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

    // ⚠️ 关键修复:添加当前用户输入到消息列表
    // 注意:图片会在后续通过 vision 模式单独处理
    if (currentInput.isNotEmpty) {
      messages.add(
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.string(currentInput),
        ),
      );
      debugPrint('✅ 添加当前用户输入到消息列表: $currentInput');
    }

    return messages;
  }

  // ========== 私有方法 ==========

  /// 获取选中的工具列表
  List<Map<String, String>> _getSelectedTools() {
    final metadata = conversation.metadata;
    if (metadata == null) return [];
    final tools = metadata['selectedTools'];
    if (tools is List) {
      return tools.map((e) => Map<String, String>.from(e as Map)).toList();
    }
    return [];
  }

  /// 提取模板结果
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

  /// 清除上下文消息缓存
  void clearContextMessagesCache(String messageId) {
    _contextMessagesCache.remove(messageId);
  }

  /// 获取缓存的上下文消息
  List<ChatCompletionMessage>? getCachedContextMessages(String messageId) {
    return _contextMessagesCache[messageId];
  }
}
